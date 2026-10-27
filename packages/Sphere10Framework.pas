{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit Sphere10Framework;

interface

uses
  UCache, UCommon, UCommon.Collections, UCommon.Data, UCommon.UI, UMemory,
  UVisualGrid, UWizard, Generics.Collections, Generics.Defaults, Generics.Hashes,
  Generics.Helpers, Generics.MemoryExpanders, Generics.Strings, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('UVisualGrid', @UVisualGrid.Register);
end;

initialization
  RegisterPackage('Sphere10Framework', @Register);
end.
