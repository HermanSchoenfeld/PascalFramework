# Framework tests

The GUI and console runners use FPCUnit and register the same fixtures:

- `UCommon.Tests`, `UCommon.Collections.Tests` and `UMemory.Tests`: existing
  common utilities, collections and disposable-scope tests.
- `UCache.Tests`: expiration, invalidation, staleness, null handling, every reap
  policy, capacity accounting, pinning, callback order and failures, reentrant
  removal, value ownership and callback adapters.
- `UWizard.Tests`: initialized models, validation order, dynamic branches,
  Previous navigation, finish/cancel veto and retry, terminal state, reentry,
  host close handling and screen ownership. `UWizard.TestScreens` supplies a
  separate-unit reference-model specialization to catch FPC generic type
  compatibility regressions.
- `UWizardDemo.Tests`: actual designer-backed showcase screens, native command
  buttons, Name/Age validation, optional branches, every route action and
  retryable lifecycle outcomes.

## Console runner on Windows

Use a Free Pascal installation with matching, compiled Lazarus LCL and LazUtils
units. The script selects the Win32 widgetset, including for a Win64 target.
For example, from the repository root:

```powershell
.\tests\RunTests.ps1 `
  -FpcPath 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory 'D:\Pascal\lazarus'
```

Replace both paths with your installation. The script compiles
`FrameworkTestsConsole.lpr`, runs all tests and returns a nonzero exit code on
build or test failure. It leaves generated output and `build.log` in
`tests/lib/console-<cpu>-<os>`.

To select a fixture, add:

```powershell
-TestArguments @('--suite=TCacheTests', '--format=plain')
```

Use `TWizardTests` for wizard tests or `--list` to inspect registered fixtures.
Wizard tests initialize LCL and create real forms, but replace the modal-display
hook with synchronous test actions. They require no clicks or dialog responses.

## Lazarus GUI runner

Open `FrameworkTests.lpi` in Lazarus and build/run the project. The test tree
includes the cache and wizard fixtures. Use the same compiler and widgetset as
your built Lazarus packages. FPCUnit's GUI runner package is also required.

## Scope of verification

### Real modal window integration

The separate Windows integration check runs the real `ShowModal` loop and drives
the native wizard buttons. From the repository root:

```powershell
.\tests\RunWizardNativeTests.ps1 `
  -FpcPath 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory 'D:\Pascal\lazarus'
```

The broker starts the probe on a new private Windows desktop and never switches
the interactive desktop. It applies a watchdog to its own child process;
failure to create that desktop is an error, with no fallback to the user's
desktop. No mouse or keyboard input is sent to the user's applications.

The probe checks the real host window handle and X/Y origin through Next, Back,
route changes and retryable outcomes, including after deliberately moving its
own private host. The current screen must fill the panel's usable display area;
inactive screens must be hidden, with no additional visible top-level screen
windows. It also checks accepted completion and close-query cancellation.
Build and transition logs are retained under ignored `tests/lib/native-*`.

The real modal check passed on the final implementation, including retaining a
deliberately moved host origin through subsequent transitions. Running the same
check against the former detach behavior failed at Name → Age because the
outgoing Name screen remained visible. Screens are now hidden before detachment;
embedded child handles use designed placement and receive their final alignment
before they are shown.

### Unit and resource checks

The cache tests use controlled timestamps for expiration and real callback
failures for admission/removal paths. The wizard tests use resource-free test
screens; build the [wizard example](../examples/wizard/README.md) as well to
verify compatibility with the existing designer resources and caller APIs.
Free Pascal's compiler warnings in the bundled generic collections and common
units are separate from test errors and failures.

Verification on 27 October 2026 used Free Pascal 3.2.0, Lazarus 2.1.0 and the
Win64/Win32 widgetset: all 115 tests passed (51 cache, 21 wizard, 10 demo and 33 existing).
The GUI test runner, extended wizard example, library package and cache example
also compiled. The isolated cache run enabled range/overflow checks and heap
tracing, with no leaked blocks. The 10 actual-demo scenarios also ran with heap
tracing, with zero unfreed blocks.

Before the showcase was added, three fresh-process runs of the original name
wizard exercised first-screen
startup and cancellation. Median changes at the visible-wizard checkpoint
were +40 KiB private bytes, +88 KiB working set and +512 bytes FPC heap used;
reserved FPC heap was unchanged. The baseline needed only removal of an unused
generic forward declaration to avoid an FPC 3.2.0 internal compiler error.
An original-cache memory baseline is unavailable because that unit did not
compile. Temporary measurement sources and detailed logs remain under the
ignored `tests/lib` validation directory.

The expanded launcher's resource construction was also measured in three fresh
processes per revision, without showing windows: `Application.Initialize` then
`TFRMMain.Create(nil)`. Median changes were +24 KiB private bytes, +84 KiB
working set and +15.25 KiB FPC heap used; reserved heap stayed unchanged. These
figures compare the same construction checkpoint, separately from the original
visible-wizard measurements above.
