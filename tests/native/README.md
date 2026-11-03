# Native component checks

## Buffered streams

[BufferedStreamProbe.dproj](BufferedStreamProbe.dproj) runs the same 86
[stream contracts](../UStreams.Checks.pas) as FPCUnit, including forward-only
inputs, ownership, failures and sparse positions above 1 TiB. Build/run in Delphi
Win32 or Win64; pass an optional log-file path. Success exits normally with code
zero and leak reporting enabled. It requires no wallet, network or OpenSSL.
The same cases cover default-true read/length flags, direct mode, explicit
`FlushUnreadData`, rejected-disable atomicity and buffer re-enabling.

## Custom loading cards

Open [GridLoadingProbe.dproj](GridLoadingProbe.dproj) in Delphi and build/run
Win64 Debug. This small VCL application checks copied custom artwork, title and
subtitle, input gating, programmatic refresh, fetch/error precedence, a caller's
disabled grid and loading requested before parenting. It also checks that the
card preserves a modeless window's activation and keyboard focus. No wallet,
network or OpenSSL runtime is involved.

The probe exits automatically: zero for success, one for an assertion failure,
two for initialization failure. An optional first argument selects the log path;
without it, the log is `%TEMP%\GridLoadingProbe-<PID>.log`. It also saves native
bitmap captures beside that log. Output stays under
`tests/lib/Delphi/<Platform>/grid-loading/<Config>`. The project has no build events.

Lazarus coverage for the same API lives in the mirrored
[UVisualGrid.Refresh.Tests](../UVisualGrid.Refresh.Tests.pas), including the seven
manual-loading regressions. The VCL helper/project are mirrored in the wallet's
embedded framework checks.

## Five-second throttle

Open [NativeThrottleProbe.dproj](NativeThrottleProbe.dproj) in Delphi and build Win64 Debug. This console
executable exercises the real `TThrottledEvent` and its owned VCL timer. It uses
no wallet data, network connections or OpenSSL DLLs.

The approximately 24-second [native source](NativeThrottleProbe.dpr) runs ten scenarios concurrently:

| Scenario | Expected behavior |
|---|---|
| Inputs every 100 ms for 16 seconds | One leading call, then one final call after five quiet seconds |
| Inputs every second for 16 seconds | The same two calls |
| Another input at 4.9 seconds while delivery is pending | The quiet deadline restarts |
| Two separate bursts | One leading and one final call per burst |
| Finished-only burst mode | One final call without a leading call |
| Periodic mode | Preserve the existing periodic deadline |
| Single-input lifecycle and a later new burst | Finish Waiting without a duplicate ordinary callback; the next input leads |
| Exception in the trailing callback | Observe the failure, retain coherent timer/state and recover for later input |
| Cancel during a pending burst | Publish Waiting false without fake completion; fresh input works |
| Mode change during a pending burst | Clear Waiting and recover without delivering cancelled work |

A passive wrapper logs each real timer callback before invoking the original
component handler. The trace distinguishes timer wakes from delivered events;
both are checked independently. Burst timers must remain quiet while inputs
continue. Checks allow 20 ms for Windows tick quantization and log native
`TTimeSpan` values beside monotonic elapsed time.

The executable accepts one trace-file argument. With Free Pascal on PATH, run
these commands from the repository root after building the Delphi project:

```powershell
New-Item tests\lib\native-throttle\broker,D:\temp\ThrottleProof -ItemType Directory -Force
fpc -FEtests\lib\native-throttle\broker -FUtests\lib\native-throttle\broker tests\native\PrivateDesktopBroker.lpr
.\tests\lib\native-throttle\broker\PrivateDesktopBroker.exe `
  .\tests\lib\native-throttle\Win64\Debug\bin\NativeThrottleProbe.exe `
  D:\temp\ThrottleProof\trace.log
```

The broker creates an owned Windows desktop and never switches the input
desktop. Its watchdog is 40 seconds in PascalFramework; the wallet broker gives
the full unit suite up to ten minutes for its real persistence waits. No
additional launcher is required.
`result.json` is written beside the trace; failures return a nonzero exit code.
Compiler outputs stay under the project's adjacent ignored `lib` directory.

The mirrored source is Delphi-specific native coverage. The real-timer FPCUnit
regressions remain in each library's `UCommon.UI.Tests.pas`.

## Data-row Variant compatibility

Open [DataRowVariantProbe.dproj](DataRowVariantProbe.dproj) in Delphi, Win64 Debug.
The [source](DataRowVariantProbe.dpr) covers positional access and native text:

| Group | Required behavior |
|---|---|
| Explicit conversion | `Integer(Row._(0))` returns the declared first column |
| Variant temporary | `Value := Row._(0)` preserves a numeric Variant |
| Implicit Integer assignment | An Integer variable receives the positional value |
| Runtime Integer index | Numeric and text positions select the correct columns |
| Named columns and key | `__KEY` stays independent of declared columns and positional access |
| Copied row | Mutating the copied columns/key leaves the original unchanged |
| Actual VCL grid | Synchronous `TVisualGrid.Cells[x,y]` returns both fixture rows and their keys |
| Unicode bindings and grid | Distinct native String names/bindings and Unicode values survive actual VCL cells |
| Unicode row copy | Named values and keys survive a copy without changing the original |
| Wizard native String | Captions and validation, finish and cancellation messages retain Unicode text |

This is Delphi native coverage for the existing API; the FPC 3.2.0/3.2.2 dispatch
regressions remain in the mirrored fourteen-case `UCommon.Data.Tests` fixture.
The native source passes against both shared copies before and after the FPC-only
dispatcher correction.

## Per-grid request admission

Open [GridThrottleProbe.dproj](GridThrottleProbe.dproj), Win64 Debug. The
[source](GridThrottleProbe.dpr) exercises actual VCL grids and provider fetch
counts through eight groups, using each grid's own real five-second timer for
refresh admission and queued notifications for worker completion:

| Group | Required behavior |
|---|---|
| Refresh suspension | No query while paused; latest page/filter/sort/resize survives; resume is immediate after cancelling the old quiet interval; cancelled results/errors cannot publish across a suspend/resume/suspend race; cooperative worker cancellation releases the actual provider lock |
| Parentless/hidden populated grids | Requests still reach the owned throttle; reattachment publishes current rows without a native parent error |
| Mixed inputs and independent timers | Refresh/page/search/sort/resize reset the relevant grid only; latest parameters win |
| Busy single/latest requests | Worker completion cannot bypass Waiting; quiet finish releases a deferred single request |
| Held result and completion input | Waiting ends independently of a held fetch; selected rows shrink safely through empty/one-row results; internal layout does not Notify, while an explicit completion-listener refresh does |
| Cancel, mode and disposal | No cancelled request starts a query; a later new request still leads |
| Completion without timer dispatch | A real gated worker publishes its page and completion once through `CheckSynchronize`, without pumping `WM_TIMER` |
| Cancellation before execution | A worker cancelled before `Execute` retires without reading; exactly one latest page loads, and closing it preserves another grid receiver |

The earlier six-group runs pass against standalone and embedded copies with
natural exit zero. The selected-row/empty-result group checks native current-row bounds as
well as final selection, so suppressing an exception alone cannot satisfy it.

[`RefreshSuspended`](../../src/Sphere10/UVisualGrid.pas) is a UI-thread admission
boundary, independent of the throttle and of product/node state. It retains new
requests and allows visual layout, requests cooperative cancellation of active
work without joining it, and ignores that worker's results and errors. Cancel
`RefreshThrottle` while still suspended, then clear `RefreshSuspended` to admit
one latest query immediately; an old cancelled worker retires before its
replacement starts. The checked FPC fixture passes 47 cases against each copy,
including eight suspension and four queued-loading regressions.

On 30 October 2026, the focused suspension group passes actual Delphi Win64
range/overflow-checked builds and private-desktop runs against both source
copies, with natural exit zero. These two runs exercise the new group only;
the six-group results above remain earlier evidence.

## Cancellation before execution

The shared [worker checks](../UVisualGrid.Worker.Checks.pas) force cancellation in the actual thread
constructor before it starts. Both RTLs may skip `Execute` for an already
cancelled thread. Completion therefore comes from `DoTerminate`, using the
owned asynchronous dispatcher; the UI joins the worker before disposing it.
The check requires zero reads from the cancelled request, exactly one latest
query/completion, timer-free delivery and safe receiver disposal.

The test projects define `VISUALGRID_TEST_WORKER_START`. This enables a one-shot
constructor hook which the fixture restores in `finally`; normal applications
and packages omit the define and contain no hook. Use separate compiled-unit
output for hook-enabled tests and normal builds. No priority or CPU-affinity
changes are used.

Build [GridThrottleProbe.dproj](GridThrottleProbe.dproj), then run only this case
from the repository root:

```powershell
$env:PASCAL_GRID_EARLY_CANCEL_ONLY = '1'
.\tests\lib\Delphi\Win64\grid-throttle\Debug\GridThrottleProbe.exe D:\Builds\GridEarlyCancel.log
```

Unset that selector for a full run. The focused FPC reproduction fails against
the old worker and passes the corrected worker. Actual Delphi focused coverage
and the full eight-group grid admission probe also pass with natural exit zero.

## Running the source probes

Set `PASCAL_GRID_SUSPENSION_ONLY=1` in `GridThrottleProbe`'s process environment
to run only its new suspension group. It uses actual VCL controls and counted
typed providers; no wallet data, peer connection or node-status substitute is
involved. Leave focused selector variables unset to run the full probe.

`GridThrottleProbe` also has a completion-only case. Set
`PASCAL_GRID_COMPLETION_ONLY=1` in its process environment to run that focused
check. It releases a real blocked provider and requires exactly one page
publication and completion callback while pumping only `CheckSynchronize`;
no Windows messages or timer callbacks are dispatched. Both standalone and
embedded Delphi projects exercise the same mirrored source.

Set `PASCAL_GRID_LOADING_ONLY=1` to run four focused loading checks: visible
feedback while a request waits for throttle admission, cancellation, precedence
of caller-owned artwork, and retaining an already-visible card when a deferred
single request finally starts its worker. These checks use actual VCL controls
and providers; the test's separate manual Waiting-to-card binding is detached.
Both library copies pass this group with actual checked Delphi Win64 builds and
natural exit zero. Queued work uses the same short display delay as active work,
without changing the throttle's timer or starting a provider early.

`DataRowVariantProbe` and `GridThrottleProbe` accept zero or one log-file argument.
With no argument they use `%TEMP%\<ProbeName>-<PID>.log`; an extra argument exits
64. A successful run exits zero, and a caught assertion/runtime failure exits one.
Their reports are plain-text PASS/FAIL logs, not the throttle probe's `result.json`.
Pass a D: log path or set TEMP/TMP to an owned D: folder for controlled runs.
They require neither wallet data nor a network/OpenSSL runtime.

Use the existing private-desktop broker as above, substituting the chosen EXE
and log path. It creates only its own test desktop and never switches the input
desktop. The projects use ordinary source/resource builds with no build events.

Data-row outputs: `tests/lib/Delphi/<Platform>/data-row-variant/<Config>`.
Grid admission outputs: `tests/lib/Delphi/<Platform>/grid-throttle/<Config>`.

## Managed scopes and disposal bags

Build [ScopeProbe.dproj](ScopeProbe.dproj) in Delphi 13, or compile
[ScopeProbe.dpr](ScopeProbe.dpr) with FPC's `-MDelphi` option and both the framework
source and parent test directory on the unit search path. It runs 63 shared assertions from [UScope.Checks](../UScope.Checks.pas),
[UDisposables.Scope.Checks](../UDisposables.Scope.Checks.pas) and
[UReadWriteScope.Checks](../UReadWriteScope.Checks.pas).
Results go to standard output; success exits zero and an assertion failure exits one.
It needs no UI, wallet data, installed package or network connection.

The checks cover automatic exits, copied/returned `TScope` records, fields and
arrays, borrowed cleanup targets, nil methods and cleanup failures, original bag
ordering/transfers/reallocation, both
recursion policies, promotion/downgrade, blocked acquisition and thread affinity.
Delphi enables shutdown leak reporting; FPC can run with heap tracing (`-gh`).

## Bulk-Fetch Caching

Build [BulkCacheProbe.dproj](BulkCacheProbe.dproj) with Delphi or compile its
[shared source](BulkCacheProbe.dpr) with Lazarus/FPC. It runs the same bulk-cache
contract checks and public API recipes: one batch per lookup, snapshot retention,
explicit refresh/purge, borrowed ownership, provider failures and callback forms.
The first argument selects its log; `EXIT_CODE=0` indicates success.

## Grid paging and complete-row sizes

Build [GridViewportProbe.dproj](GridViewportProbe.dproj) with Delphi, or run
[RunGridViewportNativeTests.ps1](../RunGridViewportNativeTests.ps1) with FPC and
Lazarus paths. The shared checks compare page capacity with actual native cell
bounds at exact and one-pixel boundaries, different row/header heights, line
widths, DPI scaling, scrollbars and resizing. Only fully visible rows fit a page;
the minimum remains one row when the control is too small for any complete row.
The first probe argument selects its log; it exits nonzero on failure.

The probe also runs the shared `TVisualGridPagingTests` regressions from
[UVisualGrid.Paging.Checks](../UVisualGrid.Paging.Checks.pas) and
[UVisualGrid.Viewport.Checks](../UVisualGrid.Viewport.Checks.pas):

| Case | Required behavior |
| --- | --- |
| Legacy ShowAll | Fetch every row without a cached total, including later growth. |
| Source before parent | A synchronous source can load before docking; native geometry is valid after showing. |
| Single | Query the complete unknown/growing result and expose native vertical scrolling. |
| Mode transitions | Space activates the square icon button and opens its checked Single/Auto/Manual popup; native menu commands retain manual size and refit complete Auto rows after scrollbar or size changes. |
| Mode scroll origin | All six mode changes restore page zero and both native scroll positions after synchronous, suspended and held-worker publication; assigning the same mode preserves scroll and makes no query. |
| Search and sort | Single filters and sorts the entire result. |
| Empty and one-page results | Auto-hidden navigation never hides the mode selector, including narrow footers. |
| Suspension and input gating | Mode/size/resize changes make no query while suspended; resume loads the latest mode once; disabled loading gates the selector. |
| Obsolete completion | Switching to Single rejects a held finite worker’s result. |
| Paging disabled | Every retained mode queries all rows; re-enabling paging restores manual size. |

The mirrored `UVisualGrid.Loading.Checks` uses a real asynchronous provider and
five-second throttle. A partial page with an unknown total forces native search
chrome to change capacity: accepted rows clear Updating while the internal refit
waits. New client input retains its card; manual images and error presentation
remain independent. `GridViewportProbe` runs all four cases.

On the owned private desktop, paging-mode selection uses `WM_COMMAND` through the popup's
registered native owner after verifying its HWND/HMENU, item ID, caption and
state. The real menu-item callback and resulting fetches are checked. This proves
native command dispatch; it does not claim physical mouse or keyboard selection.

The footer matrix in
[UVisualGrid.Paging.Checks](../UVisualGrid.Paging.Checks.pas) covers 45
width/DPI/mode combinations: logical widths 240, 300, 340, 400 and 900 at 96, 144 and
192 PPI, each in Auto, Manual and Single. It measures real native window bounds,
requiring the mode selector immediately left of visible navigation in their
shared parent, aligned centers, and no overlapping or clipped visible controls.
Five-digit page-count and page-entry text must fit. Each Manual case also clicks
the real last-page button and checks page 10001, then repeats the geometry
assertions. These cases run through the same probe in Delphi/VCL and Lazarus/LCL;
their logs record the actual rectangles and spacing for review.

## Unified demo paging captures

[FrameworkDemoPagingCapture.dpr](FrameworkDemoPagingCapture.dpr) creates the
actual [unified demo form](../../examples/demo/UFRMDemoMain.pas) and its existing
10,000-row source. An owned QA timer selects **Auto**, **Manual 25**, then
**Single** through the actual popup and its native command route. Each capture waits for completed work and
stable native geometry. Assertions cover full Auto rows without vertical
scrolling, Manual’s 400 pages, and all 10,000 rows on Single’s one scrollable page.
The tool closes its own main form normally, with a 30-second overall deadline.

Compile this source as a Windows GUI application with each compiler, using the
root demo’s search paths and resources: `src/Sphere10` and `examples/demo`, plus
the matching Lazarus LCL, LazUtils, IDEIntf and RTTIControls package paths and
bundled Generics.Collections paths for FPC.
Delphi uses the same VCL resources and namespace settings as the root
`Sphere10PascalFramework.dproj`; no installed package is required. Keep the
compiler outputs separate. This source is a test tool, not another main project.

Pass exactly one absolute log filename in a fresh QA directory. For example,
after building both EXEs and the existing private-desktop broker:

```powershell
& $Broker $DelphiCaptureExe 'D:\Builds\PascalFramework\paging\delphi.log'
& $Broker $FpcCaptureExe 'D:\Builds\PascalFramework\paging\fpc.log'
```

The broker creates only its owned desktop and never switches the input desktop.
Each invocation creates `<log-stem>-captures` beside its log and refuses an
existing capture directory. VCL captures the main client with `GetFormImage`;
LCL paints the actual hosted grid page, including its inspector and native
widgets, without the main tab strip or window frame. The LCL capture requires
painted text in the fetched Name cell and live inspector, plus a visible paging icon.
Output is saved as
`unified-grid-{auto,manual,single}-{delphi,fpc}.png`. Logs distinguish the
configured page size from Single’s unbounded request and record actual rows,
pages and totals. Success exits zero; an assertion or initialization failure
exits one. Inspect the resulting PNGs as well as the log before publishing them.

## Selection event delivery

[UVisualGrid.Selection.Checks](../UVisualGrid.Selection.Checks.pas) checks four
selection scenarios on actual controls: one event per native row click, repeated
click deselection, an explicit clear inside a selection callback, and
programmatic selection/clearing with and without a handler. Native mouse tests
send button-down/up messages only to the owned grid window; they do not move the
user's cursor. The callback-clear case requires one genuine empty follow-up,
without confusing last-click memory with the current selection.

Set `PASCAL_GRID_SELECTION_ONLY=1` when running `GridViewportProbe` for these four
checks alone. The equivalent FPCUnit fixture is
`TVisualGridSelectionEventTests` in `UVisualGrid.Refresh.Tests`. Native mouse
cases explicitly skip on non-Windows widgetsets; programmatic cases remain
portable. These checks use no wallet, network or OpenSSL runtime.

## Active fetch cancellation

Set `PASCAL_GRID_ACTIVE_CANCEL_ONLY=1` when running `GridViewportProbe` to run
three shared `UVisualGrid.Worker.Checks` cases. A held provider proves
`CancelActiveFetch` returns without joining, retains accepted rows/manual
artwork, rejects the old result and publishes only the latest pending page.
A cooperative provider proves cancellation reaches its worker while the latest
request still observes the same five-second quiet interval. Idle cancellation
must neither notify nor end that wait. A cancelled provider also raises an
ordinary sentinel exception: its old error card must remain absent before a
replacement query is scheduled. These three cases require no constructor hook.

With the existing test-only `VISUALGRID_TEST_WORKER_START` define enabled, the
same selector additionally calls `CancelActiveFetch` before the real worker
starts. It queues the latest page inside that hook and requires zero old reads,
one latest publication and unchanged suspension. The hook is restored in
`finally`; no scheduler priority, affinity or global input changes are used.

FPCUnit exposes these cases as
`TVisualGridQueuedCompletionTests.CancelActiveFetchNeverJoinsOrPublishesAHeldQuery`
and `CancelledFetchRetainsTheLatestFiveSecondAdmission`, plus
`CancelledProviderExceptionCannotPublishAnErrorCard`. Hook-enabled suites also
register `PublicCancellationBeforeStartKeepsTheLatestRequest`.
A private old-source
comparison may define `VISUALGRID_ACTIVE_CANCEL_BASELINE` to omit only the API
call absent from that source; all behavioral assertions remain unchanged.
Normal builds and GREEN tests omit that comparison define.
