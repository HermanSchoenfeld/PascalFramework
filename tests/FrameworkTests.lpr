program FrameworkTests;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, Generics.Collections, generics.defaults,
  generics.hashes, generics.helpers, generics.memoryexpanders, generics.strings,
  UCommon.Collections, UCommon.Tests, UCommon.Collections.Tests, UCommon.Data.Tests, UCommon.UI.Tests, UVisualGrid.Tests,
  UVisualGrid.Refresh.Tests, UFramework.UI.Integration.Tests, UMemory.Tests,
  UCache.Tests, UWizard.Tests, UWizardDemo.Tests, UConcurrency.Tests,
  UScope.Tests, UReadWriteScope.Tests;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

