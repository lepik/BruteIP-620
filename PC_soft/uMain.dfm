object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'HardBrute'
  ClientHeight = 427
  ClientWidth = 626
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object GroupBox1: TGroupBox
    Left = 0
    Top = 0
    Width = 626
    Height = 57
    Align = alTop
    Caption = 'COM port'
    TabOrder = 0
    object cbComPort: TComboBox
      Left = 11
      Top = 22
      Width = 508
      Height = 21
      Style = csDropDownList
      ItemHeight = 0
      TabOrder = 0
    end
    object btnPortOpen: TButton
      Left = 543
      Top = 20
      Width = 75
      Height = 25
      Caption = 'Connect'
      TabOrder = 1
      OnClick = btnPortOpenClick
    end
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 408
    Width = 626
    Height = 19
    Panels = <
      item
        Width = 200
      end
      item
        Width = 200
      end>
  end
  object GroupBox2: TGroupBox
    Left = 0
    Top = 57
    Width = 626
    Height = 88
    Align = alTop
    Caption = 'Brute options'
    TabOrder = 2
    object Label1: TLabel
      Left = 11
      Top = 24
      Width = 49
      Height = 13
      Caption = 'Start pass'
    end
    object Label2: TLabel
      Left = 352
      Top = 24
      Width = 50
      Height = 13
      Caption = 'Send code'
    end
    object meStartPassw: TMaskEdit
      Left = 96
      Top = 21
      Width = 94
      Height = 21
      EditMask = '000000;1;_'
      MaxLength = 6
      TabOrder = 0
      Text = '999999'
    end
    object cbDownCount: TCheckBox
      Left = 11
      Top = 52
      Width = 86
      Height = 17
      Caption = 'Down count'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
    object btnBruteStart: TButton
      Left = 219
      Top = 19
      Width = 75
      Height = 25
      Caption = 'Start'
      TabOrder = 2
      OnClick = btnBruteStartClick
    end
    object btnBruteStop: TButton
      Left = 219
      Top = 48
      Width = 75
      Height = 25
      Caption = 'Stop'
      TabOrder = 3
      OnClick = btnBruteStopClick
    end
    object manEdtPaswd: TMaskEdit
      Left = 424
      Top = 21
      Width = 94
      Height = 21
      EditMask = '000000;1;_'
      MaxLength = 6
      TabOrder = 4
      Text = '000000'
    end
    object btnSendPassw: TButton
      Left = 543
      Top = 19
      Width = 75
      Height = 25
      Caption = 'Send'
      TabOrder = 5
      OnClick = btnSendPasswClick
    end
    object btnSendMENU: TButton
      Left = 363
      Top = 48
      Width = 75
      Height = 25
      Caption = 'MENU'
      TabOrder = 6
    end
    object btnSendF: TButton
      Left = 444
      Top = 48
      Width = 75
      Height = 25
      Caption = 'F'
      TabOrder = 7
    end
  end
  object GroupBox3: TGroupBox
    Left = 0
    Top = 145
    Width = 626
    Height = 263
    Align = alClient
    Caption = 'Brute result'
    TabOrder = 3
    object lvPasswd: TListView
      Left = 2
      Top = 15
      Width = 622
      Height = 246
      Align = alClient
      Columns = <
        item
          Caption = 'DateTime'
          Width = 130
        end
        item
        end
        item
          Caption = 'Code'
          Width = 120
        end>
      PopupMenu = PopupMenu
      TabOrder = 0
      ViewStyle = vsReport
    end
  end
  object OpenDialog: TOpenDialog
    Left = 176
    Top = 224
  end
  object SaveDialog: TSaveDialog
    Left = 256
    Top = 224
  end
  object PopupMenu: TPopupMenu
    Left = 336
    Top = 224
    object Save1: TMenuItem
      Caption = 'Save'
      OnClick = Save1Click
    end
    object Load1: TMenuItem
      Caption = 'Load'
      OnClick = Load1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Sendpasswd1: TMenuItem
      Caption = 'Send passwd'
      OnClick = Sendpasswd1Click
    end
  end
end
