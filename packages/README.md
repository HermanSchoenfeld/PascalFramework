# Sphere10 library package

Open `Sphere10Framework.lpk` with Lazarus's Package > Open Package File command.
It is also a target in the root `Sphere10Framework.lpg` project group.

The package lists the cache, wizard, common utilities, collections, data helpers,
memory helpers and visual grid, together with the bundled generic collections
and required resources. Its search paths are relative to this checkout; it
requires Lazarus's LCLBase and FCL packages. `UVisualGrid` retains its existing
design-time registration procedure.

Choose Compile in the package editor to build the library. This is a library
and component package; use the wizard or test `.lpi` projects to run an
application. Installing design-time controls into an IDE is optional and
requires an IDE rebuild; ordinary project builds do not require installation.

Keep `Sphere10Framework.pas` consistent with the `.lpk` file list when using
Lazarus to regenerate the package source. Generated units belong in the ignored
`packages/lib` output directory.
