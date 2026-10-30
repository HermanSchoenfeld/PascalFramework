unit UFRMMain;
{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}


interface

uses
  Classes, SysUtils, {$IFDEF FPC}FileUtil,{$ENDIF} Forms, Controls, Graphics, Dialogs, StdCtrls, UWizard, UWIZName_Step1, UWIZName_Step2, UFRMWorkArea, UFRMNotifyManyTest, UCommon;

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
    function CancelCallback(screenIndex:integer; {$IFDEF FPC}constref{$ELSE}const{$ENDIF} model : TGenericWizardBag; out message : String ) : boolean;
    function FinishCallback({$IFDEF FPC}constref{$ELSE}const{$ENDIF} model  : TGenericWizardBag; out message : String) : boolean;
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
  frm := TFRMWorkArea.Create(self);
  try
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

procedure TFRMMain.btnNotifyTestClick(Sender: TObject);
var
  frm : TFRMNotifyManyTest;
begin
  frm := TFRMNotifyManyTest.Create(self);
  try
    frm.ShowModal;
  finally
    frm.Free;
  end;
end;

function TFRMMain.CancelCallback( screenIndex:integer; {$IFDEF FPC}constref{$ELSE}const{$ENDIF} model : TGenericWizardBag; out message : String ) : boolean;
begin
  if screenIndex <> 0 then begin
    Result := false;
    message := 'Can only cancel on first screen';
  end else begin
    Result := true;
  end;
end;

function TFRMMain.FinishCallback({$IFDEF FPC}constref{$ELSE}const{$ENDIF} model : TGenericWizardBag; out message : String) : boolean;
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

