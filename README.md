# Pascal Framework

Sphere10's Pascal libraries for Lazarus/Free Pascal, written in Delphi mode.
The framework provides reusable utilities for collections, caching, memory
management, data binding and desktop UI composition. It favors composable
callbacks and explicit resource ownership.
The cache and wizard APIs follow the corresponding Sphere10 C# Framework
behavior while keeping Pascal classes, events, callbacks and explicit ownership.

## Open in Lazarus

Open **`Sphere10Framework.lpg`** from the repository root using Lazarus's
Project > Open Project Group command. It groups the wizard and cache demonstrations,
library package and GUI test project in one place. Project Groups is included
in the installed Lazarus configuration; other installations may need the
`LazProjectGroups` package enabled.

Individual entry points also work without Project Groups:

| Open this file | Purpose |
| --- | --- |
| `examples/wizard/FrameworkTester.lpi` | Run and edit the wizard demonstration |
| `tests/FrameworkTests.lpi` | Run all FPCUnit tests in the GUI |
| `examples/cache/CacheExample.lpi` | Run the console cache usage walkthrough |
| `packages/Sphere10Framework.lpk` | Browse/build the reusable library and control package |

Use Project > Open Project for `.lpi` files and Package > Open Package File for
the `.lpk`. Library units are `.pas` files and do not launch on their own.

## Other library units

The foundation and UI utilities documented in the existing project overview
remain available alongside caching and wizards:

| Unit | Main facilities |
| --- | --- |
| `UCommon` | Time spans, array utilities, result values, variants and multicast/thread notification helpers |
| `UCommon.Collections` | Comparer, predicate and transformer composition; list filtering and collection helpers |
| `UMemory` | `TDisposables` scopes and explicit object/pointer disposal policies |
| `UCommon.Data` | Variant-based data rows, columns, filtering and sorting specifications |
| `UCommon.UI` | Application form lifecycle helpers and throttled events |
| `UVisualGrid` | Reusable data grid controls, column rendering, filtering, sorting and paging |

Standard `Generics.Collections` containers require caller synchronization when
shared between threads. `TDisposables` scopes should remain local to the owning
thread. UI forms and wizard navigation belong on the LCL UI thread.

## Caching

`src/Sphere10/UCache.pas` provides `TCacheBase<TKey, TValue>` and the
callback-based `TActionCache<TKey, TValue>`. Fetch and estimate callbacks can be
global functions, object methods or nested functions through `TValueFetcher`
and `TSizeEstimator`. An estimator receives the **value**, rather than the key;
an omitted estimator assigns zero size to each entry.

Use `Get(key)` for cached-item metadata or the default `Values[key]` indexer
for values. Assign through the indexer or `SetValue`; `BulkLoad` uses the same
admission and replacement rules. Expiration supports time since fetch or last
access. `Invalidate` forces the next read to fetch again. Subclasses can override
`CheckStaleness` and enable `svpCheckStaleOnDemand`.

Capacity reaping favors expired entries before applying the selected size,
usage, age or idle policy. Set a cached item's `CanPurge` to false to pin it
against reaping; explicit `Remove` and `Purge` still remove pinned entries.
`Flush` is an alias for `Purge`. Null policies apply to nil references and
pointers; empty strings and numeric zero remain ordinary values.

Typed Delphi events expose fetching, fetched, removing and removed phases.
`ItemRemoving` runs before membership or capacity changes, so a raised exception
leaves the entry available for retry. `ItemRemoved` runs after removal commits.
Callbacks can reenter the cache; a pending removal cannot be replaced or counted
as released capacity.

Cache operations use a recursive critical section. Returned `TCachedItem`
objects and the entries in a `CachedItems` membership snapshot are borrowed;
callers must not free them. The most recent `Get` result is retained until the
next `Get` or cache destruction, including when it has been removed. Callers
must coordinate longer access to borrowed entries with concurrent mutations.
The configured `TItemDisposePolicy` (an alias for `UMemory.TDisposePolicy`)
controls owned object/pointer cleanup; managed Pascal values retain their normal
compiler-managed lifetime. Removal disposes an owned payload after
`ItemRemoved`, even while the last borrowed metadata handle is retained.
Rejected fetched values are disposed according to the policy; a rejected
explicit `SetValue` leaves ownership with its caller. Cache destruction releases
values without invoking application callbacks. Callbacks must not destroy their
cache, and nested callbacks must not outlive their enclosing stack frame.

The [cache usage guide](examples/cache/README.md) includes a complete program,
expiration configuration, notification handlers, capacity/pinning and object
ownership examples. Its runnable `CacheExample.lpi` is part of the project group.
For an already configured cache, ordinary usage is:

```pascal
value := cache[7];                 // Fetch once, then return cached values.
cache.Invalidate(7);               // The next read fetches again.
cache[8] := 'supplied value';       // Admission without fetching.
cache.Get(8).CanPurge := false;     // Pin against automatic reaping.
cache.Remove(8);                   // Explicit removal still works.
```

## Wizards

`src/Sphere10/UWizard.pas` retains `TWizard<T>`, `TWizardForm<T>`, modal
`Start(model)` and `TActionWizard<T>.Show`. Screens receive their model before
`Initialize`, which runs once per screen type. The wizard owns its screen and
host forms, including screens removed from a branch. The model remains owned
by the caller.

`TryNext`, `TryPrevious`, `Finish` and `Cancel` return a Boolean and an output
message for rejected operations. `Next` and `Previous` retain the interactive
error display. Validation runs before `OnNext`; model changes can be committed
there after validation succeeds. Failed or vetoed terminal callbacks leave the
wizard active and retryable. `State`, `IsBusy` and `IsCancellable` describe the
current workflow; accepted terminal callbacks are not repeated.

Screens can keep using `UpdatePath` during `OnNext`. Set
`Traits := [wstAssumeHasNext]` for a screen that creates its successor during
navigation: the host shows Next, and a missing successor leaves the current
screen active. Identical contiguous injections are idempotent. Previous
navigation restores the saved branch for a new choice. `ptRemoveNext` removes
selected future screen types, and `RemoveScreen` removes a screen from the path
while retaining its disposal owner. `Screens` returns a copy of path membership.

These are synchronous Pascal/LCL APIs. The C# task-based adapters, fluent
builders, pooled cache reapers and projection libraries are separate facilities.

## Wizard feature showcase

Run `examples/wizard/FrameworkTester.lpi` and choose **Wizard feature showcase**.
The Name → Age → optional notes → confirmation → Summary flow demonstrates
dynamic successors, every path-editing operation, validation before committing
name and age, a no-back boundary and retryable finish/cancel callbacks. Live state,
event and lifetime counters make the behavior visible. The original examples
remain available in the launcher.

![Sphere10 wizard demonstration launcher](resources/wizard/wizard-launcher.png)

The Age screen provides route editing and shows the resulting event history:

![Wizard route editing and state history](resources/wizard/wizard-routes.png)

See the [illustrated wizard walkthrough](examples/wizard/README.md) for the other
screens and a repeatable checklist of success, rejection and retry cases.

## Tests

The FPCUnit fixtures include cache policy, notification, ownership and callback
failure tests, plus wizard navigation, branching, cancellation and host cleanup
tests. Wizard fixtures construct real LCL forms and override the modal display
hook, so they run without user interaction.

On Windows, compile and run every registered fixture from PowerShell:

```powershell
.\tests\RunTests.ps1 `
  -FpcPath 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe' `
  -LazarusDirectory 'D:\Pascal\lazarus'
```

Supply the paths for your installation. Lazarus's LCL, Win32 widgetset and
LazUtils units must already be built for the selected compiler and architecture.
Generated executables, units and the compiler log go under ignored `tests/lib`.
Pass FPCUnit options with `-TestArguments`, for example
`@('--suite=TWizardTests', '--format=plain')`.

For the GUI runner, open `tests/FrameworkTests.lpi` in Lazarus. Both runners
register the same fixtures. The existing wizard demonstration is
`examples/wizard/FrameworkTester.lpi`. See the [test guide](tests/README.md)
and [wizard example guide](examples/wizard/README.md) for fixture selection,
setup and screen lifecycle details.
## License

Pascal Framework is distributed under the [MIT License](LICENSE).
Herman Schoenfeld and the Sphere10 contributors maintain the project.
