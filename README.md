<p align="center">
  <a href="https://sphere10.com/"><img src="resources/branding/sphere-10-framework-logo.jpg" alt="Sphere10 Framework" width="720"></a>
</p>

[![Lazarus / FPC build and tests](https://github.com/HermanSchoenfeld/PascalFramework/actions/workflows/main.yml/badge.svg)](https://github.com/HermanSchoenfeld/PascalFramework/actions/workflows/main.yml)
[![Delphi 13](https://img.shields.io/badge/Delphi-13-BB0000)](packages/README.md#delphi-13)
[![Lazarus 2.1.0 tested](https://img.shields.io/badge/tested_Lazarus-2.1.0-blue)](tests/README.md)
[![Free Pascal 3.2.0 tested](https://img.shields.io/badge/tested_Free_Pascal-3.2.0-blue)](tests/README.md)
[![Lazarus 4.8 tested](https://img.shields.io/badge/tested_Lazarus-4.8-blue)](tests/README.md)
[![Free Pascal 3.2.2 tested](https://img.shields.io/badge/tested_Free_Pascal-3.2.2-blue)](tests/README.md)
[![MIT License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

# PascalFramework

PascalFramework is [Sphere10's](https://sphere10.com/) reusable Object Pascal
library for **Lazarus/Free Pascal (LCL) and Delphi (VCL)**. It provides data-bound visual grids, multi-step wizards
and configurable caches, together with the supporting utilities applications
need: scoped resource cleanup, generic collection helpers, data sources,
multicast events, date/time helpers and UI event throttling.

The components work together: visual grids consume data sources that handle
filtering, sorting and paging; wizard screens share a typed model and can change
their route at runtime; caches control how values are fetched, retained and
released. Use the units directly in a project or add the optional
[Lazarus or Delphi package](packages/README.md). The examples below show their individual
APIs. Open [PascalFramework.dproj](PascalFramework.dproj) in Delphi or
[PascalFramework.lpi](PascalFramework.lpi) in Lazarus to run one application with
Visual grid, Wizard/events and Cache sections. Both projects use the same
[entry point](PascalFramework.dpr) and [demo sources](examples/demo/README.md).

The supplied projects target **Delphi 13 Community Edition**, **Lazarus 2.1 /
Free Pascal 3.2.0** and **Lazarus 4.8 / Free Pascal 3.2.2** on Windows. Delphi
uses VCL; Lazarus uses LCL's Win32 widgetset, including for Win64 applications.
See [build instructions](#open-build-and-test) and the [test guide](tests/README.md)
for the compiler-specific commands and verification scope. The [CI workflow](.github/README.md)
builds the Lazarus package and demo and runs FPCUnit; its badge reports hosted
GitHub results separately from local Delphi and Lazarus checks.
The cache and wizard designs draw from the [Sphere10 C# framework](https://github.com/HermanSchoenfeld/Sphere10.Framework),
using Pascal units, component ownership and native controls here.

## Units

| Unit | Description |
| --- | --- |
| [UVisualGrid.pas](src/Sphere10/UVisualGrid.pas) | Data-bound LCL/VCL grid with paging and automatic page sizes, text/numeric filters, single/multi-column sorting, cell/row/multi-row selection, custom rendering, popup menus, optional background fetching, an owned refresh throttle, cooperative refresh suspension and a customizable loading card with input control. |
| [ULoadingCircle.pas](src/Sphere10/ULoadingCircle.pas) | Native LCL/VCL loading animation adapted from Sphere10's rounded-spoke LoadingCircle, with an owned timer, fading spokes, configurable color and explicit start/stop control. |
| [UCache.pas](src/Sphere10/UCache.pas) | Generic caches with fetch callbacks, explicit/bulk writes, invalidation, fixed/sliding expiration, capacity and eviction policies, entry pins, staleness checks, null-value policies, lifecycle events and disposal policies. |
| [UWizard.pas](src/Sphere10/UWizard.pas) | Typed-model wizard screens in one host window, with validation, Back/Continue navigation, dynamic route insertion/replacement/removal, finish/cancel vetoes, retryable completion and lifecycle notifications. |
| [UMemory.pas](src/Sphere10/UMemory.pas) | Scope-owned cleanup of objects and allocated memory through `TDisposables`, allocation/reallocation helpers, explicit ownership transfer and shared disposal-policy definitions. |
| [UCommon.pas](src/Sphere10/UCommon.pas) | Shared helpers for arrays, Variants, date/time arithmetic, durations, bytes/hex, statistics, result diagnostics, multicast events, thread-targeted notifications, files and CPU information. |
| [UCommon.Collections.pas](src/Sphere10/UCommon.Collections.pas) | Composable predicates/comparers and transformation adapters for global functions, object methods and nested callbacks, plus list filtering, removal, slicing and transformation helpers. |
| [UCommon.Data.pas](src/Sphere10/UCommon.Data.pas) | Named Variant rows and column schemas, text/numeric search expressions, filter/sort criteria and generic data sources with filtering, sorting, paging and opt-in invalidatable snapshots. |
| [UCommon.UI.pas](src/Sphere10/UCommon.UI.pas) | Application forms with lifecycle events and owned-object cleanup, control docking and image helpers, and throttled/coalesced UI notifications. |
| [UConcurrency.pas](src/Sphere10/UConcurrency.pas) | Reader/writer synchronization with concurrent readers, exclusive writes, one upgradeable reader, configurable recursion, timed/nonblocking acquisition, thread ownership checks and recursion/waiter counts. |

The bundled [Generics.Collections](src/Generics.Collections/generics.collections.pas)
library supplies the Free Pascal lists, dictionaries, queues, stacks and sets;
Delphi uses its native RTL generics. UI components select Lazarus LCL or Delphi
VCL through compiler conditionals. The supplied projects configure those paths.

# Example uses:

## Visual grid

[TVisualGrid](src/Sphere10/UVisualGrid.pas) combines [paging and automatic page sizes](src/Sphere10/UVisualGrid.pas),
[single-expression or per-column search](src/Sphere10/UVisualGrid.pas),
[single/multi-column sorting](src/Sphere10/UVisualGrid.pas) and
[cell, row or multiple-row selection](src/Sphere10/UVisualGrid.pas). Configure column
widths/stretching, fonts/alignment, custom cell renderers, selection callbacks,
popup menus and extra toolbar controls through the same [grid unit](src/Sphere10/UVisualGrid.pas).

![Unified Delphi demo displaying eight grid columns, a live property editor and paging](resources/demo/unified-grid.png)

The native Delphi capture shows the unified demo's eight columns, generated
10,000-record source, live property editor, 100-row pages and built-in
[DollarValue renderer](src/Sphere10/UVisualGrid.pas). The same application also
contains the wizard launcher and cache demonstrations.

Implement three methods in [TCustomDataSource<T>](src/Sphere10/UCommon.Data.pas);
it supplies filtering, sorting, paging and conversion to named Variant rows.

```pascal
uses Classes, Variants, Generics.Collections, UCommon.Data;

type
  TNameSource = class(TCustomDataSource<String>)
  protected
    function GetColumns : TDataColumns; override;
    procedure FetchAll(const AContainer : TList<String>); override;
    function GetItemField({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem : String;
      const ABindingName : String) : Variant; override;
  end;

function TNameSource.GetColumns : TDataColumns;
begin
  Result := TDataColumns.Create(TDataColumn.From('Name'));
end;

procedure TNameSource.FetchAll(const AContainer : TList<String>);
begin
  AContainer.Add('Ada');
  AContainer.Add('Grace');
end;

function TNameSource.GetItemField({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem : String;
  const ABindingName : String) : Variant;
begin
  Result := AItem;
end;
```

Attach it to [TVisualGrid](src/Sphere10/UVisualGrid.pas) from your form:

```pascal
uses Forms, UCommon.Data, UCommon.UI, UVisualGrid;

procedure ShowNames(AForm : TForm);
var
  source : TNameSource;
  grid : TVisualGrid;
begin
  source := TNameSource.Create(AForm);
  source.SnapshotCacheEnabled := true;
  grid := TVisualGrid.Create(AForm);
  grid.FetchDataInThread := false;
  grid.PageSize := 25;
  with grid.AddColumn('Name') do begin
    Binding := 'Name';
    Filters := SORTABLE_TEXT_FILTER;
  end;
  AForm.AddControlDockCenter(grid);
  grid.DataSource := source; // Fetch the first page.
end;
```

```mermaid
flowchart LR
    refresh["Refresh / page / filter / sort / source / resize"] --> admission["Own RefreshThrottle"]
    admission -->|"temNone / leading / final admission"| fetch["IDataSource.FetchPage"]
    admission -->|"Further input while waiting"| latest["Retain latest parameters; reset timer"]
    latest -->|"Quiet with a pending request"| fetch
    fetch --> enabled{"Snapshot caching?"}
    enabled -->|No| rows["FetchAll"]
    enabled -->|Yes| current{"Raw snapshot current?"}
    current -->|No| rows
    current -->|Yes| view{"Same search / sort?"}
    view -->|No| filter["Filter"]
    view -->|Yes| page["Select page"]
    rows --> filter["Filter"]
    filter --> sort["Sort"]
    sort --> page["Select page"]
    page --> bind["Convert to variant rows"]
    bind --> draw["Render grid"]
```

Each grid owns a [RefreshThrottle](src/Sphere10/UVisualGrid.pas), whose default
`temNone` mode keeps immediate refresh behavior. Enable five-second leading and
trailing admission before assigning `DataSource`. Here `FGrid` is an existing
form field of type `TVisualGrid`:

```pascal
uses UCommon, UCommon.UI, UVisualGrid;

procedure TMyForm.ConfigureGridRefresh;
begin
  FGrid.RefreshThrottle.Interval := TTimeSpan.FromSeconds(5);
  FGrid.RefreshThrottle.Mode := temNotifyOnEventBurstStartAndFinished;
  FGrid.RefreshThrottle.OnWaitingChanged.Add(GridWaitingChanged);
end;

procedure TMyForm.GridWaitingChanged(Sender : TObject);
begin
  if FGrid.RefreshSuspended then Exit; // Preserve an application-owned hold card.
  if FGrid.RefreshThrottle.Waiting then
    FGrid.ShowLoading('Please Wait', 'Synchronizing')
  else
    FGrid.HideLoading;
end;
```

The first request can fetch immediately. Every later client request, including
paging, filtering, sorting, source replacement and resizing, restarts that grid's
quiet timer and retains the latest parameters. While waiting, resizing changes
layout without fetching. After five quiet seconds, one pending request is admitted
with the latest parameters; if its own older fetch is still active, it waits for
that worker to complete. This replay does not restart Waiting. A single input gets
no duplicate ordinary delivery. Internal result layout and worker replay do not
create new inputs. A user completion
handler that calls `RefreshGrid` does create a new input. Each grid is independent:
node/network state and another grid's worker cannot extend its `Waiting` state.
Call this configuration and state handler on the UI thread; remove the listener
before destroying a listener that has a shorter lifetime than the grid.

Use `RefreshSuspended` when application policy must temporarily prevent provider
queries independently of the throttle. Visual layout and refresh requests still
retain the latest parameters. Suspension requests cooperative cancellation of an
active worker without joining it; its obsolete result or error is discarded.
Providers should check their worker's termination flag while doing lengthy work.
For example, an application can pause a view during a background import:

```pascal
procedure TMyForm.ImportStarted;
begin
  FGrid.RefreshSuspended := True;
  FGrid.ShowLoading('Please Wait', 'Importing');
end;

procedure TMyForm.ImportFinished;
begin
  FGrid.HideLoading;
  FGrid.RefreshThrottle.Cancel; // Cancel while suspended: no early query.
  FGrid.RefreshSuspended := False; // Resume one latest retained request.
end;
```

Call these methods on the UI thread. Resuming normally respects any remaining
throttle wait; the explicit cancellation above admits the latest page immediately,
once a canceled older worker has retired. Suspension contains no application,
node or networking dependency and does not change the throttle's timer contract.

Call [RefreshGrid](src/Sphere10/UVisualGrid.pas) after changing source data. For worker fetching, set
`FetchDataInThread := true`, keep the grid/source alive until completion, and keep
source callbacks free of LCL/VCL control access. Publish UI state through the
grid's completion event on the main thread. The worker queues completion directly;
the grid does not poll for a finished fetch. Its owned dispatcher retires the
worker, publishes the page once and discards queued callbacks safely on disposal.
See the [unified grid demo](examples/demo/fMain.pas) for rendering and selection.
The preserved [SQLite adapter recipe](examples/demo/sqlite/fMain.pas) is reference
source for the older optional mORMot integration, with no separate application target.

Enable [SnapshotCacheEnabled](src/Sphere10/UCommon.Data.pas) when the data source
can retain a stable dataset between updates. It keeps one raw snapshot and one
current filtered/sorted view, so changing pages converts only the visible rows;
changing search or sort reuses the raw snapshot. Caching is off by default.
After changing the backing data, invalidate the snapshot before refreshing:

```pascal
procedure RefreshNames(ASource : TNameSource; AGrid : TVisualGrid);
begin
  ASource.InvalidateSnapshot;
  AGrid.RefreshGrid;
end;
```

[InvalidateSnapshot](src/Sphere10/UCommon.Data.pas) marks the next fetch for
rebuilding without waiting for an active fetch. An in-flight fetch can finish its
previous snapshot. Object items remain borrowed: keep them alive while cached
snapshots are reused and while fetches are active.

The default [FetchPage](src/Sphere10/UCommon.Data.pas) still loads the initial raw
dataset through `FetchAll`; caching makes subsequent pages cheaper, not that
initial load. Sources with indexed or database-native paging can override the
virtual method to retrieve only their requested records and return accurate
counts/page bounds. Arbitrary filtering and sorting must still apply to the
complete selected query before choosing its page.

Outstanding grid refreshes retain the previous rows and show a compact bordered
loading card after 200 ms, including requests waiting for the refresh throttle.
The card uses [TLoadingCircle](src/Sphere10/ULoadingCircle.pas), stays visible
through fetch admission and disappears after completion or cancellation; quick
cached pages avoid flashing it.

Use [ShowLoading / HideLoading](src/Sphere10/UVisualGrid.pas) to hold a card while
waiting for external work, independently of a page fetch. Supply a title,
optional subtitle and optional `TGraphic`; the grid copies the graphic so its
caller retains ownership. Omitting the image uses the loading circle.

```pascal
grid.ShowLoading('Please Wait', 'Importing records', MyLoadingImage);
// Grid, search and paging input are disabled; completed rows remain visible.
// Programmatic refreshes can still publish replacement pages.
grid.RefreshGrid;
// Call when the external work and required page publication have finished:
grid.HideLoading;
```

The optional fourth parameter, `ADisableInput`, defaults to `true`. Pass `false`
for a card that permits interaction. `LoadingVisible` reports this held state;
`IsUpdating` continues to report only an asynchronous page fetch. Fetch completion
cannot dismiss a held card. `HideLoading` restores the current fetch/error
presentation and its input restrictions without changing the grid's `Enabled`
property. Call these UI methods on the main thread.

## Loading circle

[TLoadingCircle](src/Sphere10/ULoadingCircle.pas) ports the rounded-spoke animation
used by Sphere10's WinForms framework to LCL and VCL. Its component-owned timer drives
twelve fading spokes; set `Active` on the UI thread and keep the message loop
running. Destroying the control stops its timer.

```pascal
uses Classes, Controls, ULoadingCircle;

function AddLoadingCircle(AOwner : TComponent; AParent : TWinControl) : TLoadingCircle;
begin
  Result := TLoadingCircle.Create(AOwner);
  Result.Parent := AParent;
  Result.SetBounds(12, 12, 36, 36);
  Result.Active := true;
  // Set Result.Active := false when the operation finishes.
end;
```

The port retains Martin R. Gagné's original copyright and license in the
[unit source](src/Sphere10/ULoadingCircle.pas).

## Caching

[TActionCache<TKey, TValue>](src/Sphere10/UCache.pas) memoizes fetches, accepts explicit
writes and supports invalidation. Configure [fixed or sliding expiration](src/Sphere10/UCache.pas),
[least-used, largest, smallest, oldest, idle, ASAP or no-policy eviction](src/Sphere10/UCache.pas),
[pinned entries](src/Sphere10/UCache.pas) and [on-demand staleness checks](src/Sphere10/UCache.pas).
[Null handling](src/Sphere10/UCache.pas) can cache nil, return it without caching,
or reject it; [fetch/removal events](src/Sphere10/UCache.pas) report each lifecycle
phase. [Typed callback adapters](src/Sphere10/UCache.pas) accept global functions,
object methods and nested functions.
Subclasses supply [CheckStaleness](src/Sphere10/UCache.pas) for application-specific
stale checks.

```pascal
program BasicCache;
{$IFDEF FPC}{$mode Delphi}{$H+}{$ENDIF}

uses SysUtils, UCommon, UMemory, UCache;

type
  TStringCache = TActionCache<Integer, String>;

function Fetch(const AKey : Integer) : String;
begin
  Result := 'value ' + IntToStr(AKey);
end;

function Estimate(const AValue : String) : SizeInt;
begin
  Result := Length(AValue) * SizeOf(Char);
end;

var
  cache : TStringCache;
begin
  cache := TStringCache.Create(nil,
    TStringCache.TValueFetcher.FromGlobalFunction(Fetch),
    TStringCache.TSizeEstimator.FromGlobalFunction(Estimate),
    idpNone, TStringCache.TCacheReapPolicy.crpLeastUsed,
    TStringCache.TExpirationPolicy.epSinceFetchedTime,
    TStringCache.TNullValuePolicy.nvpCacheNormally,
    1024, TTimeSpan.FromSeconds(30));
  try
    WriteLn(cache[7]);              // Fetch.
    WriteLn(cache[7]);              // Hit.
    cache.Invalidate(7);
    WriteLn(cache[7]);              // Fetch again.
    cache[8] := 'supplied value';   // Store without fetching.
    cache.Get(8).CanPurge := false; // Pin against automatic eviction.
    cache.Remove(8);               // Explicit removal ignores the pin.
  finally
    cache.Free;
  end;
end.
```

The [size estimator](src/Sphere10/UCache.pas) defines capacity units. The example
uses `Length(AValue) * SizeOf(Char)` to count native string payload bytes;
returning `1` instead counts entries. This excludes object/string allocation
overhead. Use `epSinceLastAccessedTime` for sliding expiration.

Cache operations and callbacks use a recursive lock. Callbacks may access the
same cache again, but must not destroy it. `Get` exposes a borrowed entry; keep
entries and object values alive while using them outside an operation. The value
indexer copies its result while the lock is held.

```mermaid
flowchart LR
    read["cache[key]"] --> fresh{"Present and fresh?"}
    fresh -->|Yes| hit["Return cached value"]
    fresh -->|No| fetch["Fetch source value"]
    fetch --> space["Reap expired entries, then apply eviction policy"]
    space --> store["Store and return value"]
    invalidate["Invalidate(key)"] --> stale["Next read must fetch again"]
    stale --> read
```

Object caches use [idpFreeAndNil](src/Sphere10/UMemory.pas) to free admitted objects on removal or destruction.
A rejected explicit write leaves ownership with its caller. Returned metadata and
owned values are borrowed. See [more cache examples](examples/demo/README.md) for
object ownership, notifications, capacity and callback adapters.

## Wizards

[TWizard<T> and TWizardForm<T>](src/Sphere10/UWizard.pas) host model-bound screens in
one modal window, with validation, Back/Next navigation, dynamic branches and
retryable finish/cancel vetoes. [Lifecycle events and busy-state guards](src/Sphere10/UWizard.pas)
report changes and reject reentry. The wizard owns its screens; the caller owns
the model. Run the included showcase from a Lazarus LCL or Delphi VCL application.

```pascal
uses Classes, UWizardFeatureModel, UWizardFeatureDemo;

procedure ShowFeatureWizard(AOwner : TComponent);
var
  model : TWizardFeatureModel;
  wizard : TWizardFeatureDemo;
begin
  model := TWizardFeatureModel.Create;
  try
    model.IncludeOptional := true;
    model.FinishOutcome := fcoVetoOnce;
    wizard := TWizardFeatureDemo.Create(AOwner, model);
    try
      wizard.Start(model);
    finally
      wizard.Free;
    end;
    // Inspect model.Name, model.Age and model.Events here.
  finally
    model.Free;
  end;
end;
```

Open [PascalFramework.lpi](PascalFramework.lpi) in Lazarus or
[PascalFramework.dproj](PascalFramework.dproj) in Delphi, select **Wizard and events**
and choose **Wizard feature showcase**. Both projects include these demo units.

```mermaid
flowchart LR
    name["Name"] --> valid{"Valid input?"}
    valid -->|No| name
    valid -->|Yes| age["Age and route choice"]
    age -->|Include notes| notes["Optional notes"]
    age -->|Skip notes| confirm["Confirmation"]
    notes --> confirm
    confirm --> summary["Summary"]
    summary --> accept{"Finish accepted?"}
    accept -->|No: correct or retry| summary
    accept -->|Yes| done["Finished"]
```

Actual native LCL screens from the showcase:

| Name and validation | Age and route editing |
| --- | --- |
| ![Name entry and dynamic successor](resources/wizard/wizard-name.png) | ![Age input and route controls](resources/wizard/wizard-routes.png) |
| **Optional notes** | **Confirmation boundary** |
| ![Optional notes screen](resources/wizard/wizard-optional.png) | ![Confirmation with Back disabled](resources/wizard/wizard-confirmation.png) |
| **Completion and retry** | |
| ![Summary after a vetoed finish](resources/wizard/wizard-retry.png) | [Walkthrough and launcher](examples/demo/README.md) |

Derive screens from `TWizardForm<TModel>`. Adapt the demo's
[Name screen](examples/demo/UWIZFeatureName.pas) for a minimal dynamic route as
below, adding these units to its implementation `uses` clause. `Model` is already
assigned when `Initialize` runs.

```pascal
uses UWizard, UWIZFeatureAge, UWIZFeatureCommit, UWIZFeatureSummary;

procedure TWIZFeatureName.Initialize;
begin
  Traits := [wstAssumeHasNext]; // This screen creates its successor later.
  inherited Initialize;
end;

function TWIZFeatureName.Validate(out message : String) : boolean;
begin
  message := '';
  if Trim(FNameEdit.Text) = '' then
    message := 'Enter a name before continuing'
  else if NOT FConfirmedCheckBox.Checked then
    message := 'Confirm the name before continuing';
  Result := message = '';
end;

procedure TWIZFeatureName.OnNext;
begin
  inherited OnNext;
  Model.Name := Trim(FNameEdit.Text);
  UpdatePath(ptInject, [TWIZFeatureAge, TWIZFeatureCommit, TWIZFeatureSummary]);
end;
```

Use [ptReplaceAllNext, ptReplaceAll and ptRemoveNext](src/Sphere10/UWizard.pas)
to replace the continuation, replace the full route or remove future steps. Identical contiguous injections
are idempotent. A rejected finish/cancel stays active for retry; accepted completion
runs once. See the [wizard guide](examples/demo/README.md) for callback signatures,
Back navigation and screen lifetimes.

## Scoped disposal

[TDisposables](src/Sphere10/UMemory.pas) frees registered objects and memory when
a local scope exits, including through an exception. [AddObject/AddMem/GetMem](src/Sphere10/UMemory.pas)
register ownership; [RemoveObject/RemoveMem](src/Sphere10/UMemory.pas) transfer it out.
Explicit [disposal policies](src/Sphere10/UMemory.pas) select no cleanup, object
freeing or raw-memory release.

```pascal
uses Classes, UMemory;

procedure BuildReport;
var
  scope : TDisposables;
  lines : TStringList;
begin
  lines := scope.AddObject(TStringList.Create) as TStringList;
  lines.Add('Ready');
  // Use lines here. The scope frees it when this procedure exits.
end;
```

Call `scope.RemoveObject(lines)` before transferring ownership to a caller. Keep
the scope local and do not copy it.

## Arrays and collections

[TArrayTool<T>](src/Sphere10/UCommon.pas) creates arrays, appends/removes values and
copies array storage. Object elements in a copy still refer to the same objects.

```pascal
uses Generics.Collections, UCommon;

procedure ArrayExample;
var
  values, snapshot : TArray<Integer>;
begin
  values := TArrayTool<Integer>.Create(10, 20, 30);
  TArrayTool<Integer>.Append(values, 40);
  TArrayTool<Integer>.Remove(values, 20);
  snapshot := TArrayTool<Integer>.Copy(values); // 10, 30, 40.
end;
```

[UCommon.Collections](src/Sphere10/UCommon.Collections.pas) adapts global, object and
nested callbacks for predicates, comparers and transformations. For Free Pascal, the bundled
[Generics.Collections](src/Generics.Collections/generics.collections.pas) provides
lists/object lists, dictionaries/object dictionaries, queues, stacks, hash sets and
sorted hash sets. [FilterBy](src/Sphere10/UCommon.Collections.pas) changes the supplied list.

```pascal
uses Generics.Collections, Generics.Defaults, UCommon, UCommon.Collections, UMemory;

function IsEven({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AValue : Integer) : boolean;
begin
  Result := (AValue mod 2) = 0;
end;

function Descending({$IFDEF FPC}constref{$ELSE}const{$ENDIF} ALeft, ARight : Integer) : Integer;
begin
  Result := TCompare.Integer(ARight, ALeft);
end;

procedure FilterAndSort;
var
  scope : TDisposables;
  values : TList<Integer>;
begin
  values := scope.AddObject(TList<Integer>.Create) as TList<Integer>;
  values.AddRange([1, 2, 3, 4, 5, 6]);
  TListTool<Integer>.FilterBy(values, TPredicateTool<Integer>.FromFunc(IsEven));
  values.Sort(TComparerTool<Integer>.FromFunc(Descending)); // 6, 4, 2.
end;
```

Compose [predicates with AndMany/OrMany](src/Sphere10/UCommon.Collections.pas),
[comparers with Many/Inverted](src/Sphere10/UCommon.Collections.pas), and
[transforms with TListTool<TSource, TResult>.Transform](src/Sphere10/UCommon.Collections.pas).

## Results and diagnostics

[TResult](src/Sphere10/UCommon.pas) carries a Variant value and timestamped debug,
info, warning or error messages. [IsSuccess/IsFailure](src/Sphere10/UCommon.pas)
reflect error status; [ToString](src/Sphere10/UCommon.pas) formats the collected diagnostics.

```pascal
uses UCommon;

function ValidateName(const AName : String) : TResult;
begin
  if AName = '' then
    Exit(TResult.Failure('Enter a name'));
  Result := TResult.Success('Name accepted');
  Result.Value := AName;
end;
```

## Dates, bytes and statistics

[TDateTimeHelper and TTimeSpan](src/Sphere10/UCommon.pas) provide calendar/duration
arithmetic, parsing and formatting. [Hex2Bytes/Bytes2Hex](src/Sphere10/UCommon.pas)
convert binary data; [TVariantTool](src/Sphere10/UCommon.pas) compares numeric/text
Variants; [TStatistics](src/Sphere10/UCommon.pas) accumulates count, sum, min/max,
mean and variance without keeping every sample.

```pascal
uses SysUtils, UCommon;

procedure CommonExample;
var
  expires : TDateTime;
  bytes : TBytes;
  stats : TStatistics;
begin
  expires := TDateTime.Now.AddMinutes(5);
  bytes := Hex2Bytes('00FF');
  WriteLn(Bytes2Hex(bytes));                // 00FF.
  stats.Reset;
  stats.AddDatum(10);
  stats.AddDatum(20);
  stats.AddDatum(30);
  WriteLn(stats.Mean:0:1);                  // 20.0.
  WriteLn(TVariantTool.NumericGTE(21, 18));  // TRUE.
end;
```

[TBox<T>](src/Sphere10/UCommon.pas) wraps a typed value in an object;
[TFileTool.AppendText](src/Sphere10/UCommon.pas) appends to a text file, and
[TCPUTool.GetLogicalCPUCount](src/Sphere10/UCommon.pas) reports logical processors.

## Multicast events

[TNotifyManyEvent](src/Sphere10/UCommon.pas) adds/removes several object-method
listeners and invokes them together. [Thread notification helpers](src/Sphere10/UCommon.pas)
can queue individual listeners for the UI main thread.

```pascal
uses Classes, UCommon;

type
  TDocument = class
  private
    FChanged : TNotifyManyEvent;
    procedure HandleChanged(Sender : TObject);
  public
    procedure Demonstrate;
  end;

procedure TDocument.HandleChanged(Sender : TObject);
begin
  WriteLn('Document changed');
end;

procedure TDocument.Demonstrate;
begin
  FChanged.Add(HandleChanged);
  try
    FChanged.Invoke(Self);
  finally
    FChanged.Remove(HandleChanged);
  end;
end;
```

`Add(HandleChanged, True)` queues delivery on the main thread. Queued senders and
receivers must remain alive until delivery.

## Reader/writer locking

[TReadWriteLock](src/Sphere10/UConcurrency.pas) is modeled after the read, write
and upgradeable-read contract of the .NET lock used by Sphere10's C# framework.
This implementation uses Pascal RTL critical sections and event waits; no .NET
runtime implementation was copied. Ordinary readers share access. One thread
can reserve upgradeable-read ownership while ordinary readers continue; its
write acquisition waits for those other readers to leave. Writers have exclusive
access.

```pascal
uses UConcurrency;

procedure LockExample;
var
  gate: TReadWriteLock;
  value: Integer;
begin
  gate := TReadWriteLock.Create(lrpNoRecursion);
  try
    value := 0;
    gate.EnterWriteLock;
    try
      Inc(value);
    finally
      gate.ExitWriteLock;
    end;

    // Other threads may hold their own read locks concurrently.
    if gate.TryEnterReadLock(0) then
    try
      WriteLn(value);
    finally
      gate.ExitReadLock;
    end;

    // Choose upgradeable mode before work that may need a write.
    gate.EnterUpgradeableReadLock;
    try
      if value = 1 then begin
        gate.EnterWriteLock;
        try
          value := 2;
        finally
          gate.ExitWriteLock;
        end;
      end;
      // The surrounding upgradeable acquisition is still held here.
    finally
      gate.ExitUpgradeableReadLock;
    end;
  finally
    gate.Free;
  end;
end;
```

Promotion uses `EnterWriteLock` or `TryEnterWriteLock` while the same thread
holds upgradeable read ownership. This is allowed with `lrpNoRecursion`, as in
the example. The write acquisition is additional:
`ExitWriteLock` releases only that write acquisition; the surrounding
`ExitUpgradeableReadLock` remains necessary. The nested `try`/`finally` blocks
above preserve that balance when protected work raises an exception. Recursive
acquisitions likewise require one matching typed exit for each successful entry;
the lock never guesses which mode a caller intends to release.

Each `TryEnter*Lock` accepts integer milliseconds: `-1` waits indefinitely,
`0` tests immediately, and a positive value bounds the wait; for example,
`TryEnterWriteLock(5000)` waits up to five seconds. A failed attempt
retains any outer acquisition. `lrpNoRecursion` is the default;
`lrpSupportsRecursion` permits nested ownership, including a writer taking a read
lock. Ordinary read ownership cannot become write or upgradeable ownership.
Waiting writers take precedence over new readers. There is no FIFO guarantee.

Release every acquisition on the thread that acquired it. `Is*LockHeld` and
`Recursive*Count` describe the calling thread; `CurrentReadCount` counts distinct
explicit read owners, excluding upgradeable-only access. Stop and join consumers
before freeing the lock. `Dispose` rejects active owners/waiters without changing
their state; finite `TryEnter` calls allow consumers to check their own cooperative
cancellation between waits. See the [shared regression cases](tests/UConcurrency.Tests.pas).

## Throttled UI events

Run the small [five-second grid throttle demo](examples/throttle/README.md) to
test repeated **Notify** clicks against the real grid, its owned throttle and a
counted data source. It includes Delphi and Lazarus projects, a quiet-time
countdown and a timestamped event log.

[TThrottledEvent](src/Sphere10/UCommon.UI.pas) coalesces repeated UI events. Select
[immediate, interval, burst-end or burst-start-and-end delivery](src/Sphere10/UCommon.UI.pas);
inspect suppressed-call counts and notification timestamps. Create an owned event,
then call its [Notify](src/Sphere10/UCommon.UI.pas) from UI handlers.

```pascal
uses Classes, UCommon, UCommon.UI;

function CreateRefreshEvent(AOwner : TComponent;
  AHandler : TNotifyEvent) : TThrottledEvent;
begin
  Result := TThrottledEvent.Create(AOwner);
  Result.Interval := TTimeSpan.FromMilliseconds(250);
  Result.Mode := temNotifyOnEventBurstFinished;
  Result.Add(AHandler);
end;
```

An active LCL/VCL message loop is required. `temNotifyOnEventBurstFinished` waits for
one full `Interval` without another `Notify` call; each new event restarts that
quiet period. `temNotifyOnEventBurstStartAndFinished` adds an eligible immediate
leading notification to the same trailing behavior. Use
`temNotifyEveryInterval` for periodic delivery during a continuous burst instead.
Each deferred input in the two quiet-burst modes cancels and rearms the native
timer for a full `Interval`; periodic mode retains its already armed deadline.
Polling application state must not call `Notify` unless a new event occurred.
Once the previous burst has ended with its trailing callback, a new input starts
a new leading notification without an additional delivery-based cooldown.

The two quiet-burst modes expose [Waiting and OnWaitingChanged](src/Sphere10/UCommon.UI.pas)
for driving a busy UI independently of data-fetch completion:

```pascal
procedure BindBusyState(AEvent : TThrottledEvent;
  AStateChanged : TNotifyEvent);
begin
  AEvent.OnWaitingChanged.Add(AStateChanged);
  AStateChanged(AEvent); // Also apply the initial state.
end;
```

The state-change handler reads `TThrottledEvent(Sender).Waiting` to show or hide
its busy presentation. State and timer changes are committed before listeners
run. The first input starts waiting and delivers immediately in start-and-end
mode; each further input restarts the quiet timer. After silence, one pending
delivery runs and waiting ends. A single input ends waiting without a duplicate
delivery. Node, network and worker state do not enter this calculation.

`BurstActive` is an alias for `Waiting`. The older Started/Finishing/Finished
events remain available. `Cancel` and changing `Mode` clear waiting without an
ordinary delivery or a fabricated quiet finish; state-change listeners still
receive the transition. Exceptions from callbacks propagate while leaving the
timer/state coherent. A running page fetch can retain its own loading UI after
the throttle's busy presentation has ended.

The optional [Postpone](src/Sphere10/UCommon.UI.pas) API is an explicit new request
to delay a delivery, retained for existing callers. A consumer requiring only
refresh-input quiet periods should use `Notify` and `Waiting`, without an external
finishing veto or polling another service's status.

## Form ownership and docking

[TApplicationForm](src/Sphere10/UCommon.UI.pas) adds first-activation/destruction
events, configurable close behavior and [AutoDispose](src/Sphere10/UCommon.UI.pas)
for form-owned noncomponent objects. [AddControlDockCenter](src/Sphere10/UCommon.UI.pas)
fills a container; [SetImageListPicture](src/Sphere10/UCommon.UI.pas) copies an image-list
entry into a TImage. Controls retain normal component ownership.

```pascal
uses Classes, Controls, ExtCtrls, UCommon.UI;

procedure PrepareForm(AForm : TApplicationForm; AContainer : TWinControl);
var
  names : TStringList;
  panel : TPanel;
begin
  names := AForm.AutoDispose(TStringList.Create) as TStringList;
  names.Add('Ada');
  panel := TPanel.Create(AForm);
  panel.Caption := names[0];
  AContainer.AddControlDockCenter(panel);
end;
```

Application forms hide on Close by default; hidden forms still own their resources.

## Data rows and search expressions

Column names, named row bindings, grid column names and
`Binding`/`SortBinding`/`DisplayBinding` use native `String`. Data-source overrides
must declare `GetItemField(...; const ABindingName: String)` too. This retains
Unicode text in Delphi and the normal Lazarus text conventions in FPC. The
search-expression tokenizer keeps its explicit UTF-8 input/token contract;
that byte-level parser boundary is separate from schema and UI names.

[TDataRow and TDataColumns](src/Sphere10/UCommon.Data.pas) expose named fields through
a managed Variant. [Filter/sort criteria](src/Sphere10/UCommon.Data.pas) describe text
and numeric comparisons and sort directions; [data sources choose null ordering](src/Sphere10/UCommon.Data.pas).
[TSearchExpressionService](src/Sphere10/UCommon.Data.pas) parses numeric comparisons,
inclusive/exclusive intervals and text-match expressions. Use one schema ID for
each consistent column set; field names are case-sensitive.

```pascal
uses SysUtils, Variants, UCommon.Data;

type
  TPersonSchema = class end;

procedure ShowPerson;
var
  columns : TDataColumns;
  row : Variant;
  expression : TExpressionRecord;
begin
  columns := TDataColumns.Create(
    TDataColumn.From('ID', true), TDataColumn.From('Name'));
  row := TDataRow.New(PtrInt(TPersonSchema), columns);
  row.ID := 7;
  row.Name := 'Ada';
  WriteLn(VarToStr(row.Name));
  expression := TSearchExpressionService.Parse('>=18');
  // ekNum, nckNumericGTE, Values[0] = '18'.
  expression := TSearchExpressionService.Parse('[10,20]'); // Inclusive interval.
  expression := TSearchExpressionService.Parse('Ada%');  // Text prefix.
end;
```

# Open, build and test

Open [Sphere10Framework.lpg](Sphere10Framework.lpg) in Lazarus, or select a project:

| Project | Purpose |
| --- | --- |
| [PascalFramework.dproj](PascalFramework.dproj) | Run the unified Visual grid, Wizard/events and Cache demo in Delphi |
| [PascalFramework.lpi](PascalFramework.lpi) | Run the same application in Lazarus/FPC |
| [Sphere10Framework.groupproj](Sphere10Framework.groupproj) | Delphi project group: runnable demo first, optional runtime package second |
| [Sphere10Framework.lpg](Sphere10Framework.lpg) | Lazarus project group: demo, package and tests |
| [Sphere10Framework.dproj](Sphere10Framework.dproj) | Delphi runtime package; build it for reuse |
| [Sphere10Framework.lpk](Sphere10Framework.lpk) | Lazarus library/control package |
| [FrameworkTests.lpi](tests/FrameworkTests.lpi) | Separate FPCUnit GUI test runner |

For Free Pascal, use Delphi mode and add `src/Sphere10` and `src/Generics.Collections` to the unit
search path. Its UI units use Lazarus LCL; the supplied projects configure their
paths. Package installation is optional; see the [package guide](packages/README.md).

For Delphi, open `PascalFramework.dproj` and press **F9** to build and run the
unified demo. It references `src/Sphere10` directly and needs no installed package.
The optional runtime package is a library build target; the runnable demo is the
first project in the group.
The same units use VCL forms/resources under Delphi and LCL under Free Pascal;
keep each platform's paired `.dfm`/`.lfm` resources. Delphi uses its RTL generics,
so add only `src/Sphere10` to a Delphi source project's unit search path.
Community Edition users should compile through the IDE.

Build the demo and optional runtime package separately: a source-based demo build
does not establish package compatibility. Run the native Delphi probes to check
VCL behavior; FPC's `-MDelphi` is a language mode and does not substitute for an
Embarcadero compiler build. The [test guide](tests/README.md) lists suite coverage
and native checks for grid refresh, loading, wizard windows and reader/writer locks.

Run the unit suite and the real modal wizard check on Windows:

```powershell
.\tests\RunTests.ps1 `
  -FpcPath 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory 'D:\Pascal\lazarus'

.\tests\RunWizardNativeTests.ps1 `
  -FpcPath 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory 'D:\Pascal\lazarus'
```

Replace the tool paths for your installation. The native probe checks one stable
wizard window, hidden inactive screens and retry/cancel behavior on a private
desktop. See the [test guide](tests/README.md) for coverage and fixture selection.

# License and copyright

Copyright © 2017–2026 [Herman Schoenfeld](https://sphere10.com/).

PascalFramework is distributed under the [MIT License](LICENSE). Third-party
components retain their own licenses and copyright notices in their source
directories.
