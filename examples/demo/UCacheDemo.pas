unit UCacheDemo;

{ Copyright (c) 2017 - 2018 Herman Schoenfeld <https://www.sphere10.com>

  Cache fetching, admission, notifications and ownership in the shared demo.

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.
}

{$IFDEF FPC}
  {$MODE Delphi}
  {$H+}
{$ENDIF}


interface

uses Classes;

{ The caller owns AOutput; all cache instances and callback objects are disposed
  before this synchronous demonstration returns. }
procedure RunCacheExamples(AOutput: TStrings);

implementation

uses SysUtils, UCommon, UMemory, UCache;

type
  TStringCache = TActionCache<Integer, String>;

  TPayload = class(TObject)
    public
      Name : String;
      Output: TStrings;
      constructor Create(const AName: String; AOutput: TStrings);
      destructor Destroy; override;
  end;

  TObjectCache = TActionCache<Integer, TPayload>;

  TCacheDemo = class(TObject)
    private
      FOutput: TStrings;
      FRevision : Integer;
      FFetchCount : Integer;
      procedure Log(const AText: string);
      function FetchString(const AKey: Integer) : String;
      function FetchPayload(const AKey: Integer) : TPayload;
      procedure Fetching(Sender: TObject; const AKey: Integer);
      procedure Fetched(Sender: TObject; const AKey: Integer; const AValue: String);
      procedure Removing(Sender: TObject; const AKey: Integer; AItem: TCachedItem<String>);
      procedure Removed(Sender: TObject; const AKey: Integer; const AValue: String);
      procedure ShowGlobalFunctions;
      procedure ShowObjectMethods;
      procedure ShowCapacityAndPins;
      procedure ShowOwnedObjects;
    public
      constructor Create(AOutput: TStrings);
      procedure Run;
  end;

constructor TCacheDemo.Create(AOutput: TStrings);
begin
  inherited Create;
  if AOutput = nil then raise EArgumentNilException.Create('AOutput');
  FOutput := AOutput;
end;

procedure TCacheDemo.Log(const AText: string);
begin
  FOutput.Add(AText);
end;

function GlobalFetch(const AKey: Integer) : String;
begin
  Result := 'global value ' + IntToStr(AKey);
end;

function StringSize(const AValue: String) : SizeInt;
begin
  // Size units are chosen by the caller. Count native String storage bytes.
  Result := Length(AValue) * SizeOf(Char);
end;

function ObjectSize(const AValue: TPayload) : SizeInt;
begin
  // A constant estimator makes capacity an object count.
  Result := 1;
end;

constructor TPayload.Create(const AName: String; AOutput: TStrings);
begin
  inherited Create;
  Name := AName;
  Output := AOutput;
end;

destructor TPayload.Destroy;
begin
  Output.Add('  Disposed ' + string(Name));
  inherited;
end;

function TCacheDemo.FetchString(const AKey: Integer) : String;
begin
  Inc(FFetchCount);
  Result := Format('value %d, revision %d', [AKey, FRevision]);
end;

function TCacheDemo.FetchPayload(const AKey: Integer) : TPayload;
begin
  Result := TPayload.Create('fetched object ' + IntToStr(AKey), FOutput);
end;

procedure TCacheDemo.Fetching(Sender: TObject; const AKey: Integer);
begin
  Log(Format('  Fetching key %d', [AKey]));
end;

procedure TCacheDemo.Fetched(Sender: TObject; const AKey: Integer; const AValue: String);
begin
  // This notification follows admission. A handler can inspect cache membership.
  Log(Format('  Fetched key %d: %s', [AKey, AValue]));
end;

procedure TCacheDemo.Removing(Sender: TObject; const AKey: Integer; AItem: TCachedItem<String>);
begin
  // Raising here would veto removal while retaining membership and capacity.
  Log(Format('  Removing key %d: %s', [AKey, AItem.Value]));
end;

procedure TCacheDemo.Removed(Sender: TObject; const AKey: Integer; const AValue: String);
begin
  Log(Format('  Removed key %d: %s', [AKey, AValue]));
end;

procedure TCacheDemo.ShowGlobalFunctions;
var
  cache : TStringCache;
  value : String;
begin
  Log('Global function adapters');
  cache := TStringCache.Create(nil,
    TStringCache.TValueFetcher.FromGlobalFunction(GlobalFetch),
    TStringCache.TSizeEstimator.FromGlobalFunction(StringSize),
    idpNone, TStringCache.TCacheReapPolicy.crpOldest,
    TStringCache.TExpirationPolicy.epNone,
    TStringCache.TNullValuePolicy.nvpCacheNormally, 128, TTimeSpan.MaxValue);
  try
    value := cache[7];
    Log('  ' + string(value));
    Log(Format('  Cached size: %d bytes', [cache.CurrentSize]));
  finally
    cache.Free;
  end;
end;

procedure TCacheDemo.ShowObjectMethods;
var
  cache : TStringCache;
  value : String;
begin
  Log('');
  Log('Object method adapter, hits and invalidation');
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
    Log('  First read: ' + string(value));
    Inc(FRevision);
    value := cache[7];
    Log('  Cache hit: ' + string(value));
    cache.Invalidate(7);
    value := cache[7];
    Log('  After invalidation: ' + string(value));
    cache[99] := 'explicit value';
    value := cache[99];
    Log('  Explicit write: ' + string(value));
    Log(Format('  Source fetches: %d (expected 2)', [FFetchCount]));
    Log(Format('  Entries: %d, accesses: %d', [cache.ItemCount, cache.TotalAccesses]));
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
  Log('');
  Log('Capacity, eviction and pinning');
  cache := TStringCache.Create(nil,
    TStringCache.TValueFetcher.FromGlobalFunction(GlobalFetch),
    TStringCache.TSizeEstimator.FromGlobalFunction(StringSize),
    idpNone, TStringCache.TCacheReapPolicy.crpOldest,
    TStringCache.TExpirationPolicy.epNone,
    // Keep the same six-character capacity for FPC and Delphi native Strings.
    TStringCache.TNullValuePolicy.nvpCacheNormally, 6 * SizeOf(Char), TTimeSpan.MaxValue);
  try
    cache.ItemRemoving := Removing;
    cache.ItemRemoved := Removed;
    cache[1] := 'one';
    cache[2] := 'two';
    cache.Get(1).CanPurge := false;
    cache[3] := 'new';
    Log('  Pinned key 1 present: ' + BoolToStr(cache.ContainsCachedItem(1), true));
    Log('  Evicted key 2 present: ' + BoolToStr(cache.ContainsCachedItem(2), true));
    released := cache.Reap(6 * SizeOf(Char));
    Log(Format('  Released: %d bytes; pinned bytes remaining: %d', [released, cache.CurrentSize]));
    try
      cache[4] := 'four';
    except
      on E: EInvalidOperation do
        Log('  Admission blocked by pin: ' + E.Message);
    end;
    cache.Remove(1);
    Log(Format('  Explicit removal ignores pins; entries remaining: %d', [cache.ItemCount]));
  finally
    cache.Free;
  end;
end;

procedure TCacheDemo.ShowOwnedObjects;
var
  cache : TObjectCache;
  payload : TPayload;
begin
  Log('');
  Log('Owned objects');
  cache := TObjectCache.Create(nil,
    TObjectCache.TValueFetcher.FromObjectFunction(FetchPayload),
    TObjectCache.TSizeEstimator.FromGlobalFunction(ObjectSize),
    idpFreeAndNil, TObjectCache.TCacheReapPolicy.crpOldest,
    TObjectCache.TExpirationPolicy.epNone,
    TObjectCache.TNullValuePolicy.nvpThrow, 2, TTimeSpan.MaxValue);
  try
    payload := cache[1];
    Log('  Borrowed value: ' + string(payload.Name));
    cache.Remove(1);
    // Removal has freed the payload. Do not dereference or free the old pointer.
    payload := TPayload.Create('explicit object 2', FOutput);
    try
      cache[2] := payload;
    except
      // A rejected explicit write does not take ownership of its value.
      payload.Free;
      raise;
    end;
    payload := nil;
    Log('  Cache destruction will dispose explicit object 2');
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

procedure RunCacheExamples(AOutput: TStrings);
var
  owned: TDisposables;
  demo: TCacheDemo;
begin
  demo := TCacheDemo(owned.AddObject(TCacheDemo.Create(AOutput)));
  demo.Run;
end;

end.
