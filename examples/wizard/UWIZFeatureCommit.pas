unit UWIZFeatureCommit;

{ Copyright (c) 2026 Herman Schoenfeld <https://www.sphere10.com>

  A confirmation boundary that suppresses backward navigation.

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
  TWIZFeatureCommit = class(TWIZFeatureBase)
    FTitleLabel : TLabel;
    FDescriptionLabel : TLabel;
    FStatusLabel : TLabel;
    FEventLog : TMemo;
    FAcceptCheckBox : TCheckBox;
    FReviewLabel : TLabel;
    FBoundaryLabel : TLabel;
    protected
      function GetEventLog : TMemo; override;
      function GetStatusLabel : TLabel; override;
    public
      procedure OnPresent; override;
      function Validate(out message : AnsiString) : boolean; override;
  end;

implementation

{$R *.lfm}

function TWIZFeatureCommit.GetEventLog : TMemo;
begin
  Result := FEventLog;
end;

function TWIZFeatureCommit.GetStatusLabel : TLabel;
begin
  Result := FStatusLabel;
end;

procedure TWIZFeatureCommit.OnPresent;
begin
  FReviewLabel.Caption := Format('Ready to review %s, age %d.', [Model.Name, Model.Age]);
  inherited OnPresent;
end;

function TWIZFeatureCommit.Validate(out message : AnsiString) : boolean;
begin
  Result := FAcceptCheckBox.Checked;
  message := '';
  if NOT Result then begin
    message := 'Accept the setup before opening the summary';
    Model.RecordEvent('Commit confirmation rejected; summary remains unavailable');
  end;
end;

end.
