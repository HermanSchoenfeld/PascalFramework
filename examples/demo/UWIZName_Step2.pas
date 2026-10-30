unit UWIZName_Step2;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, {$IFDEF FPC}FileUtil,{$ENDIF} Forms, Controls, Graphics, Dialogs, StdCtrls, UWizard, UCommon;

type

  { TWIZName_Step2 }

  TWIZName_Step2 = class(TWizardForm<TGenericWizardBag>)
    FDimensionLabel: TLabel;
    FMustBeCheckedCheckBox: TCheckBox;
    Label1: TLabel;
    FNameLabel: TLabel;
    Label2: TLabel;
    FAgeLabel: TLabel;
    procedure UpdateDimensionLabel(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    procedure Initialize; override;
    procedure OnPresent; override;
    procedure OnPrevious; override;
    procedure OnNext; override;
    function Validate(out message : String) : boolean; override;
  end;



implementation

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

procedure TWIZName_Step2.UpdateDimensionLabel(Sender: TObject);
begin
  FDimensionLabel.Caption := Width.ToString + ' x ' + Height.ToString;
end;



procedure TWIZName_Step2.Initialize;
begin

end;

procedure TWIZName_Step2.OnPresent;
begin
  FNameLabel.Caption := Model['Name'];
end;

procedure TWIZName_Step2.OnPrevious;
begin
  ShowMessage('TWIZName_Step2 OnPrevious');

end;

procedure TWIZName_Step2.OnNext;
begin
  ShowMessage('TWIZName_Step2 OnNext');
end;

function TWIZName_Step2.Validate(out message : String) : boolean;
begin
  Result := FMustBeCheckedCheckBox.Checked;
  if NOT result then
    message := 'Check the checkbox';
end;

end.

