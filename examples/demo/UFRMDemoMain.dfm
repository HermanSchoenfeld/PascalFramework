object DemoMainForm: TFRMDemoMain
  Left = 100
  Top = 100
  Width = 1200
  Height = 820
  Caption = 'PascalFramework examples'
  ClientWidth = 1200
  ClientHeight = 820
  Position = poScreenCenter
  OnCreate = FormCreate
  object Pages: TPageControl
    Left = 0
    Top = 0
    Width = 1200
    Height = 820
    ActivePage = GridTab
    Align = alClient
    TabOrder = 0
    object GridTab: TTabSheet
      Caption = 'Visual grid'
    end
    object WizardTab: TTabSheet
      Caption = 'Wizard and events'
    end
    object CacheTab: TTabSheet
      Caption = 'Cache'
      object CachePanel: TPanel
        Left = 0
        Top = 0
        Width = 1192
        Height = 90
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object CacheIntro: TLabel
          Left = 16
          Top = 12
          Width = 1100
          Height = 26
          AutoSize = False
          Caption = 'Fetching, hits, invalidation, eviction, pinning, admission events and owned-object disposal, using the same cache APIs as your application.'
          WordWrap = True
        end
        object RunCacheButton: TButton
          Left = 16
          Top = 48
          Width = 200
          Height = 30
          Caption = 'Run cache examples'
          OnClick = RunCacheClick
          TabOrder = 0
        end
      end
      object CacheOutput: TMemo
        Left = 0
        Top = 90
        Width = 1192
        Height = 700
        Align = alClient
        ReadOnly = True
        ScrollBars = ssBoth
        WordWrap = False
        TabOrder = 1
      end
    end
  end
end