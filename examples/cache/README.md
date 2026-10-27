# Cache example

`CacheExample.lpr` is a console program using the same `UCache` API as the
[FPCUnit fixtures](../../tests/README.md). It runs without forms or interaction.
Open `CacheExample.lpi` in Lazarus, then build and run it, or use Free Pascal
from the repository root:

```powershell
$fpc = 'D:\Pascal\fpc\bin\x86_64-win64\fpc.exe'
Push-Location examples/cache
try {
  New-Item -ItemType Directory -Force lib/x86_64-win64 | Out-Null
  & $fpc '-Fu../../src/Sphere10' '-FUlib/x86_64-win64' `
    '-FElib/x86_64-win64' CacheExample.lpr
  if ($LASTEXITCODE -ne 0) { throw 'CacheExample compilation failed.' }
  & ./lib/x86_64-win64/CacheExample.exe
} finally {
  Pop-Location
}
```

Supply your installed compiler path. This example needs the Free Pascal RTL
and generics units; it has no LCL dependency. It was compiled and run with
Free Pascal 3.2.0 on Windows x64. The Lazarus project uses the same source path
and keeps generated units and the executable under ignored `lib`.

## What it demonstrates

| Example method | Behavior to observe |
| --- | --- |
| `ShowGlobalFunctions` | Wrap global fetch and size functions with `TValueFetcher` and `TSizeEstimator`. |
| `ShowObjectMethods` | The second read is a hit. Changing the source revision takes effect after `Invalidate`. Explicit indexer assignment does not fetch. |
| `ShowCapacityAndPins` | A six-byte cache evicts key 2 while key 1 is pinned. `Reap` releases only unpinned entries. A larger admission is rejected until the pinned entry is explicitly removed. |
| `ShowOwnedObjects` | `idpFreeAndNil` disposes a fetched object on removal and an explicitly supplied object on cache destruction. |

The object-method example prints `Source fetches: 2 (expected 2)` even though
it reads key 7 three times and reads an explicitly supplied value. The capacity
example reports three bytes released with three pinned bytes remaining.

## Minimal complete program

This standalone example compiles with the same source search path. Save it as
`BasicCache.lpr` and substitute that filename in the build command above.

```pascal
program BasicCache;
{$mode Delphi}{$H+}
uses SysUtils, UCommon, UMemory, UCache;

type
  TStringCache = TActionCache<Integer, AnsiString>;

function Fetch(const AKey: Integer) : AnsiString;
begin
  Result := 'value ' + IntToStr(AKey);
end;

function Estimate(const AValue: AnsiString) : SizeInt;
begin
  Result := Length(AValue);
end;

var
  cache : TStringCache;
begin
  cache := TStringCache.Create(nil,
    TStringCache.TValueFetcher.FromGlobalFunction(Fetch),
    TStringCache.TSizeEstimator.FromGlobalFunction(Estimate),
    idpNone, TStringCache.TCacheReapPolicy.crpLeastUsed,
    TStringCache.TExpirationPolicy.epNone,
    TStringCache.TNullValuePolicy.nvpCacheNormally,
    1024, TTimeSpan.MaxValue);
  try
    WriteLn(cache[7]);
    WriteLn(cache[7]);              // Hit: no second fetch.
    cache.Invalidate(7);
    WriteLn(cache[7]);              // Fetch again.
    cache[8] := 'supplied value';  // Admission without fetching.
    WriteLn(cache[8]);
  finally
    cache.Free;
  end;
end.
```

The estimator receives a **value**. Its units determine the meaning of capacity:
`Length(value)` counts string bytes here, while returning `1` counts entries.
An omitted estimator returns zero, so a finite capacity will not bound entry
count. `ReapLevel` controls the fraction targeted for release under pressure;
`Reap(minimumRelease)` returns the actual estimator units released.

To expire values 30 seconds after a successful source fetch, use the same
callbacks with this constructor configuration:

```pascal
cache := TStringCache.Create(nil,
  TStringCache.TValueFetcher.FromGlobalFunction(Fetch),
  TStringCache.TSizeEstimator.FromGlobalFunction(Estimate),
  idpNone, TStringCache.TCacheReapPolicy.crpLeastUsed,
  TStringCache.TExpirationPolicy.epSinceFetchedTime,
  TStringCache.TNullValuePolicy.nvpCacheNormally,
  1024, TTimeSpan.FromSeconds(30));
```

Choose `epSinceLastAccessedTime` instead for sliding expiration. Explicit
`Invalidate(key)` marks an entry expired immediately; the next read fetches it.

Use `TValueFetcher.FromObjectFunction(FetchString)` for an object method, as in
`ShowObjectMethods`. Corresponding global, object and nested-function adapters
exist for size estimation. The cache must be destroyed before its callback
object; nested callbacks must not outlive their enclosing stack frame.

## Notifications, metadata and ownership

The program assigns the typed Delphi events `ItemFetching`, `ItemFetched`,
`ItemRemoving` and `ItemRemoved`. Each event accepts one object-method handler.
Fetching runs before the source callback; fetched runs after admission. A
removing handler can raise an exception to leave removal retryable. Removed
runs after membership and capacity have changed; its exception does not undo
removal. Callbacks run synchronously under a recursive critical section, may
reenter the cache and must not destroy it.

`Get(key)` returns borrowed metadata. For example,
`cache.Get(1).CanPurge := false` pins an entry against automatic reaping, while
`Remove` and `Purge` still remove it. Callers must not free metadata objects.
Coordinate use of borrowed entries and object values with concurrent mutations.
The value indexer copies its result while the operation lock is held.

For object caches, choose one ownership policy deliberately:

- `idpNone` leaves payload ownership with the caller. Managed Pascal values such
  as strings still follow their normal compiler-managed lifetime.
- `idpFreeAndNil` transfers accepted object values to the cache. Removal disposes
  the payload after `ItemRemoved`; destruction also disposes remaining payloads.
  Do not free, share across owned keys, or dereference a removed payload.
- A failed explicit assignment retains caller ownership, so the caller must free
  that object. A failed fetched admission disposes the fetched object according
  to the configured policy, because no external caller owns that result.

Retaining the most recent `Get` metadata does not extend the lifetime of an
owned payload after removal. The `ShowOwnedObjects` method demonstrates the
explicit-assignment exception path and never uses the removed object pointer.
