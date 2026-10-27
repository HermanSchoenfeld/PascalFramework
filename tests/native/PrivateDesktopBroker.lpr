program PrivateDesktopBroker;

{ Copyright (c) 2026 Sphere 10 Software <https://www.sphere10.com>

  Native wizard regression checks on a separate Windows desktop. The broker
  never switches the input desktop; all commands target only its own QA child.

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.
}


{$mode delphi}

uses Windows, SysUtils;

var
  desktop : HDESK;
  startup : TStartupInfo;
  child : TProcessInformation;
  desktopName, desktopPath, command, logPath : AnsiString;
  exitCode, waitResult : DWORD;
begin
  if ParamCount <> 2 then Halt(64);
  desktopName := 'Sphere10WizardQA_' + IntToStr(GetCurrentProcessId);
  desktopPath := 'WinSta0\' + desktopName;
  logPath := ParamStr(2);
  exitCode := 1;
  try
    desktop := CreateDesktop(PChar(desktopName), nil, nil, 0, GENERIC_ALL, nil);
    if desktop = 0 then RaiseLastOSError;
    try
      FillChar(startup, SizeOf(startup), 0);
      FillChar(child, SizeOf(child), 0);
      startup.cb := SizeOf(startup);
      startup.lpDesktop := PChar(desktopPath);
      startup.dwFlags := STARTF_USESHOWWINDOW;
      startup.wShowWindow := SW_SHOW;
      command := '"' + ParamStr(1) + '" "' + logPath + '"';
      if NOT CreateProcess(nil, PChar(command), nil, nil, false, 0, nil, nil, @startup, @child) then
        RaiseLastOSError;
      try
        Writeln('Started own QA child PID ', child.dwProcessId, ' on private desktop ', desktopPath, '; input desktop unchanged');
        waitResult := WaitForSingleObject(child.hProcess, 20000);
        if waitResult = WAIT_TIMEOUT then begin
          TerminateProcess(child.hProcess, 124);
          WaitForSingleObject(child.hProcess, 5000);
          Writeln('Watchdog terminated only QA child PID ', child.dwProcessId);
          exitCode := 124;
        end else begin
          if waitResult <> WAIT_OBJECT_0 then RaiseLastOSError;
          if NOT GetExitCodeProcess(child.hProcess, exitCode) then RaiseLastOSError;
          Writeln('QA child exited ', exitCode, '; log: ', logPath);
        end;
      finally
        CloseHandle(child.hThread);
        CloseHandle(child.hProcess);
      end;
    finally
      CloseDesktop(desktop);
    end;
  except
    on E : Exception do begin
      Writeln('Private desktop QA failed: ', E.Message);
      exitCode := 1;
    end;
  end;
  Halt(exitCode);
end.
