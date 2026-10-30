unit UWIZFeatureName;

{ Copyright (c) 2026 Herman Schoenfeld <https://www.sphere10.com>

  Name validation and dynamic successor registration.

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.
}

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, UWIZFeatureBase, UWizardFeatureModel;

type
  TWIZFeatureName = class(TWIZFeatureBase)
    FTitleLabel : TLabel;
    FDescriptionLabel : TLabel;
    FStatusLabel : TLabel;
    FEventLog : TMemo;
    FNameLabel : TLabel;
    FNameEdit : TEdit;
    FConfirmedCheckBox : TCheckBox;
    FRegisterSuccessorCheckBox : TCheckBox;
    FRepeatInjectionCheckBox : TCheckBox;
    protected
      function GetEventLog : TMemo; override;
      function GetStatusLabel : TLabel; override;
    public
      procedure Initialize; override;
      procedure OnPresent; override;
      procedure OnNext; override;
      function Validate(out message : String) : boolean; override;
  end;

implementation

uses UWizard;

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

function TWIZFeatureName.GetEventLog : TMemo;
begin
  Result := FEventLog;
end;

function TWIZFeatureName.GetStatusLabel : TLabel;
begin
  Result := FStatusLabel;
end;

procedure TWIZFeatureName.Initialize;
begin
  Traits := [wstAssumeHasNext];
  inherited Initialize;
end;

procedure TWIZFeatureName.OnPresent;
begin
  FNameEdit.Text := Model.Name;
  FRegisterSuccessorCheckBox.Checked := Model.RegisterSuccessor;
  FRepeatInjectionCheckBox.Checked := Model.RepeatInjection;
  inherited OnPresent;
end;

function TWIZFeatureName.Validate(out message : String) : boolean;
begin
  message := '';
  if Trim(FNameEdit.Text) = '' then
    message := 'Enter a name before continuing'
  else if NOT FConfirmedCheckBox.Checked then
    message := 'Confirm the name before continuing';
  Result := message = '';
  if NOT Result then Model.RecordEvent('Name validation rejected; model and route unchanged');
end;

procedure TWIZFeatureName.OnNext;
begin
  inherited OnNext;
  Model.Name := Trim(FNameEdit.Text);
  Model.RegisterSuccessor := FRegisterSuccessorCheckBox.Checked;
  Model.RepeatInjection := FRepeatInjectionCheckBox.Checked;
  Model.RecordEvent('Accepted name committed: ' + Model.Name);
  if Assigned(Model.ConfigureInitialRoute) then Model.ConfigureInitialRoute;
end;

end.
