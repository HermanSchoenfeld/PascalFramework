program FrameworkTestsConsole;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, consoletestrunner,
  UCommon.Tests, UCommon.Collections.Tests, UMemory.Tests,
  UCache.Tests, UWizard.Tests;

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
