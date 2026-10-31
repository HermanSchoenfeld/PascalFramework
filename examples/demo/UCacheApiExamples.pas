unit UCacheApiExamples;

{ Copyright © 2026 Herman Schoenfeld <https://www.sphere10.com>
  Distributed under the MIT software license, see LICENSE. }

{$IFDEF FPC}
  {$MODE Delphi}
  {$MODESWITCH NESTEDPROCVARS}
{$ENDIF}

interface

uses Classes;

// The output is borrowed; caches, source dictionaries and callback owners are
// disposed before this synchronous example returns.
procedure RunCacheApiExamples(AOutput: TStrings);

implementation

uses SysUtils, Generics.Collections, UCommon, UMemory, UCache;

type
  TCacheFamily = TCacheBase<Integer,String>;
  TAction = TActionCache<Integer,String>;
  TBulk = TBulkFetchActionCache<Integer,String>;
  TBulkFamily = TBulkFetchCacheBase<Integer,String>;
  TValuePairs = TList<TPair<Integer,String>>;

  // A subclass supplies value retrieval, size and optional stale detection.
  TRevisionCache = class(TCacheFamily)
  public
    Revision: Integer;
  protected
    function Fetch(const AKey: Integer): String; override;
    function EstimateSize(const AVal: String): SizeInt; override;
    function CheckStaleness(const AKey: Integer; AItem: TCachedItem<String>): Boolean; override;
  end;

  TCacheExamples = class
  private
    FResources: TDisposables;
    FOutput: TStrings;
    FSource: TDictionary<Integer,String>;
    FRevision: Integer;
    function FetchValue(const AKey: Integer): String;
    function MeasureValue(const AValue: String): SizeInt;
    procedure FillAll(AValues: TCacheBulkValues<Integer,String>);
    procedure Fetching(Sender: TObject; const AKey: Integer);
    procedure Fetched(Sender: TObject; const AKey: Integer; const AValue: String);
    procedure Removing(Sender: TObject; const AKey: Integer; AItem: TCachedItem<String>);
    procedure Removed(Sender: TObject; const AKey: Integer; const AValue: String);
  public
    constructor Create(AOutput: TStrings);
    procedure ShowCallbacks;
    procedure ShowSubclass;
    procedure ShowBulkFetch;
    procedure ShowPreloaded;
  end;

function GlobalFetch(const AKey: Integer): String;
begin
  Result := 'product ' + IntToStr(AKey);
end;

function GlobalMeasure(const AValue: String): SizeInt;
begin
  Result := Length(AValue) * SizeOf(Char);
end;

procedure GlobalFillAll(AValues: TCacheBulkValues<Integer,String>);
begin
  AValues.Add(1,'global catalogue');
  AValues.Add(2,'second product');
end;

function TRevisionCache.Fetch(const AKey: Integer): String;
begin
  Result := Format('%d: revision %d',[AKey,Revision]);
end;

function TRevisionCache.EstimateSize(const AVal: String): SizeInt;
begin
  Result := Length(AVal) * SizeOf(Char);
end;

function TRevisionCache.CheckStaleness(const AKey: Integer; AItem: TCachedItem<String>): Boolean;
begin
  Result := AItem.Value <> Format('%d: revision %d',[AKey,Revision]);
end;

constructor TCacheExamples.Create(AOutput: TStrings);
begin
  inherited Create;
  if AOutput = nil then raise EArgumentNilException.Create('AOutput');
  FOutput := AOutput;
  // Registered first, the borrowed source outlives the subsequently added caches.
  FSource := TDictionary<Integer,String>(FResources.AddObject(TDictionary<Integer,String>.Create));
  FSource.Add(1,'apple'); FSource.Add(2,'pear');
end;

function TCacheExamples.FetchValue(const AKey: Integer): String;
begin
  Result := Format('product %d / revision %d',[AKey,FRevision]);
end;

function TCacheExamples.MeasureValue(const AValue: String): SizeInt;
begin
  Result := GlobalMeasure(AValue);
end;

procedure TCacheExamples.FillAll(AValues: TCacheBulkValues<Integer,String>);
var pair: TPair<Integer,String>;
begin
  for pair in FSource do AValues.AddOrSetValue(pair.Key,pair.Value);
end;

procedure TCacheExamples.Fetching(Sender: TObject; const AKey: Integer);
begin
  FOutput.Add('Fetching ' + IntToStr(AKey));
end;

procedure TCacheExamples.Fetched(Sender: TObject; const AKey: Integer; const AValue: String);
begin
  FOutput.Add('Fetched ' + AValue);
end;

procedure TCacheExamples.Removing(Sender: TObject; const AKey: Integer; AItem: TCachedItem<String>);
begin
  FOutput.Add('Removing ' + AItem.Value);
end;

procedure TCacheExamples.Removed(Sender: TObject; const AKey: Integer; const AValue: String);
begin
  FOutput.Add('Removed ' + AValue);
end;

procedure TCacheExamples.ShowCallbacks;
var
  cache: TAction;
  fetcher: ICacheValueFetcher<Integer,String>;
  estimator: ICacheSizeEstimator<String>;
  globalFetch: TCacheGlobalFetchFunc<Integer,String>;
  globalEstimate: TCacheGlobalEstimateFunc<String>;
  objectFetch: TCacheObjectFetchFunc<Integer,String>;
  objectEstimate: TCacheObjectEstimateFunc<String>;
  nestedFetch: TCacheNestedFetchFunc<Integer,String>;
  nestedEstimate: TCacheNestedEstimateFunc<String>;
  fetchingEvent: TCacheItemFetchingEvent<Integer>;
  fetchedEvent, removedEvent: TCacheItemValueEvent<Integer,String>;
  removingEvent: TCacheItemRemovingEvent<Integer,String>;
  suffix: String;
  procedure Show(const AFetcher: ICacheValueFetcher<Integer,String>; const AEstimator: ICacheSizeEstimator<String>);
  begin
    cache := TAction(FResources.AddObject(TAction.Create(nil,AFetcher,AEstimator,
      idpNone,TCacheReapPolicy.crpOldest,TCacheExpirationPolicy.epNone,TCacheNullValuePolicy.nvpCacheNormally,1024,TTimeSpan.MaxValue)));
    cache.ItemFetching := fetchingEvent; cache.ItemFetched := fetchedEvent;
    cache.ItemRemoving := removingEvent; cache.ItemRemoved := removedEvent;
    FOutput.Add(cache[41]);
    cache.Remove(41);
  end;
  {$IFDEF FPC}
  function FetchNested(const AKey: Integer): String;
  begin
    Result := IntToStr(AKey) + suffix;
  end;
  function MeasureNested(const AValue: String): SizeInt;
  begin
    Result := GlobalMeasure(AValue);
  end;
  {$ENDIF}
begin
  FOutput.Add('Cache callbacks: global functions, object methods and closures');
  fetchingEvent := Fetching; fetchedEvent := Fetched;
  removingEvent := Removing; removedEvent := Removed;
  globalFetch := UCacheApiExamples.GlobalFetch;
  globalEstimate := GlobalMeasure;
  fetcher := TCacheValueFetcher<Integer,String>.FromGlobalFunction(globalFetch);
  estimator := TCacheSizeEstimator<String>.FromGlobalFunction(globalEstimate);
  // The wrappers also accept an existing interface implementation.
  fetcher := TCacheValueFetcher<Integer,String>.Create(fetcher);
  estimator := TCacheSizeEstimator<String>.Create(estimator);
  Show(fetcher,estimator);
  objectFetch := FetchValue; objectEstimate := MeasureValue;
  Show(TCacheValueFetcher<Integer,String>.FromObjectFunction(objectFetch),
    TCacheSizeEstimator<String>.FromObjectFunction(objectEstimate));
  suffix := ' captured suffix';
  {$IFDEF FPC}
  nestedFetch := FetchNested; nestedEstimate := MeasureNested;
  {$ELSE}
  nestedFetch := function(const AKey: Integer): String
    begin
      Result := IntToStr(AKey) + suffix;
    end;
  nestedEstimate := function(const AValue: String): SizeInt
    begin
      Result := GlobalMeasure(AValue);
    end;
  {$ENDIF}
  // A nested callback must not outlive captured stack locals under Free Pascal.
  // Free the cache here instead of retaining it in the session disposal bag.
  cache := TAction.Create(nil,TCacheValueFetcher<Integer,String>.FromNestedFunction(nestedFetch),
    TCacheSizeEstimator<String>.FromNestedFunction(nestedEstimate),idpNone,
    TCacheReapPolicy.crpOldest,TCacheExpirationPolicy.epNone,TCacheNullValuePolicy.nvpCacheNormally,1024,TTimeSpan.MaxValue);
  try FOutput.Add(cache[42]); finally cache.Free; end;
end;

procedure TCacheExamples.ShowSubclass;
var
  cache: TRevisionCache;
  entry: TCachedItem<String>;
  policy: TCacheItemDisposePolicy;
  valuePair: TPair<Integer,String>;
  entryPair: TPair<Integer,TCachedItem<String>>;
  entryAlias: TCachedItem<String>;
  pairs: TList<TPair<Integer,String>>;
begin
  FOutput.Add('Custom cache: stale detection, entries and explicit bulk admission');
  policy := idpNone; // Native strings manage themselves; no object ownership transfer.
  cache := TRevisionCache(FResources.AddObject(TRevisionCache.Create(nil,policy,
    TCacheReapPolicy.crpOldest,TCacheExpirationPolicy.epSinceFetchedTime,TCacheNullValuePolicy.nvpCacheNormally,4096,
    TTimeSpan.FromMinutes(1),0.1,TCacheStaleValuePolicy.svpCheckStaleOnDemand)));
  FOutput.Add(cache[5]); cache.Revision := 1;
  FOutput.Add(cache[5]); // CheckStaleness causes a new fetch for revision 1.
  entry := cache.Get(5); // Borrowed metadata: never Free this returned entry.
  entry.CanPurge := False; cache.Invalidate(5);
  FOutput.Add(Format('Entry invalidated: %s',[BoolToStr(entry.Invalidated,True)]));
  FOutput.Add(cache[5]);
  valuePair := TPair<Integer,String>.Create(6,'explicit six');
  pairs := TValuePairs(FResources.AddObject(TValuePairs.Create));
  pairs.Add(valuePair); pairs.Add(TPair<Integer,String>.Create(7,'explicit seven'));
  cache.BulkLoad(pairs); // Sequential admission; later duplicate keys replace earlier ones.
  entryAlias := cache.Get(6);
  entryPair := TPair<Integer,TCachedItem<String>>.Create(6,entryAlias);
  FOutput.Add(entryPair.Value.Value);
  FOutput.Add(Format('Cached values: %d',[Length(cache.GetAllCachedValues)]));
  cache.Flush;
end;

procedure TCacheExamples.ShowBulkFetch;
var
  cache: TBulk;
  family: TBulkFamily;
  values: TCacheBulkValues<Integer,String>;
  fetcher: ICacheBulkValueFetcher<Integer,String>;
  globalProc: TCacheGlobalBulkFetchProc<Integer,String>;
  objectProc: TCacheObjectBulkFetchProc<Integer,String>;
  nestedProc: TCacheNestedBulkFetchProc<Integer,String>;
  localText: String;
  {$IFDEF FPC}
  procedure FillNested(AValues: TCacheBulkValues<Integer,String>);
  begin
    AValues.Add(3,localText);
  end;
  {$ENDIF}
begin
  FOutput.Add('Bulk fetch: one provider call loads the complete source');
  objectProc := FillAll;
  fetcher := TCacheBulkValueFetcher<Integer,String>.FromObjectFunction(objectProc);
  fetcher := TCacheBulkValueFetcher<Integer,String>.Create(fetcher);
  cache := TBulk(FResources.AddObject(TBulk.Create(nil,fetcher,TCacheExpirationPolicy.epNone,TTimeSpan.MaxValue,True)));
  family := cache;
  FOutput.Add(family[1]); // Fetches both apple and pear in a single batch.
  FSource[1] := 'apricot';
  family.Invalidate(1);
  FOutput.Add(family[1]); // FetchOnceOnly preserves apple until an explicit refresh.
  family.ForceRefresh;
  FOutput.Add(family[1]); // Now apricot.
  values := TCacheBulkValues<Integer,String>(FResources.AddObject(TCacheBulkValues<Integer,String>.Create));
  globalProc := GlobalFillAll;
  fetcher := TCacheBulkValueFetcher<Integer,String>.FromGlobalFunction(globalProc);
  fetcher.Fetch(values);
  FOutput.Add(values[1]);
  localText := 'captured bulk entry';
  {$IFDEF FPC}
  nestedProc := FillNested;
  {$ELSE}
  nestedProc := procedure(AValues: TCacheBulkValues<Integer,String>)
    begin
      AValues.Add(3,localText);
    end;
  {$ENDIF}
  fetcher := TCacheBulkValueFetcher<Integer,String>.FromNestedFunction(nestedProc);
  fetcher.Fetch(values);
  fetcher := nil; // Release this callback before captured stack locals leave scope.
  FOutput.Add(values[3]);
end;

procedure TCacheExamples.ShowPreloaded;
var cache: TPreloadedCache<Integer,String>;
begin
  FOutput.Add('Preloaded cache: borrowed dictionary with an explicit refresh');
  cache := TPreloadedCache<Integer,String>(FResources.AddObject(TPreloadedCache<Integer,String>.Create(nil,FSource)));
  FOutput.Add(cache[2]); FSource[2] := 'plum';
  FOutput.Add(cache[2]); // Still pear: the existing snapshot remains available.
  cache.ForceRefresh; FOutput.Add(cache[2]); // Now plum.
  FOutput.Add(Format('Snapshot values: %d',[Length(cache.GetAllCachedValues)]));
  // FSource and its payloads remain caller-owned and must outlive cache.
end;

procedure RunCacheApiExamples(AOutput: TStrings);
var demo: TCacheExamples;
begin
  demo := TCacheExamples.Create(AOutput);
  try
    demo.ShowCallbacks; demo.ShowSubclass;
    demo.ShowBulkFetch; demo.ShowPreloaded;
  finally demo.Free; end;
end;

end.
