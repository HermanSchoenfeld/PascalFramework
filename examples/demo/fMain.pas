unit fMain;

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils, Classes, Forms, Controls, Graphics, Dialogs, Math,
  {$IFDEF FPC}PropEdits, LCLType, RTTIGrids,{$ELSE}
  Vcl.ValEdit, Winapi.Windows, Variants,{$ENDIF} UVisualGrid, StdCtrls, Menus, Types, Grids, ExtCtrls, CheckLst,
  UMemory, UCommon, UCommon.Data, Generics.Collections, TypInfo, SyncObjs;

type

  { TEntity }

  TEntity = record
    ID : Integer;
    Name : String;
    Foo: Integer;
    &Boolean : boolean;
    &Char : char;
    &UInt16 : UInt16;
    &Real : Real;
    Bar : utf8String;
  end;

  { TEntityDataSource }

  TEntityDataSource = class(TCustomDataSource<TEntity>)
    private
      FOwned: TDisposables;
      FStateLock: TCriticalSection;
      FItems: TList<TEntity>;
      FCriteria: TStringList;
      FAddDelay: Boolean;
    public
      constructor Create(AOwner: TComponent); override;
      procedure Regenerate(ACount: Integer);
      procedure CopyCriteria(ADestination: TStrings);
      procedure SetAddDelay(AValue: Boolean);
    protected
      function GetItemDisposePolicy : TDisposePolicy; override;
      function GetColumns : TDataColumns;  override;
      procedure OnBeforeFetchAll({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AParams: TPageFetchParams); override;
      procedure FetchAll(const AContainer : TList<TEntity> ); override;
      procedure OnAfterFetchAll({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AParams: TPageFetchParams); override;
      function GetItemField({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem: TEntity; const AColumnName : String) : Variant; override;
  end;

  { TForm1 }

  TForm1 = class(TForm)
    AddDelayCheckBox: TCheckBox;
    bRegenerate: TButton;
    bDeselect: TButton;
    bSetWidth: TButton;
    bSearchParser: TButton;
    Button1: TButton;
    cbExpectedKind: TComboBox;
    ColumnsAutoFillCheckBox: TCheckBox;
    cbSearchParser: TComboBox;
    ComboBox1: TComboBox;
    eCol: TEdit;
    Edit1: TEdit;
    eWidth: TEdit;
    eNumEntities: TEdit;
    FirstColumnStretchedCheckBox: TCheckBox;
    bRefresh: TButton;
    GridPanel: TPanel;
    Label1: TLabel;
    lExpectedKind: TLabel;
    lbSearchCriteria: TListBox;
    lWidth: TLabel;
    lSelection: TLabel;
    miUpdateCell: TMenuItem;
    miUpdateRow: TMenuItem;
    MenuItem3: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    pWidgets: TPanel;
    PopupMenu1: TPopupMenu;
    TIPropertyGrid1: {$IFDEF FPC}TTIPropertyGrid{$ELSE}TValueListEditor{$ENDIF};
    procedure bDeselectClick(Sender: TObject);
    procedure bSetWidthClick(Sender: TObject);
    procedure bSearchParserClick(Sender: TObject);
    procedure bRegenerateClick(Sender: TObject);
    procedure ColumnsAutoFillCheckBoxChange(Sender: TObject);
    procedure bRefreshClick(Sender: TObject);
    procedure eNumEntitiesChange(Sender: TObject);
    procedure FirstColumnStretchedCheckBoxChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure miUpdateCellClick(Sender: TObject);
    procedure miUpdateRowClick(Sender: TObject);
  private
    FDataSource : TEntityDataSource;
    FVisualGrid: TVisualGrid;
    {$IFNDEF FPC}
    FRefreshingProperties: Boolean;
    procedure RefreshProperties;
    procedure PropertyValueValidate(Sender: TObject; ACol, ARow: Longint;
      const KeyName, KeyValue: string);
    {$ENDIF}
    { Private declarations }
  private
    procedure FetchFinished(Sender: TObject);
    procedure AddDelayChanged(Sender: TObject);
    procedure PreparePopupMenu(Sender: TObject; {$IFDEF FPC}constref{$ELSE}const{$ENDIF} ASelection: TVisualGridSelection; out APopupMenu: TPopupMenu);
    procedure DrawVisualCell(Sender: TObject; ACol, ARow: Longint; Canvas : TCanvas; Rect: TRect; State: TGridDrawState; const CellData, RowData: Variant; var Handled: boolean);
    procedure Selection(Sender: TObject; {$IFDEF FPC}constref{$ELSE}const{$ENDIF} ASelection: TVisualGridSelection);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  UCommon.UI;

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

var
  GNumEntities: Integer;

  { Data belongs to the example source, which outlives its grid worker. The
    worker never reads controls or the property editor. TDisposables owns the
    source's supporting objects; the short state lock protects regeneration
    and snapshots without synchronizing a worker back into the GUI. }
  constructor TEntityDataSource.Create(AOwner: TComponent);
  begin
    inherited;
    FStateLock := TCriticalSection(FOwned.AddObject(TCriticalSection.Create));
    FItems := TList<TEntity>(FOwned.AddObject(TList<TEntity>.Create));
    FCriteria := TStringList(FOwned.AddObject(TStringList.Create));
  end;

  procedure TEntityDataSource.Regenerate(ACount: Integer);
  var
    I: Integer;
    LEntity: TEntity;
    LItems: TList<TEntity>;
    LOwned: TDisposables;
  begin
    LItems := TList<TEntity>(LOwned.AddObject(TList<TEntity>.Create));
    for I := 0 to ACount - 1 do begin
      LEntity.ID := I;
      LEntity.Name := Format('Name %d', [I + 1]);
      LEntity.Foo := I div 5;
      LEntity.&Boolean := I mod 2 = 0;
      LEntity.&Char := Char(65 + (I mod 3));
      LEntity.&UInt16 := I + 1;
      LEntity.&Real := I / 2.0;
      LEntity.Bar := TGuid.NewGuid.ToString{$IFDEF FPC}(True){$ENDIF};
      LItems.Add(LEntity);
    end;
    FStateLock.Enter;
    try
      FItems.Clear;
      FItems.AddRange(LItems);
    finally
      FStateLock.Leave;
    end;
    InvalidateSnapshot;
  end;

  procedure TEntityDataSource.CopyCriteria(ADestination: TStrings);
  begin
    FStateLock.Enter;
    try ADestination.Assign(FCriteria); finally FStateLock.Leave; end;
  end;

  procedure TEntityDataSource.SetAddDelay(AValue: Boolean);
  begin
    FStateLock.Enter;
    try FAddDelay := AValue; finally FStateLock.Leave; end;
  end;

  { TEntityDataSource }

  function TEntityDataSource.GetItemDisposePolicy : TDisposePolicy;
  begin
    Result := idpNone;
  end;

  function TEntityDataSource.GetColumns : TDataColumns;
  begin
    Result := TDataColumns.Create(
      TDataColumn.From('ID'),
      TDataColumn.From('Name'),
      TDataColumn.From('Foo'),
      TDataColumn.From('Boolean'),
      TDataColumn.From('Char'),
      TDataColumn.From('UInt16'),
      TDataColumn.From('Real'),
      TDataColumn.From('Bar')
    );
  end;

  procedure TEntityDataSource.OnBeforeFetchAll({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AParams: TPageFetchParams);
  var
    LFilter: TColumnFilter;

    function FilterToStr(const AFilter: TColumnFilter): string;
    var
      LValues: utf8string;
      LValue: Variant;
    begin
      for LValue in AFilter.Values do
        LValues := LValues + QuotedStr(LValue) + ',';
      if LValues <> '' then SetLength(LValues, Length(LValues) - 1);
      Result := Format('Col: ''%s'' :: Kind: %s :: Sort: %s :: Values(%s)', [
        AFilter.ColumnName,
        GetEnumName(TypeInfo(TDataFilter), Ord(AFilter.Filter)),
        GetEnumName(TypeInfo(UCommon.Data.TSortDirection), Ord(AFilter.Sort)),
        LValues]);
    end;
  begin
    // show in GUI search criteria
    FStateLock.Enter;
    try
      FCriteria.Clear;
      for LFilter in AParams.Filter do
        FCriteria.Add(FilterToStr(LFilter));
    finally
      FStateLock.Leave;
    end;
  end;

  procedure TEntityDataSource.FetchAll(const AContainer : TList<TEntity>);
  begin
    FStateLock.Enter;
    try AContainer.AddRange(FItems); finally FStateLock.Leave; end;
  end;

  procedure TEntityDataSource.OnAfterFetchAll({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AParams: TPageFetchParams);
  var
    LAddDelay: Boolean;
  begin
    FStateLock.Enter;
    try LAddDelay := FAddDelay; finally FStateLock.Leave; end;
    if LAddDelay then Sleep(3000);
  end;

  function TEntityDataSource.GetItemField({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem: TEntity; const AColumnName : String) : Variant;
  begin
     if AColumnName = 'ID' then
       Result := AItem.ID
     else if AColumnName = 'Name' then
       Result := AItem.Name
     else if AColumnName = 'Foo' then
       Result := AItem.Foo
     else if AColumnName = 'Boolean' then
       Result := AItem.&Boolean
     else if AColumnName = 'Char' then
       Result := AItem.&Char
     else if AColumnName = 'UInt16' then
       Result := AItem.&UInt16
     else if AColumnName = 'Real' then
       Result := AItem.&Real
     else if AColumnName = 'Bar' then
       Result := AItem.&Bar
     else raise Exception.Create(Format('Field not found [%s]', [AColumnName]));
  end;

  { TForm1 }

  procedure TForm1.PreparePopupMenu(Sender: TObject; {$IFDEF FPC}constref{$ELSE}const{$ENDIF}
    ASelection: TVisualGridSelection; out APopupMenu: TPopupMenu);
  begin
    APopupMenu := PopupMenu1;
  end;

  procedure TForm1.FormCreate(Sender: TObject);
  begin
    FDataSource := TEntityDataSource.Create(Self);
    FDataSource.Regenerate(GNumEntities);
    FDataSource.SetAddDelay(AddDelayCheckBox.Checked);
    AddDelayCheckBox.OnClick := AddDelayChanged;
    FVisualGrid := TVisualGrid.Create(Self);
    FVisualGrid.OnFinishedUpdating := FetchFinished;
    FVisualGrid.OnDrawVisualCell:=DrawVisualCell;
    FVisualGrid.OnPreparePopupMenu:=PreparePopupMenu;
    FVisualGrid.OnSelection:=Selection;
    with FVisualGrid.AddColumn('1: ID') do begin
      Binding := 'ID';
      Filters:=SORTABLE_NUMERIC_FILTER;
    end;
    with FVisualGrid.AddColumn('Name') do begin
      Filters:=SORTABLE_TEXT_FILTER;
    end;
    with FVisualGrid.AddColumn('Foo') do begin
      Filters:=SORTABLE_TEXT_FILTER;
    end;
    with FVisualGrid.AddColumn('Boolean') do begin
      Filters:=SORTABLE_NUMERIC_FILTER;
    end;
    with FVisualGrid.AddColumn('Char') do begin
      Filters:=SORTABLE_TEXT_FILTER;
    end;
    with FVisualGrid.AddColumn('UInt16') do begin
      Filters:=SORTABLE_NUMERIC_FILTER;
    end;
    with FVisualGrid.AddColumn('Real') do begin
      Filters:=SORTABLE_NUMERIC_FILTER;
      Renderer:=TVisualCellRenderers.DollarValue;
    end;
    with FVisualGrid.AddColumn('Bar') do begin
      Filters:=SORTABLE_TEXT_FILTER;
    end;

    GridPanel.AddControlDockCenter(FVisualGrid);
    FVisualGrid.DataSource := FDataSource;
    {$IFDEF FPC}
    TIPropertyGrid1.TIObject := FVisualGrid;
    TIPropertyGrid1.PropertyEditorHook.LookupRoot := Self;
    {$ELSE}
    TIPropertyGrid1.OnValidate := PropertyValueValidate;
    RefreshProperties;
    {$ENDIF}
  end;

  procedure TForm1.FetchFinished(Sender: TObject);
  begin
    // This event is collected by the grid on the UI thread, after its fetch.
    FDataSource.CopyCriteria(lbSearchCriteria.Items);
  end;

  procedure TForm1.AddDelayChanged(Sender: TObject);
  begin
    FDataSource.SetAddDelay(AddDelayCheckBox.Checked);
  end;

  procedure TForm1.miUpdateCellClick(Sender: TObject);
  begin
    with FVisualGrid.Selection do
      FVisualGrid.Cells[Col, Row] := 'Test';
  end;

  procedure TForm1.miUpdateRowClick(Sender: TObject);
  var
    i, j: Integer;
    r: variant;
    rd: TDataRowData absolute r;
  begin
{    with FVisualGrid.Selection do
      for i := 0 to RowCount - 1 do
      begin
        r := FVisualGrid.Rows[i + Row];
        for j := 0 to High(rd.vvalues) do
          rd.vvalues[j] := 'Test';
        FVisualGrid.Rows[i + Row] := r;
      end;}
  end;

  procedure TForm1.bRefreshClick(Sender: TObject);
  begin
    {$IFDEF FPC}TIPropertyGrid1.RefreshPropertyValues;{$ELSE}RefreshProperties;{$ENDIF}
  end;

  procedure TForm1.eNumEntitiesChange(Sender: TObject);
  var
    LCount: Integer;
  begin
    // An edit can be temporarily empty while its value is being replaced.
    if TryStrToInt(eNumEntities.Text, LCount) and (LCount >= 0) then
      GNumEntities := LCount;
  end;

  procedure TForm1.FirstColumnStretchedCheckBoxChange(Sender: TObject);
  begin
    FVisualGrid.Columns[0].StretchedToFill:=FirstColumnStretchedCheckBox.Checked;
  end;

  procedure TForm1.ColumnsAutoFillCheckBoxChange(Sender: TObject);
  begin
    if ColumnsAutoFillCheckBox.Checked then
      FVisualGrid.Options := FVisualGrid.Options + [vgoColAutoFill]
    else
      FVisualGrid.Options := FVisualGrid.Options - [vgoColAutoFill];

    {$IFDEF FPC}TIPropertyGrid1.RefreshPropertyValues;{$ELSE}RefreshProperties;{$ENDIF}
  end;

  procedure TForm1.bSetWidthClick(Sender: TObject);
  var
    LCol: Integer;
  begin
    if FVisualGrid.ColCount = 0 then Exit;
    LCol := StrToIntDef(eCol.Text, 0);
    if LCol < 0 then
    begin
      LCol := 0;
      eCol.Text := '0';
    end;
    if LCol >= FVisualGrid.ColCount then
    begin
      LCol := FVisualGrid.ColCount - 1;
      eCol.Text := IntToStr(LCol);
    end;

    FVisualGrid.Columns[LCol].Width := StrToIntDef(eWidth.Text, 150);
  end;

  procedure TForm1.bDeselectClick(Sender: TObject);
  begin
    FVisualGrid.ClearSelection;
  end;

  procedure TForm1.bSearchParserClick(Sender: TObject);
  var
    er: TExpressionRecord;
    i: Integer;
    LExpressionKind, LSubKind, LValues: string;
    LMsg: string;
    LExpectedKind: TExpressionKind;
  begin
    LExpectedKind := TExpressionKind(cbExpectedKind.ItemIndex);
    TSearchExpressionService.Parse(cbSearchParser.Text, LExpectedKind, er);

    LExpressionKind := GetEnumName(TypeInfo(TExpressionKind), Ord(er.Kind));
    case er.Kind of
      ekNum: LSubKind := GetEnumName(TypeInfo(TNumericComparisionKind), Ord(er.NumericComparisionKind));
      ekText: LSubKind := GetEnumName(TypeInfo(TTextMatchKind), Ord(er.TextMatchKind));
      ekSet: LSubKind := GetEnumName(TypeInfo(TSetKind), Ord(er.SetKind));
    end;

    for i := 0 to High(er.Values) do
      LValues:=LValues + (er.Values[i]) + sLineBreak;
    SetLength(LValues, Length(LValues) - Length(sLineBreak));

    LMsg := Format('Kind : %s'+sLineBreak+'SubKind : %s'+sLineBreak+'Values:'+sLineBreak+'%s',
      [LExpressionKind, LSubKind, LValues]);
    if IsConsole then
      WriteLn(LMsg, sLineBreak)
    else
      ShowMessage(LMsg);
  end;

  procedure TForm1.DrawVisualCell(Sender: TObject; ACol, ARow: Longint; Canvas : TCanvas; Rect: TRect; State: TGridDrawState; const CellData, RowData: Variant; var Handled: boolean);
  var
    {$IFDEF FPC}LTextStyle: TTextStyle;{$ELSE}LText: string;{$ENDIF}
  begin
    Handled := (ACol = 2) and (ARow > 0);
    if Handled then
    begin
      Canvas.Font.Color:=clRed;
      Canvas.Font.Style:=[fsBold];
      {$IFDEF FPC}
      LTextStyle := Canvas.TextStyle;
//      LTextStyle.Alignment:=taCenter;
      LTextStyle.Alignment:=taRightJustify;
      Canvas.TextStyle:=LTextStyle;
      Canvas.TextRect(Rect, Rect.Left+2, Rect.Top+2, CellData, LTextStyle);
      {$ELSE}
      LText := VarToStr(CellData);
      InflateRect(Rect, -2, -2);
      Winapi.Windows.DrawText(Canvas.Handle, PChar(LText), Length(LText), Rect,
        DT_RIGHT or DT_TOP or DT_SINGLELINE or DT_NOPREFIX);
      {$ENDIF}
    end;
  end;

  procedure TForm1.Selection(Sender: TObject; {$IFDEF FPC}constref{$ELSE}const{$ENDIF} ASelection: TVisualGridSelection);
  begin
    lSelection.Caption := Format('C=%d R=%d ColCount=%d RowCount=%d P=%d',
      [ASelection.Col, ASelection.Row, ASelection.ColCount, ASelection.RowCount, ASelection.Page]);
  end;

  procedure TForm1.bRegenerateClick(Sender: TObject);
  begin
    FDataSource.Regenerate(GNumEntities);
    FVisualGrid.RefreshGrid;
  end;

{$IFNDEF FPC}
{ The VCL demo uses the RTL RTTI and standard value-list editor instead of
  Lazarus's design-time property editor. The same published grid properties
  remain editable, including the live widget-control selector. }
procedure TForm1.RefreshProperties;
var
  LProperties: PPropList;
  LCount, I, J: Integer;
  LProperty: PPropInfo;
  LName, LValue: string;
  LControl: TControl;
  LTypeData: PTypeData;

  procedure AddCaptionProperty(const APath: string; ATarget: TObject;
    const AName: string);
  begin
    TIPropertyGrid1.InsertRow(APath, VarToStr(GetPropValue(ATarget, AName, True)), True);
  end;
begin
  if FRefreshingProperties or not Assigned(FVisualGrid) then Exit;
  FRefreshingProperties := True;
  TIPropertyGrid1.Strings.BeginUpdate;
  try
    TIPropertyGrid1.Strings.Clear;
    LCount := GetPropList(FVisualGrid, LProperties);
    try
      for I := 0 to LCount - 1 do
      begin
        LProperty := LProperties^[I];
        LName := string(LProperty.Name);
        if SameText(LName, 'Align') or SameText(LName, 'Cursor') or
          SameText(LName, 'HelpContext') or SameText(LName, 'HelpKeyword') or
          SameText(LName, 'HelpType') or SameText(LName, 'Hint') or
          SameText(LName, 'Name') or SameText(LName, 'Tag') or
          SameText(LName, 'Left') or SameText(LName, 'Top') or
          SameText(LName, 'Width') or SameText(LName, 'Height') then Continue;
        if LProperty.PropType^.Kind = tkClass then
        begin
          if not SameText(LName, 'WidgetControl') then Continue;
          LControl := FVisualGrid.WidgetControl;
          if Assigned(LControl) then LValue := LControl.Name else LValue := '(none)';
        end
        else
        begin
          if not (LProperty.PropType^.Kind in
            [tkInteger, tkChar, tkEnumeration, tkFloat, tkSet, tkWChar,
             tkLString, tkWString, tkUString, tkInt64]) then Continue;
          LValue := VarToStr(GetPropValue(FVisualGrid, LProperty, True));
        end;
        TIPropertyGrid1.InsertRow(LName, LValue, True);
        TIPropertyGrid1.ItemProps[LName].ReadOnly := not Assigned(LProperty.SetProc);
        if SameText(LName, 'WidgetControl') then
        begin
          TIPropertyGrid1.ItemProps[LName].EditStyle := esPickList;
          TIPropertyGrid1.ItemProps[LName].PickList.Clear;
          TIPropertyGrid1.ItemProps[LName].PickList.Add('(none)');
          // Ownership stays with this form even after docking a widget in the grid.
          TIPropertyGrid1.ItemProps[LName].PickList.Add(Edit1.Name);
          TIPropertyGrid1.ItemProps[LName].PickList.Add(Button1.Name);
          TIPropertyGrid1.ItemProps[LName].PickList.Add(ComboBox1.Name);
        end
        else if LProperty.PropType^.Kind = tkEnumeration then
        begin
          TIPropertyGrid1.ItemProps[LName].EditStyle := esPickList;
          TIPropertyGrid1.ItemProps[LName].PickList.Clear;
          LTypeData := GetTypeData(LProperty.PropType^);
          for J := LTypeData.MinValue to LTypeData.MaxValue do
            TIPropertyGrid1.ItemProps[LName].PickList.Add(GetEnumName(LProperty.PropType^, J));
        end;
      end;
    finally
      FreeMem(LProperties);
    end;
    // Preserve the persistent caption/font settings exposed by Lazarus RTTI.
    AddCaptionProperty('Caption.Text', FVisualGrid.Caption, 'Text');
    AddCaptionProperty('Caption.Visible', FVisualGrid.Caption, 'Visible');
    AddCaptionProperty('Caption.Alignment', FVisualGrid.Caption, 'Alignment');
    AddCaptionProperty('Caption.Font.Name', FVisualGrid.Caption.Font, 'Name');
    AddCaptionProperty('Caption.Font.Size', FVisualGrid.Caption.Font, 'Size');
    AddCaptionProperty('Caption.Font.Style', FVisualGrid.Caption.Font, 'Style');
    TIPropertyGrid1.InsertRow('Caption.Font.Color',
      ColorToString(FVisualGrid.Caption.Font.Color), True);
  finally
    TIPropertyGrid1.Strings.EndUpdate;
    FRefreshingProperties := False;
  end;
end;

procedure TForm1.PropertyValueValidate(Sender: TObject; ACol, ARow: Longint;
  const KeyName, KeyValue: string);
var
  LComponent: TComponent;
  LTarget: TObject;
  LProperty, LPart: string;
  LDot: Integer;
begin
  if FRefreshingProperties then Exit;
  if SameText(KeyName, 'WidgetControl') then
  begin
    if KeyValue = '(none)' then FVisualGrid.WidgetControl := nil
    else
    begin
      LComponent := FindComponent(KeyValue);
      if not (LComponent is TControl) then
        raise EConvertError.CreateFmt('Unknown widget control: %s', [KeyValue]);
      FVisualGrid.WidgetControl := TControl(LComponent);
    end;
  end
  else
  begin
    LTarget := FVisualGrid;
    LProperty := KeyName;
    LDot := Pos('.', LProperty);
    while LDot > 0 do begin
      LPart := Copy(LProperty, 1, LDot - 1);
      Delete(LProperty, 1, LDot);
      LTarget := GetObjectProp(LTarget, LPart);
      if LTarget = nil then raise EConvertError.CreateFmt('Property is unavailable: %s', [KeyName]);
      LDot := Pos('.', LProperty);
    end;
    if (LTarget is TFont) and SameText(LProperty, 'Color') then
      TFont(LTarget).Color := StringToColor(KeyValue)
    else
      SetPropValue(LTarget, LProperty, KeyValue);
  end;
end;
{$ENDIF}

{$IFDEF FPC}
type

  { TWidgetsPropertyEditor }

  TWidgetsPropertyEditor = class(TComponentOneFormPropertyEditor)
  public
    procedure GetValues(Proc: TGetStrProc); override;
  end;

{ TWidgetsPropertyEditor }

procedure TWidgetsPropertyEditor.GetValues(Proc: TGetStrProc);
var
  LForm: TForm1;
begin
  if not (GetComponent(0) is TVisualGrid) then Exit;
  LForm := TForm1(TVisualGrid(GetComponent(0)).Owner);
  Proc(LForm.Edit1.Name);
  Proc(LForm.Button1.Name);
  Proc(LForm.ComboBox1.Name);
end;

{$ENDIF}

initialization
  GNumEntities := 10000;

{ID : Integer;
Name : String;
Foo: Integer;
&Boolean : boolean;
&Char : char;
&UInt16 : UInt16;
&Real : Real;
Bar : utf8String;
}

  {$IFDEF FPC}
  RegisterPropertyEditor(TypeInfo(TAlign), TVisualGrid, 'Align', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(TCursor), TVisualGrid, 'Cursor', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(THelpContext), TVisualGrid, 'HelpContext', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(string), TVisualGrid, 'HelpKeyword', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(THelpType), TVisualGrid, 'HelpType', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(TTranslateString), TVisualGrid, 'Hint', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(TComponentName), TVisualGrid, 'Name', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(PtrInt), TVisualGrid, 'Tag', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(Integer), TVisualGrid, 'Left', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(Integer), TVisualGrid, 'Top', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(Integer), TVisualGrid, 'Width', THiddenPropertyEditor);
  RegisterPropertyEditor(TypeInfo(Integer), TVisualGrid, 'Height', THiddenPropertyEditor);

  RegisterPropertyEditor(TypeInfo(TControl), TVisualGrid, 'WidgetControl', TWidgetsPropertyEditor);
  {$ENDIF}

end.
