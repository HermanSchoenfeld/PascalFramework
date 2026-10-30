unit UThrottleDemo;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>. MIT license. }

{$IFDEF FPC}{$mode Delphi}{$H+}{$ENDIF}

interface

uses
  Classes, SysUtils, Variants, Generics.Collections,
  {$IFDEF FPC}Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  {$ELSE}Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Graphics,{$ENDIF}
  UCommon, UCommon.UI, UCommon.Data, UVisualGrid;

type
  TThrottleDemoSource = class(TCustomDataSource<Integer>)
  private
    FRevision, FPageFetches, FLastPageIndex: Integer;
    FOnFetched: TNotifyEvent;
  protected
    function GetColumns: TDataColumns; override;
    function GetItemField({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem: Integer;
      const ABindingName: String): Variant; override;
    procedure FetchAll(const AContainer: TList<Integer>); override;
    function FetchPage({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AParams: TPageFetchParams;
      var ADataTable: TDataTable): TPageFetchResult; override;
  public
    property Revision: Integer read FRevision write FRevision;
    property PageFetches: Integer read FPageFetches;
    property LastPageIndex: Integer read FLastPageIndex;
    property OnFetched: TNotifyEvent read FOnFetched write FOnFetched;
  end;

  TThrottleDemoForm = class(TForm)
  private
    FSource: TThrottleDemoSource;
    FGrid: TVisualGrid;
    FNotifyButton: TButton;
    FEventLog: TMemo;
    FWaitingStatus, FClockStatus, FCounters: TLabel;
    FDisplayTimer: TTimer;
    FStartedAt: TDateTime;
    FInitialized: Boolean;
    FNotifyCount, FDeliveries, FBaseFetches: Integer;
    procedure NotifyClick(Sender: TObject);
    procedure WaitingChanged(Sender: TObject);
    procedure Delivered(Sender: TObject);
    procedure SourceFetched(Sender: TObject);
    procedure GridUpdated(Sender: TObject);
    procedure DisplayTick(Sender: TObject);
    procedure UpdateStatus;
    procedure Log(const AMessage: String);
    procedure BuildControls;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure InitializeDemo;
  end;

var
  ThrottleDemoForm: TThrottleDemoForm;

implementation

constructor TThrottleDemoForm.Create(AOwner: TComponent);
begin
  // Code-created controls keep the Delphi and Lazarus sample on one source path.
  inherited CreateNew(AOwner);
  FStartedAt := Now;
  Caption := 'Five-second grid throttle';
  Position := poScreenCenter;
  ClientWidth := 960;
  ClientHeight := 720;
  Constraints.MinWidth := 800;
  Constraints.MinHeight := 620;
  Font.Name := 'Segoe UI';
  Font.Size := 10;
end;

procedure TThrottleDemoForm.InitializeDemo;
begin
  // CreateNew bypasses VCL's main-form construction flag. Recreate the empty
  // window after CreateForm has registered MainForm, before creating child HWNDs.
  {$IFNDEF FPC}RecreateWnd;{$ENDIF}
  BuildControls;
  FDisplayTimer := TTimer.Create(Self);
  FDisplayTimer.Interval := 100;
  FDisplayTimer.OnTimer := DisplayTick;
end;

destructor TThrottleDemoForm.Destroy;
begin
  FDisplayTimer.Free;
  if FInitialized and Assigned(FGrid) then begin
    FGrid.RefreshThrottle.Remove(Delivered);
    FGrid.RefreshThrottle.OnWaitingChanged.Remove(WaitingChanged);
  end;
  // Release the consumer before its component-backed data source.
  if Assigned(FGrid) then FGrid.OnFinishedUpdating := nil;
  if Assigned(FSource) then FSource.OnFetched := nil;
  FGrid.Free;
  FSource.Free;
  inherited;
end;

procedure TThrottleDemoForm.NotifyClick(Sender: TObject);
begin
  Inc(FNotifyCount);
  FSource.Revision := FNotifyCount;
  Log(Format('NOTIFY click=%d: RefreshGrid -> owned RefreshThrottle.Notify',
    [FNotifyCount]));
  // RefreshGrid records the pending query and calls its own Notify exactly once.
  // Calling Notify directly would not create pending grid work; never call both.
  FGrid.RefreshGrid;
  UpdateStatus;
end;

procedure TThrottleDemoForm.WaitingChanged(Sender: TObject);
begin
  // The manual card follows ONLY this grid's throttle, including quiet finish.
  if FGrid.RefreshThrottle.Waiting then
    FGrid.ShowLoading('Please Wait', 'Synchronizing')
  else
    FGrid.HideLoading;
  Log('WAITING value=' + BoolToStr(FGrid.RefreshThrottle.Waiting, True));
  UpdateStatus;
end;

procedure TThrottleDemoForm.Delivered(Sender: TObject);
begin
  Inc(FDeliveries);
  Log(Format('DELIVERED delivery=%d actual_fetches=%d',
    [FDeliveries, FSource.PageFetches - FBaseFetches]));
  UpdateStatus;
end;

procedure TThrottleDemoForm.SourceFetched(Sender: TObject);
begin
  Log(Format('FETCH since_ready=%d revision=%d page=%d',
    [FSource.PageFetches - FBaseFetches, FSource.Revision,
     FSource.LastPageIndex + 1]));
  UpdateStatus;
end;

procedure TThrottleDemoForm.GridUpdated(Sender: TObject);
begin
  if not FInitialized then Exit;
  Log(Format('UPDATED displayed_revision=%d rows=%d',
    [Integer(FGrid.Cells[1, 0]), FGrid.RowCount]));
end;

procedure TThrottleDemoForm.DisplayTick(Sender: TObject);
begin
  if not FInitialized then begin
    // Let first-show geometry settle before measuring user-driven requests.
    FBaseFetches := FSource.PageFetches;
    FInitialized := True;
    FGrid.RefreshThrottle.Interval := TTimeSpan.FromMilliseconds(5000);
    FGrid.RefreshThrottle.Mode :=
      TThrottledEvent.TThrottledEventMode.temNotifyOnEventBurstStartAndFinished;
    FGrid.RefreshThrottle.Add(Delivered);
    FGrid.RefreshThrottle.OnWaitingChanged.Add(WaitingChanged);
    FSource.OnFetched := SourceFetched;
    FNotifyButton.Enabled := True;
    Log(Format('READY interval_ms=5000 baseline_fetches=%d', [FBaseFetches]));
  end;
  // After initialization this timer ONLY displays state; it never refreshes,
  // notifies, finishes a wait or changes the loading card.
  UpdateStatus;
end;

procedure TThrottleDemoForm.UpdateStatus;
var LElapsed, LRemaining: Double;
begin
  FWaitingStatus.Caption := 'Throttle Waiting = ' +
    BoolToStr(FGrid.RefreshThrottle.Waiting, True);
  if FGrid.RefreshThrottle.Waiting then
    FWaitingStatus.Font.Color := clMaroon
  else
    FWaitingStatus.Font.Color := clGreen;
  FCounters.Caption := Format('Notify clicks: %d     Delivered events: %d     Page fetches since Ready: %d',
    [FNotifyCount, FDeliveries, FSource.PageFetches - FBaseFetches]);
  if FGrid.RefreshThrottle.LastClientNotify = MinDateTime then
    FClockStatus.Caption := 'Ready. Click Notify to begin.'
  else begin
    LElapsed := (Now - FGrid.RefreshThrottle.LastClientNotify) * 86400;
    LRemaining := 5 - LElapsed;
    if LRemaining < 0 then LRemaining := 0;
    if FGrid.RefreshThrottle.Waiting then
      FClockStatus.Caption := Format('Quiet time: %.1f s    Remaining: %.1f s',
        [LElapsed, LRemaining])
    else
      FClockStatus.Caption := 'Idle. The next Notify delivers immediately.';
  end;
end;

procedure TThrottleDemoForm.Log(const AMessage: String);
begin
  FEventLog.Lines.Add(Format('%7.3f s  %s',
    [(Now - FStartedAt) * 86400, AMessage]));
  FEventLog.SelStart := Length(FEventLog.Text);
end;

procedure TThrottleDemoForm.BuildControls;
var LHeader, LLogPanel: TPanel; LLabel: TLabel;
begin
  LHeader := TPanel.Create(Self);
  LHeader.Parent := Self;
  LHeader.Align := alTop;
  LHeader.Height := 190;
  LHeader.BevelOuter := bvNone;
  LLabel := TLabel.Create(Self);
  LLabel.Parent := LHeader;
  LLabel.SetBounds(16, 12, 850, 28);
  LLabel.Caption := 'Five-second grid throttle';
  LLabel.Font.Size := 16;
  LLabel.Font.Style := [fsBold];
  LLabel := TLabel.Create(Self);
  LLabel.Parent := LHeader;
  LLabel.SetBounds(16, 48, 900, 38);
  LLabel.AutoSize := False;
  LLabel.Anchors := [akLeft, akTop, akRight];
  LLabel.WordWrap := True;
  LLabel.Caption := 'First click fetches immediately. Keep clicking less than five seconds apart: ' +
    'no further fetch occurs until five seconds after the LAST click.';

  FNotifyButton := TButton.Create(Self);
  FNotifyButton.Name := 'NotifyButton';
  FNotifyButton.Parent := LHeader;
  FNotifyButton.SetBounds(16, 94, 160, 42);
  FNotifyButton.Caption := 'Notify';
  FNotifyButton.Enabled := False;
  FNotifyButton.OnClick := NotifyClick;
  FWaitingStatus := TLabel.Create(Self);
  FWaitingStatus.Name := 'WaitingStatus';
  FWaitingStatus.Parent := LHeader;
  FWaitingStatus.SetBounds(200, 94, 700, 24);
  FWaitingStatus.Font.Style := [fsBold];
  FClockStatus := TLabel.Create(Self);
  FClockStatus.Name := 'ClockStatus';
  FClockStatus.Parent := LHeader;
  FClockStatus.SetBounds(200, 120, 700, 24);
  FCounters := TLabel.Create(Self);
  FCounters.Name := 'Counters';
  FCounters.Parent := LHeader;
  FCounters.SetBounds(16, 153, 900, 24);

  LLogPanel := TPanel.Create(Self);
  LLogPanel.Parent := Self;
  LLogPanel.Align := alBottom;
  LLogPanel.Height := 210;
  LLogPanel.BevelOuter := bvNone;
  LLabel := TLabel.Create(Self);
  LLabel.Parent := LLogPanel;
  LLabel.Align := alTop;
  LLabel.Caption := 'Event log: actual throttle callbacks and data-source queries';
  FEventLog := TMemo.Create(Self);
  FEventLog.Name := 'EventLog';
  FEventLog.Parent := LLogPanel;
  // VCL memo operations need their parent window before allocating the handle.
  FEventLog.Lines.Clear;
  FEventLog.Align := alClient;
  FEventLog.ReadOnly := True;
  FEventLog.ScrollBars := ssBoth;
  FEventLog.WordWrap := False;
  FEventLog.Font.Name := 'Consolas';
  FEventLog.Font.Size := 9;

  FSource := TThrottleDemoSource.Create(Self);
  FGrid := TVisualGrid.Create(Self);
  FGrid.Name := 'DataGrid';
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.FetchDataInThread := False;
  FGrid.PageSize := 8;
  FGrid.CanSearch := False;
  FGrid.AddColumn('Row').Binding := 'Row';
  FGrid.AddColumn('Displayed revision').Binding := 'Revision';
  FGrid.AddColumn('Total fetch # (incl. setup)').Binding := 'Fetch';
  FGrid.Columns[0].Width := 80;
  FGrid.Columns[1].Width := 220;
  FGrid.Columns[2].Width := 240;
  FGrid.Options := [vgoColAutoFill, vgoColSizing];
  FGrid.OnFinishedUpdating := GridUpdated;
  FGrid.DataSource := FSource;
end;

function TThrottleDemoSource.GetColumns: TDataColumns;
begin
  Result := TDataColumns.Create(TDataColumn.From('Row', True),
    TDataColumn.From('Revision'), TDataColumn.From('Fetch'));
end;

function TThrottleDemoSource.GetItemField(
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem: Integer;
  const ABindingName: String): Variant;
begin
  if ABindingName = 'Row' then Result := AItem
  else if ABindingName = 'Revision' then Result := FRevision
  else if ABindingName = 'Fetch' then Result := FPageFetches
  else Result := Null;
end;

procedure TThrottleDemoSource.FetchAll(const AContainer: TList<Integer>);
var I: Integer;
begin
  for I := 1 to 32 do AContainer.Add(I);
end;

function TThrottleDemoSource.FetchPage(
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} AParams: TPageFetchParams;
  var ADataTable: TDataTable): TPageFetchResult;
begin
  // Count the actual IDataSource call, independently of throttle delivery logs.
  Inc(FPageFetches);
  FLastPageIndex := AParams.PageIndex;
  Result := inherited;
  if Assigned(FOnFetched) then FOnFetched(Self);
end;

end.
