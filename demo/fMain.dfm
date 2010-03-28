object frmMain: TfrmMain
  Left = 249
  Top = 251
  Width = 472
  Height = 460
  Caption = 'frmMain'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  PixelsPerInch = 96
  TextHeight = 13
  object BoldGrid1: TBoldGrid
    Left = 0
    Top = 0
    Width = 464
    Height = 381
    AddNewAtEnd = False
    Align = alClient
    BoldAutoColumns = True
    BoldShowConstraints = False
    BoldHandle = BoldListHandle1
    BoldProperties.NilElementMode = neNone
    Columns = <
      item
        Color = clBtnFace
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
      end
      item
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
      end>
    DefaultRowHeight = 17
    EnableColAdjust = False
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    ColWidths = (
      17
      64)
  end
  object BoldNavigator1: TBoldNavigator
    Left = 0
    Top = 381
    Width = 464
    Height = 25
    Align = alBottom
    BoldHandle = BoldListHandle1
    TabOrder = 1
    ImageIndices.nbFirst = -1
    ImageIndices.nbPrior = -1
    ImageIndices.nbNext = -1
    ImageIndices.nbLast = -1
    ImageIndices.nbInsert = -1
    ImageIndices.nbDelete = -1
    ImageIndices.nbMoveUp = -1
    ImageIndices.nbMoveDown = -1
    DeleteQuestion = 'Delete "%1:s"?'
    UnlinkQuestion = 'Unlink "%1:s" from "%2:s"?'
    RemoveQuestion = 'Remove "%1:s" from the list?'
  end
  object MainMenu1: TMainMenu
    Left = 4
    Top = 4
    object File1: TMenuItem
      Caption = 'File'
      object Updatedatabase1: TMenuItem
        Action = dmMain.BoldUpdateDBAction1
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = 'Exit'
        OnClick = Exit1Click
      end
    end
    object Debug1: TMenuItem
      Caption = 'Debug'
      object SystemDebugger1: TMenuItem
        Caption = 'SystemDebugger'
        OnClick = SystemDebugger1Click
      end
    end
    object N1: TMenuItem
      Caption = '?'
      object About1: TMenuItem
        Caption = 'About'
        OnClick = About1Click
      end
    end
  end
  object BoldListHandle1: TBoldListHandle
    RootHandle = dmMain.bshMain
    Expression = 'Books.allInstances'
    Left = 176
    Top = 40
  end
end
