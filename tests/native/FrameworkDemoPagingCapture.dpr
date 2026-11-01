program FrameworkDemoPagingCapture;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>. MIT license.
  Capture the real unified demo, using its normal data source and native controls.
  Pass one absolute log filename in a fresh QA directory. No wallet data is used. }

{$IFDEF FPC}{$mode Delphi}{$H+}{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  {$IFDEF FPC}
  Interfaces, Forms, Controls, ExtCtrls, StdCtrls, Graphics, LMessages, Buttons, Menus,
  {$ELSE}
  Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Graphics, Vcl.Buttons, Vcl.Menus,
  Vcl.Imaging.pngimage,
  {$ENDIF}
  Classes, SysUtils, Types, Math, Windows, Messages, UVisualGrid, UFRMDemoMain,
  UVisualGrid.Paging.Checks;

type
  TCaptureGridAccess = class(TVisualGrid)
  public
    function Total: Integer;
    function Pages: Integer;
  end;

  TCaptureStage = (csAuto, csManual, csSingle);

  TDemoPagingCapture = class(TComponent)
  private
    FForm: TFRMDemoMain;
    FGrid: TVisualGrid;
    FTimer: TTimer;
    FLog: TStringList;
    FLogPath, FCaptureDirectory, FLastSignature: String;
    FDeadline, FStableSince: UInt64;
    FStage: TCaptureStage;
    FFinished: Boolean;
    FSelectPending: Boolean;
    FExceptionHooked: Boolean;
    FPreviousException: TExceptionEvent;
    procedure Tick(Sender: TObject);
    procedure OnException(Sender: TObject; E: Exception);
    procedure SelectMode(AStage: TCaptureStage);
    procedure CheckAndCapture;
    procedure CheckAutomaticRows;
    procedure Finish(AExitCode: Integer; const AMessage: String);
    function Signature: String;
  public
    constructor Create(AForm: TFRMDemoMain; const ALogPath: String); reintroduce;
    destructor Destroy; override;
  end;

procedure Require(ACondition: Boolean; const AMessage: String);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function CompilerName: String;
begin
  {$IFDEF FPC}
  Result := 'fpc';
  {$ELSE}
  Result := 'delphi';
  {$ENDIF}
end;

function StageName(AStage: TCaptureStage): String;
begin
  case AStage of
    csAuto: Result := 'auto';
    csManual: Result := 'manual';
    csSingle: Result := 'single';
  end;
end;

{$IFDEF FPC}
type
  TNativePixel = packed record
    Blue, Green, Red: Byte;
  end;
  TNativePixelRow = array[0..32767] of TNativePixel;
  PNativePixelRow = ^TNativePixelRow;

function PaintNativeForm(AForm: TForm): Graphics.TBitmap;
var
  LCanvasDC: HDC;

  procedure PaintControl(AControl: TWinControl);
  var
    LSaved, I: Integer;
    LOrigin: Types.TPoint;
    LWindow: Types.TRect;
  begin
    if not AControl.HandleAllocated or not Windows.IsWindowVisible(AControl.Handle) then
      Exit;
    LSaved := Windows.SaveDC(LCanvasDC);
    try
      // Ask the widget to paint its own native border/scrollbars first.
      Windows.GetWindowRect(AControl.Handle, LWindow);
      LOrigin := AForm.ScreenToClient(LWindow.TopLeft);
      Windows.SetViewportOrgEx(LCanvasDC, LOrigin.X, LOrigin.Y, nil);
      Windows.SendMessage(AControl.Handle, WM_PRINT, WPARAM(LCanvasDC), PRF_NONCLIENT);
      LOrigin := AForm.ScreenToClient(AControl.ClientToScreen(Types.Point(0, 0)));
      Windows.SetViewportOrgEx(LCanvasDC, LOrigin.X, LOrigin.Y, nil);
      Windows.IntersectClipRect(LCanvasDC, 0, 0, AControl.ClientWidth, AControl.ClientHeight);
      // LCL Win32 PaintTo delegates to WM_PRINT, which can leave custom-control
      // clients black on an inactive desktop. Deliver their normal LCL paint
      // messages to the supplied DC instead, retaining real cell/label painting.
      AControl.Perform(LM_ERASEBKGND, WPARAM(LCanvasDC), 0);
      AControl.Perform(LM_PAINT, WPARAM(LCanvasDC), 0);
      if not (AControl is TCustomControl) and not (AControl is TCustomForm) then
        Windows.SendMessage(AControl.Handle, WM_PRINTCLIENT, WPARAM(LCanvasDC), PRF_CLIENT);
      for I := 0 to AControl.ControlCount - 1 do
        if AControl.Controls[I] is TWinControl then
          PaintControl(TWinControl(AControl.Controls[I]));
    finally
      Windows.RestoreDC(LCanvasDC, LSaved);
    end;
  end;

begin
  Result := Graphics.TBitmap.Create;
  try
    Result.PixelFormat := pf24bit;
    Result.SetSize(AForm.ClientWidth, AForm.ClientHeight);
    // Uncovered client margins use the actual form background. Widget pixels
    // still come from their own paint handlers and are verified separately.
    Result.Canvas.Brush.Color := AForm.GetRGBColorResolvingParent;
    Result.Canvas.FillRect(Types.Rect(0, 0, Result.Width, Result.Height));
    LCanvasDC := Result.Canvas.Handle;
    PaintControl(AForm);
  except
    Result.Free;
    raise;
  end;
end;

function CountNativeInk(ABitmap: Graphics.TBitmap; AForm: TForm;
  AControl: TWinControl; const ALocalRect: Types.TRect): Integer;
var
  LOrigin: Types.TPoint;
  LRect: Types.TRect;
  LRow: PNativePixelRow;
  X, Y: Integer;
begin
  Require(ABitmap.Width <= High(TNativePixelRow) + 1, 'Native capture exceeds the pixel-check bound');
  LOrigin := AForm.ScreenToClient(AControl.ClientToScreen(ALocalRect.TopLeft));
  LRect := Types.Rect(Max(0, LOrigin.X), Max(0, LOrigin.Y),
    Min(ABitmap.Width, LOrigin.X + ALocalRect.Right - ALocalRect.Left),
    Min(ABitmap.Height, LOrigin.Y + ALocalRect.Bottom - ALocalRect.Top));
  Require((LRect.Right > LRect.Left) and (LRect.Bottom > LRect.Top),
    'Native capture region is outside the actual grid-tab client');
  Result := 0;
  for Y := LRect.Top to LRect.Bottom - 1 do begin
    LRow := ABitmap.ScanLine[Y];
    for X := LRect.Left to LRect.Right - 1 do
      if (LRow^[X].Red < 96) and (LRow^[X].Green < 96) and
        (LRow^[X].Blue < 96) then
        Inc(Result);
  end;
end;
{$ENDIF}

function TCaptureGridAccess.Total: Integer;
begin
  Result := FTotalDataCount;
end;

function TCaptureGridAccess.Pages: Integer;
begin
  Result := FPageCount;
end;

constructor TDemoPagingCapture.Create(AForm: TFRMDemoMain; const ALogPath: String);
var
  I: Integer;
begin
  inherited Create(AForm);
  FForm := AForm;
  Require((ExtractFileDrive(ALogPath) <> '') and
    SameText(ExpandFileName(ALogPath), ALogPath), 'Pass one absolute log filename');
  FLogPath := ALogPath;
  FCaptureDirectory := ChangeFileExt(FLogPath, '') + '-captures';
  Require(not DirectoryExists(FCaptureDirectory), 'Capture directory must be fresh');
  Require(ForceDirectories(FCaptureDirectory), 'Cannot create the capture directory');
  FLog := TStringList.Create;
  FLog.Add('Real TFRMDemoMain / fMain.TForm1; generated demo source; ' + CompilerName);
  Require(Assigned(FForm.GridExample), 'Unified demo did not create its grid example');
  for I := 0 to FForm.GridExample.ComponentCount - 1 do
    if FForm.GridExample.Components[I] is TVisualGrid then begin
      Require(not Assigned(FGrid), 'Grid example unexpectedly owns multiple visual grids');
      FGrid := TVisualGrid(FForm.GridExample.Components[I]);
    end;
  Require(Assigned(FGrid), 'Actual grid example has no TVisualGrid');
  FForm.Pages.ActivePage := FForm.GridTab;
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 25;
  FTimer.OnTimer := Tick;
  FPreviousException := Application.OnException;
  Application.OnException := OnException;
  FExceptionHooked := True;
  FDeadline := GetTickCount64 + 30000;
  FStage := csAuto;
  FSelectPending := True;
  FTimer.Enabled := True;
end;

destructor TDemoPagingCapture.Destroy;
begin
  if Assigned(FTimer) then
    FTimer.Enabled := False;
  if FExceptionHooked then
    Application.OnException := FPreviousException;
  FLog.Free;
  inherited Destroy;
end;

procedure TDemoPagingCapture.SelectMode(AStage: TCaptureStage);
var
  LIndex: Integer;
begin
  FStage := AStage;
  FStableSince := 0;
  FLastSignature := '';
  case FStage of
    csAuto: LIndex := 1;
    csManual: LIndex := 2;
    csSingle: LIndex := 0;
  end;
  if FStage = csManual then
    FGrid.ManualPageSize := 25;
  FTimer.Enabled := False;
  try
    ChooseVisualGridPageMode(FGrid,LIndex);
  finally
    FTimer.Enabled := True;
  end;
end;

function TDemoPagingCapture.Signature: String;
begin
  Result := Format('%d/%d/%d/%d/%d/%d/%d', [Ord(FGrid.PageMode),
    FGrid.PageSize, FGrid.RowCount, TCaptureGridAccess(FGrid).Pages,
    TCaptureGridAccess(FGrid).Total, FGrid.InternalDrawGrid.ClientWidth,
    FGrid.InternalDrawGrid.ClientHeight]);
end;

procedure TDemoPagingCapture.CheckAutomaticRows;
var
  LFirst, LSecond: TRect;
  LPitch, LFullBottom, LFixed: Integer;
begin
  Require(FGrid.PageMode = vpmAuto, 'Auto menu did not select automatic paging');
  Require((FGrid.RowCount = FGrid.PageSize) and (FGrid.RowCount > 1),
    'Auto did not display its full page');
  LFixed := FGrid.InternalDrawGrid.FixedRows;
  LFirst := FGrid.InternalDrawGrid.CellRect(0, LFixed);
  LSecond := FGrid.InternalDrawGrid.CellRect(0, LFixed + 1);
  LPitch := LSecond.Top - LFirst.Top;
  Require(LPitch > 0, 'Native row pitch is empty');
  // Extrapolate native cell geometry because VCL clips the final CellRect.
  LFullBottom := LFirst.Bottom + (FGrid.RowCount - 1) * LPitch;
  Require((LFullBottom <= FGrid.InternalDrawGrid.ClientHeight) and
    (LFullBottom + LPitch > FGrid.InternalDrawGrid.ClientHeight),
    'Auto must display exactly the complete rows that fit its native viewport');
  Require((GetWindowLongPtr(FGrid.InternalDrawGrid.Handle, GWL_STYLE) and WS_VSCROLL) = 0,
    'Auto unexpectedly exposed a vertical scrollbar');
end;

procedure TDemoPagingCapture.CheckAndCapture;
var
  LBitmap: {$IFDEF FPC}Graphics.TBitmap{$ELSE}Vcl.Graphics.TBitmap{$ENDIF};
  LPng: {$IFDEF FPC}TPortableNetworkGraphic{$ELSE}TPngImage{$ENDIF};
  LPath: String;
  LEffectivePageSize: Integer;
  {$IFDEF FPC}
  LMode: TBitBtn;
  LCell: Types.TRect;
  LDataInk, LModeInk, LInspectorInk: Integer;
  {$ENDIF}
begin
  Require(TCaptureGridAccess(FGrid).Total = 10000,
    'Capture must use all 10000 generated records from the real demo source');
  Require(FGrid.PageIndex = 0, 'Mode changes must start at page zero');
  case FStage of
    csAuto: CheckAutomaticRows;
    csManual:
      begin
        Require((FGrid.PageMode = vpmManual) and (FGrid.PageSize = 25) and
          (FGrid.ManualPageSize = 25) and (FGrid.RowCount = 25),
          'Manual must display its configured finite page of 25 rows');
        Require(TCaptureGridAccess(FGrid).Pages = 400, 'Manual page count is incorrect');
      end;
    csSingle:
      begin
        Require((FGrid.PageMode = vpmSingle) and (FGrid.PageSize = 25) and
          (FGrid.ManualPageSize = 25) and
          (FGrid.RowCount = 10000) and (TCaptureGridAccess(FGrid).Pages = 1),
          'Single must expose all 10000 records in one unbounded page');
        Require((GetWindowLongPtr(FGrid.InternalDrawGrid.Handle, GWL_STYLE) and WS_VSCROLL) <> 0,
          'Single must expose its native vertical scrollbar');
      end;
  end;
  // The demo inspector refreshes explicitly; capture its current mode as well
  // as the actual grid instead of leaving the initial Manual values on screen.
  FForm.GridExample.bRefresh.Click;
  FForm.Update;
  LPath := IncludeTrailingPathDelimiter(FCaptureDirectory) +
    'unified-grid-' + StageName(FStage) + '-' + CompilerName + '.png';
  {$IFDEF FPC}
  // The inactive-desktop widget cannot print its main tab strip. Capture the
  // real hosted grid form's client instead, without inventing missing chrome.
  LBitmap := PaintNativeForm(FForm.GridExample);
  FLog.Add('CAPTURE FPC GridExample.ClientRect: actual grid-tab content; main tab strip excluded');
  FLog.Add(Format('BACKGROUND FPC declared=%d resolved=%d',
    [FForm.GridExample.Color, FForm.GridExample.GetRGBColorResolvingParent]));
  {$ELSE}
  LBitmap := FForm.GetFormImage;
  {$ENDIF}
  try
    Require((LBitmap.Width > 0) and (LBitmap.Height > 0), 'Native form capture is empty');
    {$IFDEF FPC}
    // Background alone cannot satisfy these checks: require real text inside
    // a fetched data cell, the mode selector and the live property inspector.
    LCell := FGrid.InternalDrawGrid.CellRect(1, FGrid.InternalDrawGrid.FixedRows);
    InflateRect(LCell, -2, -2);
    LDataInk := CountNativeInk(LBitmap, FForm.GridExample, FGrid.InternalDrawGrid, LCell);
    LMode := FGrid.FindComponent('PageModeButton') as TBitBtn;
    Require(Assigned(LMode) and LMode.Visible, 'Native mode selector is missing');
    LModeInk := CountNativeInk(LBitmap, FForm.GridExample, LMode,
      Types.Rect(3, 3, LMode.ClientWidth - 3, LMode.ClientHeight - 3));
    LInspectorInk := CountNativeInk(LBitmap, FForm.GridExample, FForm.GridExample.TIPropertyGrid1,
      Types.Rect(4, 4, FForm.GridExample.TIPropertyGrid1.ClientWidth - 4,
        Min(100, FForm.GridExample.TIPropertyGrid1.ClientHeight - 4)));
    Require((LDataInk > 8) and (LModeInk > 12) and (LInspectorInk > 50),
      Format('Incomplete native control painting: data=%d mode=%d inspector=%d',
        [LDataInk, LModeInk, LInspectorInk]));
    FLog.Add(Format('PIXELS FPC native name-cell=%d mode-icon=%d inspector=%d',
      [LDataInk, LModeInk, LInspectorInk]));
    {$ENDIF}
    LPng := {$IFDEF FPC}TPortableNetworkGraphic{$ELSE}TPngImage{$ENDIF}.Create;
    try
      LPng.Assign(LBitmap);
      LPng.SaveToFile(LPath);
    finally
      LPng.Free;
    end;
  finally
    LBitmap.Free;
  end;
  // Single requests an unbounded page while PageSize retains Manual's setting.
  LEffectivePageSize := FGrid.PageSize;
  if FGrid.PageMode = vpmSingle then
    LEffectivePageSize := -1;
  FLog.Add(Format('PASS %s mode=%d effectivePageSize=%d configuredPageSize=%d rows=%d pages=%d total=%d image=%s',
    [StageName(FStage), Ord(FGrid.PageMode), LEffectivePageSize, FGrid.PageSize, FGrid.RowCount,
    TCaptureGridAccess(FGrid).Pages, TCaptureGridAccess(FGrid).Total, LPath]));
  FLog.SaveToFile(FLogPath);
end;

procedure TDemoPagingCapture.Finish(AExitCode: Integer; const AMessage: String);
begin
  if FFinished then
    Exit;
  FFinished := True;
  FTimer.Enabled := False;
  ExitCode := AExitCode;
  FLog.Add(AMessage);
  FLog.SaveToFile(FLogPath);
  // Main-form Close uses the application's normal termination and owned cleanup.
  FForm.Close;
end;

procedure TDemoPagingCapture.OnException(Sender: TObject; E: Exception);
begin
  Finish(1, 'FAIL ' + E.ClassName + ': ' + E.Message);
end;

procedure TDemoPagingCapture.Tick(Sender: TObject);
var
  LSignature: String;
begin
  if FFinished then
    Exit;
  try
    Require(GetTickCount64 < FDeadline, 'Demo capture exceeded its 30-second deadline');
    if not FForm.Visible or not FForm.HandleAllocated or FGrid.IsUpdating or
      FGrid.RefreshThrottle.Waiting or (TCaptureGridAccess(FGrid).Total <> 10000) then begin
      FStableSince := 0;
      Exit;
    end;
    if FSelectPending then begin
      FSelectPending := False;
      SelectMode(FStage);
      Exit;
    end;
    LSignature := Signature;
    if (FStableSince = 0) or (LSignature <> FLastSignature) then begin
      FLastSignature := LSignature;
      FStableSince := GetTickCount64;
      Exit;
    end;
    if GetTickCount64 - FStableSince < 400 then
      Exit;
    CheckAndCapture;
    case FStage of
      csAuto: SelectMode(csManual);
      csManual: SelectMode(csSingle);
      csSingle: Finish(0, 'PASS real unified demo: Auto, Manual 25 and Single captures');
    end;
  except
    on E: Exception do
      Finish(1, 'FAIL ' + E.ClassName + ': ' + E.Message);
  end;
end;

begin
  ExitCode := 1;
  Application.Initialize;
  Application.Title := 'Sphere 10 Pascal Framework';
  {$IFNDEF FPC}Application.MainFormOnTaskbar := True;{$ENDIF}
  try
    Require(ParamCount = 1, 'Usage: FrameworkDemoPagingCapture.exe <absolute fresh log filename>');
    Application.CreateForm(TFRMDemoMain, DemoMainForm);
    TDemoPagingCapture.Create(DemoMainForm, ParamStr(1));
    // Keep the production entry point's Application-owned main-form lifetime.
    Application.Run;
  except
    on E: Exception do begin
      ExitCode := 1;
      if ParamCount = 1 then
        with TStringList.Create do
          try
            Add('FAIL ' + E.ClassName + ': ' + E.Message);
            SaveToFile(ParamStr(1));
          finally
            Free;
          end;
    end;
  end;
end.
