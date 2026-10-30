unit UWIZName_Step1B;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, {$IFDEF FPC}FileUtil,{$ENDIF} Forms, Controls, Graphics, Dialogs, StdCtrls,
  UWizard;

type

  { TWIZName_Step1B }

  TWIZName_Step1B = class(TWizardForm<TGenericWizardBag>)
    Label1: TLabel;
  private
    { private declarations }
  public
    { public declarations }
  end;


implementation

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

{ TWIZName_Step1B }


end.

