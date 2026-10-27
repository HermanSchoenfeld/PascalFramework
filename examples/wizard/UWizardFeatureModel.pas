unit UWizardFeatureModel;

{ Copyright (c) 2026 Herman Schoenfeld <https://www.sphere10.com>

  Model and observable demo actions for the wizard feature showcase.

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.
}

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, UCommon;

type
  TFeatureCallbackOutcome = (fcoAccept, fcoVetoOnce, fcoRaiseOnce);
  TFeatureRouteAction = (fraInjectOptional, fraReplaceNext, fraReplaceAll,
    fraRemoveNext, fraRemoveScreen, fraPathSnapshot);
  TFeatureSimpleAction = procedure of object;
  TFeatureRouteActionHandler = procedure(AAction : TFeatureRouteAction) of object;
  TFeatureCancellationHandler = procedure(AAllowed : boolean) of object;

  { Only deliberately simulated failures use this exception. The demo controller
    catches it after the framework releases its busy state, making retry visible. }
  EWizardFeatureRetry = class(Exception);

  { The launcher owns the model and keeps it alive until the wizard and every
    screen have been freed. Screens borrow the model and subscribe to changes. }
  TWizardFeatureModel = class
    private
      FEvents : TStringList;
      FChangedEvent : TNotifyManyEvent;
      FRouteAction : TFeatureRouteActionHandler;
    public
      Name : AnsiString;
      Age : Integer;
      Notes : AnsiString;
      IncludeOptional : boolean;
      RegisterSuccessor : boolean;
      RepeatInjection : boolean;
      CanCancel : boolean;
      ProbeReentry : boolean;
      FinishOutcome : TFeatureCallbackOutcome;
      CancelOutcome : TFeatureCallbackOutcome;
      FinishAttempts : Integer;
      CancelAttempts : Integer;
      ChangedCount : Integer;
      FinishedCount : Integer;
      InitializedCount : Integer;
      DestroyedCount : Integer;
      ReentryRejectedCount : Integer;
      SnapshotPreserved : boolean;
      StatusText : AnsiString;
      ConfigureInitialRoute : TFeatureSimpleAction;
      ConfigureAgeRoute : TFeatureSimpleAction;
      TestReentry : TFeatureSimpleAction;
      RequestCancel : TFeatureSimpleAction;
      SetCancellationAllowed : TFeatureCancellationHandler;
      constructor Create;
      destructor Destroy; override;
      property Events : TStringList read FEvents;
      property ChangedEvent : TNotifyManyEvent read FChangedEvent;
      property RouteAction : TFeatureRouteActionHandler read FRouteAction write FRouteAction;
      procedure RecordEvent(const AText : AnsiString);
      procedure RequestRouteAction(AAction : TFeatureRouteAction);
  end;

implementation

constructor TWizardFeatureModel.Create;
begin
  inherited Create;
  FEvents := TStringList.Create;
  RegisterSuccessor := true;
  RepeatInjection := true;
  CanCancel := true;
  ProbeReentry := true;
  StatusText := 'Ready to start';
end;

destructor TWizardFeatureModel.Destroy;
begin
  FEvents.Free;
  inherited Destroy;
end;

procedure TWizardFeatureModel.RecordEvent(const AText : AnsiString);
begin
  FEvents.Add(Format('%3d  %s', [FEvents.Count + 1, AText]));
  FChangedEvent.Invoke(self);
end;

procedure TWizardFeatureModel.RequestRouteAction(AAction : TFeatureRouteAction);
begin
  if Assigned(FRouteAction) then FRouteAction(AAction);
end;

end.
