unit UDisposalReadmeExamples;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>. MIT license.
  Worked public API examples shared by the Delphi and Lazarus demo. }

{$IFDEF FPC}{$mode Delphi}{$H+}{$ENDIF}

interface

uses Classes, UMemory;

type
  TReportBuilder = class
  private
    FResources : TDisposables;
    FLines : TStringList;
    FText : TStringStream;
    FOutput : TMemoryStream;
  public
    constructor Create;
    function Build : String;
  end;

function BuildLocalReport : String;
function BuildClassReport : String;
function CreateReadyLines : TStringList;
function CreateOwnedBuffer : Pointer;

implementation

function BuildLocalReport : String;
var
  scope : TDisposables;
  lines : TStringList;
  text : TStringStream;
  output : TMemoryStream;
  scratch : Pointer;
begin
  lines := scope.AddObject(TStringList.Create) as TStringList;
  text := scope.AddObject(TStringStream.Create('Report: ')) as TStringStream;
  output := scope.AddObject(TMemoryStream.Create) as TMemoryStream;
  scope.GetMem(scratch, 256);
  scope.ReallocMem(scratch, 512);
  FillChar(scratch^, 512, 0);
  lines.Add('Ready');
  text.Position := text.Size;
  text.WriteString(lines.Text);
  output.CopyFrom(text, 0);
  Result := text.DataString;
  // Reverse registration order: scratch, output, text, lines.
end;

constructor TReportBuilder.Create;
begin
  inherited Create;
  FLines := FResources.AddObject(TStringList.Create) as TStringList;
  FText := FResources.AddObject(TStringStream.Create('')) as TStringStream;
  FOutput := FResources.AddObject(TMemoryStream.Create) as TMemoryStream;
end;

function TReportBuilder.Build : String;
begin
  FLines.Clear;
  FText.Size := 0;
  FOutput.Size := 0;
  FLines.Add('Ready');
  FText.WriteString(FLines.Text);
  FOutput.CopyFrom(FText, 0);
  Result := FText.DataString;
end;

function BuildClassReport : String;
var
  report : TReportBuilder;
begin
  report := TReportBuilder.Create;
  try
    Result := report.Build;
  finally
    report.Free; // Finalizes FResources and frees its three objects.
  end;
end;

function CreateReadyLines : TStringList;
var
  scope : TDisposables;
begin
  Result := scope.AddObject(TStringList.Create) as TStringList;
  Result.Add('Ready');
  scope.RemoveObject(Result); // Caller now owns the returned object.
end;

function CreateOwnedBuffer : Pointer;
var
  scope : TDisposables;
begin
  scope.GetMem(Result, 256);
  FillChar(Result^, 256, 0);
  scope.RemoveMem(Result); // Caller must eventually call System.FreeMem.
end;

end.
