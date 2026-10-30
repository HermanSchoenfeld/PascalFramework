program GridLoadingProbe;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>

  Real LCL grid loading checks, launched only by the private-desktop broker.
  Distributed under the MIT software license; see LICENSE.
}

{$mode delphi}

uses
  Interfaces, Windows, Types, Forms, Controls, Graphics, ExtCtrls, SysUtils,
  Classes, Variants, Generics.Collections, UCommon.Data, UVisualGrid;

type
  TItem = record
    Account : Integer;
    Name : String;
    Balance : Double;
  end;

  TSource = class(TCustomDataSource<TItem>)
  public
    Delay : Cardinal;
  protected
    function GetColumns : TDataColumns; override;
    procedure FetchAll(const AContainer : TList<TItem>); override;
    function GetItemField(constref AItem : TItem;
      const AColumnName : String) : Variant; override;
  end;

  TGrid = class(TVisualGrid)
  public
    function LoadingVisible : Boolean;
    function SpinnerActive : Boolean;
    procedure CheckLoading(const AStatus : String);
    function CaptureSpinner : TBitmap;
    procedure PaintLoadingTo(ACanvas : TCanvas; AForm : TForm);
  end;

  TProbe = class
  private
    FForm : TForm;
    FSource : TSource;
    FGrid : TGrid;
    FTimer : TTimer;
    FFrame : TBitmap;
    FLog : TStringList;
    FPath : String;
    FStarted, FPhaseStarted : QWord;
    FPhase : Integer;
    FPageRows : Integer;
    FFailure : String;
    procedure Tick(Sender : TObject);
    procedure Log(const AMessage : String);
    procedure Require(ACondition : Boolean; const AMessage : String);
    procedure Capture(const AName : String);
  public
    constructor Create(const APath : String);
    destructor Destroy; override;
    procedure Run;
  end;

function TSource.GetColumns : TDataColumns;
begin
  Result := TDataColumns.Create(TDataColumn.From('Account',True),
    TDataColumn.From('Name'),TDataColumn.From('Balance',True));
end;

procedure TSource.FetchAll(const AContainer : TList<TItem>);
var
  i : Integer;
  LItem : TItem;
begin
  Sleep(Delay);
  for i := 1 to 48 do begin
    LItem.Account := 4200+i;
    LItem.Name := 'Account '+IntToStr(i);
    LItem.Balance := i*3.125;
    AContainer.Add(LItem);
  end;
end;

function TSource.GetItemField(constref AItem : TItem;
  const AColumnName : String) : Variant;
begin
  if AColumnName = 'Account' then Result := AItem.Account
  else if AColumnName = 'Name' then Result := AItem.Name
  else if AColumnName = 'Balance' then Result := AItem.Balance
  else Result := Null;
end;

function TGrid.LoadingVisible : Boolean;
begin
  Result := FLoadDataPanel.Visible;
end;

function TGrid.SpinnerActive : Boolean;
begin
  Result := FLoadingCircle.Active;
end;

procedure TGrid.CheckLoading(const AStatus : String);
var
  I, LVisibleChildren : Integer;
begin
  if not FLoadDataPanel.IsVisible then
    raise Exception.Create('Loading overlay is hidden');
  if FLoadDataPanel.BorderStyle <> bsSingle then
    raise Exception.Create('Loading overlay has no border');
  if FLoadDataPanel.Caption<>'' then
    raise Exception.Create('Loading overlay has an unintended panel caption');
  if not FLoadingCircle.Active then
    raise Exception.Create('Loading circle is not animating');
  if FLoadDataLabel.Caption <> AStatus then
    raise Exception.Create('Wrong loading status: '+FLoadDataLabel.Caption);
  // Optional manual-card image/subtitle controls remain owned by this panel,
  // but the default automatic card displays only its circle and status.
  LVisibleChildren := 0;
  for I := 0 to FLoadDataPanel.ControlCount-1 do
    if FLoadDataPanel.Controls[I].Visible then Inc(LVisibleChildren);
  if (LVisibleChildren<>2) or (not FLoadingCircle.Visible) or
    (not FLoadDataLabel.Visible) or FLoadingImage.Visible or FLoadingSubtitle.Visible then
    raise Exception.Create('Default loading overlay must display only its circle and status');
  if (FLoadingImage.Parent<>FLoadDataPanel) or (FLoadingSubtitle.Parent<>FLoadDataPanel) then
    raise Exception.Create('Optional loading controls have the wrong parent');
  if Abs(2*FLoadDataLabel.Top+FLoadDataLabel.Height-FLoadDataPanel.ClientHeight)>2 then
    raise Exception.Create('The single loading status is not vertically centered');
  if Windows.GetParent(FLoadDataPanel.Handle)<>FClientPanel.Handle then
    raise Exception.Create('Loading overlay has the wrong native parent');
  if GetWindow(FClientPanel.Handle,GW_CHILD)<>FLoadDataPanel.Handle then
    raise Exception.Create('Loading overlay is behind another native child');
  if (FLoadDataPanel.Width >= FClientPanel.ClientWidth) or
    (FLoadDataPanel.Height >= FClientPanel.ClientHeight div 2) then
    raise Exception.Create('Loading overlay obscures too much of the grid');
  if (Abs(2*FLoadDataPanel.Left+FLoadDataPanel.Width-FClientPanel.ClientWidth)>2) or
    (Abs(2*FLoadDataPanel.Top+FLoadDataPanel.Height-FClientPanel.ClientHeight)>2) then
    raise Exception.Create('Loading overlay is not centered over the rows');
end;

procedure TGrid.PaintLoadingTo(ACanvas : TCanvas; AForm : TForm);
var
  LPoint : TPoint;
begin
  // Win32 PaintTo can traverse sibling windows out of their native Z order.
  // Paint this already-verified top native child last at its real client origin.
  LPoint := AForm.ScreenToClient(FLoadDataPanel.ClientToScreen(Types.Point(0,0)));
  FLoadDataPanel.PaintTo(ACanvas,LPoint.X-1,LPoint.Y-1);
end;

function TGrid.CaptureSpinner : TBitmap;
begin
  Result := TBitmap.Create;
  Result.SetSize(FLoadingCircle.Width,FLoadingCircle.Height);
  FLoadingCircle.PaintTo(Result.Canvas,0,0);
end;

constructor TProbe.Create(const APath : String);
begin
  inherited Create;
  FPath := APath;
  FLog := TStringList.Create;
  FForm := TForm.CreateNew(nil);
  FForm.Caption := 'PascalFramework - Grid loading';
  FForm.Position := poDesigned;
  FForm.SetBounds(80,90,760,520);
  FSource := TSource.Create(FForm);
  FGrid := TGrid.Create(FForm);
  FGrid.Parent := FForm;
  FGrid.Align := alClient;
  FGrid.PageSize := 12;
  FGrid.AddColumn('Account').Binding := 'Account';
  FGrid.AddColumn('Name').Binding := 'Name';
  FGrid.AddColumn('Balance').Binding := 'Balance';
  FGrid.Columns[0].Width := 160;
  FGrid.Columns[1].Width := 370;
  FGrid.Columns[2].Width := 160;
  FGrid.Columns[2].Renderer := TVisualCellRenderers.DollarValue;
  FGrid.FetchDataInThread := True;
  FTimer := TTimer.Create(FForm);
  FTimer.Enabled := False;
  FTimer.Interval := 20;
  FTimer.OnTimer := Tick;
end;

destructor TProbe.Destroy;
var
  LDeadline : QWord;
begin
  if Assigned(FTimer) then FTimer.Enabled := False;
  // Drain the bounded test fetch before destroying components it references;
  // this also permits Synchronize completion in legacy grid implementations.
  LDeadline := GetTickCount64+5000;
  while Assigned(FGrid) and FGrid.IsUpdating and (GetTickCount64<LDeadline) do begin
    Application.ProcessMessages;
    Sleep(1);
  end;
  FForm.Free;
  FFrame.Free;
  FLog.Free;
  inherited Destroy;
end;

procedure TProbe.Log(const AMessage : String);
begin
  FLog.Add(IntToStr(GetTickCount64)+' '+AMessage);
  FLog.SaveToFile(FPath);
end;

procedure TProbe.Require(ACondition : Boolean; const AMessage : String);
begin
  if not ACondition then raise Exception.Create(AMessage);
end;

procedure TProbe.Capture(const AName : String);
var
  LBitmap : TBitmap;
  LPng : TPortableNetworkGraphic;
begin
  LBitmap := FForm.GetFormImage;
  LPng := TPortableNetworkGraphic.Create;
  try
    FGrid.PaintLoadingTo(LBitmap.Canvas,FForm);
    LPng.Assign(LBitmap);
    LPng.SaveToFile(FPath+'.'+AName+'.png');
  finally
    LPng.Free;
    LBitmap.Free;
  end;
end;

procedure TProbe.Tick(Sender : TObject);
var
  LElapsed : QWord;
  LFrame : TBitmap;
  x, y, LDifferent : Integer;
begin
  try
    Require(GetTickCount64-FStarted<12000,'Loading probe timed out');
    LElapsed := GetTickCount64-FPhaseStarted;
    case FPhase of
      0: if LElapsed>=100 then begin
        Require(not FGrid.LoadingVisible,'Fast fetch flashes an immediate overlay');
        Log('DELAY: overlay remains hidden during initial 100ms');
        Inc(FPhase);
      end;
      1: if LElapsed>=550 then begin
        FGrid.CheckLoading('Loading...');
        Capture('initial');
        Log('INITIAL: compact bordered circle centered over the empty grid');
        Inc(FPhase);
      end;
      2: if not FGrid.IsUpdating then begin
        Require(not FGrid.LoadingVisible,'Initial overlay survived completion');
        Require(not FGrid.SpinnerActive,'Initial spinner timer survived completion');
        Log(Format('PAGE: rows=%d page-size=%d page-index=%d',
          [FGrid.RowCount,FGrid.PageSize,FGrid.PageIndex]));
        FPageRows := FGrid.RowCount;
        Require(FPageRows>0,'Initial data page is empty');
        FSource.Delay := 1500;
        FGrid.RefreshGrid;
        FPhaseStarted := GetTickCount64;
        Inc(FPhase);
      end;
      3: if LElapsed>=550 then begin
        FGrid.CheckLoading('Updating...');
        Require(FGrid.RowCount=FPageRows,'Previous rows disappeared during refresh');
        Require(VarToStr(FGrid.Cells[1,0])='Account 1','Previous row values changed');
        Capture('updating');
        FFrame := FGrid.CaptureSpinner;
        FPhaseStarted := GetTickCount64;
        Log('REFRESH: old rows remain readable behind compact updating overlay');
        Inc(FPhase);
      end;
      4: if LElapsed>=200 then begin
        LFrame := FGrid.CaptureSpinner;
        try
          LDifferent := 0;
          for y := 0 to LFrame.Height-1 do
            for x := 0 to LFrame.Width-1 do
              if LFrame.Canvas.Pixels[x,y]<>FFrame.Canvas.Pixels[x,y] then Inc(LDifferent);
          Require(LDifferent>10,'Loading circle pixels did not rotate');
          Log('ANIMATION: circle rotates with fading rounded spokes');
        finally
          LFrame.Free;
        end;
        Inc(FPhase);
      end;
      5: if not FGrid.IsUpdating then begin
        Require(not FGrid.LoadingVisible,'Refresh overlay survived completion');
        Require(not FGrid.SpinnerActive,'Refresh spinner timer survived completion');
        FSource.Delay := 0;
        FGrid.RefreshGrid;
        FPhaseStarted := GetTickCount64;
        Inc(FPhase);
      end;
      6: begin
        Require(not FGrid.LoadingVisible,'Fast replacement page flashed an overlay');
        if not FGrid.IsUpdating then begin
          Require(not FGrid.SpinnerActive,'Fast fetch left its spinner timer active');
          Log('FAST: immediate replacement completed without showing an overlay');
          FTimer.Enabled := False;
          Application.Terminate;
        end;
      end;
    end;
  except
    on E:Exception do begin
      FFailure := E.ClassName+': '+E.Message;
      Log('FAIL '+FFailure);
      FTimer.Enabled := False;
      Application.Terminate;
    end;
  end;
end;

procedure TProbe.Run;
begin
  FForm.Show;
  FStarted := GetTickCount64;
  FPhaseStarted := FStarted;
  FSource.Delay := 1000;
  FGrid.DataSource := FSource;
  FTimer.Enabled := True;
  Application.Run;
  if FFailure<>'' then raise Exception.Create(FFailure);
  Require(FPhase=6,'Not all grid loading checks completed');
  Log('PASS grid loading: delay, bordered circle, old rows, animation, completion');
end;

var
  LProbe : TProbe;
begin
  if ParamCount<>1 then Halt(64);
  Application.Initialize;
  LProbe := TProbe.Create(ParamStr(1));
  try
    try
      LProbe.Run;
    except
      on E:Exception do begin
        WriteLn(E.ClassName,': ',E.Message);
        ExitCode := 1;
      end;
    end;
  finally
    LProbe.Free;
  end;
end.
