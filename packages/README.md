# Sphere 10 Pascal Framework packages

The optional `Sphere10Framework.*` library packages and project groups build the
framework units for Delphi and Lazarus. The [demo](../examples/demo/README.md)
has the runnable projects.

## Delphi 13

Open [Sphere10Framework.dproj](../Sphere10Framework.dproj) in the repository root,
choose Win64 or Win32 and Release or Debug, then choose **Project > Build**. The
[runtime package source](../Sphere10Framework.dpk) requires Delphi's `rtl`, `vcl`,
`vclx` and `vclimg` packages.

Output goes to `lib/Delphi/<platform>/<configuration>/`, in `dcu`, `dcp`, `bpl`
and `res` subdirectories. Keep the leading `.\` on the project's output paths. The
package is runtime only and installs no IDE controls.

The [test guide](../tests/README.md) covers the compiler-specific checks.

Without the package, add only `src/Sphere10` to the application's unit search path:

```pascal
uses
  UMemory, UCommon, UCommon.Collections, UCache, UCommon.Data,
  UCommon.UI, UConcurrency, UStreams, UVisualGrid, UWizard;
```

If the application compiles the grid sources, also add
[`UVisualGrid.VCL.rc`](../src/Sphere10/UVisualGrid.VCL.rc) to the project. The
package already includes this resource compiler entry:

```xml
<PropertyGroup>
  <BRCC_IncludePath>src\Sphere10;$(BRCC_IncludePath)</BRCC_IncludePath>
</PropertyGroup>
<ItemGroup>
  <RcCompile Include="src\Sphere10\UVisualGrid.VCL.rc" />
</ItemGroup>
```

Adjust the relative path, and keep `BRCC_OutputDir` in an ignored build directory.

## Lazarus/FPC

In Lazarus, open [Sphere10Framework.lpk](../Sphere10Framework.lpk) in the repository
root with **Package > Open Package File**, then choose **Compile** in the package
editor. The root [Sphere10Framework.lpg](../Sphere10Framework.lpg) project group
also lists it. The package includes the bundled generic collections and requires
LCLBase and FCL.

Installing its design-time controls is optional and requires an IDE rebuild. For
the demo, run [Sphere10PascalFramework.lpi](../Sphere10PascalFramework.lpi).

When Lazarus regenerates the package source, keep `Sphere10Framework.pas`
consistent with the `.lpk` file list. Generated units belong in the ignored `lib`
output directory.
