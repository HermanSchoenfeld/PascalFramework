# Five-second grid throttle

Open [Sphere10PascalFramework.dproj](../../Sphere10PascalFramework.dproj) in Delphi
or [Sphere10PascalFramework.lpi](../../Sphere10PascalFramework.lpi) in Lazarus,
then select **Refresh throttle**. This is a section of the shared demo, using
[the same form source](../demo/UThrottleDemo.pas) on both compilers. All rows are
local; no wallet or network is involved.

1. Click **Notify** once: the grid fetches immediately and starts its quiet timer.
2. Click again less than five seconds later: the timer restarts. Keep clicking
   to postpone fetching; the grid keeps its previous rows.
3. Stop for five seconds: one pending fetch runs and **Please Wait / Synchronizing**
   disappears. One isolated click produces no duplicate trailing fetch.
4. Click after the wait finishes: a new burst can fetch immediately.

The counters distinguish requests, throttle deliveries and actual source fetches.
The log reports initial setup separately; the displayed revision is the click
count captured by the latest fetch. A display-only timer updates the countdown.
It never requests a refresh or changes throttle admission.

```pascal
Grid.RefreshThrottle.Interval := TTimeSpan.FromSeconds(5);
Grid.RefreshThrottle.Mode :=
    TThrottledEvent.TThrottledEventMode.temNotifyOnEventBurstStartAndFinished;

// Each request records the latest page and notifies the owned throttle once.
Grid.RefreshGrid;
```

Paging, filtering and resizing use the same admission path. Resizing still changes
visual layout while waiting; it fetches only after admission. The loading card
follows `RefreshThrottle.Waiting`, independently of any external service.

Copyright © 2026 [Herman Schoenfeld](https://sphere10.com).
[MIT license](../../LICENSE).
