unit UWizardDemo.Tests;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Forms, fpcunit, testregistry, UWizard,
  UWizardFeatureModel, UWizardFeatureDemo;

type
  { Exercise the actual designer-backed example screens on their native host,
    replacing only the modal loop and message dialogs. }
  TFeatureProbeWizard = class(TWizardFeatureDemo)
    private
      function GetTestHost : TWizardHostForm;
    protected
      procedure ShowHost; override;
      procedure ShowError(const message : AnsiString); override;
    public
      Run : TNotifyEvent;
      LastError : AnsiString;
      property TestHost : TWizardHostForm read GetTestHost;
  end;

  TWizardDemoTests = class(TTestCase)
    private
      FModel : TWizardFeatureModel;
      FWizard : TFeatureProbeWizard;
      FOutcome : TFeatureCallbackOutcome;
      procedure RunDemo(AAction : TNotifyEvent);
      procedure EnterName;
      procedure EnterSummary;
      procedure VerifyDynamicValidation(Sender : TObject);
      procedure VerifyAgeAndNoBack(Sender : TObject);
      procedure VerifyOptionalBranch(Sender : TObject);
      procedure VerifyPathActions(Sender : TObject);
      procedure VerifyFinishRetry(Sender : TObject);
      procedure VerifyCancelRetry(Sender : TObject);
      procedure VerifyCancellationLock(Sender : TObject);
    protected
      procedure SetUp; override;
      procedure TearDown; override;
    published
      procedure NameValidationAndMissingSuccessorAreRetryable;
      procedure AgeValidationCommitsOnlyAcceptedInputAndZeroIsValid;
      procedure OptionalBranchCanBeRevisitedAndRemoved;
      procedure EveryIdleRouteActionUsesTheActualPath;
      procedure FinishVetoIsRetryableAndCompletionIsIdempotent;
      procedure FinishExceptionIsRetryable;
      procedure CancelVetoIsRetryableAndCancellationIsIdempotent;
      procedure CancelExceptionIsRetryable;
      procedure CancellationPermissionCanBeChanged;
      procedure RemovedDemoScreensRemainOwnedUntilWizardDestruction;
  end;

implementation

uses
  UWIZFeatureName, UWIZFeatureAge, UWIZFeatureOptional,
  UWIZFeatureCommit, UWIZFeatureSummary;

function TFeatureProbeWizard.GetTestHost : TWizardHostForm;
begin
  Result := Host;
end;

procedure TFeatureProbeWizard.ShowHost;
begin
  if Assigned(Run) then Run(self);
end;

procedure TFeatureProbeWizard.ShowError(const message : AnsiString);
begin
  LastError := message;
end;

procedure TWizardDemoTests.SetUp;
begin
  inherited SetUp;
  FModel := TWizardFeatureModel.Create;
end;

procedure TWizardDemoTests.TearDown;
begin
  FreeAndNil(FWizard);
  FreeAndNil(FModel);
  inherited TearDown;
end;

procedure TWizardDemoTests.RunDemo(AAction : TNotifyEvent);
begin
  FWizard := TFeatureProbeWizard.Create(nil, FModel);
  FWizard.Run := AAction;
  FWizard.Start(FModel);
  AssertTrue('Start must release the native host', FWizard.TestHost = nil);
end;

procedure TWizardDemoTests.EnterName;
var
  screen : TWIZFeatureName;
begin
  AssertTrue(FWizard.CurrentScreen is TWIZFeatureName);
  screen := TWIZFeatureName(FWizard.CurrentScreen);
  screen.FNameEdit.Text := '  Ada Lovelace  ';
  screen.FConfirmedCheckBox.Checked := true;
  screen.FRegisterSuccessorCheckBox.Checked := true;
  FWizard.TestHost.FNextButton.Click;
  AssertTrue(FWizard.CurrentScreen is TWIZFeatureAge);
  AssertEquals('Ada Lovelace', FModel.Name);
  AssertEquals('Injected initialization must receive the accepted model', 'Ada Lovelace', TWIZFeatureAge(FWizard.CurrentScreen).InitializedName);
  AssertTrue(TWIZFeatureAge(FWizard.CurrentScreen).DemoModel = FModel);
end;

procedure TWizardDemoTests.EnterSummary;
var
  screen : TWIZFeatureAge;
begin
  EnterName;
  screen := TWIZFeatureAge(FWizard.CurrentScreen);
  screen.FAgeEdit.Text := '36';
  screen.FIncludeOptionalCheckBox.Checked := false;
  FWizard.TestHost.FNextButton.Click;
  AssertTrue(FWizard.CurrentScreen is TWIZFeatureCommit);
  TWIZFeatureCommit(FWizard.CurrentScreen).FAcceptCheckBox.Checked := true;
  FWizard.TestHost.FNextButton.Click;
  AssertTrue(FWizard.CurrentScreen is TWIZFeatureSummary);
end;

procedure TWizardDemoTests.NameValidationAndMissingSuccessorAreRetryable;
begin
  RunDemo(VerifyDynamicValidation);
end;

procedure TWizardDemoTests.VerifyDynamicValidation(Sender : TObject);
var
  screen : TWIZFeatureName;
begin
  screen := TWIZFeatureName(FWizard.CurrentScreen);
  AssertEquals(FWizard.NextText, FWizard.TestHost.NextText);
  AssertTrue(FWizard.TestHost.HidePrevious);
  AssertEquals(1, Length(FWizard.Screens));
  AssertEquals(1, FModel.InitializedCount);
  screen.FNameEdit.Text := '   ';
  screen.FConfirmedCheckBox.Checked := true;
  FWizard.TestHost.FNextButton.Click;
  AssertTrue(FWizard.CurrentScreen = screen);
  AssertEquals('', FModel.Name);
  AssertTrue(FWizard.LastError <> '');
  screen.FNameEdit.Text := '  Ada  ';
  screen.FConfirmedCheckBox.Checked := false;
  FWizard.TestHost.FNextButton.Click;
  AssertEquals('', FModel.Name);
  screen.FConfirmedCheckBox.Checked := true;
  screen.FRegisterSuccessorCheckBox.Checked := false;
  FWizard.TestHost.FNextButton.Click;
  AssertTrue(FWizard.CurrentScreen = screen);
  AssertEquals('Ada', FModel.Name);
  AssertEquals(Ord(wsActive), Ord(FWizard.State));
  AssertFalse(FWizard.IsBusy);
  screen.FRegisterSuccessorCheckBox.Checked := true;
  FWizard.TestHost.FNextButton.Click;
  AssertTrue(FWizard.CurrentScreen is TWIZFeatureAge);
  AssertEquals(4, Length(FWizard.Screens));
  AssertEquals(4, FModel.InitializedCount);
end;

procedure TWizardDemoTests.AgeValidationCommitsOnlyAcceptedInputAndZeroIsValid;
begin
  RunDemo(VerifyAgeAndNoBack);
end;

procedure TWizardDemoTests.VerifyAgeAndNoBack(Sender : TObject);
const
  invalidAges : array[0..3] of AnsiString = ('', '-1', 'abc', '2147483648');
var
  screen : TWIZFeatureAge;
  value : string;
  originalAge : Integer;
  message : AnsiString;
begin
  EnterName;
  screen := TWIZFeatureAge(FWizard.CurrentScreen);
  originalAge := FModel.Age;
  for value in invalidAges do begin
    screen.FAgeEdit.Text := value;
    FWizard.TestHost.FNextButton.Click;
    AssertTrue('Invalid age must retain the Age screen: ' + value, FWizard.CurrentScreen = screen);
    AssertEquals('Invalid age must not commit: ' + value, originalAge, FModel.Age);
  end;
  screen.FAgeEdit.Text := '0';
  screen.FIncludeOptionalCheckBox.Checked := false;
  FWizard.TestHost.FNextButton.Click;
  AssertEquals(0, FModel.Age);
  AssertTrue('Zero age must advance to confirmation', FWizard.CurrentScreen is TWIZFeatureCommit);
  AssertFalse('Confirmation must reject backward navigation', FWizard.HasPrevious);
  AssertTrue('The host must hide Previous at the boundary', FWizard.TestHost.HidePrevious);
  AssertFalse('Programmatic Previous must honor the boundary', FWizard.TryPrevious(message));
  FWizard.TestHost.FNextButton.Click;
  AssertTrue('Confirmation must validate before leaving', FWizard.CurrentScreen is TWIZFeatureCommit);
  TWIZFeatureCommit(FWizard.CurrentScreen).FAcceptCheckBox.Checked := true;
  FWizard.TestHost.FNextButton.Click;
  AssertTrue('Accepted confirmation must show Summary', FWizard.CurrentScreen is TWIZFeatureSummary);
  AssertTrue('Summary can return to confirmation', FWizard.HasPrevious);
  AssertEquals(FWizard.FinishText, FWizard.TestHost.NextText);
  AssertTrue('Summary must display the accepted name', Pos(FModel.Name, TWIZFeatureSummary(FWizard.CurrentScreen).FSummaryLabel.Caption) > 0);
  AssertTrue('Summary must display zero age', Pos('0', TWIZFeatureSummary(FWizard.CurrentScreen).FSummaryLabel.Caption) > 0);
end;

procedure TWizardDemoTests.OptionalBranchCanBeRevisitedAndRemoved;
begin
  RunDemo(VerifyOptionalBranch);
end;

procedure TWizardDemoTests.VerifyOptionalBranch(Sender : TObject);
var
  ageScreen : TWIZFeatureAge;
  optionalScreen : TWIZFeatureOptional;
  initialized : Integer;
begin
  EnterName;
  ageScreen := TWIZFeatureAge(FWizard.CurrentScreen);
  ageScreen.FAgeEdit.Text := '36';
  ageScreen.FIncludeOptionalCheckBox.Checked := true;
  FWizard.TestHost.FNextButton.Click;
  AssertTrue(FWizard.CurrentScreen is TWIZFeatureOptional);
  optionalScreen := TWIZFeatureOptional(FWizard.CurrentScreen);
  initialized := FModel.InitializedCount;
  AssertEquals(5, Length(FWizard.Screens));
  FWizard.TestHost.FPreviousButton.Click;
  AssertTrue(FWizard.CurrentScreen = ageScreen);
  ageScreen.FIncludeOptionalCheckBox.Checked := false;
  FWizard.TestHost.FNextButton.Click;
  AssertTrue(FWizard.CurrentScreen is TWIZFeatureCommit);
  AssertEquals(4, Length(FWizard.Screens));
  AssertEquals(initialized, FModel.InitializedCount);
  AssertEquals(0, FModel.DestroyedCount);
  AssertTrue(optionalScreen.Owner = FWizard);
end;

procedure TWizardDemoTests.EveryIdleRouteActionUsesTheActualPath;
begin
  RunDemo(VerifyPathActions);
end;

procedure TWizardDemoTests.VerifyPathActions(Sender : TObject);
var
  ageScreen : TWIZFeatureAge;
  path : TWizardScreenPath;
  i : Integer;
begin
  EnterName;
  ageScreen := TWIZFeatureAge(FWizard.CurrentScreen);
  ageScreen.FInjectOptionalButton.Click;
  AssertEquals(5, Length(FWizard.Screens));
  AssertTrue(FWizard.Screens[2] = TWIZFeatureOptional);
  ageScreen.FInjectOptionalButton.Click;
  AssertEquals('Repeated injection must stay idempotent', 5, Length(FWizard.Screens));
  ageScreen.FRemoveNextButton.Click;
  AssertEquals(4, Length(FWizard.Screens));
  AssertFalse(FModel.IncludeOptional);
  ageScreen.FInjectOptionalButton.Click;
  ageScreen.FRemoveScreenButton.Click;
  AssertEquals(4, Length(FWizard.Screens));
  FModel.IncludeOptional := true;
  ageScreen.FReplaceNextButton.Click;
  AssertEquals(5, Length(FWizard.Screens));
  ageScreen.FReplaceAllButton.Click;
  AssertEquals(5, Length(FWizard.Screens));
  AssertEquals(1, FWizard.CurrentScreenIndex);
  AssertTrue(FWizard.CurrentScreen = ageScreen);
  path := FWizard.Screens;
  ageScreen.FSnapshotButton.Click;
  AssertEquals(Length(path), Length(FWizard.Screens));
  for i := 0 to High(path) do
    AssertTrue(path[i] = FWizard.Screens[i]);
  AssertTrue(FModel.SnapshotPreserved);
end;

procedure TWizardDemoTests.FinishVetoIsRetryableAndCompletionIsIdempotent;
begin
  FOutcome := fcoVetoOnce;
  RunDemo(VerifyFinishRetry);
end;

procedure TWizardDemoTests.FinishExceptionIsRetryable;
begin
  FOutcome := fcoRaiseOnce;
  RunDemo(VerifyFinishRetry);
end;

procedure TWizardDemoTests.VerifyFinishRetry(Sender : TObject);
var
  message : AnsiString;
begin
  EnterSummary;
  TWIZFeatureSummary(FWizard.CurrentScreen).FFinishOutcomeComboBox.ItemIndex := Ord(FOutcome);
  AssertTrue(Assigned(TWIZFeatureSummary(FWizard.CurrentScreen).FFinishOutcomeComboBox.OnChange));
  TWIZFeatureSummary(FWizard.CurrentScreen).FFinishOutcomeComboBox.OnChange(TWIZFeatureSummary(FWizard.CurrentScreen).FFinishOutcomeComboBox);
  FWizard.TestHost.FNextButton.Click;
  AssertEquals(1, FModel.FinishAttempts);
  AssertEquals(0, FModel.FinishedCount);
  AssertEquals(Ord(wsActive), Ord(FWizard.State));
  AssertFalse(FWizard.IsBusy);
  AssertTrue(FWizard.LastError <> '');
  FWizard.TestHost.FNextButton.Click;
  AssertEquals(2, FModel.FinishAttempts);
  AssertEquals(1, FModel.FinishedCount);
  AssertEquals(Ord(wsFinished), Ord(FWizard.State));
  AssertTrue(FWizard.Finish(message));
  AssertEquals(2, FModel.FinishAttempts);
  AssertTrue(FModel.ChangedCount > 0);
  AssertTrue(FModel.Events.Count > 0);
  AssertTrue('The demo must exercise and report rejected reentry', FModel.ReentryRejectedCount > 0);
end;

procedure TWizardDemoTests.CancelVetoIsRetryableAndCancellationIsIdempotent;
begin
  FOutcome := fcoVetoOnce;
  RunDemo(VerifyCancelRetry);
end;

procedure TWizardDemoTests.CancelExceptionIsRetryable;
begin
  FOutcome := fcoRaiseOnce;
  RunDemo(VerifyCancelRetry);
end;

procedure TWizardDemoTests.VerifyCancelRetry(Sender : TObject);
var
  message : AnsiString;
begin
  FModel.CancelOutcome := FOutcome;
  AssertFalse(FWizard.Cancel(message));
  AssertTrue(message <> '');
  AssertEquals(1, FModel.CancelAttempts);
  AssertEquals(Ord(wsActive), Ord(FWizard.State));
  AssertFalse(FWizard.IsBusy);
  AssertTrue(FWizard.Cancel(message));
  AssertEquals(2, FModel.CancelAttempts);
  AssertEquals(Ord(wsCancelled), Ord(FWizard.State));
  AssertTrue(FWizard.Cancel(message));
  AssertEquals(2, FModel.CancelAttempts);
  AssertEquals(0, FModel.FinishedCount);
end;

procedure TWizardDemoTests.CancellationPermissionCanBeChanged;
begin
  RunDemo(VerifyCancellationLock);
end;

procedure TWizardDemoTests.VerifyCancellationLock(Sender : TObject);
var
  message : AnsiString;
begin
  FWizard.SetCancellationAllowed(false);
  AssertFalse(FWizard.IsCancellable);
  AssertFalse(FWizard.Cancel(message));
  AssertEquals(0, FModel.CancelAttempts);
  FWizard.SetCancellationAllowed(true);
  AssertTrue(FWizard.Cancel(message));
  AssertEquals(1, FModel.CancelAttempts);
end;

procedure TWizardDemoTests.RemovedDemoScreensRemainOwnedUntilWizardDestruction;
var
  initialized : Integer;
begin
  RunDemo(VerifyPathActions);
  initialized := FModel.InitializedCount;
  AssertEquals(0, FModel.DestroyedCount);
  FreeAndNil(FWizard);
  AssertEquals(initialized, FModel.DestroyedCount);
end;

initialization
  RegisterTest(TWizardDemoTests);

end.
