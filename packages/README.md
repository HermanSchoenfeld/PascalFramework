# Sphere 10 Pascal Framework packages

The packages contain Sphere10 units for common utilities, collections,
disposal scopes, caching, data sources, application forms, the loading circle,
visual grid, wizard and shared-memory read/write locking through `UConcurrency`.
The `Sphere10Framework.*` files are optional reusable library packages and
project groups. They are build targets, not runnable applications; the main
[demo](../examples/demo/README.md) has one Delphi and one Lazarus project.

## Delphi 13

Open [Sphere10Framework.dproj](../Sphere10Framework.dproj) in the repository root, choose Win64
or Win32 and a Release or Debug configuration, then choose **Project > Build**.
The [runtime package source](../Sphere10Framework.dpk) lists the library units and
requires Delphi's native `rtl`, `vcl`, `vclx` and `vclimg` packages. Its search
paths use the Sphere10 source directory; Delphi uses its own generic collections.
The package includes `UConcurrency` alongside the grid, wizard and cache units.
Use the [test documentation](../tests/README.md) for compiler-specific unit/native
checks; build the package and source-based demo separately.

Build outputs are separated by platform and configuration beneath
`lib/Delphi/<platform>/<configuration>/`, with `dcu`, `dcp`, `bpl` and
`res` subdirectories. The package is runtime only and does not install controls
or change the IDE toolbox.
Keep the leading `.\` on its output paths so the IDE also resolves the package
relative to the project directory.

To consume the units directly in a Delphi application, add `src/Sphere10` to
its unit search path and use the units normally:

```pascal
uses
  UMemory, UCommon, UCommon.Collections, UCache, UCommon.Data,
  UCommon.UI, UConcurrency, UVisualGrid, UWizard;
```

When using the grid sources directly, also add
[`UVisualGrid.VCL.rc`](../src/Sphere10/UVisualGrid.VCL.rc) to the application
project. The package already includes this resource compiler entry, which builds
the search glyph from its checked-in PNG into the configuration's `res` output:

```xml
<PropertyGroup>
  <BRCC_IncludePath>src\Sphere10;$(BRCC_IncludePath)</BRCC_IncludePath>
</PropertyGroup>
<ItemGroup>
  <RcCompile Include="src\Sphere10\UVisualGrid.VCL.rc" />
</ItemGroup>
```

Adjust the relative path for your application. Keep its `BRCC_OutputDir` in an
ignored build directory; Delphi adds this directory to its resource search path.

## Lazarus / Free Pascal

Open [Sphere10Framework.lpk](../Sphere10Framework.lpk) in the repository root with Lazarus's **Package >
Open Package File** command. It is also a target in the root
[Sphere10Framework.lpg](../Sphere10Framework.lpg) project group.

The package lists the cache, wizard, common utilities, collections, data helpers,
memory helpers and visual grid, together with the bundled generic collections
and required resources. Its search paths are relative to this checkout; it
requires Lazarus's LCLBase and FCL packages. `UVisualGrid` retains its existing
design-time registration procedure.

Choose Compile in the package editor to build the library. This is a library
and component package; run [Sphere10PascalFramework.lpi](../Sphere10PascalFramework.lpi) for the
unified grid, wizard and cache demonstration. Installing design-time controls into an IDE is optional and
requires an IDE rebuild; ordinary project builds do not require installation.

Keep `Sphere10Framework.pas` consistent with the `.lpk` file list when using
Lazarus to regenerate the package source. Generated units belong in the ignored
`lib` output directory.
