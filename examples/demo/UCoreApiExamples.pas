unit UCoreApiExamples;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>. MIT license.
  Worked data, notification, locking and common-control examples shared by
  the Delphi and Lazarus application. }

{$IFDEF FPC}{$mode Delphi}{$H+}{$ENDIF}

interface

uses Classes;

// Call on the application thread. Each group checks the result it demonstrates.
procedure RunCoreApiExamples(AOutput: TStrings);

implementation

uses SysUtils, Types, Variants, Math, Generics.Collections, Generics.Defaults,
  {$IFDEF FPC}Forms, Controls, ExtCtrls, Graphics, ImgList,
  {$ELSE}Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls, Vcl.Graphics, Vcl.ImgList,{$ENDIF}
  UMemory, UCommon, UCommon.Collections, UCommon.Data, UCommon.UI, UConcurrency;

type
  TIntegerArrays = TArrayTool<Integer>;
  TNotificationArrays = TArrayTool<TNotifyEvent>;
  TIntegerDataTools = TDataSourceTool<Integer>;
  TThrottleMode = TThrottledEvent.TThrottledEventMode;

  TExampleListener = class
  public
    Calls, WaitingChanges, Activations, Destructions: Integer;
    CallbackThread: TThreadID;
    procedure Received(Sender: TObject);
    procedure WaitingChanged(Sender: TObject);
    procedure Activated(Sender: TObject);
    procedure Destroyed(Sender: TObject);
  end;

  TNotificationProducer = class(TThread)
  private
    FDispatcher: TThreadNotify;
    FListener: TExampleListener;
  protected
    procedure Execute; override;
  public
    constructor Create(ADispatcher: TThreadNotify; AListener: TExampleListener);
  end;

  // The callback target and its borrowed flag outlive the nested scope.
  TTemporaryFlag = class
  private
    FFlag: PBoolean;
    FPrevious: Boolean;
  public
    constructor Create(AFlag: PBoolean);
    procedure Activate;
    procedure Restore;
  end;

  // The base handles rows, filtering, sorting and paging; an adapter supplies
  // only its source items, column descriptions and field values.
  TExampleDataSource = class(TCustomDataSource<Integer>)
  protected
    function GetColumns: TDataColumns; override;
    function GetItemField({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem: Integer;
      const ABindingName: String): Variant; override;
    procedure FetchAll(const AContainer: TList<Integer>); override;
  public
    FetchCount: Integer;
    function FilterValue({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem: Integer;
      {$IFDEF FPC}constref{$ELSE}const{$ENDIF} AFilter: TColumnFilter): Boolean;
    function CompareValues({$IFDEF FPC}constref{$ELSE}const{$ENDIF} ALeft, ARight: Integer;
      {$IFDEF FPC}constref{$ELSE}const{$ENDIF} AFilter: TColumnFilter): Integer;
    function NullOrder(const AFilter: TColumnFilter): TSortNullPolicy;
  end;

procedure Require(ACondition: Boolean; const AMessage: String);
begin
  if not ACondition then raise Exception.Create('Core example: ' + AMessage);
end;

procedure CommonValuesAndResults;
var
  LScope: TDisposables;
  LBox: TBox<String>;
  LSize: SizeInt;
  LPointer: PtrInt;
  LSequence: QWord;
  LFlags: DWord;
  LDelay: TTimeSpan;
  LDate: TDateTime;
  LSeverity: TLogSeverity;
  LMessage: TLogMessage;
  LResult: TResult;
  LStats: TStatistics;
begin
  // These aliases retain pointer-sized and unsigned intent on both compilers.
  LBox := LScope.AddObject(TBox<String>.Create('shared value')) as TBox<String>;
  LSize := Length(LBox.Value);
  LPointer := PtrInt(LBox);
  LSequence := 42;
  LFlags := $10;
  Require((LSize = 12) and (LPointer <> 0) and (LSequence = 42) and
    (LFlags = $10), 'portable numeric aliases and boxed value');
  LBox.Value := 'updated';
  Require(LBox.Value = 'updated', 'boxed value replacement');

  LDelay := TTimeSpan.FromSeconds(2).Add(TTimeSpan.FromMilliseconds(500));
  Require(Abs(LDelay.TotalMilliseconds - 2500) < EPSILON, 'time span addition');
  LDelay := LDelay.Subtract(TTimeSpan.FromMilliseconds(500));
  Require(Abs(LDelay.TotalSeconds - 2) < EPSILON, 'time span subtraction');
  LDate := TDateTime.Create(2026, 10, 30, 12, 15, 0, 0);
  Require((LDate.Year = 2026) and (LDate.Month = 10) and (LDate.Day = 30),
    'date component helper');
  Require(LDate.AddDays(1).IsSameDay(TDateTime.Create(2026, 10, 31)),
    'date arithmetic helper');
  Require(LDate.StartOfMonth.Day = 1, 'month boundary helper');

  LSeverity := lsInfo;
  LMessage := TLogMessage.From('Imported three rows', LSeverity, LDate);
  Require((LMessage.Severity = LSeverity) and (LMessage.TimeStamp = LDate),
    'explicit log metadata is retained');
  LResult := TResult.Success;
  LResult.Value := 3;
  LResult.Add(LMessage);
  LResult.AddDebug('Parsed input');
  LResult.AddWarning('Optional note absent');
  Require(LResult.IsSuccess and (Integer(LResult.Value) = 3) and
    (Length(LResult.Messages) = 3), 'result carries a value and diagnostic messages');
  LResult.AddError('Required value absent');
  Require(LResult.IsFailure and (Pos('Required value absent',
    LResult.ToString(False, True)) > 0), 'error makes a result fail');
  Require(TResult.Failure('Validation failed').IsFailure, 'failure factory');

  LStats.Reset;
  LStats.AddDatum(1);
  LStats.AddDatum(2);
  LStats.AddDatum(3);
  Require((LStats.SampleCount = 3) and (Abs(LStats.Mean - 2) < EPSILON) and
    (Abs(LStats.SampleVariance - 1) < EPSILON), 'running statistics');
  LStats.RemoveDatum(2);
  Require((LStats.SampleCount = 2) and (Abs(LStats.Sum - 4) < EPSILON),
    'remove a datum without retaining its source array');
  Require(TCPUTool.GetLogicalCPUCount > 0, 'logical CPU count');
end;

procedure VariantAndFileTools;
var
  LBytes: TBytes;
  LBoolean: Boolean;
  LGuid: TGUID;
  LFileName: String;
  LFile: TFileStream;
  LUnicode: UnicodeString;
  {$IFDEF FPC}LUTF8: UTF8String;{$ENDIF}
  LText: String;
  LExpected: TBytes;
  I: Integer;
begin
  Require(TryHex2Bytes('00ff10', LBytes), 'hex decoding');
  Require(Bytes2Hex(LBytes) = '00FF10', 'hex encoding');
  Require(BytesEqual(LBytes, Hex2Bytes('00ff10')), 'byte equality');
  Require(BinStrComp(#0'A', #0'B') < 0, 'binary-safe string comparison');
  Require(TVariantTool.IsNumeric(42) and TVariantTool.IsBool(True),
    'variant type inspection');
  Require(TVariantTool.TryParseBool(VarToStr(True), LBoolean) and LBoolean,
    'variant Boolean parsing');
  Require((TVariantTool.VarToInt('42') = 42) and
    (TVariantTool.CompareVariant(10, 20) < 0), 'variant conversion and comparison');
  // Text matches are case-sensitive; Boolean text uses the RTL's spelling.
  Require(TVariantTool.MatchTextExact('report', 'report') and
    TVariantTool.MatchTextBeginning('report', 'rep') and
    TVariantTool.MatchTextEnd('report', 'ort') and
    TVariantTool.MatchTextAnywhere('report', 'por'), 'text match variants');
  Require(TVariantTool.NumericEQ(2, 2) and TVariantTool.NumericLT(1, 2) and
    TVariantTool.NumericLTE(2, 2) and TVariantTool.NumericGT(3, 2) and
    TVariantTool.NumericGTE(2, 2) and
    TVariantTool.NumericBetweenInclusive(2, 1, 3) and
    TVariantTool.NumericBetweenExclusive(2, 1, 3), 'numeric match variants');

  CreateGUID(LGuid);
  LFileName := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) +
    'Sphere10CoreExample-' + GUIDToString(LGuid) + '.tmp';
  LUnicode := #$0041#$03A9#$6F22#$D83D#$DE80;
  {$IFDEF FPC}
  // Preserve Lazarus UTF-8 bytes even when this recipe runs in an ANSI console.
  LUTF8 := UTF8Encode(LUnicode);
  SetLength(LText, Length(LUTF8));
  Move(LUTF8[1], LText[1], Length(LUTF8));
  {$ELSE}
  LText := LUnicode;
  {$ENDIF}
  try
    TFileTool.AppendText(LFileName, 'ABC');
    TFileTool.AppendText(LFileName, LText);
    TFileTool.AppendText(LFileName, '');
    // Expected bytes are literal, independent of the encoder under test.
    LExpected := TBytes.Create($41, $42, $43, $0D, $0A,
      $41, $CE, $A9, $E6, $BC, $A2, $F0, $9F, $9A, $80, $0D, $0A, $0D, $0A);
    LFile := TFileStream.Create(LFileName, fmOpenReadWrite or fmShareDenyWrite);
    try
      {$IFNDEF FPC}
      LFile.Position := LFile.Size;
      // TFileStreamHelper adds WriteString only on Delphi. LCL's RTL already
      // has binary string APIs; the empty FPC helper adds no methods.
      LFile.WriteString('');
      LFile.WriteString(LText);
      LFile.WriteString('Z');
      LExpected := TBytes.Create($41, $42, $43, $0D, $0A,
        $41, $CE, $A9, $E6, $BC, $A2, $F0, $9F, $9A, $80, $0D, $0A, $0D, $0A,
        $41, $CE, $A9, $E6, $BC, $A2, $F0, $9F, $9A, $80, $5A);
      {$ENDIF}
      Require(LFile.Size = Length(LExpected), 'UTF-8 has no BOM or length prefix');
      LFile.Position := 0;
      SetLength(LBytes, Length(LExpected));
      LFile.ReadBuffer(LBytes[0], Length(LBytes));
      for I := 0 to High(LExpected) do
        Require(LBytes[I] = LExpected[I], 'exact UTF-8 byte ' + IntToStr(I));
    finally
      LFile.Free;
    end;
  finally
    if FileExists(LFileName) then DeleteFile(LFileName);
  end;
end;

procedure TExampleListener.Received(Sender: TObject);
begin
  Inc(Calls);
  CallbackThread := TThread.CurrentThread.ThreadID;
end;

procedure TExampleListener.WaitingChanged(Sender: TObject);
begin
  Inc(WaitingChanges);
end;

procedure TExampleListener.Activated(Sender: TObject);
begin
  Inc(Activations);
end;

procedure TExampleListener.Destroyed(Sender: TObject);
begin
  Inc(Destructions);
end;

constructor TNotificationProducer.Create(ADispatcher: TThreadNotify;
  AListener: TExampleListener);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FDispatcher := ADispatcher;
  FListener := AListener;
end;

procedure TNotificationProducer.Execute;
begin
  // The worker queues the callback and returns; UI handling does not run here.
  FDispatcher.Invoke(FListener, FListener.Received);
end;

procedure Notifications;
var
  LScope: TDisposables;
  LListener: TExampleListener;
  LEvent: TNotifyManyEvent;
  LPending: TThreadNotify.TPendingNotifyManyEvent;
  LDispatcher: TThreadNotify;
  LProducer: TNotificationProducer;
begin
  LListener := LScope.AddObject(TExampleListener.Create) as TExampleListener;
  LEvent.Add(LListener.Received);
  LEvent.Add(LListener.Received); // A duplicate registration is ignored.
  LEvent.Invoke(LListener);
  Require(LListener.Calls = 1, 'multicast notification and duplicate prevention');
  LEvent.Remove(LListener.Received);
  LEvent.Invoke(LListener);
  Require(LListener.Calls = 1, 'multicast listener removal');

  // This public transport record borrows its sender and callback targets.
  LPending.Sender := LListener;
  LPending.Handlers := TNotificationArrays.Create(LListener.Received);
  LDispatcher := LScope.AddObject(TThreadNotify.Create(TThread.CurrentThread))
    as TThreadNotify;
  LDispatcher.Invoke(LPending.Sender, LPending.Handlers);
  Require(LListener.Calls = 2, 'notification transport record');
  TThreadNotify.InvokeMainThread(LListener, LListener.Received);
  Require(LListener.Calls = 3, 'main-thread dispatch from the main thread');

  LProducer := TNotificationProducer.Create(LDispatcher, LListener);
  try
    LProducer.Start;
    LProducer.WaitFor;
    CheckSynchronize;
    Require((LListener.Calls = 4) and
      (LListener.CallbackThread = TThread.CurrentThread.ThreadID),
      'worker completion marshals its callback to the UI thread');
  finally
    // Join producers before their dispatcher or borrowed receivers are freed.
    LProducer.Free;
  end;
end;

constructor TTemporaryFlag.Create(AFlag: PBoolean);
begin
  inherited Create;
  FFlag := AFlag;
end;

procedure TTemporaryFlag.Activate;
begin
  FPrevious := FFlag^;
  FFlag^ := True;
end;

procedure TTemporaryFlag.Restore;
begin
  if Assigned(FFlag) then FFlag^ := FPrevious;
end;

procedure ScopedReadWriteLocking;
var
  Resources: TDisposables;
  Gate: TReadWriteLock;
  Value: Integer;
  Active: Boolean;
  Flag: TTemporaryFlag;

  procedure WriteValue;
  var Scope: TScope;
  begin
    Scope := Gate.EnterWriteScope;
    Require(Gate.IsWriteLockHeld, 'managed write scope is held');
    Inc(Value);
  end;

  procedure ReadValue;
  var Scope: TScope;
  begin
    Scope := Gate.EnterReadScope;
    Require(Gate.IsReadLockHeld and (Value = 1), 'managed read scope sees the value');
  end;

  procedure TemporaryChange;
  var Scope: TScope;
  begin
    Scope := TScope.Create(Flag.Restore);
    Flag.Activate;
    Require(Active and not Scope.IsEmpty, 'custom cleanup is retained');
    WriteValue;
    ReadValue;
  end;

  procedure UpgradeAndWrite;
  var Scope: TScope;
  begin
    Scope := Gate.EnterUpgradeableReadScope;
    if Value = 1 then WriteValue;
    Require(Gate.IsUpgradeableReadLockHeld and not Gate.IsWriteLockHeld,
      'inner write released while the upgradeable scope remains held');
  end;

begin
  Gate := Resources.AddObject(TReadWriteLock.Create) as TReadWriteLock;
  Value := 0;
  Active := False;
  Flag := Resources.AddObject(TTemporaryFlag.Create(@Active)) as TTemporaryFlag;
  TemporaryChange;
  Require(not Active, 'custom scope automatically restored the flag');
  UpgradeAndWrite;
  Require((Value = 2) and not Gate.IsReadLockHeld and
    not Gate.IsWriteLockHeld and not Gate.IsUpgradeableReadLockHeld,
    'routine exits automatically released every managed lock scope');
end;

procedure ReadWriteLocking;
var
  LScope: TDisposables;
  LPolicy: TLockRecursionPolicy;
  LLock, LNonRecursive: TReadWriteLock;
  LValue: Integer;
  LCaught: Boolean;
begin
  LPolicy := lrpSupportsRecursion;
  LLock := LScope.AddObject(TReadWriteLock.Create(LPolicy)) as TReadWriteLock;
  LValue := 10;
  LLock.AcquireUpgradeableReadLock;
  try
    Require(LLock.IsUpgradeableReadLockHeld, 'upgradeable read ownership');
    if LValue = 10 then begin
      Require(LLock.TryAcquireWriteLock(0), 'upgrade without another reader');
      try
        LLock.AcquireWriteLock;
        try
          LValue := 20;
          Require(LLock.RecursiveWriteCount = 2, 'recursive write ownership');
        finally
          LLock.ReleaseWriteLock;
        end;
      finally
        LLock.ReleaseWriteLock;
      end;
    end;
    Require(not LLock.IsWriteLockHeld and LLock.IsUpgradeableReadLockHeld,
      'leaving write scope retains the outer upgradeable scope');
  finally
    LLock.ReleaseUpgradeableReadLock;
  end;
  Require(LLock.TryAcquireReadLock(0), 'timed read acquisition');
  try
    Require((LValue = 20) and (LLock.CurrentReadCount = 1), 'shared read scope');
  finally
    LLock.ReleaseReadLock;
  end;

  LNonRecursive := LScope.AddObject(TReadWriteLock.Create(lrpNoRecursion))
    as TReadWriteLock;
  LNonRecursive.AcquireReadLock;
  try
    LCaught := False;
    try
      LNonRecursive.AcquireReadLock;
    except
      on E: ELockRecursionException do LCaught := True;
    end;
    Require(LCaught, 'no-recursion policy rejects nested reads');
  finally
    LNonRecursive.ReleaseReadLock;
  end;
  LCaught := False;
  try
    LNonRecursive.ReleaseWriteLock;
  except
    on E: ESynchronizationLockException do LCaught := True;
  end;
  Require(LCaught, 'only an owning thread may release a scope');
  LNonRecursive.Dispose;
  LCaught := False;
  try
    LNonRecursive.AcquireReadLock;
  except
    on E: ELockDisposedException do LCaught := True;
  end;
  Require(LCaught, 'disposed locks reject acquisition');
end;

function TExampleDataSource.GetColumns: TDataColumns;
begin
  SetLength(Result, 2);
  Result[0] := TDataColumn.From('Value', True);
  Result[1] := TDataColumn.From('Name');
end;

function TExampleDataSource.GetItemField(
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem: Integer;
  const ABindingName: String): Variant;
begin
  if ABindingName = 'Value' then Result := AItem
  else if ABindingName = 'Name' then Result := 'Item ' + IntToStr(AItem)
  else raise EDataTable.Create('Unknown example column: ' + ABindingName);
end;

procedure TExampleDataSource.FetchAll(const AContainer: TList<Integer>);
begin
  Inc(FetchCount);
  AContainer.AddRange(TIntegerArrays.Create(30, 10, 20));
end;

function TExampleDataSource.FilterValue(
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} AItem: Integer;
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} AFilter: TColumnFilter): Boolean;
begin
  Result := ApplyColumnFilter(AItem, AFilter);
end;

function TExampleDataSource.CompareValues(
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} ALeft, ARight: Integer;
  {$IFDEF FPC}constref{$ELSE}const{$ENDIF} AFilter: TColumnFilter): Integer;
begin
  Result := ApplyColumnSort(ALeft, ARight, AFilter);
end;

function TExampleDataSource.NullOrder(const AFilter: TColumnFilter): TSortNullPolicy;
begin
  Result := GetNullPolicy(AFilter);
end;

procedure DataRowsAndPaging;
var
  LScope: TDisposables;
  LSource: TExampleDataSource;
  LInterface: IDataSource;
  LTable: TDataTable;
  LTablePointer: PDataTable;
  LRow, LCopy: Variant;
  LRowData: TDataRowData;
  LFilter, LSort: TColumnFilter;
  LFilters: TFilterCriteria;
  LAllowed: TDataFilters;
  LParams: TPageFetchParams;
  LPage: TPageFetchResult;
  LApplyFilter: TApplyFilterDelegate<Integer>;
  LApplySort: TApplySortDelegate<Integer>;
  LPredicate, LCombined: IPredicate<Integer>;
  LComparer: IComparer<Integer>;
  LCaught: Boolean;
begin
  LSource := LScope.AddObject(TExampleDataSource.Create(nil)) as TExampleDataSource;
  LSource.SnapshotCacheEnabled := True;
  try
    LInterface := LSource; // Component lifetime is owned by the disposal bag.
    LAllowed := SORTABLE_NUMERIC_FILTER;
    Require((vgfNumericGTE in LAllowed) and (vgfSortable in LAllowed),
      'column filter capability set');
    LFilter := Default(TColumnFilter);
    LFilter.ColumnName := 'Value';
    LFilter.Filter := vgfNumericGTE;
    SetLength(LFilter.Values, 1);
    LFilter.Values[0] := 20;
    LSort := Default(TColumnFilter);
    LSort.ColumnName := 'Value';
    LSort.Filter := vgfSortable;
    LSort.Sort := sdDescending;
    LSort.SortSequence := 0;
    SetLength(LFilters, 2);
    LFilters[0] := LFilter;
    LFilters[1] := LSort;
    LParams := TPageFetchParams.Create(0, 1, LFilters, foAnd);
    Require((Length(LParams.GetSearchFilters) = 1) and
      (Length(LParams.GetSortFilters) = 1), 'separate search and sort criteria');
    LPage := LInterface.FetchPage(LParams, LTable);
    Require((LPage.TotalDataCount = 2) and (LPage.PageCount = 2) and
      (Length(LTable.Rows) = 1) and (Integer(LTable.Rows[0].Value) = 30),
      'filter, sort and fetch only the first visible row');
    LTablePointer := @LTable;
    Require((Length(LTablePointer^.Columns) = 2) and
      LTablePointer^.Columns[0].IsKey, 'table pointer and key column metadata');
    LParams.PageIndex := 1;
    LPage := LInterface.FetchPage(LParams, LTable);
    Require((Integer(LTable.Rows[0].Value) = 20) and (LSource.FetchCount = 1),
      'page navigation reuses the source snapshot');
    LSource.InvalidateSnapshot;
    LPage := LInterface.FetchPage(LParams, LTable);
    Require(LSource.FetchCount = 2, 'explicit snapshot invalidation');

    LRow := TDataRow.New(PtrInt(TExampleDataSource), LTable.Columns);
    LRowData := TDataRowData(LRow);
    LRowData['Value'] := 40;
    LRowData['Name'] := 'Item 40';
    LRowData['__KEY'] := 400;
    LCopy := LRow;
    LCopy.Name := 'independent copy';
    Require(LRowData.HasData('Name') and (String(LRow.Name) = 'Item 40') and
      (Integer(LRow._(0)) = 40) and (Integer(LRow.__KEY) = 400),
      'dynamic named/positional bindings, row copies and separate key');
    LCaught := False;
    try
      LCopy := LRow.MissingColumn;
    except
      on E: EDataRow do LCaught := True;
    end;
    Require(LCaught, 'row binding errors have a specific exception');

    LApplyFilter := LSource.FilterValue;
    LApplySort := LSource.CompareValues;
    LPredicate := TColumnFilterPredicate<Integer>.Create(LFilter, LApplyFilter);
    LComparer := TColumnFieldComparer<Integer>.Create(LSort, LApplySort);
    Require(LPredicate.Evaluate(20) and not LPredicate.Evaluate(10) and
      (LComparer.Compare(30, 20) < 0), 'delegate-backed predicates and comparers');
    LCombined := TIntegerDataTools.ConstructRowPredicate(LFilters, LApplyFilter, foOr);
    LComparer := TIntegerDataTools.ConstructRowComparer(LFilters, LApplySort);
    Require(LCombined.Evaluate(30) and (LComparer.Compare(30, 20) < 0),
      'data-source predicate/comparer composition');
    LSort.Sort := sdAscending;
    Require(LSource.NullOrder(LSort) = snpNullLast, 'ascending null placement');
    LSort.Sort := sdDescending;
    Require(LSource.NullOrder(LSort) = snpNullFirst, 'descending null placement');
    LSort.Sort := sdNone;
    Require(LSource.NullOrder(LSort) = snpNone, 'no sort has no null ordering');
    LFilter.ColumnName := 'MissingColumn';
    LCaught := False;
    try
      LSource.FilterValue(10, LFilter);
    except
      on E: EDataTable do LCaught := True;
    end;
    Require(LCaught, 'adapter rejects an unknown column with EDataTable');
  finally
    // TComponent interfaces are borrowed, not reference-counted owners. Release
    // the view before the disposal bag frees its concrete component.
    LInterface := nil;
    LPredicate := nil;
    LCombined := nil;
    LComparer := nil;
  end;
end;

procedure SearchExpressions;
var
  LExpression: TExpressionRecord;
  LKind: TExpressionKind;
  LText: TTextMatchKind;
  LNumber: TNumericComparisionKind;
  LSet: TSetKind;
  LCaught: Boolean;
begin
  LKind := ekText;
  TSearchExpressionService.Parse('report%', LKind, LExpression);
  LText := LExpression.TextMatchKind;
  Require((LExpression.Kind = ekText) and (LText = tmkMatchTextBeginning) and
    (String(LExpression.Values[0]) = 'report'), 'text prefix expression');
  LExpression := TSearchExpressionService.Parse('>=20');
  LNumber := LExpression.NumericComparisionKind;
  Require((LExpression.Kind = ekNum) and (LNumber = nckNumericGTE),
    'numeric comparison expression');
  LExpression := TSearchExpressionService.Parse('[10,30]');
  LSet := LExpression.SetKind;
  Require((LExpression.Kind = ekSet) and (LSet = skNumericBetweenInclusive) and
    (Length(LExpression.Values) = 2), 'inclusive numeric range expression');
  LCaught := False;
  try
    TSearchExpressionService.Parse('>=', ekNum, LExpression);
  except
    on E: ESearchExpressionParserException do LCaught := True;
  end;
  Require(LCaught, 'invalid expressions retain a parser-specific exception');
end;

procedure CommonVisuals;
var
  LScope: TDisposables;
  LListener: TExampleListener;
  LHost: TForm;
  LPanel: TPanel;
  LHosted: TApplicationForm;
  LImages: TImageList;
  LBitmap: TBitmap;
  LImage: TImage;
  LCircle: TLoadingCircle;
  LThrottle: TThrottledEvent;
  LMode: TThrottleMode;
begin
  LListener := LScope.AddObject(TExampleListener.Create) as TExampleListener;
  LHost := LScope.AddObject(TForm.CreateNew(nil)) as TForm;
  LHost.ClientWidth := 200;
  LHost.ClientHeight := 100;
  LPanel := TPanel.Create(LHost);
  LPanel.Parent := LHost;
  LPanel.Align := alClient;
  LHosted := TApplicationForm.CreateNew(LHost);
  LHosted.OnActivateFirstTime := LListener.Activated;
  LHosted.OnDestroyed := LListener.Destroyed;
  LHosted.CloseAction := caHide;
  LHosted.AutoDispose(TStringList.Create);
  LPanel.AddControlDockCenter(LHosted);
  Require((LHosted.Parent = LPanel) and (LHosted.ActivationCount = 1) and
    (LListener.Activations = 1), 'embedded application form and first activation');
  LPanel.RemoveAllControls(True);
  Require((LPanel.ControlCount = 0) and (LListener.Destructions = 1),
    'remove embedded controls and release form-owned disposables');
  // TFormHelper is currently empty: it adds no callable API to demonstrate.

  LImages := TImageList.Create(LHost);
  LImages.Width := 16;
  LImages.Height := 16;
  LBitmap := LScope.AddObject(TBitmap.Create) as TBitmap;
  LBitmap.SetSize(16, 16);
  LBitmap.Canvas.Brush.Color := clRed;
  LBitmap.Canvas.FillRect(Rect(0, 0, 16, 16));
  LImages.Add(LBitmap, nil);
  LImage := TImage.Create(LHost);
  LImage.Parent := LPanel;
  LImage.SetImageListPicture(LImages, 0);
  Require(LImage.Picture.Width = 16, 'copy native image-list picture');
  LCircle := TLoadingCircle.Create(LHost);
  LCircle.Parent := LPanel;
  LCircle.SpokeColor := clGray;
  LCircle.Active := True;
  Require(LCircle.Active, 'component-owned loading animation');
  LCircle.Active := False;

  LThrottle := TThrottledEvent.Create(LHost);
  LThrottle.Interval := TTimeSpan.FromSeconds(5);
  LThrottle.Add(LListener.Received);
  LThrottle.OnWaitingChanged.Add(LListener.WaitingChanged);
  for LMode := Low(TThrottleMode) to High(TThrottleMode) do begin
    LThrottle.Mode := LMode;
    LThrottle.Notify;
    if LMode in [TThrottleMode.temNotifyOnEventBurstFinished,
      TThrottleMode.temNotifyOnEventBurstStartAndFinished] then
      Require(LThrottle.Waiting, 'quiet-burst mode owns its waiting state');
    // The interactive Throttle tab demonstrates elapsed time and repeated
    // notifications. This quick API example cancels each pending timer.
    LThrottle.Cancel;
    Require(not LThrottle.Waiting, 'cancel releases throttle waiting state');
  end;
  LThrottle.Remove(LListener.Received);
  Require(LListener.WaitingChanges > 0, 'waiting-change notification');
end;

procedure RunCoreApiExamples(AOutput: TStrings);
begin
  CommonValuesAndResults;
  AOutput.Add('Values: boxing, numeric aliases, dates, spans, results, statistics and CPU count passed.');
  VariantAndFileTools;
  AOutput.Add('Tools: bytes, variant matching and temporary-file append passed.');
  Notifications;
  AOutput.Add('Events: multicast subscription and worker-to-main-thread dispatch passed.');
  ReadWriteLocking;
  ScopedReadWriteLocking;
  AOutput.Add('Read/Write Locking: nested upgrade/write scopes and ownership errors passed.');
  DataRowsAndPaging;
  SearchExpressions;
  AOutput.Add('Data: adapter, rows, filters, sorting, cached paging and expression parsing passed.');
  CommonVisuals;
  AOutput.Add('UI: hosted forms, native images, loading circle and throttle lifecycle passed.');
end;

end.
