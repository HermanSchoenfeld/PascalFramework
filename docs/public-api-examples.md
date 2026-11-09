# Public API examples

The shared Delphi/Lazarus demo exercises the Framework’s public classes, records,
helpers, callbacks and aliases. Use **Utilities** for core, collection, disposal
and UI recipes; **Run complete cache API** is in the Cache tab. Interactive grid
and wizard walkthroughs remain in their own tabs.

Aliases reuse the underlying type’s example. Platform-specific APIs are marked
below. Each table follows its unit’s supported public-type inventory; bundled
third-party generics and compiler-exported implementation adapters are excluded.

## UCache

[Unit source](../src/Sphere10/UCache.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `ICacheBulkValueFetcher<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `ICacheSizeEstimator<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `ICacheValueFetcher<TKey, TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TActionCache<TKey, TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TBulkFetchActionCache<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TBulkFetchCacheBase<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheBase<TKey, TValue>` | [ShowSubclass](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheBulkValueFetcher<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheBulkValues<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCachedItem<TValue>` | [ShowSubclass](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheExpirationPolicy` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) | Fixed/sliding expiration or no expiration. |
| `TCacheGlobalBulkFetchProc<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheGlobalEstimateFunc<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheGlobalFetchFunc<TKey, TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheItemDisposePolicy` | [ShowSubclass](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheItemFetchingEvent<TKey>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheItemRemovingEvent<TKey, TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheItemValueEvent<TKey, TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheNestedBulkFetchProc<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheNestedEstimateFunc<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheNestedFetchFunc<TKey, TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheNullValuePolicy` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) | Retain, bypass or reject null values. |
| `TCacheObjectBulkFetchProc<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheObjectEstimateFunc<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheObjectFetchFunc<TKey, TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheReapPolicy` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) | Capacity eviction strategy. |
| `TCacheSizeEstimator<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheStaleValuePolicy` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) | Optional on-demand staleness checks. |
| `TCacheValueFetcher<TKey, TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TPreloadedCache<TKey, TValue>` | [ShowPreloaded](../examples/demo/UCacheApiExamples.pas) |  |

## UCommon

[Unit source](../src/Sphere10/UCommon.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `DWord` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) | Delphi compatibility alias; FPC provides the corresponding built-in type. |
| `PtrInt` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) | Delphi compatibility alias; FPC provides the corresponding built-in type. |
| `QWord` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) | Delphi compatibility alias; FPC provides the corresponding built-in type. |
| `SizeInt` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) | Delphi compatibility alias; FPC provides the corresponding built-in type. |
| `TArrayTool<T>` | [ArrayMethods](../examples/demo/UArrayCollectionExamples.pas) | Existing complete ArrayMethods group; additional typed array use in the core example. |
| `TBox<T>` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TCPUTool` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TDateTimeHelper` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TFileStreamHelper` | [VariantAndFileTools](../examples/demo/UCoreApiExamples.pas) | WriteString is Delphi only; the FPC helper adds no methods. |
| `TFileTool` | [VariantAndFileTools](../examples/demo/UCoreApiExamples.pas) |  |
| `TLogMessage` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TLogSeverity` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TNotifyManyEvent` | [Notifications](../examples/demo/UCoreApiExamples.pas) |  |
| `TNotifyManyEventHelper` | [Notifications](../examples/demo/UCoreApiExamples.pas) |  |
| `TResult` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TScope` | [ScopedReadWriteLocking](../examples/demo/UCoreApiExamples.pas) | Managed record; copied scopes retain one cleanup until the last owner ends. |
| `TStatistics` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TThreadNotify` | [Notifications](../examples/demo/UCoreApiExamples.pas) |  |
| `TTimeSpan` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TVariantTool` | [VariantAndFileTools](../examples/demo/UCoreApiExamples.pas) |  |

## UCommon.Collections

[Unit source](../src/Sphere10/UCommon.Collections.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `IPredicate<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `ITransformer<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TComparerTool<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TGlobalComparerFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TGlobalPredicateFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TGlobalTransformFunc<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TListTool<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TListTool<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TNestedComparerFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TNestedPredicateFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TNestedTransformFunc<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TObjectComparerFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TObjectPredicateFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TObjectTransformFunc<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TPredicateTool<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TSortedHashSetTool<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) | FPC only. |

## UCommon.Data

[Unit source](../src/Sphere10/UCommon.Data.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `EDataRow` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `EDataTable` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `ESearchExpressionParserException` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `IDataSource` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `PDataTable` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TApplyFilterDelegate<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TApplySortDelegate<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TColumnFilter` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TCustomDataSource<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataColumn` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataColumns` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataFilter` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataFilters` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataRow` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataRowData` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) | Borrow the backing of an existing row Variant; do not separately own raw storage. |
| `TDataSourceTool<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataTable` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TExpressionKind` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TExpressionRecord` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TFilterCriteria` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TFilterOperand` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TNumericComparisionKind` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) | Deprecated alias; use `TNumericComparisonKind`. |
| `TNumericComparisonKind` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TPageFetchParams` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TPageFetchResult` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TSearchExpressionService` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TSetKind` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TSortDirection` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TSortNullPolicy` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TTextMatchKind` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |

## UCommon.UI

[Unit source](../src/Sphere10/UCommon.UI.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TApplicationForm` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |
| `TFormHelper` | [No added behavior](../examples/demo/UCoreApiExamples.pas) | Empty helper: adds no methods. |
| `TImageHelper` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |
| `TLoadingCircle` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) | Animated control in UCommon.UI. |
| `TThrottledEvent` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |
| `TThrottledEventMode` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |
| `TWinControlHelper` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |

## UConcurrency

[Unit source](../src/Sphere10/UConcurrency.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `ELockDisposedException` | [ReadWriteLocking](../examples/demo/UCoreApiExamples.pas) |  |
| `ELockRecursionException` | [ReadWriteLocking](../examples/demo/UCoreApiExamples.pas) |  |
| `ESynchronizationLockException` | [ReadWriteLocking](../examples/demo/UCoreApiExamples.pas) |  |
| `TLockRecursionPolicy` | [ReadWriteLocking](../examples/demo/UCoreApiExamples.pas) |  |
| `TReadWriteLock` | [ReadWriteLocking / ScopedReadWriteLocking](../examples/demo/UCoreApiExamples.pas) | Explicit Acquire/Release methods and automatic TScope read/write/upgradeable ownership. |

## UMemory

[Unit source](../src/Sphere10/UMemory.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TDisposables` | [BuildLocalReport / TReportBuilder](../examples/demo/UDisposalReadmeExamples.pas) |  |
| `TDisposePolicy` | [BuildLocalReport / TReportBuilder](../examples/demo/UDisposalReadmeExamples.pas) | Cleanup policies are also used by the collection and cache recipes. |

## UStreams

[Unit source](../src/Sphere10/UStreams.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TBufferedStream` | [BufferedStreams](../examples/demo/UCoreApiExamples.pas) | Switchable read-ahead and length caching, explicit unread-data flushing, input ownership, logical seeking and synchronous writes. |

## UVisualGrid

[Unit source](../src/Sphere10/UVisualGrid.pas)

The unified demo’s **Visual grid** tab uses the real grid and 10,000 generated
records. Its square footer button opens a checked menu for **Single** (all matching rows with native
scrolling), **Auto** (complete rows fitting the viewport) and **Manual** (an
editable finite page size). Changing modes starts at page zero; resizing Auto
keeps the current page number. Manual size is retained across mode changes.

```pascal
Grid.PageMode := vpmAuto;
Grid.ManualPageSize := 25;
Grid.PageMode := vpmManual;
Grid.PageMode := vpmSingle;
```

`PageSize` remains a positive setting in Single mode; the source receives an
unbounded page request. Filtering and sorting still cover the complete result.
The shared [paging checks](../tests/UVisualGrid.Paging.Checks.pas) exercise the
same controls in Delphi and Lazarus; the [capture tool](../tests/native/FrameworkDemoPagingCapture.dpr)
records all three modes in the actual demo.

| Public type | Worked example | Note |
| --- | --- | --- |
| `EVisualGridError` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TCheckComboBox` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TCheckComboItemChange` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TColumnInitializeEvent` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TCustomVisualGrid` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TDeselectionType` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TDrawGrid` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TDrawVisualCellEvent` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TGridColumn` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TGridZone` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TPreparePopupMenuEvent` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TSearchMode` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TSelectionEvent` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TSelectionType` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TSortMode` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualCellRenderers` | [TForm1.FormCreate (DollarValue)](../examples/demo/fMain.pas) |  |
| `TVisualColumn` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualColumnDataSanitizer` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualColumnRenderer` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualGrid` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualGridCaption` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualGridCellSelected` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TVisualGridHeaderClick` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TVisualGridOptions` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualGridPageMode` | [TVisualGridPagingTests](../tests/UVisualGrid.Paging.Checks.pas) | Single loads every matching row; Auto fits complete rows; Manual uses a remembered finite size. The demo selects modes through the grid's own footer button. |
| `TVisualGridSearchExpressionService` | [No added behavior](../src/Sphere10/UVisualGrid.pas) | Empty placeholder: no parser methods. Use TSearchExpressionService from UCommon.Data. |
| `TVisualGridSelection` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |

## UWizard

[Unit source](../src/Sphere10/UWizard.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TActionWizard<T>` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TActionWizard<T>.TActionWizardCancelFunc` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TActionWizard<T>.TActionWizardFinishFunc` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TGenericWizardBag` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TPathUpdateType` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizard<T>` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardForm<T>` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardFormBase` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardFormClass` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardHostForm` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardHostForm.TWizardHostFormCloseQueryDelegate` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardScreenPath` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardState` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardStepTrait` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardStepTraits` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
