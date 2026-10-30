program ThrottleDemo;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>. MIT license. }

{$IFDEF FPC}{$mode Delphi}{$H+}{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  {$IFDEF FPC}Interfaces, Forms,{$ELSE}Vcl.Forms,{$ENDIF}
  UThrottleDemo in 'UThrottleDemo.pas';

begin
  Application.Initialize;
  {$IFNDEF FPC}Application.MainFormOnTaskbar := True;{$ENDIF}
  Application.Title := 'Five-second grid throttle';
  Application.CreateForm(TThrottleDemoForm, ThrottleDemoForm);
  ThrottleDemoForm.InitializeDemo;
  Application.Run;
end.
