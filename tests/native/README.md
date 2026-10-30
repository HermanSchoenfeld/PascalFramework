# Native component checks

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
counts through seven groups, using each grid's own real five-second timer for
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

## Running the source probes

Set `PASCAL_GRID_SUSPENSION_ONLY=1` in `GridThrottleProbe`'s process environment
to run only its new suspension group. It uses actual VCL controls and counted
typed providers; no wallet data, peer connection or node-status substitute is
involved. Leave both selector variables unset to run all seven groups.

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

## Whole-source caches

Build [BulkCacheProbe.dproj](BulkCacheProbe.dproj) with Delphi or compile its
[shared source](BulkCacheProbe.dpr) with Lazarus/FPC. It runs the same bulk-cache
contract checks and public API recipes: one batch per lookup, snapshot retention,
explicit refresh/purge, borrowed ownership, provider failures and callback forms.
The first argument selects its log; `EXIT_CODE=0` indicates success.

## Automatic grid page sizes

Build [GridViewportProbe.dproj](GridViewportProbe.dproj) with Delphi, or run
[RunGridViewportNativeTests.ps1](../RunGridViewportNativeTests.ps1) with FPC and
Lazarus paths. The shared checks compare page capacity with actual native cell
bounds at exact and one-pixel boundaries, different row/header heights, line
widths, DPI scaling, scrollbars and resizing. Only fully visible rows fit a page;
the minimum remains one row when the control is too small for any complete row.
The first probe argument selects its log; it exits nonzero on failure.
