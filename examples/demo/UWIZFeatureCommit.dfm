object WIZFeatureCommit: TWIZFeatureCommit
  Left = 0
  Height = 520
  Top = 0
  Width = 760
  BorderStyle = bsNone
  ClientHeight = 520
  ClientWidth = 760
  Caption = 'Confirm before review'
  Position = poDefault
  object FTitleLabel: TLabel
    Left = 20
    Height = 26
    Top = 16
    Width = 720
    Caption = 'Confirm before review'
    Font.Height = -20
    Font.Style = [fsBold]
    ParentFont = False
  end
  object FDescriptionLabel: TLabel
    Left = 20
    Height = 38
    Top = 54
    Width = 720
    Caption = 'This confirmation boundary hides Previous through the wizard navigation policy. The summary remains available after acceptance.'
    AutoSize = False
    WordWrap = True
    Anchors = [akTop, akLeft, akRight]
  end
  object FReviewLabel: TLabel
    Left = 20
    Height = 24
    Top = 112
    Width = 720
    Caption = 'Your accepted setup appears here.'
    AutoSize = False
    WordWrap = True
  end
  object FAcceptCheckBox: TCheckBox
    TabOrder = 0
    Left = 20
    Height = 24
    Top = 156
    Width = 700
    Caption = 'I accept this setup and want to open the summary'
  end
  object FBoundaryLabel: TLabel
    Left = 20
    Height = 54
    Top = 210
    Width = 720
    Caption = 'Previous is unavailable on this screen. The final summary can return here without permitting changes behind this boundary.'
    AutoSize = False
    WordWrap = True
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
