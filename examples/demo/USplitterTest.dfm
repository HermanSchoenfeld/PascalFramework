object SplitterTestForm: TSplitterTestForm
  Left = 0
  Height = 420
  Top = 0
  Width = 764
  Caption = 'Form1'
  ClientHeight = 420
  ClientWidth = 764
  Visible = False
  object PairSplitter1: TPanel
    BevelOuter = bvNone
    Left = 0
    Height = 420
    Top = 0
    Width = 764
    Align = alClient
    object PairSplitterSide1: TPanel
      BevelOuter = bvNone
      Align = alLeft
      Cursor = crArrow
      Left = 0
      Height = 420
      Top = 0
      Width = 384
      object StaticText1: TStaticText
        Left = 80
        Height = 17
        Top = 72
        Width = 65
        Caption = 'StaticText1'
        TabOrder = 0
      end
    end
    object NativeSplitter: TSplitter
      Left = 384
      Top = 0
      Width = 5
      Height = 420
      Align = alLeft
    end
    object PairSplitterSide2: TPanel
      BevelOuter = bvNone
      Align = alClient
      Cursor = crArrow
      Left = 389
      Height = 420
      Top = 0
      Width = 375
    end
  end
end
