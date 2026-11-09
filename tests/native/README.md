# Native component checks

These probes check framework components in native Delphi and Lazarus/FPC
builds. They need no wallet, network, OpenSSL or installed Delphi package. The
[test guide](../README.md) covers the FPCUnit suite and the Lazarus wizard and
loading probes.

## Private-desktop broker

The broker creates its own Windows desktop for a probe and never switches the
input desktop. It returns the probe's exit code, or 124 if its 40-second
watchdog stops the probe. An optional third argument sets the watchdog in
milliseconds, up to 300000.

Build the [throttle probe](#five-second-throttle) in Delphi. Then, with Free
Pascal on PATH, build the broker and run the probe from the repository root:

```powershell
New-Item tests\lib\native-throttle\broker,<new-folder> -ItemType Directory -Force
fpc -FEtests\lib\native-throttle\broker -FUtests\lib\native-throttle\broker tests\native\PrivateDesktopBroker.lpr
.\tests\lib\native-throttle\broker\PrivateDesktopBroker.exe `
  .\tests\lib\native-throttle\Win64\Debug\bin\NativeThrottleProbe.exe `
  <new-folder>\trace.log
```

For another probe, pass its executable and log path instead.

## Buffered streams

[BufferedStreamProbe.dproj](BufferedStreamProbe.dproj) runs the same 101
[stream contracts](../UStreams.Checks.pas) as FPCUnit. Build and run it in
Delphi for Win32 or Win64, optionally passing a log-file path. It exits zero on
success and reports leaks at shutdown.

## Managed scopes and disposal bags

ScopeProbe runs 63 shared checks from [UScope.Checks](../UScope.Checks.pas),
[UDisposables.Scope.Checks](../UDisposables.Scope.Checks.pas) and
[UReadWriteScope.Checks](../UReadWriteScope.Checks.pas).

Build [ScopeProbe.dproj](ScopeProbe.dproj) in Delphi 13, where it reports leaks
at shutdown. Or compile [ScopeProbe.dpr](ScopeProbe.dpr) with FPC's `-MDelphi`
option, putting the framework source and the parent test directory on the unit
search path. Optionally add `-gh` for heap tracing. Results go to standard
output. Success exits zero and an assertion failure exits one.

## Read-write locks

[ReadWriteLockProbe.dproj](ReadWriteLockProbe.dproj) is a console program
whose [source](ReadWriteLockProbe.dpr) checks seven `TReadWriteLock` contract
groups on real threads: concurrent readers, writer exclusion, recursion
policies, upgrade and downgrade, queued promotion, timeouts with disposal, and
wrong-thread release with invalid timeouts. Build and run it in Delphi for
Win32 or Win64, passing one log-file path. The log gets a PASS line per group,
or a FAIL line, and leaks are reported at shutdown. Success exits zero, a
failure exits one and a wrong argument count exits 64. Build output goes to
`tests/lib/native-read-write/<Platform>/<Config>/bin`.

## Bulk-fetch caching

Build [BulkCacheProbe.dproj](BulkCacheProbe.dproj) with Delphi, or compile its
[shared source](BulkCacheProbe.dpr) with Lazarus/FPC. It runs the bulk-cache
contract checks and public API recipes. The optional first argument sets the
log, which ends with `EXIT_CODE=0` on success.

## Five-second throttle

[NativeThrottleProbe.dproj](NativeThrottleProbe.dproj) is a console program
that checks `TThrottledEvent` and its VCL timer. Its
[source](NativeThrottleProbe.dpr) runs ten scenarios concurrently in about 24
seconds, covering input bursts, throttle modes, cancellation and callback
exceptions.

Build it in Delphi as Win64 Debug and run it through the
[broker](#private-desktop-broker) with one trace-file argument. The probe writes
`result.json` beside the trace and exits nonzero on failure.

## Data-row Variant compatibility

[DataRowVariantProbe.dproj](DataRowVariantProbe.dproj) and its
[source](DataRowVariantProbe.dpr) check positional, named and key access to data
rows, copied rows and VCL grid cells. They also check Unicode text in bindings
and wizard messages.

Build the probe in Delphi as Win64 Debug and run it through the
[broker](#private-desktop-broker). It accepts zero or one log-file argument.
Without one, it logs to `%TEMP%\<ProbeName>-<PID>.log`. The plain-text log
reports PASS and FAIL. Success exits 0, a caught assertion or runtime failure
exits 1, and more than one argument exits 64. Build output goes to
`tests/lib/Delphi/<Platform>/data-row-variant/<Config>`.

## Per-grid request admission

[GridThrottleProbe.dproj](GridThrottleProbe.dproj) checks refresh admission on
VCL grids, each with its own five-second throttle. Its
[source](GridThrottleProbe.dpr) runs eight groups:

- refresh suspension through [`RefreshSuspended`](../../src/Sphere10/UVisualGrid.pas)
- parentless and hidden grids
- mixed inputs on independent timers
- requests during a running fetch
- held fetches and completion-handler requests
- cancel, mode change and disposal
- completion without timer dispatch
- [cancellation before execution](#cancellation-before-execution)

The [main README](../../README.md#refresh-suspension) describes the
suspension API.

Build it in Delphi as Win64 Debug and run it through the
[broker](#private-desktop-broker). Arguments, logs and exit codes match the
[data-row probe](#data-row-variant-compatibility). Build output goes to
`tests/lib/Delphi/<Platform>/grid-throttle/<Config>`.

To run one check alone, set its selector to `1` in the probe's process
environment. Leave all selectors unset for a full run.

- `PASCAL_GRID_SUSPENSION_ONLY` runs the suspension group.
- `PASCAL_GRID_COMPLETION_ONLY` runs completion without timer dispatch.
- `PASCAL_GRID_LOADING_ONLY` runs four loading-card checks for requests that
  wait for admission. The full run skips them.
- `PASCAL_GRID_EARLY_CANCEL_ONLY` runs
  [cancellation before execution](#cancellation-before-execution).

## Cancellation before execution

The shared [worker checks](../UVisualGrid.Worker.Checks.pas) cancel a worker
before it starts. They require zero reads from the canceled request and exactly
one latest query and completion.

`GridThrottleProbe.dproj` defines `VISUALGRID_TEST_WORKER_START`, which enables
the test-only hook this case needs. Keep units compiled with it separate from
normal builds.

Build [GridThrottleProbe.dproj](GridThrottleProbe.dproj), then run only this case
from the repository root:

```powershell
$env:PASCAL_GRID_EARLY_CANCEL_ONLY = '1'
.\tests\lib\Delphi\Win64\grid-throttle\Debug\GridThrottleProbe.exe <new-folder>\GridEarlyCancel.log
```

Unset that selector for a full run.

## Custom loading cards

[GridLoadingProbe.dproj](GridLoadingProbe.dproj) is a VCL application that
checks custom loading cards, including artwork, input gating, fetch and error
precedence, and focus in modeless windows.

Build and run it in Delphi as Win64 Debug. The optional first argument sets the
log path, which defaults to `%TEMP%\GridLoadingProbe-<PID>.log`. Bitmap captures
go beside the log. Build output goes to
`tests/lib/Delphi/<Platform>/grid-loading/<Config>`. The probe exits on its own
with 0 for success, 1 for an assertion failure, 2 for an initialization failure
and 64 for extra arguments.

FPCUnit covers the same API in
[UVisualGrid.Refresh.Tests](../UVisualGrid.Refresh.Tests.pas).

## Grid paging and complete-row sizes

[GridViewportProbe.dproj](GridViewportProbe.dproj) checks that a grid page holds
only fully visible rows, with a minimum of one row. The checks cover row
heights, DPI scaling, scrollbars and resizing. The probe also runs the paging
regressions from [UVisualGrid.Paging.Checks](../UVisualGrid.Paging.Checks.pas)
and [UVisualGrid.Viewport.Checks](../UVisualGrid.Viewport.Checks.pas), plus the
five `UVisualGrid.Loading.Checks` cases. A footer matrix covers 45 width, DPI
and mode combinations.

Build it with Delphi and run it through the [broker](#private-desktop-broker),
or run [RunGridViewportNativeTests.ps1](../RunGridViewportNativeTests.ps1) with
`-FpcPath` and `-LazarusDirectory`. Delphi build output goes to
`tests/lib/Delphi/<Platform>/grid-viewport/<Config>`. The probe takes the log
path as its first argument and exits 1 without it. It exits nonzero on failure,
including a log it cannot write.

## Selection event delivery

[UVisualGrid.Selection.Checks](../UVisualGrid.Selection.Checks.pas) checks
selection events for native row clicks, repeated clicks, a clear inside a
selection callback and programmatic changes. Set `PASCAL_GRID_SELECTION_ONLY=1`
when running `GridViewportProbe` to run only these checks. The FPCUnit
equivalent is `TVisualGridSelectionEventTests` in `UVisualGrid.Refresh.Tests`.

Mouse cases never move the user's cursor and skip on non-Windows widgetsets.

## Active fetch cancellation

Set `PASCAL_GRID_ACTIVE_CANCEL_ONLY=1` when running `GridViewportProbe` to run
three shared `UVisualGrid.Worker.Checks` cases for `CancelActiveFetch`. FPCUnit
runs them in `TVisualGridQueuedCompletionTests`.

With `VISUALGRID_TEST_WORKER_START` defined, the probe also cancels a fetch
before its worker starts.

`VISUALGRID_ACTIVE_CANCEL_BASELINE` skips the `CancelActiveFetch` calls, so the
checks compile against older source without that method. Normal builds omit it.

## Unified demo paging captures

[FrameworkDemoPagingCapture.dpr](FrameworkDemoPagingCapture.dpr) creates the
[unified demo form](../../examples/demo/UFRMDemoMain.pas) with its 10,000-row
source and captures the grid in **Auto**, **Manual 25** and **Single** modes. It
checks full Auto rows without vertical scrolling, 400 Manual pages and all
10,000 rows on Single's scrollable page, within a 30-second overall deadline.

Compile it as a Windows GUI application with each compiler, keeping their
outputs separate. Use the root demo's search paths and resources, `src/Sphere10`
and `examples/demo`.

- For FPC, add the matching Lazarus LCL, LazUtils, IDEIntf and RTTIControls
  package paths and the bundled Generics.Collections paths.
- For Delphi, use the VCL resources and namespace settings of the root
  `Sphere10PascalFramework.dproj`.

Run each executable through the [broker](#private-desktop-broker) with one
absolute log path in a new folder, for example:

```powershell
& $Broker $DelphiCaptureExe '<new-folder>\delphi.log'
& $Broker $FpcCaptureExe '<new-folder>\fpc.log'
```

Each run saves `unified-grid-{auto,manual,single}-{delphi,fpc}.png` in
`<log-stem>-captures` beside its log and refuses a capture directory that
already exists. Success exits zero, and an assertion or initialization failure
exits one. Inspect the PNGs and the log before publishing them.

## Recorded results

GridThrottleProbe's suspension group passed range- and overflow-checked Delphi
Win64 builds on 30 October 2026.
