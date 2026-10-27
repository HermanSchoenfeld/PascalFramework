unit UWIZFeatureBase;

{ Copyright (c) 2026 Sphere 10 Software <https://www.sphere10.com>

  Shared behavior for the wizard feature demonstration.

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.
}

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, StdCtrls, UCommon, UWizard, UWizardFeatureModel;

type
  { The caller owns the model. Its lifetime encloses the wizard and all screens. }
  TWIZFeatureBase = class(TWizardForm<TWizardFeatureModel>)
    private
      FObservedModel : TWizardFeatureModel;
      procedure ModelChanged(Sender : TObject);
    protected
      function GetEventLog : TMemo; virtual; abstract;
      function GetStatusLabel : TLabel; virtual; abstract;
      procedure RefreshLog; virtual;
    public
      InitializeCount : Integer;
      NextCount : Integer;
      PreviousCount : Integer;
      InitializedName : AnsiString;
      InitializedAge : Integer;
      destructor Destroy; override;
      procedure Initialize; override;
      procedure OnPresent; override;
      procedure OnNext; override;
      procedure OnPrevious; override;
      property DemoModel : TWizardFeatureModel read FObservedModel;
  end;

implementation

destructor TWIZFeatureBase.Destroy;
begin
  if Assigned(FObservedModel) then begin
    FObservedModel.ChangedEvent.Remove(ModelChanged);
    inc(FObservedModel.DestroyedCount);
    FObservedModel.RecordEvent(ClassName + ' destroyed; model remains caller-owned');
  end;
  inherited Destroy;
end;

procedure TWIZFeatureBase.Initialize;
begin
  inherited Initialize;
  FObservedModel := Model;
  InitializedName := Model.Name;
  InitializedAge := Model.Age;
  inc(InitializeCount);
  inc(Model.InitializedCount);
  Model.ChangedEvent.Add(ModelChanged);
  Model.RecordEvent(ClassName + ' initialized with the shared model');
end;

procedure TWIZFeatureBase.OnPresent;
begin
  inherited OnPresent;
  Model.RecordEvent(ClassName + ' presented');
  RefreshLog;
end;

procedure TWIZFeatureBase.OnNext;
begin
  inherited OnNext;
  inc(NextCount);
  Model.RecordEvent(ClassName + ' OnNext after accepted validation');
  if Model.ProbeReentry and Assigned(Model.TestReentry) then
    Model.TestReentry;
end;

procedure TWIZFeatureBase.OnPrevious;
begin
  inherited OnPrevious;
  inc(PreviousCount);
  Model.RecordEvent(ClassName + ' OnPrevious');
end;

procedure TWIZFeatureBase.ModelChanged(Sender : TObject);
begin
  RefreshLog;
end;

procedure TWIZFeatureBase.RefreshLog;
begin
  if NOT Assigned(FObservedModel) then exit;
  GetEventLog.Lines.Assign(FObservedModel.Events);
  GetEventLog.SelStart := Length(GetEventLog.Text);
  GetStatusLabel.Caption := FObservedModel.StatusText + LineEnding +
    Format('Initialized: %d   Changes: %d   Finished events: %d   Reentry rejected: %d',
      [FObservedModel.InitializedCount, FObservedModel.ChangedCount,
       FObservedModel.FinishedCount, FObservedModel.ReentryRejectedCount]);
end;

end.
