program PascalWizard;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, UFRMMain, UFRMWorkArea, UFRMNotifyManyTest, Generics.Defaults,
  UWIZName_Step1A, UWIZName_Step1B, UWizardFeatureModel, UWizardFeatureDemo,
  UWIZFeatureBase, UWIZFeatureName, UWIZFeatureAge, UWIZFeatureOptional,
  UWIZFeatureCommit, UWIZFeatureSummary;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TFRMMain, MainForm);
  Application.Run;
end.

