unit UFRMWorkArea;

{$IFDEF FPC}{$mode objfpc}{$H+}{$ENDIF}

interface

uses
  Classes, SysUtils, {$IFDEF FPC}FileUtil,{$ENDIF} Forms, Controls, Graphics, Dialogs, ComCtrls,
  Buttons, StdCtrls;

type

  { TFRMWorkArea }

  TFRMWorkArea = class(TForm)
    FSomeButton: TBitBtn;
    FSomeButton1: TBitBtn;
    FSomeButton2: TBitBtn;
    FSomeButton3: TBitBtn;
    FSomeButton4: TBitBtn;
    FSomeButton5: TBitBtn;
    FSomeButton6: TBitBtn;
    FSomeButton7: TBitBtn;
    Label1: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    ToolBar1: TToolBar;
    procedure FormCreate(Sender: TObject);
    procedure FSomeButton2Click(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  WorkAreaForm: TFRMWorkArea;

implementation

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

{ TFRMWorkArea }

procedure TFRMWorkArea.Label1Click(Sender: TObject);
begin

end;

procedure TFRMWorkArea.SpeedButton2Click(Sender: TObject);
begin

end;

procedure TFRMWorkArea.FSomeButton2Click(Sender: TObject);
begin

end;

procedure TFRMWorkArea.FormCreate(Sender: TObject);
begin

end;

end.

