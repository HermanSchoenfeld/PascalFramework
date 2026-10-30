unit USplitterTest;

{$IFDEF FPC}{$mode objfpc}{$H+}{$ENDIF}

interface

uses
  Classes, SysUtils, {$IFDEF FPC}FileUtil,{$ENDIF} Forms, Controls, Graphics, Dialogs, {$IFDEF FPC}PairSplitter,{$ELSE}Vcl.ExtCtrls,{$ENDIF}
  StdCtrls, UCommon.UI;

type
  TSplitterTestForm = class(TApplicationForm)
    {$IFNDEF FPC}
    PairSplitter1, PairSplitterSide1, PairSplitterSide2: TPanel;
    NativeSplitter: TSplitter;
    StaticText1: TStaticText;
    {$ENDIF}
  private

  public

  end;

implementation

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

end.
