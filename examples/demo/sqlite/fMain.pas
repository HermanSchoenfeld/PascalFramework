unit fMain;

{$MODE DELPHI}

interface

uses
  SynSQLite3Static, SysUtils, Classes, Forms, Controls, Graphics, Dialogs, Math,
  UVisualGrid, SynCommons, mORMot, StdCtrls, mORMotSQLite3, SynDBSQLite3, SynDB;

type
  TSampleData = class(TSQLRecord)
  protected
    fName: RawUTF8;
    fFoo: Integer;
  published
    property name: RawUTF8 read fName write fName;
    property foo: Integer read fFoo write fFoo;
  end;

  { TForm1 }

  TForm1 = class(TForm, IDataSource)
    VisualGrid1: TVisualGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FModel: TSQLModel;
    FServer: TSQLRestServerDB;
    FProp: TSQLDBConnectionProperties;

    function FetchPage(constref AParams: TPageFetchParams; var ADataTable: TDataTable): TPageFetchResult;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

function TForm1.FetchPage(constref AParams: TPageFetchParams;
  var ADataTable: TDataTable): TPageFetchResult;
var
  LColumnFilter: TColumnFilter;
  LOrderBy: utf8string;
  LModulo, LLimit, LRowCount: Integer;
  LOffset: Int64;
  i: integer;
begin
  if Length(AParams.Filter) > 0 then
  begin
    LOrderBy := ' order by';
    for LColumnFilter in AParams.Filter do
    begin
      LOrderBy := LOrderBy + ' ' + LColumnFilter.ColumnName;
      case LColumnFilter.Sort of
        sdNone: ;
        sdAscending: LOrderBy := LOrderBy + ' asc';
        sdDescending: LOrderBy := LOrderBy + ' desc';
      end;
      LOrderBy := LOrderBy + ',';
    end;
    SetLength(LOrderBy, Length(LOrderBy)-1);
  end;

  // rather bad approach, but for demo purposes is ok
  // https://stackoverflow.com/questions/14468586/efficient-paging-in-sqlite-with-millions-of-records
  Result.TotalDataCount := FServer.TableRowCount(TSampleData);
  // APageIndex = -1 is acceptable as initial value
  if AParams.PageIndex < -1 then
    raise Exception.CreateFmt('Wrong value for APageNumber (%d)', [AParams.PageIndex]);

  // Single mode uses the shared nonpositive-size contract. SQLite's LIMIT -1
  // returns the complete ordered result without dividing by a page size.
  if AParams.PageSize <= 0 then begin
    Result.PageCount := Ord(Result.TotalDataCount > 0);
    Result.PageIndex := Result.PageCount - 1;
    LLimit := -1;
    LOffset := 0;
    LRowCount := Result.TotalDataCount;
  end else begin
    Result.PageCount := Result.TotalDataCount div AParams.PageSize;
    LModulo := Result.TotalDataCount mod AParams.PageSize;
    if LModulo > 0 then Inc(Result.PageCount);
    Result.PageIndex := Min(Max(0,AParams.PageIndex),Result.PageCount-1);
    LLimit := AParams.PageSize;
    LOffset := Int64(Max(0,Result.PageIndex)) * AParams.PageSize;
    LRowCount := Min(AParams.PageSize,Result.TotalDataCount-Integer(LOffset));
  end;

  with FProp.Execute('select * from SampleData' + LOrderBy +
    ' LIMIT ? OFFSET ?', [LLimit, LOffset]) do
  begin
    SetLength(ADataTable.Columns, ColumnCount);
    for i := 0 to ColumnCount - 1 do
      ADataTable.Columns[i] := ColumnName(i);

    SetLength(ADataTable.Rows, LRowCount);
    i := 0;
    while Step do
    begin
      RowDocVariant(ADataTable.Rows[i]);
      Inc(i);
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i: Integer;
  sd: TSampleData;
begin
  FModel := TSQLModel.Create([TSampleData]);
  FServer := TSQLRestServerDB.Create(FModel, ':memory:');
  FServer.CreateMissingTables;
  FProp := TSQLDBSQLite3ConnectionProperties.Create(FServer.DB);

  with TAutoFree.One(sd, TSampleData.Create) do
  for i := 0 to 10000 do
  begin
    sd.Name := 'name' + inttostr(i);
    sd.Foo := i;
    FServer.Add(sd, true);
  end;

  VisualGrid1.DataSource := Self;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FProp.Free;
  FServer.Free;
  FModel.Free;
end;

end.
