# Public API examples

The shared Delphi/Lazarus demo exercises the Framework’s public classes, records,
helpers, callbacks and aliases. Use **Utilities** for core, collection, disposal
and UI recipes; **Run complete cache API** is in the Cache tab. Interactive grid
and wizard walkthroughs remain in their own tabs.

Aliases reuse the underlying type’s example. Empty placeholders have no added
behavior to call. Platform-specific APIs are marked below; bundled third-party
generics and protected/private implementation types are excluded.

## UCache

[Unit source](../src/Sphere10/UCache.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TCacheItemDisposePolicy` | [ShowSubclass](../examples/demo/UCacheApiExamples.pas) |  |
| `TCachedItem<TValue>` | [ShowSubclass](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheBase<TKey, TValue>` | [ShowSubclass](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheExpirationPolicy` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) | Fixed/sliding expiration or no expiration. |
| `TCacheReapPolicy` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) | Capacity eviction strategy. |
| `TCacheNullValuePolicy` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) | Retain, bypass or reject null values. |
| `TCacheStaleValuePolicy` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) | Optional on-demand staleness checks. |
| `TCacheItemFetchingEvent<TKey>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheItemValueEvent<TKey,TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheItemRemovingEvent<TKey,TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TActionCache<TKey, TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `ICacheValueFetcher<TKey,TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `ICacheSizeEstimator<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheNestedFetchFunc<TKey,TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheObjectFetchFunc<TKey,TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheGlobalFetchFunc<TKey,TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheNestedEstimateFunc<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheObjectEstimateFunc<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheGlobalEstimateFunc<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheValueFetcher<TKey,TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheSizeEstimator<TValue>` | [ShowCallbacks](../examples/demo/UCacheApiExamples.pas) |  |
| `TBulkFetchCacheBase<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheBulkValues<TKey,TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TBulkFetchActionCache<TKey, TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `ICacheBulkValueFetcher<TKey,TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheNestedBulkFetchProc<TKey,TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheObjectBulkFetchProc<TKey,TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheGlobalBulkFetchProc<TKey,TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TCacheBulkValueFetcher<TKey,TValue>` | [ShowBulkFetch](../examples/demo/UCacheApiExamples.pas) |  |
| `TPreloadedCache<TKey, TValue>` | [ShowPreloaded](../examples/demo/UCacheApiExamples.pas) |  |

## UCommon

[Unit source](../src/Sphere10/UCommon.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TScope` | [ScopedReadWriteLocking](../examples/demo/UCoreApiExamples.pas) | Managed record; copied scopes retain one cleanup until the last owner ends. |
| `SizeInt` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) | Delphi compatibility alias; FPC provides the corresponding built-in type. |
| `PtrInt` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) | Delphi compatibility alias; FPC provides the corresponding built-in type. |
| `QWord` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) | Delphi compatibility alias; FPC provides the corresponding built-in type. |
| `DWord` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) | Delphi compatibility alias; FPC provides the corresponding built-in type. |
| `TTimeSpan` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TBox<T>` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TLogSeverity` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TLogMessage` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TResult` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TDateTimeHelper` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TNotifyManyEvent` | [Notifications](../examples/demo/UCoreApiExamples.pas) |  |
| `TNotifyManyEventHelper` | [Notifications](../examples/demo/UCoreApiExamples.pas) |  |
| `TThreadNotify` | [Notifications](../examples/demo/UCoreApiExamples.pas) |  |
| `TThreadNotify.TPendingNotifyManyEvent` | [Notifications](../examples/demo/UCoreApiExamples.pas) |  |
| `TArrayTool<T>` | [ArrayMethods](../examples/demo/UArrayCollectionExamples.pas) | Existing complete ArrayMethods group; additional typed array use in the core example. |
| `TVariantTool` | [VariantAndFileTools](../examples/demo/UCoreApiExamples.pas) |  |
| `TFileStreamHelper` | [VariantAndFileTools](../examples/demo/UCoreApiExamples.pas) | WriteString is Delphi only; the FPC helper adds no methods. |
| `TFileTool` | [VariantAndFileTools](../examples/demo/UCoreApiExamples.pas) |  |
| `TCPUTool` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |
| `TStatistics` | [CommonValuesAndResults](../examples/demo/UCoreApiExamples.pas) |  |

## UCommon.Collections

[Unit source](../src/Sphere10/UCommon.Collections.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TNestedComparerFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TObjectComparerFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TGlobalComparerFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TComparerTool<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TNestedPredicateFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TObjectPredicateFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TGlobalPredicateFunc<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TNestedTransformFunc<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TObjectTransformFunc<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TGlobalTransformFunc<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `IPredicate<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `ITransformer<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TPredicateTool<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TListTool<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TListTool<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TSortedHashSetTool<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) | FPC only. |
| `TNestedComparer<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TObjectComparer<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TGlobalComparer<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TManyComparer<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TInvertedComparer<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TNestedPredicate<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TObjectPredicate<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TGlobalPredicate<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TNotPredicate<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TAndManyPredicate<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TOrManyPredicate<T>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TNestedTransformer<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TObjectTransformer<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |
| `TGlobalTransformer<T1, T2>` | [CollectionAdapters](../examples/demo/UArrayCollectionExamples.pas) |  |

## UCommon.Data

[Unit source](../src/Sphere10/UCommon.Data.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TSortDirection` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TFilterOperand` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TSortNullPolicy` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataFilter` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataFilters` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataColumn` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataColumns` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataRow` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `EDataRow` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataRowData` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) | Borrow the backing of an existing row Variant; do not separately own raw storage. |
| `TColumnFilter` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TFilterCriteria` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TApplyFilterDelegate<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TApplySortDelegate<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataTable` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `PDataTable` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `EDataTable` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TColumnFilterPredicate<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TColumnFieldComparer<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TPageFetchParams` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TPageFetchResult` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `IDataSource` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TCustomDataSource<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |
| `TExpressionKind` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TTextMatchKind` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TNumericComparisionKind` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TSetKind` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TExpressionRecord` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `ESearchExpressionParserException` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TSearchExpressionService` | [SearchExpressions](../examples/demo/UCoreApiExamples.pas) |  |
| `TDataSourceTool<T>` | [DataRowsAndPaging](../examples/demo/UCoreApiExamples.pas) |  |

## UCommon.UI

[Unit source](../src/Sphere10/UCommon.UI.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TApplicationForm` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |
| `TThrottledEvent` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |
| `TThrottledEvent.TThrottledEventMode` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |
| `TWinControlHelper` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |
| `TFormHelper` | [No added behavior](../examples/demo/UCoreApiExamples.pas) | Empty helper: adds no methods. |
| `TImageHelper` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) |  |
| `TLoadingCircle` | [CommonVisuals](../examples/demo/UCoreApiExamples.pas) | Animated control in UCommon.UI. |

## UConcurrency

[Unit source](../src/Sphere10/UConcurrency.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TLockRecursionPolicy` | [ReadWriteLocking](../examples/demo/UCoreApiExamples.pas) |  |
| `ELockRecursionException` | [ReadWriteLocking](../examples/demo/UCoreApiExamples.pas) |  |
| `ESynchronizationLockException` | [ReadWriteLocking](../examples/demo/UCoreApiExamples.pas) |  |
| `ELockDisposedException` | [ReadWriteLocking](../examples/demo/UCoreApiExamples.pas) |  |
| `TReadWriteLock` | [ReadWriteLocking / ScopedReadWriteLocking](../examples/demo/UCoreApiExamples.pas) | Explicit Acquire/Release methods and automatic TScope read/write/upgradeable ownership. |

## UMemory

[Unit source](../src/Sphere10/UMemory.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TDisposePolicy` | [BuildLocalReport / TReportBuilder](../examples/demo/UDisposalReadmeExamples.pas) | Cleanup policies are also used by the collection and cache recipes. |
| `TDisposables` | [BuildLocalReport / TReportBuilder](../examples/demo/UDisposalReadmeExamples.pas) |  |

## UVisualGrid

[Unit source](../src/Sphere10/UVisualGrid.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TSelectionType` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TDeselectionType` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualGridSelection` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualColumnRenderer` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualColumnDataSanitizer` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualColumn` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TPreparePopupMenuEvent` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TSelectionEvent` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TDrawVisualCellEvent` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TColumnInitializeEvent` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `EVisualGridError` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualGridOptions` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TSortMode` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TSearchMode` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualGridCaption` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TCustomVisualGrid` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualGrid` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) |  |
| `TVisualCellRenderers` | [TForm1.FormCreate (DollarValue)](../examples/demo/fMain.pas) |  |
| `TVisualGridSearchExpressionService` | [No added behavior](../examples/demo/UUiApiExamples.pas) | Empty placeholder: no parser methods. Use TSearchExpressionService from UCommon.Data. |
| `TGridColumn` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TVisualGridHeaderClick` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TVisualGridCellSelected` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TGridZone` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TDrawGrid` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TCheckComboItemChange` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |
| `TCheckComboBox` | [TGridRecipe.Run](../examples/demo/UUiApiExamples.pas) | Delphi/VCL compatibility API; guarded in the shared recipe. |

## UWizard

[Unit source](../src/Sphere10/UWizard.pas)

| Public type | Worked example | Note |
| --- | --- | --- |
| `TPathUpdateType` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardState` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardStepTrait` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardStepTraits` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardScreenPath` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardHostForm` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardHostForm.TWizardHostFormCloseQueryDelegate` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardFormBase` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardFormClass` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizardForm<T>` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizard<T>` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizard<T>.__TScreenType` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TWizard<T>.__TList_TComponentClass` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TActionWizard<T>` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TActionWizard<T>.TActionWizardCancelFunc` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TActionWizard<T>.TActionWizardFinishFunc` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
| `TGenericWizardBag` | [TRecipeWizard.ShowHost / RunUiApiExamples](../examples/demo/UUiApiExamples.pas) |  |
