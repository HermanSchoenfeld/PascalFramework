# PascalFramework

## Project Overview

PascalFramework (also known as Sphere10Framework) is a foundational library for Free Pascal and Lazarus applications, providing enterprise-grade components and utilities that extend the standard FCL and LCL libraries. The framework addresses the gap between Pascal's standard libraries and the demands of modern application development by offering production-ready implementations of common patterns, data structures, and UI components.

The library is designed for developers building desktop applications with Lazarus/FPC who need robust, reusable solutions for collection manipulation, caching, memory management, data binding, and UI components. Rather than reinventing these patterns in each project, PascalFramework provides battle-tested implementations that handle edge cases, threading concerns, and memory management correctly.

## Design Philosophy

PascalFramework is built on several core principles:

**Correctness Over Convenience**: Components prioritize correct behavior, particularly around memory management, threading safety, and edge cases. The framework provides explicit dispose policies and memory scope management rather than relying on implicit behavior that can lead to leaks or undefined behavior.

**Composability**: The library emphasizes small, composable abstractions. Comparers, predicates, and transformers can be combined through tool classes like `TComparerTool` and `TPredicateTool`, allowing complex behavior to be built from simple functions.

**Extensibility Through Interfaces**: Core abstractions are defined as interfaces (`IComparer<T>`, `IPredicate<T>`, `ITransformer<T>`) with multiple implementation paths (nested functions, object methods, global functions) to support different coding styles and use cases.

**Explicit Resource Management**: The framework provides tools like `TDisposables` for scope-based resource cleanup, reducing the risk of leaks while maintaining explicitness about object lifetimes.

**Cross-Platform Compatibility**: All components work with both Free Pascal Compiler (FPC) and include compatibility shims where needed, such as the `TTimeSpan` implementation for FPC that mirrors Delphi's API.

## Domains Covered

### Core Utilities (UCommon)

The `UCommon` unit provides fundamental utilities that extend Pascal's standard library, including:

- **Type Extensions**: Helper types and functions for working with hex strings, byte arrays, and variant types
- **Temporal Types**: A complete `TTimeSpan` implementation for FPC that provides Delphi compatibility, supporting duration arithmetic and formatting
- **Result Pattern**: A `TResult` type that encapsulates success/failure with optional messages and return values, enabling functional error handling
- **Event System**: `TNotifyManyEvent` and `TThreadNotify` for multi-cast events with thread-safe invocation and main-thread marshalling
- **Array Utilities**: Generic `TArrayTool<T>` for common array operations like searching, insertion, removal, and concatenation
- **DateTime Extensions**: Rich helpers for date/time manipulation, comparison, and formatting
- **Variant Tools**: Safe variant type checking, parsing, and comparison utilities

### Collections (UCommon.Collections)

Advanced collection utilities that extend `Generics.Collections`:

- **Comparer Composition**: `TComparerTool<T>` for building comparers from functions, inverting comparers, or chaining multiple comparers
- **Predicate Logic**: `TPredicateTool<T>` for creating predicates from functions and combining them with logical AND/OR operations
- **List Filtering**: `TListTool<T>` for filtering and removing items from lists based on predicates with configurable dispose policies
- **Transformations**: `TListTool<T1, T2>` for mapping arrays and lists through transformation functions
- **Collection Extensions**: Utilities for working with specialized collections like `TSortedHashSet<T>`

These tools support nested functions, object methods, and global functions, providing flexibility in how predicates and comparers are defined.

### Caching (UCache)

A sophisticated caching system with configurable policies:

- **Generic Cache Base**: `TCacheBase<TKey, TValue>` provides the foundation for both action-based and data-driven caches
- **Expiration Policies**: Time-based expiration calculated from fetch time or last access time
- **Reap Policies**: Multiple eviction strategies including LRU, idle time, size-based (largest/smallest), and oldest-first
- **Null Value Handling**: Configurable behavior for null values (cache normally, return but don't cache, or throw)
- **Action Cache**: `TActionCache<TKey, TValue>` automatically fetches values on cache miss using provided functions
- **Size Management**: Automatic capacity management with configurable maximum sizes and size estimation

The cache implementation is thread-safe using read-write synchronization and supports bulk loading, invalidation, and flushing.

### Memory Management (UMemory)

Explicit memory and object lifetime management:

- **Scope-Based Cleanup**: `TDisposables` provides automatic cleanup of objects and memory at scope exit
- **Multiple Dispose Policies**: Support for various cleanup strategies including nil, free, free-and-nil, and FreeMem
- **Exception Safety**: Cleanup continues even if individual dispose operations throw exceptions
- **Flexible Registration**: Add objects or memory allocations to disposables at any point during scope execution

This enables RAII-like patterns in Pascal code without language-level support.

### Data Binding and Filtering (UCommon.Data)

Infrastructure for data manipulation and binding:

- **Data Rows**: `TDataRow` provides a variant-based dynamic record type with named field access
- **Column Metadata**: `TDataColumn` for defining column schemas with key designation
- **Filter Criteria**: Rich filtering support including text matching (exact, prefix, suffix, substring) and numeric comparisons (equality, ranges, inequalities)
- **Sort Specifications**: Multi-column sorting with ascending/descending direction and null handling policies
- **Generic Delegates**: `TApplyFilterDelegate<T>` and `TApplySortDelegate<T>` enable custom filtering and sorting logic
- **Data Tables**: In-memory table structures with column definitions and variant-based row storage

### UI Components (UCommon.UI, UWizard, UVisualGrid)

Enterprise-grade UI components for Lazarus:

**Application Framework** (`UCommon.UI`):
- `TApplicationForm` base class with lifecycle events (first activation, destruction)
- `TThrottledEvent` for rate-limiting event notifications with multiple throttling modes
- Helper extensions for `TWinControl` and `TForm`

**Wizard Framework** (`UWizard`):
- Generic wizard system `TWizard<T>` with model-driven screen flow
- Dynamic path updates allowing screens to conditionally inject or replace subsequent screens
- Screen lifecycle management (initialization, presentation, validation, navigation)
- `TActionWizard<T>` for wizards without subclassing, using function delegates

**Visual Grid** (`UVisualGrid`):
- `TCustomVisualGrid` enterprise data grid with advanced features
- Column binding to variant-based data with expression support for nested fields
- Custom renderers per column with full canvas access
- Filtering with multiple filter types (text matching, numeric comparisons)
- Multi-column sorting with visual indicators
- Selection modes including single cell, row, and multi-row with configurable deselection behavior
- Data sanitization hooks for transforming cell values before display
- Paging support for large datasets

## Key Concepts

### Dispose Policies

Throughout the framework, dispose policies explicitly control object and memory cleanup. The `TDisposePolicy` enumeration defines strategies:

- `idpNone`: No action taken, caller retains responsibility
- `idpNil`: Set pointer to nil without freeing
- `idpFree` / `idpFreeAndNil`: Free object instance
- `idpRelease`: Decrement reference count (interface objects)
- `idpFreeMem`: Free raw memory allocation

This explicitness prevents ambiguity about ownership and lifetime.

### Functional Composition

The framework embraces functional patterns through its comparer, predicate, and transformer APIs. Rather than requiring inheritance, these systems accept functions as first-class values and provide tools for composition:

```pascal
// Example conceptual usage
TComparerTool<T>.Many([comparer1, comparer2, comparer3])  // Chain comparers
TPredicateTool<T>.AndMany([pred1, pred2])                 // Logical AND
TPredicateTool<T>.Inverted(predicate)                     // Negation
```

### Variant-Based Data Rows

The `TDataRow` system provides dynamic records with named field access using variants. This enables flexible data structures without compile-time schema definitions, particularly useful for data binding scenarios where column sets are determined at runtime.

### Generic Thread Safety

Cache and collection components use synchronization primitives (`TCriticalSection`, `TSimpleRWSync`) to provide thread-safe operations. The framework follows a pattern of coarse-grained locking at operation boundaries rather than fine-grained locks at every field access, balancing simplicity and performance.

### Event Multi-casting with Thread Marshalling

The `TNotifyManyEvent` and `TThreadNotify` types provide event systems that support multiple subscribers with explicit control over which thread executes handlers. This is critical for UI applications where certain operations must run on the main thread.

## Typical Use Cases

PascalFramework is well-suited for:

- **Lazarus Desktop Applications**: Building rich-client applications that need advanced data grids, wizards, and form management
- **Data-Intensive Applications**: Applications that process large datasets with filtering, sorting, and paging requirements
- **Cached Data Access**: Systems that need configurable caching layers with expiration and eviction policies
- **Dynamic Schema Applications**: Programs working with data structures determined at runtime rather than compile time
- **Cross-Platform FPC Projects**: Code that needs to work across Windows, Linux, and macOS with FPC

The framework may not be appropriate for:

- **Web Applications**: The library is focused on desktop applications and does not address HTTP, REST, or web frameworks
- **Mobile Applications**: No mobile platform support or touch-optimized components
- **Minimalist Projects**: If you only need one or two utilities, the framework's design assumes you're building substantial applications
- **Real-Time Systems**: While thread-safe, the framework is not designed for hard real-time constraints or lock-free algorithms

## Architecture Overview

The framework follows a layered architecture:

**Foundation Layer** (`UMemory`, `UCommon`):
- Basic type extensions, utilities, and memory management
- No dependencies on other framework units
- Provides building blocks used throughout higher layers

**Collection Layer** (`UCommon.Collections`):
- Built on foundation layer and `Generics.Collections`
- Provides functional composition tools for working with collections
- Used by data and caching layers

**Data Layer** (`UCommon.Data`):
- Depends on collection and foundation layers
- Provides data binding abstractions and filtering infrastructure
- Used by UI components for data-driven behavior

**Caching Layer** (`UCache`):
- Depends on foundation and collection layers
- Standalone subsystem with minimal coupling to other domains
- Can be used independently of UI components

**UI Layer** (`UCommon.UI`, `UWizard`, `UVisualGrid`):
- Depends on all lower layers
- Integrates with Lazarus Component Library (LCL)
- Provides visual components and application framework

Components within each layer are designed to be composable. For example, `TVisualGrid` uses the data binding infrastructure from `UCommon.Data`, caching from `UCache` for performance optimization, and collection tools from `UCommon.Collections` for filtering operations.

## Getting Started

### Installation

The framework is distributed as a Lazarus package:

1. Clone or download the repository
2. Open `packages/Sphere10Framework.lpk` in Lazarus IDE
3. Compile and install the package
4. Add `Sphere10Framework` to your project's required packages

### Minimal Usage Example

```pascal
program MinimalExample;

{$mode delphi}

uses
  UCommon, UCommon.Collections, UMemory;

var
  numbers: TArray<Integer>;
  filtered: TList<Integer>;
  predicate: IPredicate<Integer>;
  GC: TDisposables;
begin
  // Use TDisposables for automatic cleanup
  numbers := TArrayTool<Integer>.Create(1, 2, 3, 4, 5);
  
  filtered := GC.AddObject(TList<Integer>.Create) as TList<Integer>;
  filtered.AddRange(numbers);
  
  // Create predicate: filter even numbers
  predicate := TPredicateTool<Integer>.FromFunc(
    function(constref x: Integer): Boolean
    begin
      Result := x mod 2 = 0;
    end
  );
  
  // Filter list in place
  TListTool<Integer>.FilterBy(filtered, predicate);
  
  // filtered now contains only even numbers: [2, 4]
  
  // GC automatically frees filtered at scope exit
end.
```

### Basic Cache Example

```pascal
var
  cache: TActionCache<Integer, string>;
  
cache := TActionCache<Integer, string>.Create(
  nil,  // Owner
  idpFree,  // Dispose cached strings
  TActionCache<Integer, string>.TValueFetcher.FromGlobalFunction(@MyFetchFunc),
  TActionCache<Integer, string>.TSizeEstimator.FromGlobalFunction(@MyEstimateFunc),
  crpLeastUsed,  // Eviction policy
  epSinceFetchedTime,  // Expiration policy
  nvpCacheNormally,  // Null handling
  1024 * 1024,  // Max size in bytes
  TTimeSpan.FromSeconds(60)  // Expiration duration
);

try
  // Automatically fetches on first access
  WriteLn(cache.Get(42).Value);
finally
  cache.Free;
end;
```

## Extensibility & Customization

The framework provides multiple extension points:

### Custom Comparers and Predicates

Implement `IComparer<T>` or `IPredicate<T>` or use tool classes to create them from functions:

```pascal
// From nested function
myComparer := TComparerTool<TMyType>.FromFunc(
  function(constref L, R: TMyType): Integer
  begin
    Result := CompareStr(L.Name, R.Name);
  end
);

// From object method
myPredicate := TPredicateTool<TMyType>.FromFunc(
  @Self.MyValidationMethod
);
```

### Custom Cache Fetch and Size Logic

`TActionCache` accepts function-based fetchers and size estimators:

```pascal
fetcher := TActionCache<K, V>.TValueFetcher.FromNestedFunction(
  function(const key: K): V
  begin
    // Custom fetch logic
  end
);
```

### Custom Visual Grid Renderers

Each column in `TVisualGrid` can have custom rendering logic:

```pascal
myColumn.Renderer := @MyCustomRenderer;

procedure MyCustomRenderer(Sender: TObject; ACol, ARow: Longint; 
  Canvas: TCanvas; Rect: TRect; State: TGridDrawState; 
  const CellData, RowData: Variant; var Handled: Boolean);
begin
  // Custom drawing logic with full canvas access
  Handled := True;
end;
```

### Wizard Screen Injection

Wizard screens can dynamically modify the wizard path based on user input:

```pascal
procedure TMyWizardScreen.OnNext;
begin
  if SomeCondition then
    UpdatePath(ptInject, [TOptionalScreen])
  else
    UpdatePath(ptReplaceAllNext, [TAlternativeScreen]);
end;
```

### Custom Data Sanitizers

Transform data before display in grids:

```pascal
myColumn.Sanitizer := @MySanitizeFunc;

function MySanitizeFunc(const CellData, RowData: Variant): Variant;
begin
  // Transform data for display
  Result := FormatFloat('0.00', CellData);
end;
```

## Threading / Performance / Safety Notes

### Thread Safety

- **Cache Components**: `TCacheBase` and `TActionCache` are thread-safe using read-write locks. Multiple threads can safely read and write to the same cache instance.
- **Collections**: Standard collection classes from `Generics.Collections` are **not** thread-safe. Application code must provide synchronization when sharing collections across threads.
- **Event System**: `TThreadNotify` provides thread-safe event dispatching with automatic marshalling to target threads. Main-thread invocation is explicitly supported.
- **Memory Management**: `TDisposables` is **not** thread-safe. Each thread should maintain its own disposables scope.

### Performance Characteristics

- **Cache Lookups**: O(1) average case using `TDictionary` internally. Eviction operations vary by reap policy: O(n) for sorting-based policies, O(1) for ASAP.
- **Sorted Collections**: `TSortedHashSet<T>` maintains sorted order with O(log n) insertion and O(1) membership testing.
- **Grid Rendering**: `TVisualGrid` uses virtual rendering and only paints visible rows. Paging should be used for datasets exceeding tens of thousands of rows.
- **Variant Operations**: Data rows using variants incur overhead compared to strongly-typed records. This is acceptable for UI binding scenarios but may be unsuitable for compute-intensive inner loops.

### Memory Safety

- **Explicit Dispose Policies**: The framework requires explicit specification of object ownership at collection and cache boundaries. This prevents double-free and leak scenarios but requires developer attention.
- **Scope Management**: `TDisposables` provides reliable cleanup even in the presence of exceptions. Each registered object is freed in reverse registration order with exception isolation.
- **Reference Counting**: Interface-based abstractions (`IComparer`, `IPredicate`) use reference counting. Avoid creating circular references between objects holding interfaces.

### Known Limitations

- **Generic Nesting**: FPC has limitations with nested generics. Some workarounds using type aliases are present in the codebase.
- **TTimeSpan Precision**: The FPC `TTimeSpan` implementation is accurate to millisecond scale, not tick scale like Delphi. This is sufficient for most application-level timing but unsuitable for high-precision measurement.

## Status & Maturity

PascalFramework is **stable and production-ready**. The library has been used in commercial applications since 2017 and has a test suite covering core functionality.

**API Stability**: The public APIs are considered stable. Breaking changes are avoided, though additions and deprecations may occur in future versions.

**Platform Support**: 
- Free Pascal Compiler (FPC) 3.0 and later
- Lazarus IDE 1.8 and later
- Windows, Linux, and macOS

**Testing**: Unit tests exist for core utilities (`UCommon`, `UCache`, `UMemory`, `UCommon.Collections`) using FPCUnit. UI components have example applications demonstrating functionality.

**Maintenance**: The project is actively maintained by Herman Schoenfeld and the Sphere10 team. Issues and pull requests are accepted via GitHub.

**Backward Compatibility**: The project aims to maintain backward compatibility within major versions. Deprecated features will be marked before removal.

## License

PascalFramework is distributed under the **MIT License**. See the [LICENSE](LICENSE) file for complete terms.

In summary: The software is provided as-is without warranty. You are free to use, modify, and distribute it for any purpose, including commercial applications, provided the license text and copyright notice are retained.
