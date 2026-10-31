unit UArrayCollectionExamples;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>. MIT license.
  Worked public API examples shared by the Delphi and Lazarus demo. }

{$IFDEF FPC}{$mode Delphi}{$H+}{$modeswitch nestedprocvars}{$ENDIF}

interface

procedure ArrayMethods;
procedure CollectionAdapters;

implementation

uses Classes, SysUtils, Generics.Collections, Generics.Defaults,
  UCommon, UCommon.Collections, UMemory;

type
  TIntArrays = TArrayTool<Integer>;
  TIntComparerArrays = TArrayTool<IComparer<Integer>>;
  TIntPredicateArrays = TArrayTool<IPredicate<Integer>>;
  TIntComparerTools = TComparerTool<Integer>;
  TIntPredicateTools = TPredicateTool<Integer>;
  TIntListTools = TListTool<Integer>;
  TIntTextTransforms = TListTool<Integer,String>;
  {$IFDEF FPC}TIntSetTools = TSortedHashSetTool<Integer>;{$ENDIF}

procedure Require(ACondition: Boolean; const AMessage: String);
begin
  if not ACondition then raise Exception.Create(AMessage);
end;

procedure RequireArray(const AActual: TArray<Integer>; const AExpected: array of Integer);
var I: Integer;
begin
  Require(Length(AActual)=Length(AExpected),'Array length');
  for I:=0 to High(AActual) do Require(AActual[I]=AExpected[I],'Array value');
end;

procedure ArrayMethods;
var
  values, snapshot, middle, combined: TArray<Integer>;
  equality: IEqualityComparer<Integer>;
  index: SizeInt;
  scope: TDisposables;
  list: TList<Integer>;
begin
  values := TIntArrays.Empty;
  Require(Length(values)=0,'Empty');
  // Create has overloads for one through six values.
  values := TIntArrays.Create(10);
  RequireArray(values,[10]);
  values := TIntArrays.Create(10,20);
  RequireArray(values,[10,20]);
  values := TIntArrays.Create(10,20,30);
  RequireArray(values,[10,20,30]);
  values := TIntArrays.Create(10,20,30,40);
  RequireArray(values,[10,20,30,40]);
  values := TIntArrays.Create(10,20,30,40,50);
  RequireArray(values,[10,20,30,40,50]);
  values := TIntArrays.Create(10,20,30,40,50,60);
  RequireArray(values,[10,20,30,40,50,60]);

  values := TIntArrays.Create(10,20,30);
  TIntArrays.Add(values,40);               // 10,20,30,40
  TIntArrays.Append(values,50);            // 10,20,30,40,50
  TIntArrays.Prepend(values,0);            // 0,10,20,30,40,50
  TIntArrays.InsertAt(values,2,15);         // 0,10,15,20,30,40,50
  TIntArrays.Swap(values,0,6);             // 50,10,15,20,30,40,0
  TIntArrays.MoveItem(values,6,0);         // 0,50,10,15,20,30,40
  TIntArrays.Remove(values,20);            // 0,50,10,15,30,40
  equality := TEqualityComparer<Integer>.Default;
  TIntArrays.Remove(values,50,equality);   // 0,10,15,30,40
  TIntArrays.RemoveAt(values,0);           // 10,15,30,40
  RequireArray(values,[10,15,30,40]);

  snapshot := TIntArrays.Copy(values);
  middle := TIntArrays.Copy(values,1,2);   // 15,30
  combined := TIntArrays.Concat([
    middle,TIntArrays.Create(50,60)]);     // 15,30,50,60
  values[0] := 99;                                 // snapshot still starts with 10.
  RequireArray(snapshot,[10,15,30,40]);
  RequireArray(middle,[15,30]);
  RequireArray(combined,[15,30,50,60]);
  Require(TIntArrays.Contains(combined,30,index),'Contains/out');
  Require(index=1,'Contains/out index');
  Require(TIntArrays.Contains(combined,60,equality,index),'Contains/comparer');
  Require(index=3,'Contains/comparer index');
  Require(not TIntArrays.Contains(combined,999),'Contains/bool');
  Require(TIntArrays.IndexOf(combined,50)=2,'IndexOf');
  Require(TIntArrays.IndexOf(combined,15,equality)=0,'IndexOf/comparer');
  Require(TIntArrays._Length(combined)=4,'_Length');
  list := scope.AddObject(TList<Integer>.Create) as TList<Integer>;
  list.AddRange(combined);
  values := TIntArrays.ToArray(list,list.Count);
  RequireArray(values,[15,30,50,60]);
end;

function Ascending({$IFDEF FPC}constref{$ELSE}const{$ENDIF} ALeft,ARight: Integer): Integer;
begin
  Result := TComparer<Integer>.Default.Compare(ALeft,ARight);
end;

function Even({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AValue: Integer): Boolean;
begin
  Result := (AValue mod 2)=0;
end;

function NumberText({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AValue: Integer): String;
begin
  Result := 'item '+IntToStr(AValue);
end;

type
  TCallbacks = class
    function Compare({$IFDEF FPC}constref{$ELSE}const{$ENDIF} ALeft,ARight: Integer): Integer;
    function Positive({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AValue: Integer): Boolean;
    function Text({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AValue: Integer): String;
  end;

function TCallbacks.Compare({$IFDEF FPC}constref{$ELSE}const{$ENDIF} ALeft,ARight: Integer): Integer;
begin
  Result := Ascending(ALeft,ARight);
end;
function TCallbacks.Positive({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AValue: Integer): Boolean;
begin
  Result := AValue>0;
end;
function TCallbacks.Text({$IFDEF FPC}constref{$ELSE}const{$ENDIF} AValue: Integer): String;
begin
  Result := 'object '+IntToStr(AValue);
end;

procedure CollectionAdapters;
var
  scope: TDisposables;
  callbacks: TCallbacks;
  globalCompare: TGlobalComparerFunc<Integer>;
  objectCompare: TObjectComparerFunc<Integer>;
  nestedCompare: TNestedComparerFunc<Integer>;
  globalPredicate: TGlobalPredicateFunc<Integer>;
  objectPredicate: TObjectPredicateFunc<Integer>;
  nestedPredicate: TNestedPredicateFunc<Integer>;
  globalTransform: TGlobalTransformFunc<Integer,String>;
  objectTransform: TObjectTransformFunc<Integer,String>;
  nestedTransform: TNestedTransformFunc<Integer,String>;
  globalComparer,objectComparer,nestedComparer,combinedComparer,invertedComparer: IComparer<Integer>;
  globalFilter,objectFilter,nestedFilter,both,either,negated: IPredicate<Integer>;
  globalTransformer,objectTransformer,nestedTransformer: ITransformer<Integer,String>;
  list, copied: TList<Integer>;
  numbers: TArray<Integer>;
  texts: TArray<String>;
  {$IFDEF FPC}setOfNumbers: TSortedHashSet<Integer>; popped: Integer;{$ENDIF}

  {$IFDEF FPC}
  function CompareInScope(constref ALeft,ARight: Integer): Integer;
  begin
    Result := Ascending(ALeft,ARight);
  end;
  function UnderTen(constref AValue: Integer): Boolean;
  begin
    Result := AValue<10;
  end;
  function ScopedText(constref AValue: Integer): String;
  begin
    Result := 'nested '+IntToStr(AValue);
  end;
  {$ENDIF}
begin
  callbacks := scope.AddObject(TCallbacks.Create) as TCallbacks;
  globalCompare := Ascending; objectCompare := callbacks.Compare;
  globalPredicate := Even; objectPredicate := callbacks.Positive;
  globalTransform := NumberText; objectTransform := callbacks.Text;
  {$IFDEF FPC}
  nestedCompare := CompareInScope; nestedPredicate := UnderTen; nestedTransform := ScopedText;
  {$ELSE}
  nestedCompare :=
    function(const L,R: Integer): Integer
    begin
      Result := Ascending(L,R);
    end;
  nestedPredicate :=
    function(const V: Integer): Boolean
    begin
      Result := V<10;
    end;
  nestedTransform :=
    function(const V: Integer): String
    begin
      Result := 'nested '+IntToStr(V);
    end;
  {$ENDIF}

  // The factories return reference-counted interfaces. These concrete adapters
  // are also public, although declared for compiler compatibility.
  globalComparer := TGlobalComparer<Integer>.Create(globalCompare);
  objectComparer := TObjectComparer<Integer>.Create(objectCompare);
  nestedComparer := TNestedComparer<Integer>.Create(nestedCompare);
  combinedComparer := TManyComparer<Integer>.Create(
    TIntComparerArrays.Create(globalComparer,objectComparer));
  invertedComparer := TInvertedComparer<Integer>.Create(combinedComparer);
  Require(invertedComparer.Compare(1,2)>0,'Concrete comparer adapters');
  Require(nestedComparer.Compare(1,2)<0,'Nested comparer');
  globalComparer := TIntComparerTools.FromFunc(globalCompare);
  objectComparer := TIntComparerTools.FromFunc(objectCompare);
  nestedComparer := TIntComparerTools.FromFunc(nestedCompare);
  combinedComparer := TIntComparerTools.Many([globalComparer,objectComparer]);
  invertedComparer := TIntComparerTools.Inverted(combinedComparer);
  Require(invertedComparer.Compare(1,2)>0,'Comparer tool');
  Require(TIntComparerTools.AlwaysEqual.Compare(1,2)=0,'AlwaysEqual');

  globalFilter := TGlobalPredicate<Integer>.Create(globalPredicate);
  objectFilter := TObjectPredicate<Integer>.Create(objectPredicate);
  nestedFilter := TNestedPredicate<Integer>.Create(nestedPredicate);
  both := TAndManyPredicate<Integer>.Create(
    TIntPredicateArrays.Create(globalFilter,objectFilter));
  either := TOrManyPredicate<Integer>.Create(
    TIntPredicateArrays.Create(globalFilter,nestedFilter));
  negated := TNotPredicate<Integer>.Create(globalFilter);
  Require(both.Evaluate(2) and not both.Evaluate(-2),'And predicate');
  Require(either.Evaluate(3) and not either.Evaluate(11),'Or predicate');
  Require(negated.Evaluate(3),'Not predicate');
  both := TIntPredicateTools.AndMany([globalFilter,objectFilter]);
  either := TIntPredicateTools.OrMany([globalFilter,nestedFilter]);
  negated := TIntPredicateTools.NegatePredicate(globalFilter);
  Require(both.Evaluate(2) and either.Evaluate(3) and negated.Evaluate(3),'Predicate tool');
  globalFilter := TIntPredicateTools.FromFunc(globalPredicate);
  objectFilter := TIntPredicateTools.FromFunc(objectPredicate);
  nestedFilter := TIntPredicateTools.FromFunc(nestedPredicate);
  both := TIntPredicateTools.TruePredicate;
  either := TIntPredicateTools.FalsePredicate;
  Require(both.Evaluate(0) and not either.Evaluate(0),'Constant predicates');

  globalTransformer := TGlobalTransformer<Integer,String>.Create(globalTransform);
  objectTransformer := TObjectTransformer<Integer,String>.Create(objectTransform);
  nestedTransformer := TNestedTransformer<Integer,String>.Create(nestedTransform);
  Require(globalTransformer.Transform(2)='item 2','Global transformer');
  Require(objectTransformer.Transform(2)='object 2','Object transformer');
  Require(nestedTransformer.Transform(2)='nested 2','Nested transformer');
  numbers := TIntArrays.Create(1,2,3,4);
  texts := TIntTextTransforms.Transform(numbers,globalTransformer);
  Require((Length(texts)=4) and (texts[3]='item 4'),'Interface array transform');
  list := scope.AddObject(TList<Integer>.Create) as TList<Integer>;
  list.AddRange(numbers);
  texts := TIntTextTransforms.Transform(list,objectTransformer);
  Require(texts[0]='object 1','Interface list transform');
  // Function-adapter overloads work on both arrays and lists.
  texts := TIntTextTransforms.Transform(numbers,globalTransform);
  Require(texts[0]='item 1','Global array transform');
  texts := TIntTextTransforms.Transform(numbers,objectTransform);
  Require(texts[0]='object 1','Object array transform');
  texts := TIntTextTransforms.Transform(numbers,nestedTransform);
  Require(texts[0]='nested 1','Nested array transform');
  texts := TIntTextTransforms.Transform(list,globalTransform);
  Require(texts[0]='item 1','Global list transform');
  texts := TIntTextTransforms.Transform(list,objectTransform);
  Require(texts[0]='object 1','Object list transform');
  texts := TIntTextTransforms.Transform(list,nestedTransform);
  Require(texts[0]='nested 1','Nested list transform');
  TIntListTools.FilterBy(list,globalFilter); // list now contains 2,4.
  list.Sort(invertedComparer); // 4,2.
  Require((list.Count=2) and (list[0]=4) and (list[1]=2),'List filter/sort');
  Require(TIntListTools.RemoveBy(list,objectFilter)=2,'Remove matching items');
  list.AddRange([10,20,30,40]);
  copied := scope.AddObject(TIntListTools.Copy(list,1,2)) as TList<Integer>;
  Require((copied.Count=2) and (copied[0]=20) and (copied[1]=30),'Copy count');
  Require(TIntListTools.Range(list,1,3)=-1,'Range size delta'); // 20,30,40
  Require(TIntListTools.Skip(list,1)=-1,'Skip size delta');    // 30,40
  Require(TIntListTools.Take(list,1)=-1,'Take size delta');    // 30
  TIntListTools.DiposeItem(list,0,idpNil); // Zero the slot; this does not remove it.
  Require((list.Count=1) and (list[0]=0),'Explicit item policy');
  {$IFDEF FPC}
  setOfNumbers := scope.AddObject(TSortedHashSet<Integer>.Create) as TSortedHashSet<Integer>;
  setOfNumbers.Add(1); setOfNumbers.Add(3);
  popped := TIntSetTools.Pop(setOfNumbers);
  Require((setOfNumbers.Count=1) and not setOfNumbers.Contains(popped),'Sorted set Pop');
  {$ENDIF}
end;

end.
