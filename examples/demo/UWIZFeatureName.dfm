object WIZFeatureName: TWIZFeatureName
  Left = 0
  Height = 520
  Top = 0
  Width = 760
  BorderStyle = bsNone
  ClientHeight = 520
  ClientWidth = 760
  Caption = 'Name and dynamic route'
  Position = poDefault
  object FTitleLabel: TLabel
    Left = 20
    Height = 26
    Top = 16
    Width = 720
    Caption = 'Name and dynamic route'
    Font.Height = -20
    Font.Style = [fsBold]
    ParentFont = False
  end
  object FDescriptionLabel: TLabel
    Left = 20
    Height = 38
    Top = 54
    Width = 720
    Caption = 'Enter and confirm a name. This first step offers Continue before any successor exists; it creates the route only after validation.'
    AutoSize = False
    WordWrap = True
    Anchors = [akTop, akLeft, akRight]
  end
  object FNameLabel: TLabel
    Left = 20
    Height = 20
    Top = 104
    Width = 80
    Caption = 'Name'
  end
  object FNameEdit: TEdit
    TabOrder = 0
    Left = 20
    Height = 28
    Top = 128
    Width = 540
    Anchors = [akTop, akLeft, akRight]
  end
  object FConfirmedCheckBox: TCheckBox
    TabOrder = 1
    Left = 20
    Height = 24
    Top = 170
    Width = 520
    Caption = 'I confirm this name is ready to use'
  end
  object FRegisterSuccessorCheckBox: TCheckBox
    TabOrder = 2
    Left = 20
    Height = 24
    Top = 204
    Width = 620
    Caption = 'Create the next steps when I continue'
  end
  object FRepeatInjectionCheckBox: TCheckBox
    TabOrder = 3
    Left = 20
    Height = 24
    Top = 238
    Width = 680
    Caption = 'Repeat the same insertion to demonstrate idempotency'
  end
  object FStatusLabel: TLabel
    Left = 20
    Height = 36
    Top = 296
    Width = 720
    Caption = 'Wizard events and state'
    AutoSize = False
    WordWrap = True
    Anchors = [akLeft, akRight, akBottom]
  end
  object FEventLog: TMemo
    Left = 20
    Height = 166
    Top = 338
    Width = 720
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssBoth
    WordWrap = False
    TabStop = False
  end
end
