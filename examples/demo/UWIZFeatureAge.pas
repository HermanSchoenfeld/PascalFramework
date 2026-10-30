unit UWIZFeatureAge;

{ Copyright (c) 2026 Herman Schoenfeld <https://www.sphere10.com>

  Age validation and an interactive wizard route playground.

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
  TWIZFeatureAge = class(TWIZFeatureBase)
    FTitleLabel : TLabel;
    FDescriptionLabel : TLabel;
    FStatusLabel : TLabel;
    FEventLog : TMemo;
    FAgeLabel : TLabel;
    FAgeEdit : TEdit;
    FIncludeOptionalCheckBox : TCheckBox;
    FRouteLabel : TLabel;
    FRouteDescriptionLabel : TLabel;
    FInjectOptionalButton : TButton;
    FReplaceNextButton : TButton;
    FReplaceAllButton : TButton;
    FRemoveNextButton : TButton;
    FRemoveScreenButton : TButton;
    FSnapshotButton : TButton;
    procedure IncludeOptionalChanged(Sender : TObject);
    procedure InjectOptionalClick(Sender : TObject);
    procedure ReplaceNextClick(Sender : TObject);
    procedure ReplaceAllClick(Sender : TObject);
    procedure RemoveNextClick(Sender : TObject);
    procedure RemoveScreenClick(Sender : TObject);
    procedure SnapshotClick(Sender : TObject);
    protected
      procedure RefreshLog; override;
      function GetEventLog : TMemo; override;
      function GetStatusLabel : TLabel; override;
    public
      procedure OnPresent; override;
      procedure OnNext; override;
      function Validate(out message : String) : boolean; override;
  end;

implementation

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

procedure TWIZFeatureAge.RefreshLog;
begin
  if Assigned(DemoModel) then
    FIncludeOptionalCheckBox.Checked := Model.IncludeOptional;
  inherited RefreshLog;
end;

function TWIZFeatureAge.GetEventLog : TMemo;
begin
  Result := FEventLog;
end;

function TWIZFeatureAge.GetStatusLabel : TLabel;
begin
  Result := FStatusLabel;
end;

procedure TWIZFeatureAge.OnPresent;
begin
  FAgeEdit.Text := IntToStr(Model.Age);
  FIncludeOptionalCheckBox.Checked := Model.IncludeOptional;
  inherited OnPresent;
end;

function TWIZFeatureAge.Validate(out message : String) : boolean;
var
  age : Integer;
begin
  message := '';
  Result := TryStrToInt(Trim(FAgeEdit.Text), age) and (age >= 0);
  if NOT Result then begin
    message := 'Enter an age of zero or more using whole numbers';
    Model.RecordEvent('Age validation rejected; accepted model age unchanged');
  end;
end;

procedure TWIZFeatureAge.OnNext;
begin
  inherited OnNext;
  Model.Age := StrToInt(Trim(FAgeEdit.Text));
  Model.IncludeOptional := FIncludeOptionalCheckBox.Checked;
  Model.RecordEvent('Accepted age committed: ' + IntToStr(Model.Age));
  if Assigned(Model.ConfigureAgeRoute) then Model.ConfigureAgeRoute;
end;

procedure TWIZFeatureAge.IncludeOptionalChanged(Sender : TObject);
begin
  if Assigned(DemoModel) then Model.IncludeOptional := FIncludeOptionalCheckBox.Checked;
end;

procedure TWIZFeatureAge.InjectOptionalClick(Sender : TObject);
begin
  FIncludeOptionalCheckBox.Checked := true;
  Model.IncludeOptional := true;
  Model.RequestRouteAction(fraInjectOptional);
end;

procedure TWIZFeatureAge.ReplaceNextClick(Sender : TObject);
begin
  Model.RequestRouteAction(fraReplaceNext);
end;

procedure TWIZFeatureAge.ReplaceAllClick(Sender : TObject);
begin
  Model.RequestRouteAction(fraReplaceAll);
end;

procedure TWIZFeatureAge.RemoveNextClick(Sender : TObject);
begin
  FIncludeOptionalCheckBox.Checked := false;
  Model.IncludeOptional := false;
  Model.RequestRouteAction(fraRemoveNext);
end;

procedure TWIZFeatureAge.RemoveScreenClick(Sender : TObject);
begin
  FIncludeOptionalCheckBox.Checked := false;
  Model.IncludeOptional := false;
  Model.RequestRouteAction(fraRemoveScreen);
end;

procedure TWIZFeatureAge.SnapshotClick(Sender : TObject);
begin
  Model.RequestRouteAction(fraPathSnapshot);
end;

end.
