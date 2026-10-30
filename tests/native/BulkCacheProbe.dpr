program BulkCacheProbe;

{ Copyright © 2026 Herman Schoenfeld <https://www.sphere10.com>
  Bulk cache contracts and the runnable public cache examples.
  Distributed under the MIT software license; see LICENSE. }

{$IFDEF FPC}{$MODE Delphi}{$ELSE}{$APPTYPE CONSOLE}{$ENDIF}

uses SysUtils, Classes, UBulkCacheChecks, UCacheApiExamples;

var
  i, currentCheck: Integer;
  lines: TStringList;
begin
  {$IFNDEF FPC}ReportMemoryLeaksOnShutdown := True;{$ENDIF}
  currentCheck := 0;
  lines := TStringList.Create;
  try
    try
      for i := 1 to BulkCacheCheckCount do begin
        currentCheck := i;
        RunBulkCacheCheck(i);
        lines.Add('PASS bulk check ' + IntToStr(i));
      end;
      currentCheck := 0;
      RunCacheApiExamples(lines);
      lines.Add('PASS all bulk cache checks and public cache examples');
    except
      on E: Exception do begin
        ExitCode := 1;
        lines.Add(Format('FAIL check %d %s: %s',[currentCheck,E.ClassName,E.Message]));
      end;
    end;
    // The receipt and natural exit are both checked by the external runner.
    lines.Add('EXIT_CODE=' + IntToStr(ExitCode));
    if ParamStr(1) <> '' then lines.SaveToFile(ParamStr(1))
    else WriteLn(lines.Text);
  finally
    lines.Free;
  end;
end.
