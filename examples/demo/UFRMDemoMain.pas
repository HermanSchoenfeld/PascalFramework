unit UFRMDemoMain;

{ Copyright © 2026 Herman Schoenfeld <https://sphere10.com>
  One shared Lazarus/VCL application for the existing framework examples.
  Distributed under the MIT license. }

{$IFDEF FPC}{$mode Delphi}{$H+}{$ENDIF}

interface

uses Classes, SysUtils, Forms, Controls, ComCtrls, StdCtrls, ExtCtrls,
  UCommon.UI, fMain, UFRMMain, UThrottleDemo;

type
  TFRMDemoMain = class(TForm)
    Pages: TPageControl;
    GridTab: TTabSheet;
    WizardTab: TTabSheet;
    CacheTab: TTabSheet;
    ThrottleTab: TTabSheet;
    UtilitiesTab: TTabSheet;
    UtilitiesPanel: TPanel;
    RunArraysButton: TButton;
    RunDisposalButton: TButton;
    RunCoreApiButton: TButton;
    RunUiApiButton: TButton;
    UtilitiesOutput: TMemo;
    CachePanel: TPanel;
    CacheIntro: TLabel;
    RunCacheButton: TButton;
    RunCacheApiButton: TButton;
    CacheOutput: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure RunCacheClick(Sender: TObject);
    procedure RunCacheApiClick(Sender: TObject);
    procedure RunArraysClick(Sender: TObject);
    procedure RunDisposalClick(Sender: TObject);
    procedure RunCoreApiClick(Sender: TObject);
    procedure RunUiApiClick(Sender: TObject);
  private
    FGridExample: TForm1;
    FWizardExample: TFRMMain;
    FThrottleExample: TThrottleDemoForm;
  public
    property GridExample: TForm1 read FGridExample;
    property WizardExample: TFRMMain read FWizardExample;
    property ThrottleExample: TThrottleDemoForm read FThrottleExample;
  end;

var
  DemoMainForm: TFRMDemoMain;

implementation

uses UCacheDemo, UArrayCollectionExamples, UDisposalReadmeExamples,
  UCoreApiExamples, UUiApiExamples, UCacheApiExamples;

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

procedure TFRMDemoMain.FormCreate(Sender: TObject);
begin
  // Component ownership disposes hosted examples before their tab pages.
  // AddControlDockCenter supplies the established embedded-form lifecycle.
  FGridExample := TForm1.Create(Self);
  GridTab.AddControlDockCenter(FGridExample);
  FWizardExample := TFRMMain.Create(Self);
  WizardTab.AddControlDockCenter(FWizardExample);
  FThrottleExample := TThrottleDemoForm.Create(Self);
  ThrottleTab.AddControlDockCenter(FThrottleExample);
  FThrottleExample.InitializeDemo;
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

procedure TFRMDemoMain.RunArraysClick(Sender: TObject);
begin
  // These are executable usage examples; failures remain visible to the caller.
  ArrayMethods;
  CollectionAdapters;
  UtilitiesOutput.Lines.Add('TArrayTool and collection examples passed.');
end;

procedure TFRMDemoMain.RunCacheApiClick(Sender: TObject);
begin
  CacheOutput.Lines.BeginUpdate;
  try
    CacheOutput.Clear;
    RunCacheApiExamples(CacheOutput.Lines);
    CacheOutput.Lines.Add('Complete cache API examples passed.');
  finally
    CacheOutput.Lines.EndUpdate;
  end;
end;

procedure TFRMDemoMain.RunDisposalClick(Sender: TObject);
begin
  UtilitiesOutput.Lines.Add('Local scope: ' + Trim(BuildLocalReport));
  UtilitiesOutput.Lines.Add('Class-owned bag: ' + Trim(BuildClassReport));
  UtilitiesOutput.Lines.Add('Registered objects and memory have been released.');
end;

procedure TFRMDemoMain.RunCoreApiClick(Sender: TObject);
begin
  RunCoreApiExamples(UtilitiesOutput.Lines);
  UtilitiesOutput.Lines.Add('Core API examples passed.');
end;

procedure TFRMDemoMain.RunUiApiClick(Sender: TObject);
begin
  RunUiApiExamples(UtilitiesTab,UtilitiesOutput.Lines);
  UtilitiesOutput.Lines.Add('UI API examples passed.');
end;

end.
