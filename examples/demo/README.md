# Unified framework demo

Open [PascalFramework.dproj](../../PascalFramework.dproj) in Delphi or [PascalFramework.lpi](../../PascalFramework.lpi) in Lazarus, then build and run. Both projects use [one entry point](../../PascalFramework.dpr), the same demo units, and native `.dfm`/`.lfm` resource companions. No installed runtime package is required.

The **Visual grid** section is selected first. **Wizard and events** contains the feature wizard, the original name wizard, the notification/throttle demo and Work Area. **Cache** provides **Run cache examples**, which writes each case into its memo. All data is generated locally. The application needs no node, wallet, database or network connection.

## Visual grid

[fMain.pas](fMain.pas) generates 10,000 typed records and binds eight columns through the existing [data-source abstraction](../../src/Sphere10/UCommon.Data.pas). Edit the live grid's published properties with the Lazarus RTTI inspector or Delphi's standard value-list editor. Both support paging, search/sort and selection settings and the existing edit, button and combo-box widget controls; the native editor also exposes caption and font settings.

Regenerate records, change column widths, stretch columns, enable automatic column filling, clear selection or try the search-expression parser. Numeric, text and set criteria are available. The `Foo` column draws bold red values; `Real` uses the dollar renderer. The popup demonstrates replacing an individual displayed cell. **Add fetch delay** adds three seconds without moving GUI access onto the worker: criteria are captured in the source and published through the grid's completion event. A short lock protects regenerated record snapshots; `TDisposables` owns the supporting objects.

![Unified demo showing its visual grid and live property editor](../../resources/demo/unified-grid.png)

## Wizard and events

Choose **Wizard feature showcase** in this section:

1. Enter and confirm a name. Disable **Create the next steps when I continue** to see a missing dynamic successor remain retryable, then enable it. Repeated insertion is idempotent.
2. Enter a nonnegative whole-number age. Inject, replace or remove the optional notes step; the path-snapshot action proves that changing a returned copy cannot mutate the route.
3. Visit optional notes, go Back, and change the route. Removed forms remain wizard-owned and are disposed with the wizard; counters show their lifetime.
4. Accept the confirmation boundary. Previous is unavailable there; the final Summary can return to it.
5. Select a veto or simulated exception for finishing/cancellation. The first attempt stays active and the next succeeds. Toggle cancellation permission and inspect the busy reentry rejection counts.

The wizard uses one modal host. It retains the same native window and top-left position through navigation, hides outgoing pages and disposes all screens before the caller-owned model. The launcher keeps the event history after closure. Actual screen captures and framework usage examples are in the [main README](../../README.md#wizards).

![Native Delphi wizard launched from the unified demonstration](../../resources/demo/unified-wizard.png)

**Run Wizard Test** retains the original property-bag name/branch flow. The finish callback rejects `fail`; cancellation is allowed from its first page. **Notify Test** retains listener registration, synchronous/asynchronous notifications and throttle modes. Its destructor cancels its queued callback using the existing platform API. **Work Area** retains the existing control-layout example.

## Cache

[UCacheDemo.pas](UCacheDemo.pas) uses the same `UCache` APIs as the unit tests and writes output to the caller-owned memo. It demonstrates:

| Case | Observable result |
| --- | --- |
| Global function adapters | A fetcher and string-byte estimator wrap existing global functions. |
| Object method adapters | Hits avoid fetching; invalidation fetches again; explicit assignment does not fetch. The source count is 2. |
| Capacity and pins | A budget of six native characters evicts key 2 while retaining pinned key 1. Reap releases `3 * SizeOf(Char)` bytes; an oversized admission is rejected. |
| Notifications | Fetching/fetched and removing/removed events show callback order and cache state changes. |
| Owned objects | Removal disposes the fetched object; cache destruction disposes an explicitly assigned object. Failed assignment retains caller ownership. |

The capacity-rejection case and the wizard's simulated failure cases deliberately raise handled exceptions. A debugger may stop at the first-chance exception; Continue resumes the demonstrated recovery.

The synchronous demonstration finishes disposing caches and callback objects before returning. `TDisposables` owns the demo runner; individual caches retain their existing `try/finally` lifetime around the callback provider. Complete reusable cache code examples are in the [main README](../../README.md#caching).

![Cache examples and their observable output in the same application](../../resources/demo/unified-cache.png)

## Build layout and optional SQLite recipe

Delphi outputs go under `lib/Delphi/<platform>/demo/<configuration>`; Lazarus outputs go under `lib/FPC/<cpu>-<os>/demo`. Build with the IDE when using Delphi Community Edition. The root project groups include this single runnable app and the optional reusable package; the FPCUnit test project remains separate.

The preserved [SQLite adapter source](sqlite/fMain.pas) is a recipe for the older optional mORMot integration. It has no separate application entry point and is not required by this cross-compiler demonstration. The complete supported grid UI is exercised by the generated-record source above.

Copyright © 2026 [Herman Schoenfeld](https://sphere10.com). Distributed under the [MIT license](../../LICENSE).
