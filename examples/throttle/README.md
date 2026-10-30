# Five-second grid throttle

Open [ThrottleDemo.dproj](ThrottleDemo.dproj) in Delphi and run it. Lazarus uses
[ThrottleDemo.lpi](ThrottleDemo.lpi)
with the same form source. The app uses generated rows and does not open a wallet,
connect to a network or read any PascalCoin data.

Click **Notify** once for an immediate fetch. Keep clicking less than five seconds
apart: each click restarts the quiet interval. The next fetch must occur only
after five seconds without a click. The **Please Wait / Synchronizing** card
follows the throttle's `Waiting` state. After it disappears, the next click
delivers immediately. One isolated click does not produce a duplicate fetch at
the end of its wait.

This focused timing tool complements the [unified grid/wizard/cache demo](../demo/README.md).

The event log and counters distinguish button clicks, ordinary throttle deliveries
and actual `IDataSource.FetchPage` calls since **Ready**. The grid's total fetch
number also includes initial setup, which the first log entry reports separately.
The displayed revision is the click count captured by its latest fetch.
A 100 ms display timer only reads the
state and countdown after first-show setup; it never requests or admits a refresh.

The button uses the real grid admission path:

```pascal
Grid.RefreshThrottle.Interval := TTimeSpan.FromMilliseconds(5000);
Grid.RefreshThrottle.Mode :=
  TThrottledEvent.TThrottledEventMode.temNotifyOnEventBurstStartAndFinished;

// The button requests pending grid work and triggers the owned throttle once.
Grid.RefreshGrid;
```

`RefreshGrid` records the latest page request and calls the owned
`RefreshThrottle.Notify`. Calling `Notify` alone would not queue page work, so
the button must not call both. Resizing or paging also follows that same grid
admission path and therefore restarts the quiet interval.

© 2026 [Herman Schoenfeld](https://sphere10.com). [MIT license](../../LICENSE).
