program GridViewportProbe;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>
  Distributed under the MIT software license; see LICENSE. }

{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}

uses {$IFDEF FPC}Interfaces,{$ENDIF} Forms, Classes, SysUtils,
  UVisualGrid.Viewport.Checks, UVisualGrid.Paging.Checks, UVisualGrid.Loading.Checks,
  UVisualGrid.Selection.Checks, UVisualGrid.Worker.Checks;

var
  LLog: TStringList;
  LScenario: TGridViewportScenario;
  LPaging: TGridPagingScenario;
  LLoading: TGridLoadingScenario;
  LSelection: TGridSelectionScenario;
  LCancellation: TGridActiveCancellationScenario;
begin
  Application.Initialize;
  LLog := TStringList.Create;
  try
    try
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
          CheckVisualGridSelection(LSelection,LLog);
        LLog.Add('PASS complete native grid selection checks');
      end
      else
      begin
        for LScenario := Low(TGridViewportScenario) to High(TGridViewportScenario) do
          CheckVisualGridViewport(LScenario,LLog);
        CheckVisualGridShowAllCompatibility(LLog);
        CheckVisualGridDeferredParenting(LLog);
        for LPaging := Low(TGridPagingScenario) to High(TGridPagingScenario) do
          CheckVisualGridPaging(LPaging,LLog);
        for LLoading := Low(TGridLoadingScenario) to High(TGridLoadingScenario) do
          CheckVisualGridLoading(LLoading,LLog);
        for LSelection := Low(TGridSelectionScenario) to High(TGridSelectionScenario) do
          CheckVisualGridSelection(LSelection,LLog);
        for LCancellation := Low(TGridActiveCancellationScenario) to High(TGridActiveCancellationScenario) do
          CheckVisualGridActiveCancellation(LCancellation);
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
    LLog.SaveToFile(ParamStr(1));
  finally
    LLog.Free;
  end;
end.
