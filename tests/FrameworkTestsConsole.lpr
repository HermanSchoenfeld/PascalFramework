program FrameworkTestsConsole;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, consoletestrunner,
  UCommon.Tests, UCommon.Collections.Tests, UCommon.Data.Tests, UCommon.UI.Tests, UVisualGrid.Tests,
  UVisualGrid.Refresh.Tests, UFramework.UI.Integration.Tests, UMemory.Tests,
  UCache.Tests, UWizard.Tests, UWizardDemo.Tests, UConcurrency.Tests,
  UScope.Tests, UReadWriteScope.Tests;

var
  runner : TTestRunner;
begin
  Forms.Application.Initialize;
  DefaultFormat := fPlain;
  DefaultRunAllTests := true;
  runner := TTestRunner.Create(nil);
  try
    runner.Initialize;
    runner.Run;
  finally
    runner.Free;
  end;
end.
