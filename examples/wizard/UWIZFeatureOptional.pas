unit UWIZFeatureOptional;

{ Copyright (c) 2026 Herman Schoenfeld <https://www.sphere10.com>

  An optional step retained and owned after route removal.

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
  TWIZFeatureOptional = class(TWIZFeatureBase)
    FTitleLabel : TLabel;
    FDescriptionLabel : TLabel;
    FStatusLabel : TLabel;
    FEventLog : TMemo;
    FNotesLabel : TLabel;
    FNotesMemo : TMemo;
    protected
      function GetEventLog : TMemo; override;
      function GetStatusLabel : TLabel; override;
    public
      procedure OnPresent; override;
      procedure OnNext; override;
      procedure OnPrevious; override;
  end;

implementation

{$R *.lfm}

function TWIZFeatureOptional.GetEventLog : TMemo;
begin
  Result := FEventLog;
end;

function TWIZFeatureOptional.GetStatusLabel : TLabel;
begin
  Result := FStatusLabel;
end;

procedure TWIZFeatureOptional.OnPresent;
begin
  FNotesMemo.Text := Model.Notes;
  inherited OnPresent;
end;

procedure TWIZFeatureOptional.OnNext;
begin
  inherited OnNext;
  Model.Notes := Trim(FNotesMemo.Text);
  Model.RecordEvent('Optional notes committed');
end;

procedure TWIZFeatureOptional.OnPrevious;
begin
  Model.Notes := Trim(FNotesMemo.Text);
  inherited OnPrevious;
end;

end.
