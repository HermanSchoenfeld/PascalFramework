program WizardNativeProbe;

{ Copyright (c) 2026 Herman Schoenfeld <https://www.sphere10.com>

  Native wizard regression checks on a separate Windows desktop. The broker
  never switches the input desktop; all commands target only its own QA child.

  Distributed under the MIT software license, see the accompanying file LICENSE
  or visit http://www.opensource.org/licenses/mit-license.php.

  THIS LICENSE HEADER MUST NOT BE REMOVED.
}


{$mode delphi}

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Windows, SysUtils, Classes,
  UWizard, UWizardFeatureModel, UWizardFeatureDemo, UWIZFeatureBase,
  UWIZFeatureName, UWIZFeatureAge, UWIZFeatureOptional, UWIZFeatureCommit, UWIZFeatureSummary;

type
  TPanelAccess = class(TPanel)
    public
      function ContentRect : TRect;
  end;

  TNativeWizard = class(TWizardFeatureDemo)
    public
      function NativeHost : TWizardHostForm;
  end;

  TModalHarness = class
    private
      FLog : TStringList;
      FLogPath : AnsiString;
      FTimer : TTimer;
      FWizard : TNativeWizard;
      FModel : TWizardFeatureModel;
      FHostHandle : HWND;
      FExpectedLeft : Integer;
      FExpectedTop : Integer;
      FPhase : Integer;
      FInsideTick : boolean;
      FFailure : AnsiString;
      FDialogCount : Integer;
      procedure Tick(Sender : TObject);
      procedure Log(const text : AnsiString);
      procedure Require(condition : boolean; const message : AnsiString);
      procedure CheckNative(const checkpoint : AnsiString; expectedClass : TComponentClass);
      procedure CheckNoVisibleWindows;
      procedure CloseVetoDialog;
      procedure MoveOwnHost;
      procedure Flow(firstPhase : Integer);
    public
      constructor Create(const logPath : AnsiString);
      destructor Destroy; override;
      procedure Run;
  end;

var
  allowedWindow : HWND;
  unexpectedWindow : HWND;
  dialogWindow : HWND;

function FindUnexpectedWindow(window : HWND; parameter : LPARAM) : WINBOOL; stdcall;
var
  processId : DWORD;
  windowClass : array[0..127] of AnsiChar;
begin
  Result := true;
  processId := 0;
  if GetWindowThreadProcessId(window, @processId) = 0 then exit;
  if (processId = GetCurrentProcessId) and Windows.IsWindowVisible(window) and (window <> allowedWindow) then begin
    // Windows creates this IME overlay inside GUI processes on private desktops.
    // It is not an application form; every LCL form is checked separately below.
    FillChar(windowClass, SizeOf(windowClass), 0);
    GetClassName(window, @windowClass[0], Length(windowClass));
    if (StrPas(@windowClass[0]) = 'UAC_InputIndicatorOverlayWnd') or
       (StrPas(@windowClass[0]) = 'UAC Input Indicator') then exit;
    unexpectedWindow := window;
    Result := false;
  end;
end;

function FindMessageDialog(window : HWND; parameter : LPARAM) : WINBOOL; stdcall;
var
  processId : DWORD;
  className : array[0..127] of AnsiChar;
begin
  Result := true;
  processId := 0;
  if GetWindowThreadProcessId(window, @processId) = 0 then exit;
  if (processId <> GetCurrentProcessId) or NOT Windows.IsWindowVisible(window) then exit;
  FillChar(className, SizeOf(className), 0);
  GetClassName(window, @className[0], Length(className));
  if StrPas(@className[0]) = '#32770' then begin
    dialogWindow := window;
    Result := false;
  end;
end;

function TNativeWizard.NativeHost : TWizardHostForm;
begin
  Result := Host;
end;

function TPanelAccess.ContentRect : TRect;
begin
  Result := ClientRect;
  AdjustClientRect(Result);
end;

constructor TModalHarness.Create(const logPath : AnsiString);
begin
  inherited Create;
  FLogPath := logPath;
  FLog := TStringList.Create;
  FTimer := TTimer.Create(nil);
  FTimer.Enabled := false;
  FTimer.Interval := 100;
  FTimer.OnTimer := Tick;
end;

destructor TModalHarness.Destroy;
begin
  FTimer.Free;
  FWizard.Free;
  FModel.Free;
  FLog.Free;
  inherited Destroy;
end;

procedure TModalHarness.Log(const text : AnsiString);
begin
  FLog.Add(Format('%d %s', [GetTickCount64, text]));
  FLog.SaveToFile(FLogPath);
end;

procedure TModalHarness.Require(condition : boolean; const message : AnsiString);
begin
  if NOT condition then raise Exception.Create(message);
end;

procedure TModalHarness.CheckNative(const checkpoint : AnsiString; expectedClass : TComponentClass);
var
  host : TWizardHostForm;
  current, screen : TCustomForm;
  panel : TPanel;
  i : Integer;
  hostRect, screenRect, contentRect : TRect;
  panelOrigin : TPoint;
  windowClass, windowText : array[0..255] of AnsiChar;
begin
  host := FWizard.NativeHost;
  Require(Assigned(host) and host.Visible, checkpoint + ': modal host is not visible');
  Require(GetWindowRect(host.Handle, hostRect), checkpoint + ': cannot read native host rectangle');
  if FHostHandle = 0 then begin
    FHostHandle := host.Handle;
    FExpectedLeft := hostRect.Left;
    FExpectedTop := hostRect.Top;
  end;
  Require(host.Handle = FHostHandle, checkpoint + ': host HWND changed');
  Require((hostRect.Left = FExpectedLeft) and (hostRect.Top = FExpectedTop), checkpoint + ': host moved or recentered');
  current := FWizard.CurrentScreen;
  Require(current.ClassType = expectedClass, checkpoint + ': wrong current screen ' + current.ClassName);
  panel := host.FWizardScreenPanel;
  contentRect := TPanelAccess(panel).ContentRect;
  Require(current.Visible, checkpoint + ': current screen is hidden');
  Require(current.Parent = panel, checkpoint + ': current LCL parent is not the host panel');
  Require(Windows.GetParent(current.Handle) = panel.Handle, checkpoint + ': Win32 parent HWND is wrong');
  Require((GetWindowLongPtr(current.Handle, GWL_STYLE) and WS_CHILD) <> 0, checkpoint + ': screen is a popup rather than WS_CHILD');
  Log(Format('GEOMETRY %s logical child=%d,%d,%d,%d panel-client=%d,%d',
    [checkpoint, current.Left, current.Top, current.Width, current.Height, panel.ClientWidth, panel.ClientHeight]));
  Require((current.Left = contentRect.Left) and (current.Top = contentRect.Top) and
    (current.Width = contentRect.Right - contentRect.Left) and
    (current.Height = contentRect.Bottom - contentRect.Top), checkpoint + ': screen does not fill adjusted host panel');
  panelOrigin := Point(contentRect.Left, contentRect.Top);
  Require(Windows.ClientToScreen(panel.Handle, panelOrigin), checkpoint + ': cannot read panel native client origin');
  Require(GetWindowRect(current.Handle, screenRect), checkpoint + ': cannot read current native rectangle');
  Log(Format('ABSOLUTE %s child=%d,%d,%d,%d expected-origin=%d,%d',
    [checkpoint, screenRect.Left, screenRect.Top, screenRect.Right, screenRect.Bottom, panelOrigin.X, panelOrigin.Y]));
  Require((screenRect.Left = panelOrigin.X) and (screenRect.Top = panelOrigin.Y), checkpoint + ': screen absolute origin differs from panel client origin');
  Require((screenRect.Right - screenRect.Left = contentRect.Right - contentRect.Left) and
    (screenRect.Bottom - screenRect.Top = contentRect.Bottom - contentRect.Top), checkpoint + ': screen native bounds do not fill adjusted panel');
  Require(panel.ControlCount = 1, checkpoint + ': host has extra embedded controls');
  for i := 0 to FWizard.ComponentCount - 1 do
    if FWizard.Components[i] is TWIZFeatureBase then begin
      screen := TCustomForm(FWizard.Components[i]);
      if screen <> current then begin
        Require(NOT screen.Visible, checkpoint + ': outgoing screen remains visible: ' + screen.ClassName);
        if screen.HandleAllocated then
          Require(NOT Windows.IsWindowVisible(screen.Handle), checkpoint + ': outgoing native screen remains visible: ' + screen.ClassName);
      end;
    end;
  for i := 0 to Forms.Screen.FormCount - 1 do
    if Forms.Screen.Forms[i].Visible and (Forms.Screen.Forms[i].Parent = nil) then
      Require(Forms.Screen.Forms[i] = host, checkpoint + ': extra visible top-level LCL form ' + Forms.Screen.Forms[i].ClassName);
  allowedWindow := host.Handle;
  unexpectedWindow := 0;
  EnumWindows(@FindUnexpectedWindow, 0);
  if unexpectedWindow <> 0 then begin
    FillChar(windowClass, SizeOf(windowClass), 0);
    FillChar(windowText, SizeOf(windowText), 0);
    GetClassName(unexpectedWindow, @windowClass[0], Length(windowClass));
    GetWindowText(unexpectedWindow, @windowText[0], Length(windowText));
    GetWindowRect(unexpectedWindow, screenRect);
    Log(Format('UNEXPECTED class=%s text=%s rect=%d,%d,%d,%d style=%d owner=%d',
      [StrPas(@windowClass[0]), StrPas(@windowText[0]), screenRect.Left, screenRect.Top, screenRect.Right,
       screenRect.Bottom, GetWindowLongPtr(unexpectedWindow, GWL_STYLE), PtrUInt(GetWindow(unexpectedWindow, GW_OWNER))]));
  end;
  Require(unexpectedWindow = 0, checkpoint + ': unexpected visible top-level HWND ' + IntToStr(unexpectedWindow));
  Log(Format('PASS %s host=%d xy=%d,%d current=%s parent=%d child-xy=%d,%d WS_CHILD fill-panel inactive-hidden no-extra-top-level',
    [checkpoint, PtrUInt(FHostHandle), hostRect.Left, hostRect.Top, current.ClassName, PtrUInt(panel.Handle), screenRect.Left, screenRect.Top]));
end;

procedure TModalHarness.MoveOwnHost;
var
  rect : TRect;
begin
  Require(GetWindowRect(FHostHandle, rect), 'Cannot read host before deliberate private-desktop move');
  Require(MoveWindow(FHostHandle, rect.Left + 93, rect.Top + 47, rect.Right - rect.Left, rect.Bottom - rect.Top, true),
    'Cannot move our own private-desktop wizard');
  Require(GetWindowRect(FHostHandle, rect), 'Cannot read host after deliberate move');
  FExpectedLeft := rect.Left;
  FExpectedTop := rect.Top;
  Log(Format('Moved only own private-desktop host to %d,%d; subsequent steps must preserve this origin', [FExpectedLeft, FExpectedTop]));
end;

procedure TModalHarness.CheckNoVisibleWindows;
begin
  allowedWindow := 0;
  unexpectedWindow := 0;
  EnumWindows(@FindUnexpectedWindow, 0);
  Require(unexpectedWindow = 0, 'Visible top-level window remained after real modal Start returned');
  Log('PASS modal returned: no visible top-level windows');
end;

procedure TModalHarness.CloseVetoDialog;
var
  i : Integer;
  form : TCustomForm;
begin
  // Only our child process exists on this private desktop. Dismiss the real
  // ShowMessage dialog while the outer timer tick is in its nested modal loop.
  for i := 0 to Screen.FormCount - 1 do begin
    form := Screen.Forms[i];
    if form.Visible and (form.Parent = nil) and (form <> FWizard.NativeHost) then begin
      form.ModalResult := mrOK;
      inc(FDialogCount);
      inc(FPhase);
      Log('PASS dismissed real LCL veto message dialog');
      exit;
    end;
  end;
  dialogWindow := 0;
  EnumWindows(@FindMessageDialog, 0);
  if dialogWindow <> 0 then begin
    PostMessage(dialogWindow, WM_COMMAND, IDOK, 0);
    inc(FDialogCount);
    inc(FPhase);
    Log('PASS dismissed real native veto message dialog');
  end;
end;

procedure TModalHarness.Tick(Sender : TObject);
var
  name : TWIZFeatureName;
  age : TWIZFeatureAge;
  summary : TWIZFeatureSummary;
begin
  if FPhase in [6, 22] then begin
    CloseVetoDialog;
    exit;
  end;
  if FInsideTick then begin
    exit;
  end;
  FInsideTick := true;
  try
    try
      case FPhase of
        0: begin
          CheckNative('initial Name', TWIZFeatureName);
          name := TWIZFeatureName(FWizard.CurrentScreen);
          name.FNameEdit.Text := 'Ada Lovelace';
          name.FConfirmedCheckBox.Checked := true;
          inc(FPhase);
          FWizard.NativeHost.FNextButton.Click;
        end;
        1: begin
          CheckNative('Name -> Age', TWIZFeatureAge);
          MoveOwnHost;
          CheckNative('Age deliberately moved', TWIZFeatureAge);
          age := TWIZFeatureAge(FWizard.CurrentScreen);
          age.FAgeEdit.Text := '36';
          age.FInjectOptionalButton.Click;
          CheckNative('Age inject optional', TWIZFeatureAge);
          inc(FPhase);
          FWizard.NativeHost.FNextButton.Click;
        end;
        2: begin
          CheckNative('Age -> Optional', TWIZFeatureOptional);
          TWIZFeatureOptional(FWizard.CurrentScreen).FNotesMemo.Text := 'Real ShowModal private desktop QA';
          inc(FPhase);
          FWizard.NativeHost.FPreviousButton.Click;
        end;
        3: begin
          CheckNative('Optional -> Age', TWIZFeatureAge);
          age := TWIZFeatureAge(FWizard.CurrentScreen);
          age.FRemoveNextButton.Click;
          age.FAgeEdit.Text := '0';
          CheckNative('Age remove optional', TWIZFeatureAge);
          inc(FPhase);
          FWizard.NativeHost.FNextButton.Click;
        end;
        4: begin
          CheckNative('Age -> Commit', TWIZFeatureCommit);
          Require(NOT FWizard.HasPrevious, 'Commit must suppress Previous');
          TWIZFeatureCommit(FWizard.CurrentScreen).FAcceptCheckBox.Checked := true;
          inc(FPhase);
          FWizard.NativeHost.FNextButton.Click;
        end;
        5: begin
          CheckNative('Commit -> Summary', TWIZFeatureSummary);
          summary := TWIZFeatureSummary(FWizard.CurrentScreen);
          summary.FFinishOutcomeComboBox.ItemIndex := Ord(fcoVetoOnce);
          summary.FFinishOutcomeComboBox.OnChange(summary.FFinishOutcomeComboBox);
          inc(FPhase);
          FWizard.NativeHost.FNextButton.Click;
        end;
        7: begin
          CheckNative('finish veto retained Summary', TWIZFeatureSummary);
          Require((FWizard.State = wsActive) and (FModel.FinishAttempts = 1), 'Finish veto must retain active state');
          inc(FPhase);
          FWizard.NativeHost.FNextButton.Click;
        end;
        20: begin
          CheckNative('cancel flow Name', TWIZFeatureName);
          FWizard.SetCancellationAllowed(false);
          inc(FPhase);
          FWizard.NativeHost.Close;
        end;
        21: begin
          CheckNative('disabled Close retained Name', TWIZFeatureName);
          Require((FWizard.State = wsActive) and (FModel.CancelAttempts = 0), 'Disabled cancellation invoked callback');
          FWizard.SetCancellationAllowed(true);
          FModel.CancelOutcome := fcoVetoOnce;
          inc(FPhase);
          FWizard.NativeHost.Close;
        end;
        23: begin
          CheckNative('cancel veto retained Name', TWIZFeatureName);
          Require((FWizard.State = wsActive) and (FModel.CancelAttempts = 1), 'Cancellation veto did not stay active');
          inc(FPhase);
          FWizard.NativeHost.Close;
        end;
      end;
    except
      on E : Exception do begin
        FFailure := E.Message;
        Log('FAIL ' + FFailure);
        FTimer.Enabled := false;
        if Assigned(FWizard.NativeHost) then begin
          FWizard.NativeHost.CloseQueryEvent := nil;
          FWizard.NativeHost.ModalResult := mrAbort;
        end;
      end;
    end;
  finally
    FInsideTick := false;
  end;
end;

procedure TModalHarness.Flow(firstPhase : Integer);
begin
  FPhase := firstPhase;
  FHostHandle := 0;
  FModel := TWizardFeatureModel.Create;
  FWizard := TNativeWizard.Create(nil, FModel);
  try
    FTimer.Enabled := true;
    try
      FWizard.Start(FModel); // Real inherited ShowHost and native ShowModal loop.
    finally
      FTimer.Enabled := false;
    end;
    Require(FFailure = '', FFailure);
    if firstPhase = 0 then begin
      Require((FWizard.State = wsFinished) and (FModel.FinishAttempts = 2), 'Finish retry did not complete exactly once');
      Require(FModel.FinishedCount = 1, 'Finished notification count incorrect');
    end else
      Require((FWizard.State = wsCancelled) and (FModel.CancelAttempts = 2), 'Close cancellation retry did not complete');
    Require(FWizard.NativeHost = nil, 'Host retained after modal loop');
    CheckNoVisibleWindows;
  finally
    FreeAndNil(FWizard);
    Require(FModel.InitializedCount = FModel.DestroyedCount, 'Screen ownership count mismatch');
    FreeAndNil(FModel);
  end;
end;

procedure TModalHarness.Run;
var
  nameBuffer : array[0..255] of AnsiChar;
  needed : DWORD;
begin
  FillChar(nameBuffer, SizeOf(nameBuffer), 0);
  Require(GetUserObjectInformation(GetThreadDesktop(GetCurrentThreadId), UOI_NAME, @nameBuffer[0], SizeOf(nameBuffer), @needed),
    'Cannot inspect QA desktop');
  Require(Pos('Sphere10WizardQA_', StrPas(@nameBuffer[0])) = 1, 'Probe must never run on the user desktop');
  Log('Private desktop confirmed: ' + StrPas(@nameBuffer[0]));
  Flow(0);
  Flow(20);
  Require(FDialogCount = 2, 'Both native finish and cancellation veto dialogs must be exercised');
  Log('PASS ALL real ShowModal, native command, HWND/parent/style/bounds/visibility, finish-veto/retry and Close permission/cancellation checks');
end;

var
  harness : TModalHarness;
  resultCode : Integer;
begin
  if ParamCount <> 1 then Halt(64);
  resultCode := 0;
  Application.Initialize;
  harness := TModalHarness.Create(ParamStr(1));
  try
    try
      harness.Run;
    except
      on E : Exception do begin
        harness.Log('FINAL FAIL ' + E.Message);
        resultCode := 1;
      end;
    end;
  finally
    harness.Free;
  end;
  Halt(resultCode);
end.
