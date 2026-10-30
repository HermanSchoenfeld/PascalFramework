unit UUiApiExamples;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>
  Worked grid and wizard recipes. Components own child controls; wizard models
  remain caller-owned. Distributed under the MIT license. }

{$IFDEF FPC}{$MODE DELPHI}{$H+}{$ENDIF}

interface

uses Classes, Controls;

procedure RunUiApiExamples(AParent: TWinControl; AOutput: TStrings);

implementation

uses SysUtils, Variants, Types, Forms, Graphics, Grids, Menus, StdCtrls,
  Generics.Collections, UCommon.Data, UCommon.UI, UVisualGrid, UWizard;

type
  TRecipeGrid = class(TVisualGrid)
  public
    procedure ClickHeader(AIndex: Integer);
  end;

  TNameSource = class(TCustomDataSource<String>)
  protected
    function GetColumns: TDataColumns; override;
    procedure FetchAll(const AContainer: TList<String>); override;
    function GetItemField({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem: String;
      const ABindingName: String): Variant; override;
  end;

  TGridRecipe = class(TComponent)
  private
    FOutput: TStrings;
    FPopup: TPopupMenu;
    procedure InitializeColumn(Sender: TObject; AColumn: TVisualColumn);
    function DisplayName(const CellData, RowData: Variant): Variant;
    procedure DrawName(Sender: TObject; ACol, ARow: Longint; Canvas: TCanvas;
      Rect: TRect; State: TGridDrawState; const CellData, RowData: Variant;
      var Handled: Boolean);
    procedure DrawCell(Sender: TObject; ACol, ARow: Longint; Canvas: TCanvas;
      Rect: TRect; State: TGridDrawState; const CellData, RowData: Variant;
      var Handled: Boolean);
    procedure Selected(Sender: TObject; {$IFDEF FPC}constref{$ELSE}const{$ENDIF}
      ASelection: TVisualGridSelection);
    procedure PreparePopup(Sender: TObject; {$IFDEF FPC}constref{$ELSE}const{$ENDIF}
      ASelection: TVisualGridSelection; out APopupMenu: TPopupMenu);
    {$IFNDEF FPC}
    procedure HeaderClicked(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure CellSelected(Sender: TObject; ACol, ARow: Integer);
    procedure ItemChanged(Sender: TObject; AIndex: Integer);
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent; AOutput: TStrings); reintroduce;
    procedure Run(AParent: TWinControl);
  end;

  TBagWizard = TActionWizard<TGenericWizardBag>;

  TRecipeScreen = class(TWizardForm<TGenericWizardBag>)
  public
    constructor Create(AOwner: TComponent); override;
    function Validate(out message: String): Boolean; override;
    procedure OnNext; override;
  end;

  TRecipeSummary = class(TRecipeScreen);

  TRecipeWizard = class(TBagWizard)
  protected
    procedure ShowHost; override;
  end;

  TWizardCallbacks = class
  private
    FOutput: TStrings;
  public
    constructor Create(AOutput: TStrings);
    function CanCancel(screenIndex: Integer;
      {$IFDEF FPC}constref{$ELSE}const{$ENDIF} model: TGenericWizardBag;
      out message: String): Boolean;
    function CanFinish({$IFDEF FPC}constref{$ELSE}const{$ENDIF}
      model: TGenericWizardBag; out message: String): Boolean;
    function CanClose(out message: String): Boolean;
  end;

procedure Require(ACondition: Boolean; const AMessage: String);
begin
  if not ACondition then raise Exception.Create(AMessage);
end;

procedure TRecipeGrid.ClickHeader(AIndex: Integer);
begin
  GridHeaderClick(Self, True, AIndex);
end;

function TNameSource.GetColumns: TDataColumns;
begin
  Result := TDataColumns.Create(TDataColumn.From('Name'));
end;

procedure TNameSource.FetchAll(const AContainer: TList<String>);
begin
  AContainer.Add('Ada');
  AContainer.Add('Grace');
end;

function TNameSource.GetItemField({$IFDEF FPC}constref{$ELSE}const{$ENDIF}
  AItem: String; const ABindingName: String): Variant;
begin
  Result := AItem;
end;

constructor TGridRecipe.Create(AOwner: TComponent; AOutput: TStrings);
begin
  inherited Create(AOwner);
  FOutput := AOutput;
  FPopup := TPopupMenu.Create(Self);
  FPopup.Items.Add(TMenuItem.Create(FPopup));
  FPopup.Items[0].Caption := 'Example action';
end;

procedure TGridRecipe.InitializeColumn(Sender: TObject; AColumn: TVisualColumn);
begin
  AColumn.HeaderFontStyles := [fsBold];
end;

function TGridRecipe.DisplayName(const CellData, RowData: Variant): Variant;
begin
  Result := UpperCase(VarToStr(CellData));
end;

procedure TGridRecipe.DrawName(Sender: TObject; ACol, ARow: Longint;
  Canvas: TCanvas; Rect: TRect; State: TGridDrawState;
  const CellData, RowData: Variant; var Handled: Boolean);
begin
  Canvas.Font.Style := [fsBold];
  Canvas.TextRect(Rect, Rect.Left + 2, Rect.Top + 2, VarToStr(CellData));
  Handled := True;
end;

procedure TGridRecipe.DrawCell(Sender: TObject; ACol, ARow: Longint;
  Canvas: TCanvas; Rect: TRect; State: TGridDrawState;
  const CellData, RowData: Variant; var Handled: Boolean);
begin
  // Leave handling to the configured column renderer.
  Handled := False;
end;

procedure TGridRecipe.Selected(Sender: TObject;
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} ASelection: TVisualGridSelection);
begin
  FOutput.Add(Format('Selection: page %d, %d row(s), %d column(s)',
    [ASelection.Page, ASelection.RowCount, ASelection.ColCount]));
end;

procedure TGridRecipe.PreparePopup(Sender: TObject;
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} ASelection: TVisualGridSelection;
  out APopupMenu: TPopupMenu);
begin
  APopupMenu := FPopup;
end;

{$IFNDEF FPC}
procedure TGridRecipe.HeaderClicked(Sender: TObject; IsColumn: Boolean; Index: Integer);
begin
  Require(IsColumn and (Index = 0), 'Header callback lost its column');
end;

procedure TGridRecipe.CellSelected(Sender: TObject; ACol, ARow: Integer);
begin
  Require((ACol = 0) and (ARow = 1), 'Cell callback lost its coordinates');
end;

procedure TGridRecipe.ItemChanged(Sender: TObject; AIndex: Integer);
begin
  FOutput.Add(Format('Checked search item %d changed', [AIndex]));
end;
{$ENDIF}

procedure TGridRecipe.Run(AParent: TWinControl);
var
  Grid: TRecipeGrid;
  BaseGrid: TCustomVisualGrid;
  Source: TNameSource;
  Column: TVisualColumn;
  GridCaption: TVisualGridCaption;
  Options: TVisualGridOptions;
  SelectionType: TSelectionType;
  DeselectionType: TDeselectionType;
  SortMode: UVisualGrid.TSortMode;
  SearchMode: UVisualGrid.TSearchMode;
  Renderer: TVisualColumnRenderer;
  Sanitizer: TVisualColumnDataSanitizer;
  DrawCallback: TDrawVisualCellEvent;
  SelectionCallback: TSelectionEvent;
  PopupCallback: TPreparePopupMenuEvent;
  ColumnCallback: TColumnInitializeEvent;
  Selection: TVisualGridSelection;
  Popup: TPopupMenu;
  {$IFNDEF FPC}
  NativeGrid: UVisualGrid.TDrawGrid;
  NativeColumn: UVisualGrid.TGridColumn;
  HeaderCallback: TVisualGridHeaderClick;
  CellCallback: TVisualGridCellSelected;
  Zone: TGridZone;
  CheckCombo: UVisualGrid.TCheckComboBox;
  CheckCallback: TCheckComboItemChange;
  {$ENDIF}
begin
  Source := TNameSource.Create(Self);
  Grid := TRecipeGrid.Create(Self);
  // A real parent supplies native metrics; the short recipe stays invisible.
  Grid.Visible := False;
  Grid.Parent := AParent;
  Grid.SetBounds(0, 0, 480, 240);
  BaseGrid := Grid;
  BaseGrid.FetchDataInThread := False;
  BaseGrid.PageSize := 2;
  Options := [vgoColSizing, vgoAutoHidePaging];
  SelectionType := stMultiRow;
  DeselectionType := dtDefault;
  SortMode := smMultiColumn;
  SearchMode := smSingle;
  Grid.Options := Options;
  Grid.SelectionType := SelectionType;
  Grid.DeselectionType := DeselectionType;
  Grid.SortMode := SortMode;
  Grid.SearchMode := SearchMode;
  GridCaption := Grid.Caption;
  GridCaption.Text := 'Names';
  GridCaption.Visible := True;
  ColumnCallback := InitializeColumn;
  Grid.OnColumnInitialize := ColumnCallback;
  Column := Grid.AddColumn('Name');
  Column.Binding := 'Name';
  Column.Filters := SORTABLE_TEXT_FILTER;
  Sanitizer := DisplayName;
  Renderer := DrawName;
  Column.Sanitizer := Sanitizer;
  Column.Renderer := Renderer;
  DrawCallback := DrawCell;
  SelectionCallback := Selected;
  PopupCallback := PreparePopup;
  Grid.OnDrawVisualCell := DrawCallback;
  Grid.OnSelection := SelectionCallback;
  Grid.OnPreparePopupMenu := PopupCallback;
  Grid.DataSource := Source;
  Grid.RefreshGrid;
  Require(Grid.RowCount = 2, 'Grid recipe did not populate its page');
  Require(VarToStr(Grid.Rows[0].Name) = 'Ada', 'Grid recipe lost row data');
  Require(VarToStr(Sanitizer(Grid.Cells[0, 0], Grid.Rows[0])) = 'ADA',
    'Column sanitizer did not transform its displayed value');
  Selection.Page := 0;
  SetLength(Selection.Selections, 1);
  Selection.Selections[0] := Rect(0, 0, 0, 1);
  SelectionCallback(Grid, Selection);
  PopupCallback(Grid, Selection, Popup);
  Require(Popup = FPopup, 'Popup callback did not return its menu');
  try
    Grid.ClickHeader(99);
    Require(False, 'An invalid header should be rejected');
  except
    on E: EVisualGridError do FOutput.Add('Invalid column: ' + E.Message);
  end;
  {$IFNDEF FPC}
  // The VCL branch exposes small compatibility types used by the same grid.
  NativeGrid := Grid.InternalDrawGrid;
  NativeColumn := Grid.Columns[0].InternalColumn;
  Require(NativeColumn <> nil, 'Native column metadata is missing');
  Zone := NativeGrid.MouseToGridZone(-1, -1);
  Require(Zone = gzInvalid, 'Outside coordinates should have no grid zone');
  HeaderCallback := HeaderClicked;
  CellCallback := CellSelected;
  HeaderCallback(NativeGrid, True, 0);
  CellCallback(NativeGrid, 0, 1);
  CheckCombo := UVisualGrid.TCheckComboBox.Create(Self);
  CheckCombo.Visible := False;
  CheckCombo.Parent := AParent;
  CheckCombo.AddItem('Name', cbChecked);
  CheckCombo.Objects[0] := Self; // Borrowed metadata, not transferred ownership.
  CheckCallback := ItemChanged;
  CheckCombo.OnItemChange := CheckCallback;
  Require(CheckCombo.Checked[0], 'Checked search field lost its state');
  CheckCombo.Checked[0] := False;
  Require(CheckCombo.Objects[0] = Self, 'Checked search field lost its metadata');
  CheckCombo.Clear;
  {$ENDIF}
  FOutput.Add('Grid columns, rendering, selection and popup recipes passed.');
end;

constructor TRecipeScreen.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  ClientWidth := 360;
  ClientHeight := 180;
end;

function TRecipeScreen.Validate(out message: String): Boolean;
begin
  Result := VarToStr(Model['Name']) <> '';
  if Result then message := '' else message := 'Enter a name';
end;

procedure TRecipeScreen.OnNext;
begin
  inherited;
  // Back restores the old branch, so the dynamic first page registers its
  // continuation on every accepted Next. Repeated injection is idempotent.
  if ClassType = TRecipeScreen then UpdatePath(ptInject, [TRecipeSummary]);
end;

procedure TRecipeWizard.ShowHost;
var
  Screen: TBagWizard.__TScreenType;
  ScreenBase: TWizardFormBase;
  ScreenClass: TWizardFormClass;
  Route: TWizardScreenPath;
  Classes: TBagWizard.__TList_TComponentClass;
  Trait: TWizardStepTrait;
  Traits: TWizardStepTraits;
  PathUpdate: TPathUpdateType;
  WizardState: TWizardState;
  Message: String;
begin
  // The interactive feature wizard uses the same host. This recipe walks the
  // lifecycle without opening a second modal loop or requiring user input.
  Screen := CurrentScreen;
  ScreenBase := Screen;
  ScreenClass := TRecipeScreen;
  Require(ScreenBase.InheritsFrom(ScreenClass), 'Unexpected first screen');
  Trait := wstAssumeHasNext;
  Traits := [Trait];
  Screen.Traits := Traits;
  PathUpdate := ptInject;
  UpdatePath(PathUpdate, [TRecipeSummary]);
  Route := Screens;
  Classes := TBagWizard.__TList_TComponentClass.Create;
  try
    Classes.AddRange(Route);
    Require(Classes.Count = 2, 'Dynamic wizard path was not injected');
  finally
    Classes.Free;
  end;
  Require(TryNext(Message), Message);
  Require(TryPrevious(Message), Message);
  Require(CurrentScreen = Screen, 'Previous did not reuse the owned screen');
  Require(TryNext(Message), Message);
  Require(Finish(Message), Message);
  WizardState := State;
  Require(WizardState = wsFinished, 'Wizard did not reach its terminal state');
end;

constructor TWizardCallbacks.Create(AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

function TWizardCallbacks.CanCancel(screenIndex: Integer;
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} model: TGenericWizardBag;
  out message: String): Boolean;
begin
  message := '';
  Result := True;
end;

function TWizardCallbacks.CanFinish({$IFDEF FPC}constref{$ELSE}const{$ENDIF}
  model: TGenericWizardBag; out message: String): Boolean;
begin
  message := '';
  Result := True;
  FOutput.Add('Wizard finished for ' + VarToStr(model['Name']));
end;

function TWizardCallbacks.CanClose(out message: String): Boolean;
begin
  message := '';
  Result := True;
end;

procedure RunUiApiExamples(AParent: TWinControl; AOutput: TStrings);
var
  GridRecipe: TGridRecipe;
  Model: TGenericWizardBag;
  Callbacks: TWizardCallbacks;
  Wizard: TRecipeWizard;
  CancelCallback: TBagWizard.TActionWizardCancelFunc;
  FinishCallback: TBagWizard.TActionWizardFinishFunc;
  Host: TWizardHostForm;
  CloseCallback: TWizardHostForm.TWizardHostFormCloseQueryDelegate;
  Message: String;
begin
  GridRecipe := TGridRecipe.Create(nil, AOutput);
  try
    GridRecipe.Run(AParent);
  finally
    GridRecipe.Free;
  end;
  Model := TGenericWizardBag.Create;
  Callbacks := TWizardCallbacks.Create(AOutput);
  try
    Model.Add('Name', 'Ada');
    CancelCallback := Callbacks.CanCancel;
    FinishCallback := Callbacks.CanFinish;
    Wizard := TRecipeWizard.Create(nil, 'Name recipe', 'Finish',
      [TRecipeScreen], CancelCallback, FinishCallback);
    try
      Wizard.Start(Model);
    finally
      Wizard.Free; // Screens finish using the borrowed model before it is freed.
    end;
    Host := TWizardHostForm.Create(nil);
    try
      Host.TitleText := 'Custom host';
      Host.SetContentSize(Point(360, 180));
      CloseCallback := Callbacks.CanClose;
      Host.CloseQueryEvent := CloseCallback;
      Require(Host.CloseQueryEvent(Message), Message);
    finally
      Host.Free;
    end;
  finally
    Callbacks.Free;
    Model.Free;
  end;
  AOutput.Add('Wizard model, dynamic route, host and callback recipes passed.');
end;

end.
