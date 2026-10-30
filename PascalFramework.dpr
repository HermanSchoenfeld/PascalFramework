program PascalFramework;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>. MIT license. }

{$IFDEF FPC}{$mode Delphi}{$H+}{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  {$IFDEF FPC}Interfaces, Forms,{$ELSE}Vcl.Forms,{$ENDIF}
  UFRMDemoMain;

{$R *.res}

begin
  Application.Initialize;
  {$IFNDEF FPC}Application.MainFormOnTaskbar := True;{$ENDIF}
  Application.CreateForm(TFRMDemoMain, DemoMainForm);
  Application.Run;
end.