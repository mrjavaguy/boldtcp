object BoldTCPMonitor: TBoldTCPMonitor
  Left = 210
  Top = 161
  Width = 870
  Height = 640
  Caption = 'Bold TCP Monitor'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 862
    Height = 606
    ActivePage = tsClients
    Align = alClient
    TabOrder = 0
    object tsClients: TTabSheet
      Caption = 'Clients'
      object Panel1: TPanel
        Left = 0
        Top = 537
        Width = 854
        Height = 41
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 0
        object MonitorButton: TButton
          Left = 8
          Top = 8
          Width = 75
          Height = 25
          Caption = 'Start'
          TabOrder = 0
          OnClick = MonitorButtonClick
        end
      end
      object DBGrid1: TDBGrid
        Left = 0
        Top = 0
        Width = 854
        Height = 537
        Align = alClient
        DataSource = MonitorDM.dsClients
        TabOrder = 1
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
      end
    end
    object tsLocks: TTabSheet
      Caption = 'Locks'
      ImageIndex = 1
      object Label1: TLabel
        Left = 120
        Top = 200
        Width = 247
        Height = 29
        Caption = 'Not Implemented Yet'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
    end
  end
end
