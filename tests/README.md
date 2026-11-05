# Framework tests

The Lazarus GUI and console runners register the same FPCUnit fixtures. They use
real component ownership, counted data sources, thread/event gates and the native
LCL message loop where the behavior requires one. Delphi/VCL has separate native
probes: Free Pascal's Delphi language mode does not exercise Embarcadero's compiler
or VCL controls.

## Latest verification

The complete local FPC 3.2.0/Lazarus 2.1 console suite passed **538 tests** on
6 November 2026 with zero errors, failures or ignored tests. The final native
paging matrix also passed in Delphi 13 Release and checked/unchecked FPC Release:
large totals, narrow footers, native row capacity and Single/Auto/Manual modes.
The 101 stream checks passed in Delphi Win32/Win64 and Free Pascal. These are
local checks; the CI badge reports the separate hosted build.

## Unit coverage

[UStreams.Tests](UStreams.Tests.pas) registers 101 shared buffered-stream
checks. They cover bounded read-ahead, ownership, forward-only inputs, 64-bit
positions, seeking, write-through, resizing and failure recovery. The same
[check bodies](UStreams.Checks.pas) run in the native Delphi Win32/Win64 probe.
Four thousand deterministic mixed operations are compared with `TMemoryStream`.
Length-cache cases verify all four read-buffering/length-caching combinations,
lazy queries, failures and invalidation after buffered or direct writes/resizing.
Toggle cases cover both default-true flags,
direct delegation, explicit unread-data flushing, rejected-disable atomicity,
forward-only failures and re-enabling after direct reads, writes and resizes.

[ConcurrencyTests.lpr](ConcurrencyTests.lpr) runs the 31 shared lock cases without
a GUI or Lazarus units, including ownership, promotion and release on Darwin's
pointer-shaped thread IDs. From the repository root on Linux or macOS:

```sh
mkdir -p tests/lib/concurrency/units
fpc -B -Mdelphi -Sh -gl -Cr -Co \
  -FUtests/lib/concurrency/units -FEtests/lib/concurrency \
  -Fusrc/Sphere10 -Fusrc/Generics.Collections -Fisrc/Generics.Collections/inc \
  -Futests tests/ConcurrencyTests.lpr
tests/lib/concurrency/ConcurrencyTests tests/lib/concurrency/tests.log
```

The same compiler arguments work on Windows; run `ConcurrencyTests.exe` there.
The runner returns a nonzero code on failure and writes test and heap reports.
Keep `heaptrc` before `cthreads` so heap tracing is installed before POSIX
thread-local storage is relocated.

| Fixture | Coverage |
| --- | --- |
| [UScope.Tests](UScope.Tests.pas) | Deferred cleanup methods, default/empty ownership, routine return/Exit/unwind, returned records, shared copies, overwrite/reset, arrays and fields, callback failures, borrowed targets and object Free callbacks. |
| [UReadWriteScope.Tests](UReadWriteScope.Tests.pas) | Automatic read/write/upgradeable ownership, all exit paths, copies, return/field lifetimes, recursion, promotion under both policies, downgrades, concurrent readers, blocked writers, failed acquisition and wrong-thread release. |
| [UCache.Tests](UCache.Tests.pas) | Unit-level policies, callback adapters and shared events across cache kinds; per-key and bulk-fetch caching, preloaded snapshots, bulk writes, missing keys, fetch-once retention, expiration/invalidation, eviction, pins, failures and value ownership. |
| [UWizard.Tests](UWizard.Tests.pas) | Shared-model initialization, validation order, dynamic routes, Back navigation, finish/cancel vetoes and retry, terminal states, reentry, host closure and screen ownership. |
| [UWizardDemo.Tests](UWizardDemo.Tests.pas) | The actual designer-backed showcase screens, command buttons, Name/Age validation, optional branches, route actions and retryable lifecycle outcomes. |
| [UConcurrency.Tests](UConcurrency.Tests.pas) | Concurrent readers, exclusive writers, recursive ownership, upgradeable-read promotion/downgrade, finite/zero/infinite waits, rejected read promotion, wrong-thread release, writer preference, ownership/waiter counts and safe disposal. |
| [UCommon.UI.Tests](UCommon.UI.Tests.pas) | Physical timer resets, leading/trailing/periodic modes, one-input completion, reentry, exceptions, cancellation, mode changes, stale callbacks, exact quiet deadlines and queued-listener ownership. Three boundary cases use real five-second waits. |
| [UVisualGrid.Refresh.Tests](UVisualGrid.Refresh.Tests.pas) | Refresh admission, paging/filter/sort/source changes, visual resizing, latest-request retention, native row-fit boundaries, automatic page sizes, loading cards, cooperative suspension/cancellation, discarded obsolete results, cancellation before execution and event-driven worker completion without polling. |
| [TVisualGridPagingTests](UVisualGrid.Refresh.Tests.pas) | Shared regressions for Single/Auto/Manual, unbounded growing results, full-result filtering/sorting, empty-result controls, manual-size retention, suspension, stale workers, disabled paging and source assignment before parenting. |
| [UVisualGrid.Tests](UVisualGrid.Tests.pas) | Unique displayed-order rows from disjoint/overlapping selections and selection clearing. |
| [UCommon.Data.Tests](UCommon.Data.Tests.pas) | Raw/query snapshot reuse, page-only conversion, counted filtering/sorting, nonblocking invalidation, retry, empty results, page bounds, named/positional Variant dispatch and Unicode schema names/values. |
| [UFramework.UI.Integration.Tests](UFramework.UI.Integration.Tests.pas) | Duration values, docked forms, main-thread completion, worker lifetime, source replacement, recovery and concurrent schemas. |
| [UCommon.Tests](UCommon.Tests.pas) | General utilities, exact log metadata, sample/population variance, byte-exact UTF-8 appends, hex conversion, results, boxes and signed/unsigned Variants. |
| [UCommon.Collections.Tests](UCommon.Collections.Tests.pas) | Array/list adapters, predicate inversion, exact-count copying, range boundaries, filtered object ownership, empty inputs, failures and cleanup. |
| [UMemory.Tests](UMemory.Tests.pas) | Original disposal bags: automatic exits, object/memory transfers, allocation/reallocation, growth and reverse cleanup, class/record fields and continued cleanup after failures. |

[UWizard.TestScreens](UWizard.TestScreens.pas) keeps a reference-model generic
specialization in a separate unit to catch compiler compatibility regressions.
Common component tests are also mirrored into the consumer's embedded library;
wallet/node-specific scenarios belong to that application.

The paging fixture calls [UVisualGrid.Paging.Checks](UVisualGrid.Paging.Checks.pas)
and [UVisualGrid.Viewport.Checks](UVisualGrid.Viewport.Checks.pas). It drives the
actual mode button/menu and native scrollbars, checks exact complete-row capacity,
and rejects obsolete finite pages after switching to Single. Requests made while
suspended cannot fetch; resuming admits only the latest mode. Legacy ShowAll
checks start without a cached total and then grow the result. The parenting
check assigns a synchronous source before docking and showing the grid. Native
capacity checks wait for the existing deferred layout task as well as data
completion, within the same five-second deadline.
The Windows FPC fixture drains queued native messages after LCL's manual message
pump, including timers left pending after a popup. Application code is unchanged.

`LargeTotalsCompactBeforeWrapping` checks a six-digit total and five-digit page
count at 100%, 125% and 150%. Totals stay beside compact navigation when it fits;
narrower footers wrap without clipping across Single, Auto and Manual modes.

The queued-completion case
`TVisualGridQueuedCompletionTests.WorkerCancelledBeforeExecutionRetiresAndPreservesOtherReceivers`
calls [UVisualGrid.Worker.Checks](UVisualGrid.Worker.Checks.pas). A test-only hook
cancels the actual worker before start; it must retire without reading, publish
one latest page and preserve another grid receiver during disposal. The fixture
restores its hook in `finally` and uses no scheduler or CPU-affinity changes.

`FrameworkTests.lpi` and `RunTests.ps1` enable `VISUALGRID_TEST_WORKER_START`.
Other FPCUnit drivers must pass `-dVISUALGRID_TEST_WORKER_START` globally to
include this Windows case. Keep its compiled units separate from
normal application/package outputs, which omit this test-only define. The
[focused native invocation](native/README.md#cancellation-before-execution) uses
`PASCAL_GRID_EARLY_CANCEL_ONLY=1` with the supplied Delphi test project.

## Console runner on Windows

Use a Free Pascal installation with matching compiled Lazarus LCL and LazUtils
units. The supplied script selects the Win32 widgetset for both Windows target
architectures. From the repository root:

```powershell
.\tests\RunTests.ps1 `
  -FpcPath 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory 'D:\Pascal\lazarus'
```

Replace the tool paths for your installation. The script clean-builds
[FrameworkTestsConsole.lpr](FrameworkTestsConsole.lpr), runs all registered cases,
and returns a nonzero code on build or test failure. Generated output and the
compiler log stay in ignored `tests/lib/console-<cpu>-<os>`.

Use `-OutputDirectory 'D:\Builds\PascalFramework\Tests'` to redirect generated
output and logs without moving the project or source files. The native wizard
and loading scripts below accept the same optional output-directory setting.

For a selected fixture, append:

```powershell
-TestArguments @('--suite=TCacheTests', '--format=plain')
```

Use `TWizardTests` for wizard tests, `TReadWriteLockTests` for locking or `--list`
to inspect the actual fixture names. Use `TVisualGridPagingTests` for the shared
paging regressions. Wizard unit cases create real forms but
replace the modal-display hook with synchronous test actions. They need no manual
clicks or dialog responses. Native modal-window checks below exercise the actual
`ShowModal` loop separately.

## Lazarus GUI runner

Open [FrameworkTests.lpi](FrameworkTests.lpi), then build and run it. Use the
compiler/widgetset matching your compiled Lazarus packages. FPCUnit's GUI runner
package is required in addition to LCL and FCL. The test tree includes all the
fixtures above, including caching, wizards, concurrency and grid refresh.

## Native Delphi/VCL checks

The FPC native viewport probe uses Release optimization (`-O2`), also exercised
by CI. Footer regressions check controls against every native parent panel at
100%, 125% and 150% scaling, including first show while a fetch is still running.
This supplements the unit runner; an outer-footer bounds check alone misses
clipping inside the navigation panel.

Build the projects with Delphi 13. Community Edition uses the official IDE
compiler; the projects need no installed runtime package and do not change the
IDE toolbox. Their native controls exercise Delphi resource loading, event and
Variant dispatch, timer delivery and rendering independently of the FPCUnit
runner. See the [native guide](native/README.md) for arguments and expected results.

| Project | Native behavior |
| --- | --- |
| [ScopeProbe.dproj](native/ScopeProbe.dproj) | The same 63 scope, disposal-bag and read/write-scope checks used by FPCUnit, including cleanup failures and copy/assignment recovery. |
| [BufferedStreamProbe.dproj](native/BufferedStreamProbe.dproj) | The same 101 buffered-stream checks used by FPCUnit, in Delphi Win32 and Win64. |
| [BulkCacheProbe.dproj](native/BulkCacheProbe.dproj) | Shared bulk-fetch cache assertions and public API recipes. |
| [GridViewportProbe.dproj](native/GridViewportProbe.dproj) | Native cell bounds at pixel/DPI/header/scrollbar/resize boundaries, plus the same paging and preparenting regressions as FPCUnit. |
| [ReadWriteLockProbe.dproj](native/ReadWriteLockProbe.dproj) | Real concurrent read/write/upgradeable ownership, recursion and timeout/cleanup behavior. |
| [NativeThrottleProbe.dproj](native/NativeThrottleProbe.dproj) | Real five-second VCL timer scenarios, including physical callback resets, independent bursts, cancellation and exception recovery. |
| [GridThrottleProbe.dproj](native/GridThrottleProbe.dproj) | Actual grid/provider admission, hidden/parentless controls, retained requests, selection bounds, queued completion and cooperative refresh suspension. |
| [GridLoadingProbe.dproj](native/GridLoadingProbe.dproj) | Copied custom artwork, title/subtitle, input gating, fetch/error precedence, deferred loading and modeless focus/activation preservation. |
| [DataRowVariantProbe.dproj](native/DataRowVariantProbe.dproj) | Positional/named row dispatch, copied values, actual grid cells and Unicode schema/wizard messages. |

Build the root [Sphere10PascalFramework.dproj](../Sphere10PascalFramework.dproj) as well: it combines
the real cache, grid and wizard examples in one executable. A native probe or
source build does not establish runtime-package compatibility; build the optional
[Sphere10Framework.dproj](../Sphere10Framework.dproj) separately.

[FrameworkDemoPagingCapture.dpr](native/FrameworkDemoPagingCapture.dpr) runs that
same unified demo through Auto, Manual 25 and Single with 10,000 generated rows,
then saves native PNGs and a result log. Build it separately with Delphi and FPC;
the [native guide](native/README.md#unified-demo-paging-captures) describes its
fresh output path and assertions.

## Real modal wizard and loading checks

On Windows, the scripted checks compile a probe and run it on an owned private
desktop without switching the interactive desktop:

```powershell
.\tests\RunWizardNativeTests.ps1 `
  -FpcPath 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory 'D:\Pascal\lazarus'

.\tests\RunGridLoadingNativeTests.ps1 `
  -FpcPath 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory 'D:\Pascal\lazarus'
```

The wizard probe checks a single stable native host and top-left position during
Next, Back, route changes and retries, including after moving its own host. Active
screens fill the host; inactive screens stay hidden; no outgoing page becomes an
extra top-level window. Completion and close-query cancellation are also checked.

The loading probe checks the bordered card, copied custom graphic, animated
circle, retained rows and completion/input cleanup. Its result and captures are
written alongside its output. Both scripts apply a watchdog only to their owned
child process; private-desktop creation failure does not fall back to the user's
desktop. Build/runtime logs remain in ignored `tests/lib` folders.

## Build and verification scope

Verified with the actual compilers and native controls:

| Compiler/runtime | Build targets | Executed checks |
| --- | --- | --- |
| Lazarus 2.1 / Free Pascal 3.2.0, Win64 / Win32 widgetset | Library package, unified demo and GUI test runner | FPCUnit suite and focused follow-up regressions; native viewport, loading and modal wizard checks; all demo actions and natural close. |
| Lazarus 4.8 / Free Pascal 3.2.2, Win64 / Win32 widgetset | The same three targets | The same suite and shared recipes, native viewport/loading/wizard checks and application lifecycle checks. |
| Delphi 13 Community Edition, VCL | Runtime package and unified demo, Win32/Win64 Debug/Release | Actual IDE compilation; native cache, grid, wizard and timer checks, complete API recipes and natural application close. |

The bulk cache probe runs the same assertions as the FPCUnit fixture through
[UBulkCacheChecks](UBulkCacheChecks.pas). Grid viewport checks likewise share
[UVisualGrid.Viewport.Checks](UVisualGrid.Viewport.Checks.pas) across FPCUnit and
both native toolkits. Compiler-specific APIs are guarded in the shared recipes;
FPC-only checks do not establish VCL compatibility.

The source projects support Delphi 13 VCL and Lazarus/FPC LCL. Keep `.dfm` and
`.lfm` companions together and verify the actual compiler for each UI runtime.
Build the optional package, combined demo and separate GUI test runner. The
five-second throttle walkthrough is a tab in the combined demo. The [CI job](../.github/CI.md) builds the root Lazarus package
and combined demo and runs the public console-test command with pinned Lazarus
4.8/FPC 3.2.2. Its hosted status is shown on the
[Actions page](https://github.com/HermanSchoenfeld/PascalFramework/actions/workflows/main.yml).
Local commands do not verify the hosted installer step or another architecture.

Generic snapshot caching still loads its initial full dataset. Source-native
paging overrides need their own record-read/count/page-bound checks. Likewise,
passing component timers or an empty demo does not establish a consumer's
large-dataset or networking performance.

`TVisualGridLoadingLifecycleTests.SynchronousFailureRetainsRowsAndCanRetry`
also covers synchronous providers which fail before or after replacing output.
The grid keeps its accepted page, stops loading, exposes the provider error
and preserves the original exception for its caller; a successful retry clears
that error. The same assertions run through `UVisualGrid.Loading.Checks` in
native Delphi and FPC checks.
