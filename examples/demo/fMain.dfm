object Form1: TForm1
  Left = 439
  Height = 584
  Top = 210
  Width = 712
  ActiveControl = lbSearchCriteria
  Caption = 'Form1'
  ClientHeight = 584
  ClientWidth = 712
  OnCreate = FormCreate
  Visible = False
  object GridPanel: TPanel
    Left = 304
    Height = 584
    Top = 0
    Width = 408
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 1
    BorderStyle = bsSingle
    ParentColor = False
    TabOrder = 0
    object lbSearchCriteria: TListBox
      Left = 1
      Height = 64
      Top = 1
      Width = 402
      Align = alTop
      ItemHeight = 0
      TabOrder = 0
    end
    object pWidgets: TPanel
      Left = 48
      Height = 163
      Top = 168
      Width = 312
      Caption = 'pWidgets'
      TabOrder = 1
      Visible = False
      object Button1: TButton
        Left = 56
        Height = 32
        Top = 104
        Width = 104
        Caption = 'Button1'
        TabOrder = 0
      end
      object ComboBox1: TComboBox
        Left = 152
        Height = 23
        Top = 24
        Width = 150
        ItemHeight = 15
        TabOrder = 1
        Text = 'ComboBox1'
      end
      object Edit1: TEdit
        Left = 8
        Height = 23
        Top = 16
        Width = 120
        TabOrder = 2
        Text = 'Edit1'
      end
    end
  end
  object Panel2: TPanel
    Left = 0
    Height = 584
    Top = 0
    Width = 304
    Align = alLeft
    Caption = 'Panel2'
    TabOrder = 1
    object TIPropertyGrid1: TValueListEditor
      Left = 1
      Height = 312
      Top = 133
      Width = 304
      Align = alLeft
    end
    object Panel1: TPanel
      Left = 1
      Height = 107
      Top = 1
      Width = 302
      Align = alTop
      AutoSize = True
      TabOrder = 1
      object AddDelayCheckBox: TCheckBox
        Left = 11
        Height = 19
        Top = 54
        Width = 103
        Caption = 'Add fetch delay'
        TabOrder = 0
      end
      object ColumnsAutoFillCheckBox: TCheckBox
        Left = 11
        Height = 19
        Top = 16
        Width = 176
        Caption = 'Columns auto fill horizontally'
        OnClick = ColumnsAutoFillCheckBoxChange
        TabOrder = 1
      end
      object lSelection: TLabel
        Left = 1
        Height = 15
        Top = 1
        Width = 300
        Align = alTop
        Caption = 'Selection'
        ParentColor = False
      end
      object FirstColumnStretchedCheckBox: TCheckBox
        Left = 31
        Height = 19
        Top = 35
        Width = 166
        Caption = 'First column stretched to fit'
        OnClick = FirstColumnStretchedCheckBoxChange
        TabOrder = 2
      end
      object bSetWidth: TButton
        Left = 5
        Height = 25
        Top = 77
        Width = 149
        Caption = 'Set width for col'
        OnClick = bSetWidthClick
        TabOrder = 3
      end
      object eCol: TEdit
        Left = 156
        Height = 25
        Top = 77
        Width = 34
        Anchors = [akTop, akLeft, akBottom]
        NumbersOnly = True
        TabOrder = 4
        Text = '0'
      end
      object lWidth: TLabel
        Left = 192
        Height = 25
        Top = 77
        Width = 30
        Anchors = [akTop, akLeft, akBottom]
        Caption = 'width'
        Layout = tlCenter
        ParentColor = False
      end
      object eWidth: TEdit
        Left = 224
        Height = 25
        Top = 77
        Width = 51
        Anchors = [akTop, akLeft, akBottom]
        NumbersOnly = True
        TabOrder = 5
        Text = '150'
      end
    end
    object bRefresh: TButton
      Left = 1
      Height = 25
      Top = 108
      Width = 302
      Align = alTop
      Caption = 'Refresh inspector'
      OnClick = bRefreshClick
      TabOrder = 2
    end
    object Panel3: TPanel
      Left = 1
      Height = 138
      Top = 445
      Width = 302
      Align = alBottom
      TabOrder = 3
      object bSearchParser: TButton
        Left = 214
        Height = 23
        Top = 72
        Width = 75
        Caption = 'Test'
        OnClick = bSearchParserClick
        TabOrder = 0
      end
      object Label1: TLabel
        Left = 105
        Height = 15
        Top = 1
        Width = 92
        Caption = 'Expressions tester'
        ParentColor = False
      end
      object lExpectedKind: TLabel
        Left = 60
        Height = 15
        Top = 40
        Width = 82
        Anchors = [akTop, akRight]
        Caption = 'Expected kind : '
        ParentColor = False
      end
      object cbExpectedKind: TComboBox
        Left = 144
        Height = 23
        Top = 36
        Width = 145
        ItemHeight = 15
        ItemIndex = 0
        Items.Strings = (
          'Unknown'
          'Text'
          'Num'
          'Set'
        )
        Style = csDropDownList
        TabOrder = 1
        Text = 'Unknown'
      end
      object cbSearchParser: TComboBox
        Left = 18
        Height = 23
        Top = 72
        Width = 190
        ItemHeight = 15
        ItemIndex = 1
        Items.Strings = (
          '%\%'
          '%\%%'
          '(123, 2)'
          '[321, 3]'
          '%foo'
          '%\%foo%'
          '=10'
          '3'
          '>=10'
        )
        TabOrder = 2
        Text = '%\%%'
      end
      object bRegenerate: TButton
        Left = 120
        Height = 23
        Top = 104
        Width = 89
        Caption = 'Re-Generate'
        OnClick = bRegenerateClick
        TabOrder = 3
      end
      object eNumEntities: TEdit
        Left = 216
        Height = 25
        Top = 104
        Width = 72
        Anchors = [akTop, akLeft, akBottom]
        NumbersOnly = True
        OnChange = eNumEntitiesChange
        TabOrder = 4
        Text = '10000'
      end
      object bDeselect: TButton
        Left = 18
        Height = 23
        Top = 104
        Width = 89
        Caption = 'Deselect'
        OnClick = bDeselectClick
        TabOrder = 5
      end
    end
  end
  object PopupMenu1: TPopupMenu
    left = 360
    top = 24
    object miUpdateCell: TMenuItem
      Caption = 'Update cell'
      OnClick = miUpdateCellClick
    end
    object miUpdateRow: TMenuItem
      Caption = 'Update row'
      OnClick = miUpdateRowClick
    end
    object MenuItem3: TMenuItem
      Caption = 'None'
    end
  end
end
