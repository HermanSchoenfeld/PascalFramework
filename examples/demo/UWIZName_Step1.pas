unit UWIZName_Step1;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, {$IFDEF FPC}FileUtil,{$ENDIF} Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, UWizard, UCommon;

type
  { TWIZName_Step1 }
  TWIZName_Step1 = class(TWizardForm<TGenericWizardBag>)
    FSomeButton: TBitBtn;
    FMustBeCheckedCheckBox: TCheckBox;
    FNameEdit: TEdit;
    FDimensionLabel: TLabel;
    Label1: TLabel;
    rbPathA: TRadioButton;
    rbPathB: TRadioButton;
    StaticText1: TStaticText;
    procedure FNameEditEditingDone(Sender: TObject);
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

uses UWIZName_Step1A, UWIZName_Step1B, UWIZName_Step2;

{%region TWIZName_Step1}

procedure TWIZName_Step1.FNameEditEditingDone(Sender: TObject);
begin
  self.Model['Name'] := Variant(FNameEdit.Text);
end;

procedure TWIZName_Step1.UpdateDimensionLabel(Sender: TObject);
begin
  FDimensionLabel.Caption := Width.ToString + ' x ' + Height.ToString;
end;

procedure TWIZName_Step1.Initialize;
begin
  // form level initialise
end;

procedure TWIZName_Step1.OnPresent;
begin
  // Display value of property bag
  FNameEdit.Text := Model['Name'];
end;

procedure TWIZName_Step1.OnPrevious;
begin

end;

procedure TWIZName_Step1.OnNext;
begin
  if rbPathA.Checked then
    UpdatePath(ptInject, [TWIZName_Step1A, TWIZName_Step1B])
  else
    UpdatePath(ptReplaceAllNext, [TWIZName_Step1B, TWIZName_Step1A, TWIZName_Step2]);
end;

function TWIZName_Step1.Validate(out message : String) : boolean;
begin
  if FMustBeCheckedCheckBox.Checked then
  begin
    Validate := true;
    message := '';
  end else begin
    Validate := false;
    message := 'Please check checkbox';
  end;
end;

{%endregion}

end.
