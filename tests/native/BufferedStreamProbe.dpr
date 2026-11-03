program BufferedStreamProbe;

{ Copyright © 2026 Herman Schoenfeld <https://www.sphere10.com>
  Runs the same stream contracts as the registered FPCUnit suite.
  Distributed under the MIT software license; see LICENSE. }

{$IFDEF FPC}{$MODE Delphi}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}

uses {$IFDEF FPC}heaptrc,{$ENDIF} SysUtils, Classes, UStreams.Checks;

var
  I, LFailures: Integer;
  LLines: TStringList;
begin
  {$IFDEF FPC}
  if ParamStr(1)<>'' then SetHeapTraceOutput(ParamStr(1)+'.heap.log');
  {$ELSE}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  LLines := TStringList.Create;
  try
    LFailures := 0;
    for I := 1 to BufferedStreamCheckCount do begin
      try
        RunBufferedStreamCheck(I);
        LLines.Add('PASS '+IntToStr(I)+' '+BufferedStreamCheckName(I));
      except
        on E: Exception do begin
          Inc(LFailures);
          LLines.Add('FAIL '+IntToStr(I)+' '+BufferedStreamCheckName(I)+' '+E.ClassName+': '+E.Message);
        end;
      end;
    end;
    if LFailures=0 then LLines.Add('PASS all '+IntToStr(BufferedStreamCheckCount)+' buffered stream checks')
    else ExitCode := 1;
    LLines.Add('EXIT_CODE='+IntToStr(ExitCode));
    if ParamStr(1)<>'' then LLines.SaveToFile(ParamStr(1))
    else WriteLn(LLines.Text);
  finally
    LLines.Free;
  end;
end.
