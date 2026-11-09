program GridViewportProbe;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>
  Distributed under the MIT software license; see LICENSE. }

{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}

uses {$IFDEF FPC}Interfaces,{$ENDIF} Forms, Classes, SysUtils,
  UVisualGrid.Viewport.Checks, UVisualGrid.Paging.Checks, UVisualGrid.Loading.Checks,
  UVisualGrid.Selection.Checks, UVisualGrid.Worker.Checks;

procedure ReportMissingLogArgument;
begin
  try
    WriteLn(ErrOutput, 'GridViewportProbe: pass the log file path as the first argument.');
  except
    // A GUI build may have no standard error stream; the exit code still reports the failure.
  end;
end;

var
  LLog: TStringList;
  LLogPath: String;
  LScenario: TGridViewportScenario;
  LPaging: TGridPagingScenario;
  LLoading: TGridLoadingScenario;
  LSelection: TGridSelectionScenario;
  LCancellation: TGridActiveCancellationScenario;
begin
  if (ParamCount < 1) or (ParamStr(1) = '') then
  begin
    ReportMissingLogArgument;
    Halt(1);
  end;
  LLogPath := ParamStr(1);
  ExitCode := 1;
  try
    // Preserve completed scenario receipts if the bounded native watchdog fires.
    LLog := TStringList.Create;
    try
      try
        Application.Initialize;
        if GetEnvironmentVariable('PASCAL_GRID_ACTIVE_CANCEL_ONLY') = '1' then
        begin
          for LCancellation := Low(TGridActiveCancellationScenario) to High(TGridActiveCancellationScenario) do
          begin
            CheckVisualGridActiveCancellation(LCancellation);
            LLog.Add('PASS active fetch cancellation scenario ' + IntToStr(Ord(LCancellation)));
          end;
          {$IF defined(MSWINDOWS) and defined(VISUALGRID_TEST_WORKER_START)}
          CheckVisualGridEarlyActiveCancellation;
          LLog.Add('PASS direct public API cancellation before Start');
          {$ENDIF}
          LLog.Add('PASS complete active fetch cancellation checks');
        end
        else if GetEnvironmentVariable('PASCAL_GRID_SELECTION_ONLY') = '1' then
        begin
          for LSelection := Low(TGridSelectionScenario) to High(TGridSelectionScenario) do
          begin
            CheckVisualGridSelection(LSelection,LLog);
            LLog.SaveToFile(LLogPath);
          end;
          LLog.Add('PASS complete native grid selection checks');
        end
        else
        begin
          for LScenario := Low(TGridViewportScenario) to High(TGridViewportScenario) do
          begin
            CheckVisualGridViewport(LScenario,LLog);
            LLog.SaveToFile(LLogPath);
          end;
          CheckVisualGridShowAllCompatibility(LLog);
          CheckVisualGridDeferredParenting(LLog);
          CheckVisualGridFooterCompaction(LLog);
          for LPaging := Low(TGridPagingScenario) to High(TGridPagingScenario) do
          begin
            CheckVisualGridPaging(LPaging,LLog);
            LLog.SaveToFile(LLogPath);
          end;
          for LLoading := Low(TGridLoadingScenario) to High(TGridLoadingScenario) do
          begin
            CheckVisualGridLoading(LLoading,LLog);
            LLog.SaveToFile(LLogPath);
          end;
          for LSelection := Low(TGridSelectionScenario) to High(TGridSelectionScenario) do
          begin
            CheckVisualGridSelection(LSelection,LLog);
            LLog.SaveToFile(LLogPath);
          end;
          for LCancellation := Low(TGridActiveCancellationScenario) to High(TGridActiveCancellationScenario) do
          begin
            CheckVisualGridActiveCancellation(LCancellation);
            LLog.SaveToFile(LLogPath);
          end;
          {$IF defined(MSWINDOWS) and defined(VISUALGRID_TEST_WORKER_START)}
          CheckVisualGridEarlyActiveCancellation;
          {$ENDIF}
          LLog.Add('PASS complete native viewport regression matrix');
        end;
        ExitCode := 0;
      except
        on E: Exception do begin
          LLog.Add('FAIL ' + E.ClassName + ': ' + E.Message);
          ExitCode := 1;
        end;
      end;
      LLog.SaveToFile(LLogPath);
    finally
      LLog.Free;
    end;
  except
    // A log that cannot be written, or a non-Exception raise, must still end with a nonzero exit.
    ExitCode := 1;
  end;
end.
