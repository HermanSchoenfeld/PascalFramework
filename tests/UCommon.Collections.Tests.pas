unit UCommon.Collections.Tests;

{$mode delphi}
{$H+}
{$modeswitch nestedprocvars}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry;

type

  TCompareTests = class(TTestCase)
    private
      function ObjectCompareFunc(constref Left, Right : Integer ) : Integer;
    published
      procedure NestedCompare;
      procedure ObjectCompare;
      procedure GlobalCompare;
      procedure ManyTest_LE;
      procedure ManyTest_EQ;
      procedure ManyTest_GE;
      procedure MemTest;
  end;

  TFilterTests = class(TTestCase)
    private
      function ObjectFilterFunc(constref AItem : Integer ) : boolean;
    protected
      procedure SetUp; override;
      procedure TearDown; override;
    published
      procedure NestedFilter;
      procedure ObjectFilter;
      procedure GlobalFilter;
      procedure AndManyFilter;
      procedure OrManyFilter;
  end;

  TTransformTests = class(TTestCase)
    private
      FTransformCount, FTransformOffset: Integer;
      function ObjectTransform(constref AItem: Integer): String;
      procedure CheckTransforms(AFamily: Integer);
    published
      procedure GlobalTransformsOwnTheirAdapters;
      procedure ObjectTransformsOwnTheirAdapters;
      procedure NestedTransformsOwnTheirAdapters;
  end;

implementation

uses Generics.Defaults, Generics.Collections, UCommon, UCommon.Collections, UMemory, LazLogger;

{ TCompareTests }

procedure TCompareTests.NestedCompare;
var
  cmp : IComparer<Integer>;
  res : Integer;

  function NestedCompareFunc(constref Left, Right : Integer ) : Integer;
  begin
    Result := TCompare.Integer(Left, Right);
  end;

begin
  cmp := TComparerTool<Integer>.FromFunc( NestedCompareFunc );
  res := cmp.Compare(2,3);
  self.AssertEquals(-1, res);
end;

function TCompareTests.ObjectCompareFunc(constref Left, Right : Integer ) : Integer;
begin
  Result := TCompare.Integer(Left, Right);
end;

procedure TCompareTests.ObjectCompare;
var
  cmp : IComparer<Integer>;
  res : Integer;

begin
  cmp := TComparerTool<Integer>.FromFunc( ObjectCompareFunc );
  res := cmp.Compare(2,3);
  self.AssertEquals(-1, res);
end;

function GlobalCompareFunc(constref Left, Right : Integer ) : Integer;
begin
  Result := TCompare.Integer(Left, Right);
end;

procedure TCompareTests.GlobalCompare;
var
  cmp : IComparer<Integer>;
  res : Integer;

begin
  cmp := TComparerTool<Integer>.FromFunc( GlobalCompareFunc );
  res := cmp.Compare(2,3);
  self.AssertEquals(-1, res);
end;

procedure TCompareTests.MemTest;

  // Manually debug and confirm destructor called on comparers
  procedure Test1;
  var
    cmp : IComparer<Integer>;
  begin
       // 1 globalcomparer destroy
      cmp := TComparerTool<Integer>.FromFunc(GlobalCompareFunc);
  end;

  procedure Test2;
  var
    cmp : IComparer<Integer>;
  begin
      // 1 andmanycomparer, 2 globalcomparers detroys
      cmp := TComparerTool<Integer>.Many([GlobalCompareFunc, GlobalCompareFunc]);
  end;

begin
   Test1;
   Test2;
end;

procedure TCompareTests.ManyTest_LE;
var
  cmp : IComparer<Integer>;
  count,res : integer;

  function NestedCompareFunc(constref Left, Right : Integer ) : Integer;
  begin
    Inc(count);
    Result := TCompare.Integer(Left, Right);
  end;

begin
  count := 0;
  cmp := TComparerTool<Integer>.Many([NestedCompareFunc, NestedCompareFunc]);
  res := cmp.Compare(1,2);
  AssertEquals(1, count);
  AssertEquals(-1, res);
end;

procedure TCompareTests.ManyTest_EQ;
var
  cmp : IComparer<Integer>;
  count,res : integer;

  function NestedCompareFunc(constref Left, Right : Integer ) : Integer;
  begin
    Inc(count);
    Result := TCompare.Integer(Left, Right);
  end;

begin
  count := 0;
  cmp := TComparerTool<Integer>.Many([NestedCompareFunc, NestedCompareFunc]);
  res := cmp.Compare(1,1);
  AssertEquals(2, count);
  AssertEquals(0, res);
end;

procedure TCompareTests.ManyTest_GE;
var
  cmp : IComparer<Integer>;
  count,res : integer;

  function NestedCompareFunc(constref Left, Right : Integer ) : Integer;
  begin
    Inc(count);
    Result := TCompare.Integer(Left, Right);
  end;

begin
  count := 0;
  cmp := TComparerTool<Integer>.Many([NestedCompareFunc, NestedCompareFunc]);
  res := cmp.Compare(2,1);
  AssertEquals(1, count);
  AssertEquals(1, res);
end;

{ TFilterTests }

procedure TFilterTests.NestedFilter;
var
  list : TList<Integer>;
  pred : IPredicate<Integer>;
  res : Integer;
  GC : TDisposables;
  i : integer;

  function NestedFilterFunc(constref AItem : Integer ) : boolean;
  begin
    Result := (AItem mod 2) = 0;
  end;

begin
  list := GC.AddObject( TList<Integer>.Create ) as TList<Integer>;
  list.AddRange([1,2,3,4,5,6,7,8,9,10]);
  pred := TPredicateTool<Integer>.FromFunc( NestedFilterFunc );
  TListTool<Integer>.FilterBy(list, pred);
  self.AssertEquals(5, list.Count);
  self.AssertEquals(2, list[0]);
  self.AssertEquals(4, list[1]);
  self.AssertEquals(6, list[2]);
  self.AssertEquals(8, list[3]);
  self.AssertEquals(10, list[4]);
end;

function TFilterTests.ObjectFilterFunc(constref AItem : Integer ) : boolean;
begin
  Result := (AItem mod 2) = 0;
end;

procedure TFilterTests.ObjectFilter;
var
  list : TList<Integer>;
  pred : IPredicate<Integer>;
  res : Integer;
  GC : TDisposables;
begin
  list := GC.AddObject( TList<Integer>.Create ) as TList<Integer>;
  list.AddRange([1,2,3,4,5,6,7,8,9,10]);
  pred := TPredicateTool<Integer>.FromFunc( ObjectFilterFunc );
  TListTool<Integer>.FilterBy(list, pred);
  self.AssertEquals(5, list.Count);
  self.AssertEquals(2, list[0]);
  self.AssertEquals(4, list[1]);
  self.AssertEquals(6, list[2]);
  self.AssertEquals(8, list[3]);
  self.AssertEquals(10, list[4]);
end;

function GlobalFilterFunc(constref AItem : Integer ) : boolean;
begin
  Result := (AItem mod 2) = 0;
end;

procedure TFilterTests.GlobalFilter;
var
  list : TList<Integer>;
  pred : IPredicate<Integer>;
  res : Integer;
  GC : TDisposables;
begin
  list := GC.AddObject( TList<Integer>.Create ) as TList<Integer>;
  list.AddRange([1,2,3,4,5,6,7,8,9,10]);
  pred := TPredicateTool<Integer>.FromFunc( GlobalFilterFunc );
  TListTool<Integer>.FilterBy(list, pred);
  self.AssertEquals(5, list.Count);
  self.AssertEquals(2, list[0]);
  self.AssertEquals(4, list[1]);
  self.AssertEquals(6, list[2]);
  self.AssertEquals(8, list[3]);
  self.AssertEquals(10, list[4]);
end;

procedure TFilterTests.AndManyFilter;
var
  list : TList<Integer>;
  pred : IPredicate<Integer>;
  res : Integer;
  GC : TDisposables;

  function NestedFilterOddFunc(constref AItem : Integer ) : boolean;
  begin
    Result := (AItem mod 2) = 0;
  end;

    function NestedFilterEvenFunc(constref AItem : Integer ) : boolean;
  begin
    Result := (AItem mod 2) <> 0;
  end;

begin
  list := GC.AddObject( TList<Integer>.Create ) as TList<Integer>;
  list.AddRange([1,2,3,4,5,6,7,8,9,10]);
  pred := TPredicateTool<Integer>.AndMany( [NestedFilterOddFunc, NestedFilterEvenFunc] );
  TListTool<Integer>.FilterBy(list, pred);
  self.AssertEquals(0, list.Count);
end;

procedure TFilterTests.OrManyFilter;
var
  list : TList<Integer>;
  pred : IPredicate<Integer>;
  res : Integer;
  GC : TDisposables;

  function NestedFilterOddFunc(constref AItem : Integer ) : boolean;
  begin
    Result := (AItem mod 2) = 0;
  end;

    function NestedFilterEvenFunc(constref AItem : Integer ) : boolean;
  begin
    Result := (AItem mod 2) <> 0;
  end;

begin
  list := GC.AddObject( TList<Integer>.Create ) as TList<Integer>;
  list.AddRange([1,2,3,4,5,6,7,8,9,10]);
  pred := TPredicateTool<Integer>.OrMany( [NestedFilterOddFunc, NestedFilterEvenFunc] );
  TListTool<Integer>.FilterBy(list, pred);
  self.AssertEquals(10, list.Count);
end;

procedure TFilterTests.SetUp;
begin

end;

procedure TFilterTests.TearDown;
begin

end;

type
  ETransformFixtureError = class(Exception);

var
  GTransformCount, GTransformOffset: Integer;

function GlobalTransform(constref AItem: Integer): String;
begin
  Inc(GTransformCount);
  if AItem < 0 then raise ETransformFixtureError.Create('Controlled transform failure');
  Result := 'mapped:' + IntToStr(AItem + GTransformOffset);
end;

function TTransformTests.ObjectTransform(constref AItem: Integer): String;
begin
  Inc(FTransformCount);
  if AItem < 0 then raise ETransformFixtureError.Create('Controlled transform failure');
  Result := 'mapped:' + IntToStr(AItem + FTransformOffset);
end;

procedure TTransformTests.CheckTransforms(AFamily: Integer);
var
  LItems, LEmpty: TArray<Integer>;
  LList, LEmptyList: TList<Integer>;
  LMapped: TArray<String>;
  LGlobal: TGlobalTransformFunc<Integer, String>;
  LObject: TObjectTransformFunc<Integer, String>;
  LNested: TNestedTransformFunc<Integer, String>;
  LOffset, i: Integer;
  LBefore, LAfter: Int64;
  LDisposed: TDisposables;

  function NestedTransform(constref AItem: Integer): String;
  begin
    Inc(FTransformCount);
    if AItem < 0 then raise ETransformFixtureError.Create('Controlled transform failure');
    Result := 'mapped:' + IntToStr(AItem + LOffset);
  end;

  function MapArray(const AItems: TArray<Integer>): TArray<String>;
  begin
    case AFamily of
      0: Result := TListTool<Integer, String>.Transform(AItems, LGlobal);
      1: Result := TListTool<Integer, String>.Transform(AItems, LObject);
      2: Result := TListTool<Integer, String>.Transform(AItems, LNested);
    end;
  end;

  function MapList(AItems: TList<Integer>): TArray<String>;
  begin
    case AFamily of
      0: Result := TListTool<Integer, String>.Transform(AItems, LGlobal);
      1: Result := TListTool<Integer, String>.Transform(AItems, LObject);
      2: Result := TListTool<Integer, String>.Transform(AItems, LNested);
    end;
  end;

  procedure ResetCalls;
  begin
    GTransformCount := 0;
    FTransformCount := 0;
  end;

  function Calls: Integer;
  begin
    if AFamily = 0 then Result := GTransformCount else Result := FTransformCount;
  end;

  procedure CheckFailure(AFromList: Boolean);
  var LFailed: Boolean;
  begin
    ResetCalls;
    LFailed := False;
    try
      if AFromList then LMapped := MapList(LList) else LMapped := MapArray(LItems);
    except
      on E: ETransformFixtureError do LFailed := True;
    end;
    AssertTrue('The original callback exception must propagate', LFailed);
    AssertEquals('Transformation stops at the failing item', 2, Calls);
    LMapped := nil;
  end;

begin
  GTransformOffset := 20;
  FTransformOffset := 30;
  LOffset := 40;
  if AFamily = 0 then LOffset := GTransformOffset;
  if AFamily = 1 then LOffset := FTransformOffset;
  LGlobal := GlobalTransform;
  LObject := ObjectTransform;
  LNested := NestedTransform;
  LList := LDisposed.AddObject(TList<Integer>.Create) as TList<Integer>;
  LEmptyList := LDisposed.AddObject(TList<Integer>.Create) as TList<Integer>;
  LItems := TArray<Integer>.Create(1, 3, 5);
  LEmpty := nil;
  LList.AddRange(LItems);

  ResetCalls;
  LMapped := MapArray(LItems);
  AssertEquals(3, Length(LMapped));
  AssertEquals('mapped:' + IntToStr(1 + LOffset), LMapped[0]);
  AssertEquals('mapped:' + IntToStr(3 + LOffset), LMapped[1]);
  AssertEquals('mapped:' + IntToStr(5 + LOffset), LMapped[2]);
  AssertEquals(3, Calls);
  ResetCalls;
  LMapped := MapList(LList);
  AssertEquals(3, Length(LMapped));
  AssertEquals('mapped:' + IntToStr(1 + LOffset), LMapped[0]);
  AssertEquals('mapped:' + IntToStr(3 + LOffset), LMapped[1]);
  AssertEquals('mapped:' + IntToStr(5 + LOffset), LMapped[2]);
  AssertEquals(3, Calls);

  ResetCalls;
  LMapped := MapArray(LEmpty);
  AssertEquals(0, Length(LMapped));
  LMapped := MapList(LEmptyList);
  AssertEquals(0, Length(LMapped));
  AssertEquals('Empty inputs never invoke the callback', 0, Calls);
  LMapped := nil;
  LBefore := GetFPCHeapStatus.CurrHeapUsed;
  for i := 1 to 16 do begin
    LMapped := MapArray(LEmpty);
    LMapped := nil;
    LMapped := MapList(LEmptyList);
    LMapped := nil;
  end;
  LAfter := GetFPCHeapStatus.CurrHeapUsed;
  AssertEquals('Completed empty transforms release their delegate adapters', LBefore, LAfter);

  LItems[1] := -1;
  LList[1] := -1;
  CheckFailure(False);
  CheckFailure(True);
  LBefore := GetFPCHeapStatus.CurrHeapUsed;
  for i := 1 to 16 do begin
    CheckFailure(False);
    CheckFailure(True);
  end;
  LAfter := GetFPCHeapStatus.CurrHeapUsed;
  AssertEquals('Exceptions release adapters and partially transformed managed strings', LBefore, LAfter);
  AssertEquals('Array input remains unchanged after failure', -1, LItems[1]);
  AssertEquals('List input remains unchanged after failure', -1, LList[1]);
  AssertEquals(3, LList.Count);

  LItems[1] := 3;
  LList[1] := 3;
  LMapped := MapArray(LItems);
  AssertEquals('mapped:' + IntToStr(3 + LOffset), LMapped[1]);
  LMapped := MapList(LList);
  AssertEquals('mapped:' + IntToStr(3 + LOffset), LMapped[1]);
end;

procedure TTransformTests.GlobalTransformsOwnTheirAdapters;
begin
  CheckTransforms(0);
end;

procedure TTransformTests.ObjectTransformsOwnTheirAdapters;
begin
  CheckTransforms(1);
end;

procedure TTransformTests.NestedTransformsOwnTheirAdapters;
begin
  CheckTransforms(2);
end;

initialization
  RegisterTest(TFilterTests);
  RegisterTest(TTransformTests);
end.

