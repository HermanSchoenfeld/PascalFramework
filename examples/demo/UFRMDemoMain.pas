unit UFRMDemoMain;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>
  One shared Lazarus/VCL application for the existing framework examples.
  Distributed under the MIT license. }

{$IFDEF FPC}{$mode Delphi}{$H+}{$ENDIF}

interface

uses Classes, SysUtils, Forms, Controls, ComCtrls, StdCtrls, ExtCtrls,
  UCommon.UI, fMain, UFRMMain;

type
  TFRMDemoMain = class(TForm)
    Pages: TPageControl;
    GridTab: TTabSheet;
    WizardTab: TTabSheet;
    CacheTab: TTabSheet;
    CachePanel: TPanel;
    CacheIntro: TLabel;
    RunCacheButton: TButton;
    CacheOutput: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure RunCacheClick(Sender: TObject);
  private
    FGridExample: TForm1;
    FWizardExample: TFRMMain;
  public
    property GridExample: TForm1 read FGridExample;
    property WizardExample: TFRMMain read FWizardExample;
  end;

var
  DemoMainForm: TFRMDemoMain;

implementation

uses UCacheDemo;

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

procedure TFRMDemoMain.FormCreate(Sender: TObject);
begin
  // Component ownership disposes both hosted examples before their tab pages.
  // AddControlDockCenter supplies the established embedded-form lifecycle.
  FGridExample := TForm1.Create(Self);
  GridTab.AddControlDockCenter(FGridExample);
  FWizardExample := TFRMMain.Create(Self);
  WizardTab.AddControlDockCenter(FWizardExample);
  Pages.ActivePage := GridTab;
  CacheOutput.Lines.Add('Choose Run cache examples to inspect fetching, eviction and disposal.');
end;

procedure TFRMDemoMain.RunCacheClick(Sender: TObject);
begin
  CacheOutput.Lines.BeginUpdate;
  try
    CacheOutput.Clear;
    RunCacheExamples(CacheOutput.Lines);
  finally
    CacheOutput.Lines.EndUpdate;
  end;
end;

end.