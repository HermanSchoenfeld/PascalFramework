unit UFRMMain;
{$R *.lfm}

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}


interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, UWizard, UWIZName_Step1, UWIZName_Step2, UFRMWorkArea, UFRMNotifyManyTest, UCommon;

type

  { TFRMMain }
  TFRMMain = class(TForm)
    btnNotifyTest: TButton;
    FFeatureWizardButton: TButton;
    FFeatureDescriptionLabel: TLabel;
    FDemoResultsMemo: TMemo;
    _wizardTestButton: TButton;
    FWorkAreaButton: TButton;
    procedure btnNotifyTestClick(Sender: TObject);
    procedure FeatureWizardClick(Sender: TObject);
    procedure FWorkAreaButtonClick(Sender: TObject);
    procedure _wizardTestButtonClick(Sender: TObject);
  private
    { private declarations }
    function CancelCallback(screenIndex:integer; constref model : TGenericWizardBag; out message : AnsiString ) : boolean;
    function FinishCallback(constref model  : TGenericWizardBag; out message : AnsiString) : boolean;
  public
    { public declarations }
  end;

var
  MainForm: TFRMMain;

implementation

uses variants, UWizardFeatureModel, UWizardFeatureDemo;

{ TFRMMain }

procedure TFRMMain.FeatureWizardClick(Sender: TObject);
var
  model : TWizardFeatureModel;
  wizard : TWizardFeatureDemo;
begin
  model := TWizardFeatureModel.Create;
  try
    wizard := TWizardFeatureDemo.Create(self, model);
    try
      wizard.Start(model);
    finally
      wizard.Free; // Destroy screens while their borrowed model is still alive.
    end;
    FDemoResultsMemo.Lines.Assign(model.Events);
    FDemoResultsMemo.Lines.Add('');
    FDemoResultsMemo.Lines.Add(Format('Result: Name="%s", Age=%d, Finish attempts=%d, Cancel attempts=%d',
      [model.Name, model.Age, model.FinishAttempts, model.CancelAttempts]));
    FDemoResultsMemo.Lines.Add(Format('Lifetime: %d initialized screens, %d destroyed; Finished events=%d; Reentry rejected=%d',
      [model.InitializedCount, model.DestroyedCount, model.FinishedCount, model.ReentryRejectedCount]));
    FDemoResultsMemo.SelStart := Length(FDemoResultsMemo.Text);
  finally
    model.Free;
  end;
end;

procedure TFRMMain._wizardTestButtonClick(Sender: TObject);

type
  TTestWizard = TActionWizard<TGenericWizardBag>;

var
  propertyBag : TGenericWizardBag;
begin
  propertyBag := TGenericWizardBag.Create;
  try
    // Pre-set property bag values when using TGenericWizardBag
    propertyBag.Add('Name', Variant(''));
    TTestWizard.Show(
      self,
      'My Test Action Wizard',
      'Finish Test',
      propertyBag,
      [TWIZName_Step1, TWIZName_Step2],
      CancelCallback,
      FinishCallback
    );
  finally
   // propertyBag['Name'].Destroy;
   propertyBag.Destroy;
  end;
end;

procedure TFRMMain.FWorkAreaButtonClick(Sender: TObject);
var
  frm : TFRMWorkArea;
begin
  try
    frm := TFRMWorkArea.Create(self);
    frm.ShowModal;
  finally
    frm.Destroy;
  end;
end;

procedure TFRMMain.btnNotifyTestClick(Sender: TObject);
var
  frm : TFRMNotifyManyTest;
begin
  try
    frm := TFRMNotifyManyTest.Create(self);
    frm.ShowModal;
  finally
    frm.Destroy;
  end;
end;

function TFRMMain.CancelCallback( screenIndex:integer; constref model : TGenericWizardBag; out message : AnsiString ) : boolean;
begin
  if screenIndex <> 0 then begin
    Result := false;
    message := 'Can only cancel on first screen';
  end else begin
    Result := true;
  end;
end;

function TFRMMain.FinishCallback(constref model : TGenericWizardBag; out message : AnsiString) : boolean;
begin
  if VarToStr(Model['Name']) = 'fail' then begin
    message := 'Name cannot be ''fail''';
    Result := false;
  end else begin
    ShowMessage('Finish: ' + VarToStr(Model['Name']));
    Result := true;
  end;
end;

end.

