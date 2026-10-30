# Framework tests

The Lazarus GUI and console runners register the same FPCUnit fixtures. They use
real component ownership, counted data sources, thread/event gates and the native
LCL message loop where the behavior requires one. Delphi/VCL has separate native
probes: Free Pascal's Delphi language mode does not exercise Embarcadero's compiler
or VCL controls.

## Unit coverage

| Fixture | Coverage |
| --- | --- |
| [UCache.Tests](UCache.Tests.pas) | Per-key and whole-source fetching, preloaded snapshots, bulk writes, missing keys, fetch-once retention, expiration/invalidation, eviction, pins, callbacks, failures and value ownership. |
| [UWizard.Tests](UWizard.Tests.pas) | Shared-model initialization, validation order, dynamic routes, Back navigation, finish/cancel vetoes and retry, terminal states, reentry, host closure and screen ownership. |
| [UWizardDemo.Tests](UWizardDemo.Tests.pas) | The actual designer-backed showcase screens, command buttons, Name/Age validation, optional branches, route actions and retryable lifecycle outcomes. |
| [UConcurrency.Tests](UConcurrency.Tests.pas) | Concurrent readers, exclusive writers, recursive ownership, upgradeable-read promotion/downgrade, finite/zero/infinite waits, rejected read promotion, wrong-thread release, writer preference, ownership/waiter counts and safe disposal. |
| [UCommon.UI.Tests](UCommon.UI.Tests.pas) | Physical timer resets, leading/trailing/periodic modes, one-input completion, reentry, exceptions, cancellation, mode changes, stale callbacks, exact quiet deadlines and queued-listener ownership. Three boundary cases use real five-second waits. |
| [UVisualGrid.Refresh.Tests](UVisualGrid.Refresh.Tests.pas) | Refresh admission, paging/filter/sort/source changes, visual resizing, latest-request retention, native row-fit boundaries, automatic page sizes, loading cards, cooperative suspension/cancellation, discarded obsolete results and event-driven worker completion without polling. |
| [UVisualGrid.Tests](UVisualGrid.Tests.pas) | Unique displayed-order rows from disjoint/overlapping selections and selection clearing. |
| [UCommon.Data.Tests](UCommon.Data.Tests.pas) | Raw/query snapshot reuse, page-only conversion, counted filtering/sorting, nonblocking invalidation, retry, empty results, page bounds, named/positional Variant dispatch and Unicode schema names/values. |
| [UFramework.UI.Integration.Tests](UFramework.UI.Integration.Tests.pas) | Duration values, docked forms, main-thread completion, worker lifetime, source replacement, recovery and concurrent schemas. |
| [UCommon.Tests](UCommon.Tests.pas) | General utilities, exact log metadata, sample/population variance, byte-exact UTF-8 appends, signed/unsigned Variants and queued-listener disposal. |
| [UCommon.Collections.Tests](UCommon.Collections.Tests.pas) | Array/list adapters, predicate inversion, exact-count copying, range boundaries, filtered object ownership, empty inputs, failures and cleanup. |
| [UMemory.Tests](UMemory.Tests.pas) | Scoped object/memory ownership, allocation and disposal behavior. |

[UWizard.TestScreens](UWizard.TestScreens.pas) keeps a reference-model generic
specialization in a separate unit to catch compiler compatibility regressions.
Common component tests are also mirrored into the consumer's embedded library;
wallet/node-specific scenarios belong to that application.

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
to inspect the actual fixture names. Wizard unit cases create real forms but
replace the modal-display hook with synchronous test actions. They need no manual
clicks or dialog responses. Native modal-window checks below exercise the actual
`ShowModal` loop separately.

## Lazarus GUI runner

Open [FrameworkTests.lpi](FrameworkTests.lpi), then build and run it. Use the
compiler/widgetset matching your compiled Lazarus packages. FPCUnit's GUI runner
package is required in addition to LCL and FCL. The test tree includes all the
fixtures above, including caching, wizards, concurrency and grid refresh.

## Native Delphi/VCL checks

Build the projects with Delphi 13. Community Edition uses the official IDE
compiler; the projects need no installed runtime package and do not change the
IDE toolbox. Their native controls exercise Delphi resource loading, event and
Variant dispatch, timer delivery and rendering independently of the FPCUnit
runner. See the [native guide](native/README.md) for arguments and expected results.

| Project | Native behavior |
| --- | --- |
| [BulkCacheProbe.dproj](native/BulkCacheProbe.dproj) | Shared whole-source cache assertions and public API recipes. |
| [GridViewportProbe.dproj](native/GridViewportProbe.dproj) | Actual cell bounds at pixel/DPI/header/scrollbar/resize boundaries. |
| [ReadWriteLockProbe.dproj](native/ReadWriteLockProbe.dproj) | Real concurrent read/write/upgradeable ownership, recursion and timeout/cleanup behavior. |
| [NativeThrottleProbe.dproj](native/NativeThrottleProbe.dproj) | Real five-second VCL timer scenarios, including physical callback resets, independent bursts, cancellation and exception recovery. |
| [GridThrottleProbe.dproj](native/GridThrottleProbe.dproj) | Actual grid/provider admission, hidden/parentless controls, retained requests, selection bounds, queued completion and cooperative refresh suspension. |
| [GridLoadingProbe.dproj](native/GridLoadingProbe.dproj) | Copied custom artwork, title/subtitle, input gating, fetch/error precedence, deferred loading and modeless focus/activation preservation. |
| [DataRowVariantProbe.dproj](native/DataRowVariantProbe.dproj) | Positional/named row dispatch, copied values, actual grid cells and Unicode schema/wizard messages. |

Build the root [Sphere10PascalFramework.dproj](../Sphere10PascalFramework.dproj) as well: it combines
the real cache, grid and wizard examples in one executable. A native probe or
source build does not establish runtime-package compatibility; build the optional
[Sphere10Framework.dproj](../Sphere10Framework.dproj) separately.

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
