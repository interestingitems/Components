object Form8: TForm8
  Left = 0
  Top = 0
  Caption = 'Form8'
  ClientHeight = 147
  ClientWidth = 578
  Color = clSilver
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object ProgressBar1: TProgressBar
    Left = 144
    Top = 195
    Width = 150
    Height = 17
    TabOrder = 0
  end
  object hProgrsssBar1: ThProgrsssBar
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 572
    Height = 33
    Align = alTop
    DoubleBuffered = True
    ColorScale = 10711881
    ColorBackground = 2102799
    ParentBackground = False
    Position = 3
    ParentColor = True
    Kind = pbkRoundRect
    RoundRadius = 15
  end
  object TrackBar1: TTrackBar
    Left = 96
    Top = 144
    Width = 300
    Height = 45
    Max = 100
    Position = 1
    TabOrder = 2
    OnChange = TrackBar1Change
  end
  object Panel1: TPanel
    Left = 184
    Top = 243
    Width = 185
    Height = 41
    Caption = 'Panel1'
    TabOrder = 3
  end
  object hTrackbar1: ThTrackbar
    AlignWithMargins = True
    Left = 3
    Top = 42
    Width = 572
    Height = 102
    Align = alClient
    Position = 3.000000000000000000
    OnChange = hTrackbar1Change
    ExplicitHeight = 298
  end
end
