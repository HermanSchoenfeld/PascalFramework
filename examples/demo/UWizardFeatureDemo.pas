unit UWizardFeatureDemo;

{ Copyright (c) 2026 Herman Schoenfeld <https://www.sphere10.com>

  Wizard feature showcase controller. Application policy stays in this example.

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.
}

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, UCommon, UWizard, UWizardFeatureModel;

type
  { Screen forms belong to the wizard. AModel and its event history belong to
    the caller, so the history can show disposal after the modal flow ends. }
  TWizardFeatureDemo = class(TWizard<TWizardFeatureModel>)
    private
      FDemoModel : TWizardFeatureModel;
      FLastFinishOutcome : TFeatureCallbackOutcome;
      FLastCancelOutcome : TFeatureCallbackOutcome;
      FFinishOutcomeAttempts : Integer;
      FCancelOutcomeAttempts : Integer;
      procedure HandleChanged(Sender : TObject);
      procedure HandleFinished(Sender : TObject);
      procedure ConfigureInitialRoute;
      procedure ConfigureAgeRoute;
      procedure TestReentry;
      procedure CancelFromScreen;
      procedure RecordStatus;
    protected
      function DetermineHasPrevious : boolean; override;
      function FinishRequested(out message : String) : boolean; override;
      function CancelRequested(out message : String) : boolean; override;
      procedure ShowError(const message : String); override;
    public
      constructor Create(AOwner : TComponent; AModel : TWizardFeatureModel);
      destructor Destroy; override;
      property DemoModel : TWizardFeatureModel read FDemoModel;
      function DescribePath : String;
      procedure ApplyRouteAction(AAction : TFeatureRouteAction);
      procedure SetCancellationAllowed(AAllowed : boolean);
      function TryNext(out message : String) : boolean; override;
      function Finish(out message : String) : boolean; override;
      function Cancel(out message : String) : boolean; override;
  end;

implementation

uses
  UWIZFeatureName, UWIZFeatureAge, UWIZFeatureOptional, UWIZFeatureCommit, UWIZFeatureSummary;

constructor TWizardFeatureDemo.Create(AOwner : TComponent; AModel : TWizardFeatureModel);
begin
  inherited Create(AOwner, [TWIZFeatureName]);
  if AModel = nil then raise Exception.Create('The feature demo needs a model');
  FDemoModel := AModel;
  TitleText := 'Sphere10 wizard feature showcase';
  NextText := '&Continue';
  PreviousText := '&Back';
  FinishText := '&Create project';
  IsCancellable := AModel.CanCancel;
  FLastFinishOutcome := AModel.FinishOutcome;
  FLastCancelOutcome := AModel.CancelOutcome;
  AModel.RouteAction := ApplyRouteAction;
  AModel.ConfigureInitialRoute := ConfigureInitialRoute;
  AModel.ConfigureAgeRoute := ConfigureAgeRoute;
  AModel.TestReentry := TestReentry;
  AModel.RequestCancel := CancelFromScreen;
  AModel.SetCancellationAllowed := SetCancellationAllowed;
  ChangedEvent.Add(HandleChanged);
  FinishedEvent.Add(HandleFinished);
  AModel.RecordEvent('Created wizard with one dynamic Name screen; the model remains caller-owned');
end;

destructor TWizardFeatureDemo.Destroy;
begin
  if Assigned(FDemoModel) then begin
    FDemoModel.RouteAction := nil;
    FDemoModel.ConfigureInitialRoute := nil;
    FDemoModel.ConfigureAgeRoute := nil;
    FDemoModel.TestReentry := nil;
    FDemoModel.RequestCancel := nil;
    FDemoModel.SetCancellationAllowed := nil;
    ChangedEvent.Remove(HandleChanged);
    FinishedEvent.Remove(HandleFinished);
    FDemoModel.RecordEvent('Disposing the wizard and every screen, including screens removed from its route');
  end;
  inherited Destroy;
end;

function TWizardFeatureDemo.DescribePath : String;
var
  path : TWizardScreenPath;
  i : Integer;
begin
  Result := '';
  path := Screens;
  for i := Low(path) to High(path) do begin
    if i > Low(path) then Result := Result + ' > ';
    Result := Result + path[i].ClassName;
  end;
end;

procedure TWizardFeatureDemo.RecordStatus;
const
  stateNames : array[TWizardState] of String = ('Active', 'Finishing', 'Cancelling', 'Finished', 'Cancelled');
begin
  FDemoModel.StatusText := Format('%s | Busy: %s | Step %d of %d | Reentry blocked: %d',
    [stateNames[State], BoolToStr(IsBusy, true), CurrentScreenIndex + 1, Length(Screens), FDemoModel.ReentryRejectedCount]);
end;

procedure TWizardFeatureDemo.HandleChanged(Sender : TObject);
begin
  inc(FDemoModel.ChangedCount);
  RecordStatus;
  FDemoModel.RecordEvent('Changed: ' + FDemoModel.StatusText);
end;

procedure TWizardFeatureDemo.HandleFinished(Sender : TObject);
begin
  inc(FDemoModel.FinishedCount);
  RecordStatus;
  FDemoModel.RecordEvent('Finished notification: accepted exactly once');
end;

procedure TWizardFeatureDemo.ConfigureInitialRoute;
var
  initialCount : Integer;
begin
  if NOT FDemoModel.RegisterSuccessor then begin
    FDemoModel.RecordEvent('No successor registered: the dynamic screen must stay active and can be retried');
    exit;
  end;
  UpdatePath(ptInject, [TWIZFeatureAge, TWIZFeatureCommit, TWIZFeatureSummary]);
  initialCount := Length(Screens);
  if FDemoModel.RepeatInjection then begin
    UpdatePath(ptInject, [TWIZFeatureAge, TWIZFeatureCommit, TWIZFeatureSummary]);
    FDemoModel.RecordEvent(Format('Repeated initial injection: %d screens before and %d after', [initialCount, Length(Screens)]));
  end;
  FDemoModel.RecordEvent('Registered continuation: ' + DescribePath);
end;

procedure TWizardFeatureDemo.ConfigureAgeRoute;
begin
  ApplyRouteAction(fraReplaceNext);
end;

procedure TWizardFeatureDemo.ApplyRouteAction(AAction : TFeatureRouteAction);
var
  path : TWizardScreenPath;
  original : TComponentClass;
  countBefore : Integer;
begin
  case AAction of
    fraInjectOptional: begin
      FDemoModel.IncludeOptional := true;
      UpdatePath(ptInject, [TWIZFeatureOptional]);
      countBefore := Length(Screens);
      if FDemoModel.RepeatInjection then
        UpdatePath(ptInject, [TWIZFeatureOptional]);
      FDemoModel.RecordEvent(Format('Inject optional step: %d screens; repeated insertion leaves %d', [countBefore, Length(Screens)]));
    end;
    fraReplaceNext: begin
      if FDemoModel.IncludeOptional then
        UpdatePath(ptReplaceAllNext, [TWIZFeatureOptional, TWIZFeatureCommit, TWIZFeatureSummary])
      else
        UpdatePath(ptReplaceAllNext, [TWIZFeatureCommit, TWIZFeatureSummary]);
      FDemoModel.RecordEvent('Replaced the continuation using the optional-step choice');
    end;
    fraReplaceAll: begin
      if FDemoModel.IncludeOptional then
        UpdatePath(ptReplaceAll, [TWIZFeatureName, TWIZFeatureAge, TWIZFeatureOptional, TWIZFeatureCommit, TWIZFeatureSummary])
      else
        UpdatePath(ptReplaceAll, [TWIZFeatureName, TWIZFeatureAge, TWIZFeatureCommit, TWIZFeatureSummary]);
      FDemoModel.RecordEvent('Replaced the complete route, preserving the current position');
    end;
    fraRemoveNext: begin
      UpdatePath(ptRemoveNext, [TWIZFeatureOptional]);
      FDemoModel.IncludeOptional := false;
      FDemoModel.RecordEvent('Removed future optional steps; cached forms remain owned by the wizard');
    end;
    fraRemoveScreen: begin
      RemoveScreen(TWIZFeatureOptional);
      FDemoModel.IncludeOptional := false;
      FDemoModel.RecordEvent('Removed the optional screen while idle; its form will be disposed with the wizard');
    end;
    fraPathSnapshot: begin
      path := Screens;
      original := path[0];
      path[0] := TWIZFeatureSummary;
      FDemoModel.SnapshotPreserved := Screens[0] = original;
      FDemoModel.RecordEvent('Changed a returned path snapshot; live membership preserved: ' + BoolToStr(FDemoModel.SnapshotPreserved, true));
    end;
  end;
  RecordStatus;
  FDemoModel.RecordEvent('Route: ' + DescribePath);
end;

procedure TWizardFeatureDemo.SetCancellationAllowed(AAllowed : boolean);
begin
  FDemoModel.CanCancel := AAllowed;
  IsCancellable := AAllowed;
  FDemoModel.RecordEvent('Cancellation allowed: ' + BoolToStr(AAllowed, true));
end;

procedure TWizardFeatureDemo.TestReentry;
var
  message : String;
  rejected : Integer;
begin
  if NOT FDemoModel.ProbeReentry then exit;
  if NOT IsBusy then begin
    FDemoModel.RecordEvent('Reentry probe runs only from an active navigation or completion callback');
    exit;
  end;
  rejected := 0;
  if NOT TryNext(message) then inc(rejected);
  if NOT Finish(message) then inc(rejected);
  if NOT Cancel(message) then inc(rejected);
  inc(FDemoModel.ReentryRejectedCount, rejected);
  RecordStatus;
  FDemoModel.RecordEvent(Format('Busy guard rejected %d nested navigation/completion requests', [rejected]));
end;

function TWizardFeatureDemo.DetermineHasPrevious : boolean;
begin
  Result := inherited DetermineHasPrevious;
  if Assigned(CurrentScreen) and (CurrentScreen.ClassType = TWIZFeatureCommit) then
    Result := false;
end;

function TWizardFeatureDemo.FinishRequested(out message : String) : boolean;
begin
  inc(FDemoModel.FinishAttempts);
  if FLastFinishOutcome <> FDemoModel.FinishOutcome then begin
    FLastFinishOutcome := FDemoModel.FinishOutcome;
    FFinishOutcomeAttempts := 0;
  end;
  inc(FFinishOutcomeAttempts);
  RecordStatus;
  FDemoModel.RecordEvent('Finish callback: ' + FDemoModel.StatusText);
  TestReentry;
  message := '';
  if FFinishOutcomeAttempts = 1 then
    case FDemoModel.FinishOutcome of
      fcoVetoOnce: begin
        message := 'The demo rejected this finish once. Choose Create project again to retry.';
        FDemoModel.RecordEvent(message);
        exit(false);
      end;
      fcoRaiseOnce: raise EWizardFeatureRetry.Create('Simulated finish exception. The wizard is active again; choose Create project to retry.');
    end;
  Result := true;
  FDemoModel.RecordEvent(Format('Created project for %s, age %d', [FDemoModel.Name, FDemoModel.Age]));
end;

function TWizardFeatureDemo.CancelRequested(out message : String) : boolean;
begin
  inc(FDemoModel.CancelAttempts);
  if FLastCancelOutcome <> FDemoModel.CancelOutcome then begin
    FLastCancelOutcome := FDemoModel.CancelOutcome;
    FCancelOutcomeAttempts := 0;
  end;
  inc(FCancelOutcomeAttempts);
  RecordStatus;
  FDemoModel.RecordEvent('Cancel callback: ' + FDemoModel.StatusText);
  TestReentry;
  message := '';
  if FCancelOutcomeAttempts = 1 then
    case FDemoModel.CancelOutcome of
      fcoVetoOnce: begin
        message := 'The demo rejected this cancellation once. Try Cancel wizard again.';
        FDemoModel.RecordEvent(message);
        exit(false);
      end;
      fcoRaiseOnce: raise EWizardFeatureRetry.Create('Simulated cancellation exception. The wizard is active again; try Cancel wizard to retry.');
    end;
  Result := true;
  FDemoModel.RecordEvent('Cancellation accepted');
end;

function TWizardFeatureDemo.TryNext(out message : String) : boolean;
begin
  try
    try
      Result := inherited TryNext(message);
    except
      on E : EWizardFeatureRetry do begin
        message := E.Message;
        Result := false;
        FDemoModel.RecordEvent(message);
      end;
    end;
  finally
    RecordStatus;
    FDemoModel.RecordEvent('Navigation outcome: ' + FDemoModel.StatusText);
  end;
end;

function TWizardFeatureDemo.Finish(out message : String) : boolean;
begin
  try
    Result := inherited Finish(message);
  except
    on E : EWizardFeatureRetry do begin
      message := E.Message;
      Result := false;
      FDemoModel.RecordEvent(message);
    end;
  end;
end;

function TWizardFeatureDemo.Cancel(out message : String) : boolean;
begin
  try
    Result := inherited Cancel(message);
  except
    on E : EWizardFeatureRetry do begin
      message := E.Message;
      Result := false;
      FDemoModel.RecordEvent(message);
    end;
  end;
end;

procedure TWizardFeatureDemo.CancelFromScreen;
var
  message : String;
begin
  if NOT Cancel(message) and (message <> '') then ShowError(message);
end;

procedure TWizardFeatureDemo.ShowError(const message : String);
begin
  FDemoModel.RecordEvent('Displayed outcome: ' + message);
  inherited ShowError(message);
end;

end.
