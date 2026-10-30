unit UFRMNotifyManyTest;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}
{$H+}

interface

uses
  Classes, SysUtils, {$IFDEF FPC}FileUtil,{$ENDIF} Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, UCommon, UCommon.UI;

type

  { TFRMNotifyManyTest }

  TFRMNotifyManyTest = class(TApplicationForm)
    Button1: TButton;
    btnFire: TButton;
    cbListener1: TCheckBox;
    cbListener2: TCheckBox;
    cbListener3: TCheckBox;
    cmbThrottle: TComboBox;
    Label1: TLabel;
    pnlEvent: TPanel;
    txtLog: TMemo;
    procedure btnFireAsyncClick(Sender: TObject);
    procedure btnFireClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cbListener1Change(Sender: TObject);
    procedure cbListener2Change(Sender: TObject);
    procedure cbListener3Change(Sender: TObject);
    procedure cmbThrottleChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure pnlEventMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);

  private
    FMouseMoveEvent : TThrottledEvent;
    {$IFNDEF FPC}
    procedure FireEventsQueued;
    {$ENDIF}
    procedure FireEvents(Data : PtrInt);
    procedure Listener1Handler(Sender : TObject);
    procedure Listener2Handler(Sender : TObject);
    procedure Listener3Handler(Sender : TObject);
  public
    destructor Destroy; override;
  end;

var
  FRMNotifyManyTest: TFRMNotifyManyTest;

implementation

var
  GHandledCount : Integer;

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

procedure TFRMNotifyManyTest.FormCreate(Sender: TObject);
begin
  FMouseMoveEvent := TThrottledEvent.Create(Self);
  FMouseMoveEvent.Mode:= temNone;
end;

{ TFRMNotifyManyTest }

procedure TFRMNotifyManyTest.pnlEventMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  FMouseMoveEvent.Notify;
end;

procedure TFRMNotifyManyTest.Listener1Handler(Sender : TObject);
begin
  Inc(GHandledCount);
  txtLog.Lines.Add(Format('[%d] %s Listener 1 - Suppressed Notifications = %d', [GHandledCount, TDateTime.Now.ToIntlString, FMouseMoveEvent.SuppressedInvocations]));
end;

procedure TFRMNotifyManyTest.Listener2Handler(Sender : TObject);
begin
  Inc(GHandledCount);
  txtLog.Lines.Add(Format('[%d] %s Listener 2 - Suppressed Notifications = %d', [GHandledCount, TDateTime.Now.ToIntlString, FMouseMoveEvent.SuppressedInvocations]));
end;

procedure TFRMNotifyManyTest.Listener3Handler(Sender : TObject);
begin
  Inc(GHandledCount);
  txtLog.Lines.Add(Format('[%d] %s Listener 3 - Suppressed Notifications = %d', [GHandledCount, TDateTime.Now.ToIntlString, FMouseMoveEvent.SuppressedInvocations]));
end;

procedure TFRMNotifyManyTest.cbListener1Change(Sender: TObject);
begin
   if cbListener1.Checked then
     FMouseMoveEvent.Add(Listener1Handler)
   else
     FMouseMoveEvent.Remove(Listener1Handler);
end;

procedure TFRMNotifyManyTest.cbListener2Change(Sender: TObject);
begin
   if cbListener2.Checked then
     FMouseMoveEvent.Add(Listener2Handler)
   else
     FMouseMoveEvent.Remove(Listener2Handler);
end;

procedure TFRMNotifyManyTest.cbListener3Change(Sender: TObject);
begin
   if cbListener3.Checked then
     FMouseMoveEvent.Add(Listener3Handler, True)
   else
     FMouseMoveEvent.Remove(Listener3Handler);
end;

procedure TFRMNotifyManyTest.btnFireClick(Sender: TObject);
begin
  FMouseMoveEvent.Notify;
end;

procedure TFRMNotifyManyTest.btnFireAsyncClick(Sender: TObject);
begin
    {$IFDEF FPC}
    Application.QueueAsyncCall(FireEvents, 0);
    {$ELSE}
    TThread.ForceQueue(nil, FireEventsQueued);
    {$ENDIF}
end;

{$IFNDEF FPC}
procedure TFRMNotifyManyTest.FireEventsQueued;
begin
  FireEvents(0);
end;
{$ENDIF}

destructor TFRMNotifyManyTest.Destroy;
begin
  {$IFDEF FPC}
  Application.RemoveAsyncCalls(Self);
  {$ELSE}
  TThread.RemoveQueuedEvents(nil, FireEventsQueued);
  {$ENDIF}
  inherited;
end;

procedure TFRMNotifyManyTest.cmbThrottleChange(Sender: TObject);
begin
  case cmbThrottle.ItemIndex of
    0: FMouseMoveEvent.Mode := temNone;
    1: FMouseMoveEvent.Mode := temNotifyEveryInterval;
    2: FMouseMoveEvent.Mode := temNotifyOnEventBurstFinished;
    3: FMouseMoveEvent.Mode := temNotifyOnEventBurstStartAndFinished;
  end;
end;

procedure TFRMNotifyManyTest.Button1Click(Sender: TObject);
begin
  txtLog.Lines.Clear;
end;

procedure TFRMNotifyManyTest.FireEvents(Data : PtrInt);
var i : integer;
begin
  for i := 1 to 1000 do
    FMouseMoveEvent.Notify;
end;
initialization
  GHandledCount := 0;

end.
