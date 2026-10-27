program FrameworkTests;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, Generics.Collections, generics.defaults,
  generics.hashes, generics.helpers, generics.memoryexpanders, generics.strings,
  UCommon.Collections, UCommon.Tests, UCommon.Collections.Tests, UMemory.Tests,
  UCache.Tests;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

