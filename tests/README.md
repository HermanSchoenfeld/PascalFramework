# Framework tests

The framework's FPCUnit fixtures run in a Lazarus GUI runner and a console
runner. Delphi has separate [native probes](native/README.md).

## Console runner on Windows

You need Free Pascal with matching compiled Lazarus LCL and LazUtils units.
From the repository root, run:

```powershell
.\tests\RunTests.ps1 `
  -FpcPath '<fpc>\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory '<lazarus>'
```

Use your own tool paths. The script clean-builds
[FrameworkTestsConsole.lpr](FrameworkTestsConsole.lpr) for your compiler's Win32
or Win64 target, with the Win32 widgetset, and runs every registered case. It
exits nonzero if the build or a test fails. The tests create real forms but need
no clicks or dialog responses. Build output and the compiler log go to the
ignored `tests/lib/console-<cpu>-<os>` folder, or elsewhere with
`-OutputDirectory <folder>`. The
[wizard and loading scripts](#native-wizard-and-loading-checks) accept the same
option.

To run one fixture, append:

```powershell
-TestArguments @('--suite=TCacheTests', '--format=plain')
```

Replace `TCacheTests` with another fixture, such as `TWizardTests`,
`TReadWriteLockTests` or `TVisualGridPagingTests`. Pass `--list` to print every
fixture name.

## Lazarus GUI runner

Open [FrameworkTests.lpi](FrameworkTests.lpi) and run it with the compiler and
widgetset that match your compiled Lazarus packages. It needs the LCL, FCL and
`fpcunittestrunner` packages.

## Concurrency runner

[ConcurrencyTests.lpr](ConcurrencyTests.lpr) runs the read-write lock cases
without a GUI or Lazarus units. From the repository root on Linux or macOS, run:

```sh
mkdir -p tests/lib/concurrency/units
fpc -B -Mdelphi -Sh -gl -Cr -Co \
  -FUtests/lib/concurrency/units -FEtests/lib/concurrency \
  -Fusrc/Sphere10 -Fusrc/Generics.Collections -Fisrc/Generics.Collections/inc \
  -Futests tests/ConcurrencyTests.lpr
tests/lib/concurrency/ConcurrencyTests tests/lib/concurrency/tests.log
```

On Windows, build with the same compiler arguments and run
`ConcurrencyTests.exe`. The runner writes `tests.log`, plus a heap report in
`tests.log.heap.log`, and exits nonzero on failure.

## Coverage

| Area | FPCUnit | Delphi |
| --- | --- | --- |
| Scopes and disposal bags | [UScope.Tests](UScope.Tests.pas), [UReadWriteScope.Tests](UReadWriteScope.Tests.pas), [UMemory.Tests](UMemory.Tests.pas) | [ScopeProbe.dproj](native/ScopeProbe.dproj) |
| Read-write locks | [UConcurrency.Tests](UConcurrency.Tests.pas) | [ReadWriteLockProbe.dproj](native/ReadWriteLockProbe.dproj) |
| Buffered streams | [UStreams.Tests](UStreams.Tests.pas) | [BufferedStreamProbe.dproj](native/BufferedStreamProbe.dproj) |
| Caching | [UCache.Tests](UCache.Tests.pas) | [BulkCacheProbe.dproj](native/BulkCacheProbe.dproj) |
| Wizards | [UWizard.Tests](UWizard.Tests.pas), [UWizardDemo.Tests](UWizardDemo.Tests.pas), [UWizard.TestScreens](UWizard.TestScreens.pas) | [DataRowVariantProbe.dproj](native/DataRowVariantProbe.dproj) |
| Throttling | [UCommon.UI.Tests](UCommon.UI.Tests.pas) | [NativeThrottleProbe.dproj](native/NativeThrottleProbe.dproj) |
| Grid refresh and loading | [UVisualGrid.Refresh.Tests](UVisualGrid.Refresh.Tests.pas) | [GridThrottleProbe.dproj](native/GridThrottleProbe.dproj), [GridLoadingProbe.dproj](native/GridLoadingProbe.dproj) |
| Grid paging and viewport | [TVisualGridPagingTests](UVisualGrid.Refresh.Tests.pas) | [GridViewportProbe.dproj](native/GridViewportProbe.dproj) |
| Grid selection | [UVisualGrid.Tests](UVisualGrid.Tests.pas) | [GridViewportProbe.dproj](native/GridViewportProbe.dproj) |
| Data and UI integration | [UCommon.Data.Tests](UCommon.Data.Tests.pas), [UFramework.UI.Integration.Tests](UFramework.UI.Integration.Tests.pas) | [DataRowVariantProbe.dproj](native/DataRowVariantProbe.dproj) |
| Utilities and collections | [UCommon.Tests](UCommon.Tests.pas), [UCommon.Collections.Tests](UCommon.Collections.Tests.pas) | |

FPCUnit and the native probes share checks, including
[UStreams.Checks](UStreams.Checks.pas),
[UBulkCacheChecks](UBulkCacheChecks.pas),
[UVisualGrid.Paging.Checks](UVisualGrid.Paging.Checks.pas),
[UVisualGrid.Viewport.Checks](UVisualGrid.Viewport.Checks.pas),
[UVisualGrid.Worker.Checks](UVisualGrid.Worker.Checks.pas) and
[UVisualGrid.Loading.Checks](UVisualGrid.Loading.Checks.pas).

Data sources that override `FetchPage` need their own record-read, count and
page-bound checks. Wallet and node scenarios belong in the consuming
application.

The Windows case
`TVisualGridQueuedCompletionTests.WorkerCancelledBeforeExecutionRetiresAndPreservesOtherReceivers`
needs the `VISUALGRID_TEST_WORKER_START` define, which `FrameworkTests.lpi` and
`RunTests.ps1` set. Other FPCUnit drivers must pass
`-dVISUALGRID_TEST_WORKER_START` globally and keep their compiled units apart
from application and package outputs. In Delphi,
[GridThrottleProbe](native/README.md#cancellation-before-execution) runs only
this check when `PASCAL_GRID_EARLY_CANCEL_ONLY=1` is set.

## Native wizard and loading checks

On Windows, these scripts compile a probe and run it on a private desktop,
leaving yours untouched:

```powershell
.\tests\RunWizardNativeTests.ps1 `
  -FpcPath '<fpc>\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory '<lazarus>'

.\tests\RunGridLoadingNativeTests.ps1 `
  -FpcPath '<fpc>\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory '<lazarus>'
```

The wizard probe checks the native modal host's position through Next, Back,
route changes and retries, plus completion and close-query cancellation. The
loading probe checks the loading card's delay, border and animation, retained
rows, and cleanup on completion. It saves captures beside its log.

Logs go to ignored `tests/lib` folders by default.

## Delphi and demo builds

Build the Delphi probes with Delphi 13, in the IDE for Community Edition. They
need no installed runtime package and leave the IDE toolbox unchanged. The
[native guide](native/README.md) gives their arguments and expected results.

Build the unified demo,
[Sphere10PascalFramework.dproj](../Sphere10PascalFramework.dproj), too. To check
runtime-package compatibility, build the optional
[Sphere10Framework.dproj](../Sphere10Framework.dproj) separately.

[FrameworkDemoPagingCapture.dpr](native/FrameworkDemoPagingCapture.dpr) runs the
unified demo through Auto, Manual 25 and Single, then saves PNGs and a result
log. Build it with Delphi and FPC. The
[native guide](native/README.md#unified-demo-paging-captures) describes the new
output folder it needs.

## Tested compilers and results

| Compiler | Builds | Checks |
| --- | --- | --- |
| Lazarus 2.1, FPC 3.2.0 (Win64, Win32 widgetset) | Library package, unified demo, GUI test runner | FPCUnit suite, native viewport, loading and wizard checks, all demo actions and application close |
| Lazarus 4.8, FPC 3.2.2 (Win64, Win32 widgetset) | Same three targets | FPCUnit suite, API recipes, native viewport, loading and wizard checks, application lifecycle |
| Delphi 13 Community Edition, VCL | Runtime package and unified demo, Win32 and Win64, Debug and Release | Native cache, grid, wizard and timer checks, API recipes, application close |

All 538 console tests passed locally on 6 November 2026 with FPC 3.2.0 and
Lazarus 2.1.

## Continuous integration

The [CI job](../.github/CI.md) uses pinned Lazarus 4.8 with FPC 3.2.2. It builds
the root Lazarus package and the unified demo, then runs
[RunTests.ps1](RunTests.ps1) and
[RunGridViewportNativeTests.ps1](RunGridViewportNativeTests.ps1). The second
builds the FPC viewport probe with `-O2` and checks grid layout at 100%, 150%
and 200% scaling. The
[Actions page](https://github.com/HermanSchoenfeld/PascalFramework/actions/workflows/main.yml)
shows the hosted status. All other checks run locally.
