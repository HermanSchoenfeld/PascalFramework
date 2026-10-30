program GridViewportProbe;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>
  Distributed under the MIT software license; see LICENSE. }

{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}

uses {$IFDEF FPC}Interfaces,{$ENDIF} Forms, Classes, SysUtils,
  UVisualGrid.Viewport.Checks;

var
  LLog: TStringList;
  LScenario: TGridViewportScenario;
begin
  Application.Initialize;
  LLog := TStringList.Create;
  try
    try
      for LScenario := Low(TGridViewportScenario) to High(TGridViewportScenario) do
        CheckVisualGridViewport(LScenario,LLog);
      LLog.Add('PASS complete native viewport regression matrix');
      ExitCode := 0;
    except
      on E: Exception do begin
        LLog.Add('FAIL ' + E.ClassName + ': ' + E.Message);
        ExitCode := 1;
      end;
    end;
    LLog.SaveToFile(ParamStr(1));
  finally
    LLog.Free;
  end;
end.
