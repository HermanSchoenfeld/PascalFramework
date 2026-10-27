unit UWIZFeatureSummary;

{ Copyright (c) 2026 Sphere 10 Software <https://www.sphere10.com>

  Completion, cancellation and retry behavior for the feature wizard.

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
  TWIZFeatureSummary = class(TWIZFeatureBase)
    FTitleLabel : TLabel;
    FDescriptionLabel : TLabel;
    FStatusLabel : TLabel;
    FEventLog : TMemo;
    FSummaryLabel : TLabel;
    FFinishOutcomeLabel : TLabel;
    FFinishOutcomeComboBox : TComboBox;
    FCancelOutcomeLabel : TLabel;
    FCancelOutcomeComboBox : TComboBox;
    FCanCancelCheckBox : TCheckBox;
    FProbeReentryCheckBox : TCheckBox;
    FCancelButton : TButton;
    procedure FinishOutcomeChanged(Sender : TObject);
    procedure CancelOutcomeChanged(Sender : TObject);
    procedure CanCancelChanged(Sender : TObject);
    procedure ProbeReentryChanged(Sender : TObject);
    procedure CancelClick(Sender : TObject);
    protected
      function GetEventLog : TMemo; override;
      function GetStatusLabel : TLabel; override;
    public
      procedure OnPresent; override;
  end;

implementation

{$R *.lfm}

function TWIZFeatureSummary.GetEventLog : TMemo;
begin
  Result := FEventLog;
end;

function TWIZFeatureSummary.GetStatusLabel : TLabel;
begin
  Result := FStatusLabel;
end;

procedure TWIZFeatureSummary.OnPresent;
begin
  FSummaryLabel.Caption := Format('Name: %s    Age: %d    Notes: %s', [Model.Name, Model.Age, Model.Notes]);
  FFinishOutcomeComboBox.ItemIndex := Ord(Model.FinishOutcome);
  FCancelOutcomeComboBox.ItemIndex := Ord(Model.CancelOutcome);
  FCanCancelCheckBox.Checked := Model.CanCancel;
  FProbeReentryCheckBox.Checked := Model.ProbeReentry;
  inherited OnPresent;
end;

procedure TWIZFeatureSummary.FinishOutcomeChanged(Sender : TObject);
begin
  if Assigned(DemoModel) and (FFinishOutcomeComboBox.ItemIndex >= 0) then
    Model.FinishOutcome := TFeatureCallbackOutcome(FFinishOutcomeComboBox.ItemIndex);
end;

procedure TWIZFeatureSummary.CancelOutcomeChanged(Sender : TObject);
begin
  if Assigned(DemoModel) and (FCancelOutcomeComboBox.ItemIndex >= 0) then
    Model.CancelOutcome := TFeatureCallbackOutcome(FCancelOutcomeComboBox.ItemIndex);
end;

procedure TWIZFeatureSummary.CanCancelChanged(Sender : TObject);
begin
  if NOT Assigned(DemoModel) then exit;
  Model.CanCancel := FCanCancelCheckBox.Checked;
  if Assigned(Model.SetCancellationAllowed) then Model.SetCancellationAllowed(Model.CanCancel);
end;

procedure TWIZFeatureSummary.ProbeReentryChanged(Sender : TObject);
begin
  if Assigned(DemoModel) then Model.ProbeReentry := FProbeReentryCheckBox.Checked;
end;

procedure TWIZFeatureSummary.CancelClick(Sender : TObject);
begin
  if Assigned(Model.RequestCancel) then Model.RequestCancel;
end;

end.
