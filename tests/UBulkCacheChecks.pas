unit UBulkCacheChecks;

{ Copyright © 2026 Herman Schoenfeld <https://www.sphere10.com>
  Distributed under the MIT software license, see LICENSE. }

{$IFDEF FPC}
  {$MODE Delphi}
  {$MODESWITCH NESTEDPROCVARS}
{$ENDIF}

interface

const BulkCacheCheckCount = 27;

// The same assertions run from FPCUnit and the native Delphi probe.
procedure RunBulkCacheCheck(AIndex: Integer);

implementation

uses
  {$IFDEF FPC}Classes, SysUtils, Generics.Collections, Generics.Defaults,
  {$ELSE}System.Classes, System.SysUtils, System.Generics.Collections,
  System.Generics.Defaults, System.TimeSpan,{$ENDIF}
  UCommon, UMemory, UCache;

type
  TPlainBase = TCacheBase<Integer, String>;
  TObjectPlainBase = TCacheBase<Integer, TObject>;
  TExpiry = TPlainBase.TExpirationPolicy;
  TStale = TPlainBase.TStaleValuePolicy;
  TNull = TPlainBase.TNullValuePolicy;
  TBulkBase = TBulkFetchCacheBase<Integer, String>;
  TBulkAction = TBulkFetchActionCache<Integer, String>;
  TValues = TDictionary<Integer, String>;
  TTestBulk = class(TBulkBase)
  public
    Source: TValues;
    Calls, StaleChecks: Integer;
    RaiseOnFetch, Stale, ReenterRefresh, ReenterRead: Boolean;
  protected
    procedure BulkFetch(AValues: TValues); override;
    function CheckStaleness(const AKey: Integer; AItem: TCachedItem<String>): Boolean; override;
  end;

  TContext = class
  private
    FResources: TDisposables;
  public
    Source: TValues;
    Cache: TTestBulk;
    constructor Create(AOnce: Boolean;
      AExpiry: TExpiry;
      AStale: TStale;
      ANull: TNull);
    procedure FillValues(AValues: TValues);
  end;

  TBulkReader = class(TThread)
  private FCache: TTestBulk;
  protected procedure Execute; override;
  public
    Error: String;
    constructor Create(ACache: TTestBulk);
  end;

  TObjectBulk = TBulkFetchActionCache<Integer, TObject>;
  TObjectValues = TDictionary<Integer, TObject>;
  TInterfaceBulk = TBulkFetchActionCache<Integer, IInterface>;
  TInterfaceCache = TCacheBase<Integer, IInterface>;
  TInterfaceValues = TDictionary<Integer, IInterface>;
  TDestructionCheckValue = class(TInterfacedObject)
  private
    FCache: TInterfaceCache;
    FRejected: PBoolean;
  public
    constructor Create(ACache: TInterfaceCache; ARejected: PBoolean);
    destructor Destroy; override;
  end;
  TTrackedValue = class
    destructor Destroy; override;
  end;

var DestroyedValues: Integer;

procedure Check(ACondition: Boolean; const AMessage: String);
begin
  if not ACondition then raise Exception.Create(AMessage);
end;

constructor TContext.Create(AOnce: Boolean; AExpiry: TExpiry;
  AStale: TStale; ANull: TNull);
begin
  inherited Create;
  Source := TValues(FResources.AddObject(TValues.Create));
  Source.Add(1,'one'); Source.Add(2,'two');
  Cache := TTestBulk(FResources.AddObject(TTestBulk.Create(nil,AExpiry,
    TTimeSpan.FromSeconds(1),AOnce,ANull,AStale)));
  Cache.Source := Source;
end;

procedure TContext.FillValues(AValues: TValues);
var pair: TPair<Integer,String>;
begin
  for pair in Source do AValues.AddOrSetValue(pair.Key,pair.Value);
end;

procedure TTestBulk.BulkFetch(AValues: TValues);
var pair: TPair<Integer,String>;
begin
  Inc(Calls);
  if RaiseOnFetch then raise EInvalidOperation.Create('provider failed');
  if ReenterRefresh then ForceRefresh;
  if ReenterRead then Check(not ContainsCachedItem(99),'Reentrant query must see the current snapshot');
  for pair in Source do AValues.AddOrSetValue(pair.Key,pair.Value);
end;

function TTestBulk.CheckStaleness(const AKey: Integer; AItem: TCachedItem<String>): Boolean;
begin
  Inc(StaleChecks); Result := Stale;
end;

constructor TBulkReader.Create(ACache: TTestBulk);
begin
  inherited Create(True);
  FCache := ACache;
end;

procedure TBulkReader.Execute;
var i: Integer;
begin
  try
    for i := 1 to 100 do Check(FCache[1] = 'one','Concurrent snapshot read changed');
  except on E: Exception do Error := E.Message; end;
end;

destructor TTrackedValue.Destroy;
begin
  Inc(DestroyedValues);
  inherited;
end;

constructor TDestructionCheckValue.Create(ACache: TInterfaceCache; ARejected: PBoolean);
begin
  inherited Create;
  FCache := ACache;
  FRejected := ARejected;
end;

destructor TDestructionCheckValue.Destroy;
begin
  // The last managed value reference is released while the cache destructor
  // still owns its lock. This tests rejection without using a freed instance.
  try FCache.Reap(1);
  except on E: EInvalidOperation do FRejected^ := True; end;
  inherited;
end;

procedure GlobalFill(AValues: TValues);
begin
  AValues.Add(7,'global');
end;

procedure RunBulkCacheCheck(AIndex: Integer);
var
  ctx: TContext;
  resources: TDisposables;
  action: TBulkAction;
  preloaded: TPreloadedCache<Integer,String>;
  values: TArray<String>;
  failed: Boolean;
  i: Integer;
  readers: array[0..3] of TBulkReader;
  fetcher: TBulkAction.IBulkValueFetcher;
  wrapper: TBulkAction.TBulkValueFetcher;
  nullPolicy: TObjectPlainBase.TNullValuePolicy;
  objectCache: TObjectBulk;
  objectValue: TTrackedValue;
  nestedValue: String;
  original: TCachedItem<String>;
  interfaceCache: TInterfaceBulk;
  interfaceFetcher: TInterfaceBulk.TNestedBulkFetchProc;
  destructionRejected: Boolean;
  objectFetcher: TObjectBulk.TNestedBulkFetchProc;
  nestedFetcher: TBulkAction.TNestedBulkFetchProc;
  {$IFDEF FPC}
  procedure NestedFill(AValues: TValues);
  begin
    AValues.Add(9,nestedValue);
  end;
  procedure ObjectFill(AValues: TObjectValues);
  begin
    AValues.Add(1,nil);
    AValues.Add(2,objectValue);
  end;
  procedure InterfaceFill(AValues: TInterfaceValues);
  begin
    AValues.Add(1,TDestructionCheckValue.Create(interfaceCache,@destructionRejected));
  end;
  {$ENDIF}
begin
  if AIndex = 10 then begin
    // Bulk cache payloads stay owned by the source, including nil policies.
    DestroyedValues := 0;
    objectValue := TTrackedValue(resources.AddObject(TTrackedValue.Create));
    {$IFDEF FPC}
    objectFetcher := ObjectFill;
    {$ELSE}
    objectFetcher := procedure(AValues: TObjectValues)
      begin
        AValues.Add(1,nil);
        AValues.Add(2,objectValue);
      end;
    {$ENDIF}
    for nullPolicy := Low(TObjectPlainBase.TNullValuePolicy) to High(TObjectPlainBase.TNullValuePolicy) do begin
      objectCache := TObjectBulk.Create(nil,TObjectBulk.TBulkValueFetcher.FromNestedFunction(objectFetcher),
        TObjectPlainBase.TExpirationPolicy.epNone,TTimeSpan.MaxValue,True,nullPolicy);
      try
        failed := False;
        try Check(objectCache[1] = nil,'Null snapshot entry must stay nil');
        except on E: EInvalidOperation do failed := True; end;
        Check(failed = (nullPolicy = TObjectPlainBase.TNullValuePolicy.nvpThrow),'Null read policy');
        Check(objectCache[2] = objectValue,'Non-null borrowed payload');
        Check(objectCache.ContainsCachedItem(1) = (nullPolicy <> TObjectPlainBase.TNullValuePolicy.nvpReturnButDontCache),
          'Null membership policy');
        objectCache.ForceRefresh;
      finally objectCache.Free; end;
      Check(DestroyedValues = 0,'Refresh/destruction must not free borrowed payloads');
    end;
    Exit;
  end;

  ctx := TContext(resources.AddObject(TContext.Create((AIndex in [5,6,7,8,9,16,17,24,25]),
    TExpiry.epSinceFetchedTime,
    TStale.svpCheckStaleOnDemand,TNull.nvpCacheNormally)));
  case AIndex of
    1: begin
      Check(ctx.Cache[1] = 'one','Initial get');
      Check((ctx.Cache.ItemCount = 2) and (ctx.Cache.Calls = 1),'One get loads the whole source');
      Check(ctx.Cache[2] = 'two','Second prefetched key');
      Check(ctx.Cache.Calls = 1,'Hit must not fetch');
      Check(ctx.Cache.CurrentSize = 0,'Bulk snapshots do not consume per-entry eviction capacity');
    end;
    2: begin
      Check(ctx.Cache[99] = '','Missing key default');
      Check(ctx.Cache.Calls = 1,'Cold missing-key request must fetch exactly once');
      Check(ctx.Cache[100] = '','Subsequent missing key');
      Check(ctx.Cache.Calls = 2,'Each ordinary missing request fetches at most once');
    end;
    3: begin
      Check(ctx.Cache.ContainsCachedItem(1),'Contains initializes the complete snapshot');
      Check(not ctx.Cache.ContainsCachedItem(99),'Contains miss');
      Check(ctx.Cache.Calls = 1,'Contains miss does not refetch');
    end;
    4: begin
      values := ctx.Cache.GetAllCachedValues;
      Check(Length(values) = 2,'All-values initializes snapshot');
      ctx.Source.Add(3,'three');
      Check(Length(values) = 2,'All-values result is a copied array');
      Check(Length(ctx.Cache.GetAllCachedValues) = 2,'All-values does not silently refresh');
      Check(ctx.Cache.Calls = 1,'All-values loads once');
    end;
    5,6,7: begin
      Check(ctx.Cache[1] = 'one','Fetch-once initial value');
      ctx.Source[1] := 'changed';
      case AIndex of
        5: ctx.Cache.Invalidate(1);
        6: ctx.Cache.Get(1).FFetchedOn := Now - 1;
        7: ctx.Cache.Stale := True;
      end;
      Check(ctx.Cache.ContainsCachedItem(1),'Fetch-once keeps original membership');
      Check(ctx.Cache[1] = 'one','Fetch-once retains original snapshot despite invalidation/expiry/staleness');
      Check(ctx.Cache.Calls = 1,'Fetch-once must not refetch automatically');
      ctx.Cache.ForceRefresh;
      Check(ctx.Cache[1] = 'changed','Explicit refresh replaces fetch-once snapshot');
      Check(ctx.Cache.Calls = 2,'Explicit refresh provider call');
    end;
    8: begin
      Check(ctx.Cache[99] = '','Fetch-once initial missing');
      ctx.Source.Add(99,'later');
      Check(ctx.Cache[99] = '','Missing remains part of fetch-once snapshot');
      Check(ctx.Cache.Calls = 1,'Fetch-once missing never refetches');
    end;
    9: begin
      Check(ctx.Cache[1] = 'one','Initial snapshot'); ctx.Cache.Purge;
      Check(ctx.Cache.FetchCount = 0,'Purge resets load count');
      ctx.Source[1] := 'changed';
      Check(ctx.Cache[1] = 'changed','Purge permits new first snapshot');
      Check(ctx.Cache.Calls = 2,'Provider called after purge');
    end;
    11,12,13: begin
      Check(ctx.Cache[1] = 'one','Initial snapshot'); ctx.Source[1] := 'changed';
      case AIndex of
        11: ctx.Cache.Invalidate(1);
        12: ctx.Cache.Get(1).FFetchedOn := Now - 1;
        13: ctx.Cache.Stale := True;
      end;
      Check(ctx.Cache[1] = 'changed','Ordinary invalidated/expired/stale snapshot reloads');
      Check(ctx.Cache.Calls = 2,'One refresh per triggering request');
      Check(ctx.Cache.ItemCount = 2,'Refresh restores all source keys');
    end;
    14: begin
      Check(ctx.Cache[1] = 'one','Initial snapshot'); ctx.Cache.RaiseOnFetch := True;
      failed := False;
      try ctx.Cache.ForceRefresh; except on E: EInvalidOperation do failed := True; end;
      Check(failed,'Provider failure must propagate');
      Check(ctx.Cache.ItemCount = 0,'Failed purge-first refresh leaves no old snapshot');
      Check(ctx.Cache.FetchCount = 0,'Failed refresh does not mark loaded');
      ctx.Cache.RaiseOnFetch := False; ctx.Source[1] := 'recovered';
      Check(ctx.Cache[1] = 'recovered','A failed provider can be retried');
      Check(ctx.Cache.Calls = 3,'Failed batch is attempted once');
    end;
    15: begin
      preloaded := TPreloadedCache<Integer,String>(resources.AddObject(TPreloadedCache<Integer,String>.Create(nil,ctx.Source)));
      Check(preloaded[1] = 'one','Preloaded initial snapshot'); ctx.Source[1] := 'changed';
      Check(preloaded[1] = 'one','Preloaded snapshot retained');
      preloaded.ForceRefresh;
      Check(preloaded[1] = 'changed','Preloaded refresh sees changes to the original borrowed dictionary');
      Check(ctx.Source.Count = 2,'Preloaded does not clear source');
    end;
    16: begin
      ctx := TContext(resources.AddObject(TContext.Create(True,TExpiry.epNone,
        TStale.svpAssumeNeverStale,TNull.nvpThrow)));
      failed := False;
      try nestedValue := ctx.Cache[99];
      except on E: EInvalidOperation do failed := True; end;
      Check(failed,'Missing key obeys throw policy');
      Check(ctx.Cache.Calls = 1,'Cold missing key with throw policy fetches once');
      Check(ctx.Cache[1] = 'one','A missing key does not invalidate the complete snapshot');
      Check(ctx.Cache.Calls = 1,'Fetch-once hit after missing key retains loaded snapshot');
    end;
    17: begin
      Check(ctx.Cache[1] = 'one','Initial snapshot'); failed := False;
      try TCacheBase<Integer,String>(ctx.Cache).Remove(1);
      except on E: ENotSupportedException do failed := True; end;
      Check(failed and ctx.Cache.ContainsCachedItem(1),'Bulk removal is rejected through a base reference');
    end;
    18: begin
      action := TBulkAction(resources.AddObject(TBulkAction.Create(nil,
        TBulkAction.TBulkValueFetcher.FromGlobalFunction(GlobalFill),
        TExpiry.epNone,TTimeSpan.MaxValue)));
      Check(action[7] = 'global','Global adapter');
      action := TBulkAction(resources.AddObject(TBulkAction.Create(nil,
        TBulkAction.TBulkValueFetcher.FromObjectFunction(ctx.FillValues),
        TExpiry.epNone,TTimeSpan.MaxValue)));
      Check(action[2] = 'two','Object adapter');
      nestedValue := 'nested';
      {$IFDEF FPC}
      nestedFetcher := NestedFill;
      {$ELSE}
      nestedFetcher := procedure(AValues: TValues)
        begin
          AValues.Add(9,nestedValue);
        end;
      {$ENDIF}
      fetcher := TBulkAction.TBulkValueFetcher.FromNestedFunction(nestedFetcher);
      wrapper := TBulkAction.TBulkValueFetcher.Create(fetcher);
      fetcher := wrapper;
      action := TBulkAction(resources.AddObject(TBulkAction.Create(nil,fetcher,
        TExpiry.epNone,TTimeSpan.MaxValue)));
      Check(action[9] = 'nested','Nested adapter and interface wrapper');
    end;
    19: begin
      failed := False;
      try fetcher := TBulkAction.TBulkValueFetcher.FromGlobalFunction(nil);
      except on E: EArgumentNilException do failed := True; end;
      Check(failed,'Nil global callback rejected'); failed := False;
      try fetcher := TBulkAction.TBulkValueFetcher.FromObjectFunction(nil);
      except on E: EArgumentNilException do failed := True; end;
      Check(failed,'Nil object callback rejected'); failed := False;
      try fetcher := TBulkAction.TBulkValueFetcher.FromNestedFunction(nil);
      except on E: EArgumentNilException do failed := True; end;
      Check(failed,'Nil nested callback rejected'); failed := False;
      try action := TBulkAction.Create(nil,nil,TExpiry.epNone,TTimeSpan.MaxValue);
      except on E: EArgumentNilException do failed := True; end;
      Check(failed,'Nil fetcher rejected'); failed := False;
      try wrapper := TBulkAction.TBulkValueFetcher.Create(nil);
      except on E: EArgumentNilException do failed := True; end;
      Check(failed,'Nil wrapper fetcher rejected'); failed := False;
      try preloaded := TPreloadedCache<Integer,String>.Create(nil,nil);
      except on E: EArgumentNilException do failed := True; end;
      Check(failed,'Nil preloaded source rejected');
    end;
    20: begin
      for i := 0 to High(readers) do readers[i] := TBulkReader(resources.AddObject(TBulkReader.Create(ctx.Cache)));
      for i := 0 to High(readers) do readers[i].Start;
      for i := 0 to High(readers) do readers[i].WaitFor;
      for i := 0 to High(readers) do Check(readers[i].Error = '',readers[i].Error);
      Check(ctx.Cache.Calls = 1,'Concurrent reads share one initial batch');
    end;
    21: begin
      ctx.Cache.ReenterRefresh := True; failed := False;
      try values := ctx.Cache.GetAllCachedValues;
      except on E: EInvalidOperation do failed := True; end;
      Check(failed,'Recursive ForceRefresh is rejected instead of recursively fetching forever');
      Check(ctx.Cache.Calls = 1,'One attempt for recursive provider');
      ctx.Cache.ReenterRefresh := False; ctx.Cache.ReenterRead := True;
      Check(ctx.Cache[1] = 'one','Read-only callback reentry does not refetch');
      Check(ctx.Cache.Calls = 2,'One subsequent retry');
    end;
    22: begin
      preloaded := TPreloadedCache<Integer,String>(resources.AddObject(TPreloadedCache<Integer,String>.Create(
        nil,ctx.Source,TEqualityComparer<Integer>.Default)));
      Check(preloaded[2] = 'two','Configured key comparer works for both storage and source snapshot');
    end;
    23: begin
      ctx.Cache.Stale := True;
      Check(ctx.Cache[1] = 'one','Always-stale initial source still resolves');
      Check(ctx.Cache.Calls = 1,'Initial stale snapshot cannot cause a second fetch in the same request');
      Check(ctx.Cache[1] = 'one','Subsequent stale source resolves');
      Check(ctx.Cache.Calls = 2,'Next request may refresh once');
    end;
    24,25: begin
      original := ctx.Cache.Get(1);
      ctx.Source[1] := 'changed';
      if AIndex = 24 then ctx.Cache.Invalidate(1)
      else original.FFetchedOn := Now - 1;
      Check(TPlainBase(ctx.Cache).Reap(1) = 0,'Bulk reaping through base reference releases no capacity');
      Check(ctx.Cache.ItemCount = 2,'Reaping must preserve the complete snapshot');
      Check(ctx.Cache.Get(1) = original,'Fetch-once must retain the original entry after reaping');
      Check(ctx.Cache[1] = 'one','Fetch-once retained original value');
      Check(ctx.Cache.Calls = 1,'Reaping must not refetch the source');
    end;
    26: begin
      original := ctx.Cache.Get(1);
      original.FFetchedOn := Now - 1;
      ctx.Cache.Invalidate(2);
      ctx.Source[1] := 'changed';
      Check(TPlainBase(ctx.Cache).Reap(1) = 0,'Refreshable bulk snapshot also has no per-entry reaping');
      Check(ctx.Cache.ItemCount = 2,'Refreshable snapshot remains complete until next read');
      Check(ctx.Cache.Calls = 1,'Reaping does not fetch');
      Check(ctx.Cache[1] = 'changed','Ordinary expired read still refreshes after no-op reaping');
      Check(ctx.Cache.Calls = 2,'Ordinary expired read refreshes once');
    end;
    27: begin
      failed := False;
      try TPlainBase(ctx.Cache).Reap(-1);
      except on E: EArgumentException do failed := True; end;
      Check(failed,'Negative bulk release remains invalid');
      Check(TPlainBase(ctx.Cache).Reap(0) = 0,'Zero release is harmless');
      Check(ctx.Cache.Calls = 0,'Reaping does not initialize the source');
      destructionRejected := False;
      {$IFDEF FPC}
      interfaceFetcher := InterfaceFill;
      {$ELSE}
      interfaceFetcher := procedure(AValues: TInterfaceValues)
        begin
          AValues.Add(1,TDestructionCheckValue.Create(interfaceCache,@destructionRejected));
        end;
      {$ENDIF}
      interfaceCache := TInterfaceBulk.Create(nil,TInterfaceBulk.TBulkValueFetcher.FromNestedFunction(interfaceFetcher),
        TInterfaceCache.TExpirationPolicy.epNone,TTimeSpan.MaxValue,True);
      try
        interfaceCache.Get(1); // The entry owns the last managed interface reference.
      finally interfaceCache.Free; end;
      Check(destructionRejected,'Bulk reaping rejects destruction while the object is still alive');
    end;
  else raise EArgumentOutOfRangeException.Create('AIndex'); end;
end;

end.
