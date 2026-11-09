# Five-second grid throttle

Open [Sphere10PascalFramework.dproj](../../Sphere10PascalFramework.dproj) in Delphi
or [Sphere10PascalFramework.lpi](../../Sphere10PascalFramework.lpi) in Lazarus and
select **Refresh throttle** ([UThrottleDemo.pas](../demo/UThrottleDemo.pas)). It
needs no wallet or network. The counters show Notify clicks, delivered events and
page fetches.

1. Click **Notify**. The grid fetches at once and starts its quiet timer.
2. Click again within five seconds. The timer restarts without a fetch.
3. Stop for five seconds. One fetch runs and **Please Wait / Synchronizing**
   disappears.
4. Click once after the wait ends. The grid fetches at once, and no second fetch
   follows.

In code:

```pascal
Grid.RefreshThrottle.Interval := TTimeSpan.FromMilliseconds(5000);
Grid.RefreshThrottle.Mode :=
    TThrottledEventMode.temNotifyOnEventBurstStartAndFinished;

// Each request records the latest page and notifies the owned throttle once.
Grid.RefreshGrid;
```

The throttle also covers paging, filtering and resizing.

Copyright © 2026 [Herman Schoenfeld](https://sphere10.com).
[MIT license](../../LICENSE).
