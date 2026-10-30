object FRMMain: TFRMMain
  Left = -7
  Height = 500
  Top = 55
  Width = 800
  Caption = 'Sphere10 Pascal Framework demos'
  ClientHeight = 500
  ClientWidth = 800
  Visible = False
  object FFeatureWizardButton: TButton
    Left = 160
    Height = 40
    Top = 8
    Width = 300
    Caption = 'Wizard feature showcase'
    OnClick = FeatureWizardClick
    TabOrder = 3
  end
  object FFeatureDescriptionLabel: TLabel
    Left = 160
    Height = 78
    Top = 60
    Width = 620
    Caption = 'Explore validation, dynamic routes, optional steps, review gates, finish and cancellation retries, events and screen ownership. The event history remains here after the wizard closes. The original demos remain available on the left.'
    AutoSize = False
    WordWrap = True
    Anchors = [akTop, akLeft, akRight]
  end
  object FDemoResultsMemo: TMemo
    Left = 8
    Height = 344
    Top = 148
    Width = 784
    Anchors = [akTop, akLeft, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    Lines.Strings = (
      'Choose Wizard feature showcase to run the extended demo.'
      'Use the Age step to edit the route and the Summary step to try completion and cancellation failures.'
      'The Name wizard, Work Area and Notify Test remain unchanged.'
    )
    TabOrder = 4
  end
  object _wizardTestButton: TButton
    Left = 8
    Height = 25
    Top = 8
    Width = 131
    Caption = 'Run Wizard Test'
    OnClick = _wizardTestButtonClick
    TabOrder = 0
  end
  object FWorkAreaButton: TButton
    Left = 8
    Height = 25
    Top = 36
    Width = 131
    Caption = 'Work Area'
    OnClick = FWorkAreaButtonClick
    TabOrder = 1
  end
  object btnNotifyTest: TButton
    Left = 8
    Height = 25
    Top = 64
    Width = 131
    Caption = 'Notify Test'
    OnClick = btnNotifyTestClick
    TabOrder = 2
  end
end
