program CacheExample;

{ Copyright (c) 2017 - 2018 Sphere 10 Software <https://www.sphere10.com>

  Console examples of cache fetching, admission, notifications and ownership.

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.
}

{$IFDEF FPC}
  {$MODE Delphi}
  {$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, UCommon, UMemory, UCache;

type
  TStringCache = TActionCache<Integer, AnsiString>;

  TPayload = class(TObject)
    public
      Name : AnsiString;
      constructor Create(const AName: AnsiString);
      destructor Destroy; override;
  end;

  TObjectCache = TActionCache<Integer, TPayload>;

  TCacheDemo = class(TObject)
    private
      FRevision : Integer;
      FFetchCount : Integer;
      function FetchString(const AKey: Integer) : AnsiString;
      function FetchPayload(const AKey: Integer) : TPayload;
      procedure Fetching(Sender: TObject; const AKey: Integer);
      procedure Fetched(Sender: TObject; const AKey: Integer; const AValue: AnsiString);
      procedure Removing(Sender: TObject; const AKey: Integer; AItem: TCachedItem<AnsiString>);
      procedure Removed(Sender: TObject; const AKey: Integer; const AValue: AnsiString);
      procedure ShowGlobalFunctions;
      procedure ShowObjectMethods;
      procedure ShowCapacityAndPins;
      procedure ShowOwnedObjects;
    public
      procedure Run;
  end;

function GlobalFetch(const AKey: Integer) : AnsiString;
begin
  Result := 'global value ' + IntToStr(AKey);
end;

function StringSize(const AValue: AnsiString) : SizeInt;
begin
  // Size units are chosen by the caller. Here one unit is one string byte.
  Result := Length(AValue);
end;

function ObjectSize(const AValue: TPayload) : SizeInt;
begin
  // A constant estimator makes capacity an object count.
  Result := 1;
end;

constructor TPayload.Create(const AName: AnsiString);
begin
  inherited Create;
  Name := AName;
end;

destructor TPayload.Destroy;
begin
  WriteLn('  Disposed ', Name);
  inherited;
end;

function TCacheDemo.FetchString(const AKey: Integer) : AnsiString;
begin
  Inc(FFetchCount);
  Result := Format('value %d, revision %d', [AKey, FRevision]);
end;

function TCacheDemo.FetchPayload(const AKey: Integer) : TPayload;
begin
  Result := TPayload.Create('fetched object ' + IntToStr(AKey));
end;

procedure TCacheDemo.Fetching(Sender: TObject; const AKey: Integer);
begin
  WriteLn('  Fetching key ', AKey);
end;

procedure TCacheDemo.Fetched(Sender: TObject; const AKey: Integer; const AValue: AnsiString);
begin
  // This notification follows admission. A handler can inspect cache membership.
  WriteLn('  Fetched key ', AKey, ': ', AValue);
end;

procedure TCacheDemo.Removing(Sender: TObject; const AKey: Integer; AItem: TCachedItem<AnsiString>);
begin
  // Raising here would veto removal while retaining membership and capacity.
  WriteLn('  Removing key ', AKey, ': ', AItem.Value);
end;

procedure TCacheDemo.Removed(Sender: TObject; const AKey: Integer; const AValue: AnsiString);
begin
  WriteLn('  Removed key ', AKey, ': ', AValue);
end;

procedure TCacheDemo.ShowGlobalFunctions;
var
  cache : TStringCache;
  value : AnsiString;
begin
  WriteLn('Global function adapters');
  cache := TStringCache.Create(nil,
    TStringCache.TValueFetcher.FromGlobalFunction(GlobalFetch),
    TStringCache.TSizeEstimator.FromGlobalFunction(StringSize),
    idpNone, TStringCache.TCacheReapPolicy.crpOldest,
    TStringCache.TExpirationPolicy.epNone,
    TStringCache.TNullValuePolicy.nvpCacheNormally, 128, TTimeSpan.MaxValue);
  try
    value := cache[7];
    WriteLn('  ', value);
    WriteLn('  Cached size: ', cache.CurrentSize, ' bytes');
  finally
    cache.Free;
  end;
end;

procedure TCacheDemo.ShowObjectMethods;
var
  cache : TStringCache;
  value : AnsiString;
begin
  WriteLn;
  WriteLn('Object method adapter, hits and invalidation');
  FRevision := 1;
  FFetchCount := 0;
  cache := TStringCache.Create(nil,
    TStringCache.TValueFetcher.FromObjectFunction(FetchString),
    TStringCache.TSizeEstimator.FromGlobalFunction(StringSize),
    idpNone, TStringCache.TCacheReapPolicy.crpOldest,
    TStringCache.TExpirationPolicy.epSinceFetchedTime,
    TStringCache.TNullValuePolicy.nvpCacheNormally, 128, TTimeSpan.FromMinutes(1));
  try
    cache.ItemFetching := Fetching;
    cache.ItemFetched := Fetched;
    cache.ItemRemoving := Removing;
    cache.ItemRemoved := Removed;
    value := cache[7];
    WriteLn('  First read: ', value);
    Inc(FRevision);
    value := cache[7];
    WriteLn('  Cache hit: ', value);
    cache.Invalidate(7);
    value := cache[7];
    WriteLn('  After invalidation: ', value);
    cache[99] := 'explicit value';
    value := cache[99];
    WriteLn('  Explicit write: ', value);
    WriteLn('  Source fetches: ', FFetchCount, ' (expected 2)');
    WriteLn('  Entries: ', cache.ItemCount, ', accesses: ', cache.TotalAccesses);
    cache.Flush;
  finally
    // The cache must be freed before the object supplying its callbacks.
    cache.Free;
  end;
end;

procedure TCacheDemo.ShowCapacityAndPins;
var
  cache : TStringCache;
  released : SizeInt;
begin
  WriteLn;
  WriteLn('Capacity, eviction and pinning');
  cache := TStringCache.Create(nil,
    TStringCache.TValueFetcher.FromGlobalFunction(GlobalFetch),
    TStringCache.TSizeEstimator.FromGlobalFunction(StringSize),
    idpNone, TStringCache.TCacheReapPolicy.crpOldest,
    TStringCache.TExpirationPolicy.epNone,
    TStringCache.TNullValuePolicy.nvpCacheNormally, 6, TTimeSpan.MaxValue);
  try
    cache.ItemRemoving := Removing;
    cache.ItemRemoved := Removed;
    cache[1] := 'one';
    cache[2] := 'two';
    cache.Get(1).CanPurge := false;
    cache[3] := 'new';
    WriteLn('  Pinned key 1 present: ', BoolToStr(cache.ContainsCachedItem(1), true));
    WriteLn('  Evicted key 2 present: ', BoolToStr(cache.ContainsCachedItem(2), true));
    released := cache.Reap(6);
    WriteLn('  Released: ', released, ' bytes; pinned bytes remaining: ', cache.CurrentSize);
    try
      cache[4] := 'four';
    except
      on E: EInvalidOperation do
        WriteLn('  Admission blocked by pin: ', E.Message);
    end;
    cache.Remove(1);
    WriteLn('  Explicit removal ignores pins; entries remaining: ', cache.ItemCount);
  finally
    cache.Free;
  end;
end;

procedure TCacheDemo.ShowOwnedObjects;
var
  cache : TObjectCache;
  payload : TPayload;
begin
  WriteLn;
  WriteLn('Owned objects');
  cache := TObjectCache.Create(nil,
    TObjectCache.TValueFetcher.FromObjectFunction(FetchPayload),
    TObjectCache.TSizeEstimator.FromGlobalFunction(ObjectSize),
    idpFreeAndNil, TObjectCache.TCacheReapPolicy.crpOldest,
    TObjectCache.TExpirationPolicy.epNone,
    TObjectCache.TNullValuePolicy.nvpThrow, 2, TTimeSpan.MaxValue);
  try
    payload := cache[1];
    WriteLn('  Borrowed value: ', payload.Name);
    cache.Remove(1);
    // Removal has freed the payload. Do not dereference or free the old pointer.
    payload := TPayload.Create('explicit object 2');
    try
      cache[2] := payload;
    except
      // A rejected explicit write does not take ownership of its value.
      payload.Free;
      raise;
    end;
    payload := nil;
    WriteLn('  Cache destruction will dispose explicit object 2');
  finally
    cache.Free;
  end;
end;

procedure TCacheDemo.Run;
begin
  ShowGlobalFunctions;
  ShowObjectMethods;
  ShowCapacityAndPins;
  ShowOwnedObjects;
end;

var
  demo : TCacheDemo;
begin
  demo := TCacheDemo.Create;
  try
    demo.Run;
  finally
    demo.Free;
  end;
end.
