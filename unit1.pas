unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, EditBtn, StdCtrls,
  BGRABitmap, LazFileUtils;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    OutputDirectoryEdit: TDirectoryEdit;
    InputFileNameEdit: TFileNameEdit;
    procedure Button1Click(Sender: TObject);
    procedure InputFileNameEditChange(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  TargetImageFileName, TargetImageMaskFileName: String;
  InputImage: TBGRABitmap;
  TargetBitmap, TargetBitmapMask: TBitmap;
  ImgRect: TRect;
  X, Y: Integer;
  Alpha: Byte;
  Col: TColor;
begin
  if (InputFileNameEdit.Text = '') or (OutputDirectoryEdit.Text = '') then
    exit;

  TargetImageFileName := IncludeTrailingPathDelimiter(OutputDirectoryEdit.Text)
                 + ExtractFileNameWithoutExt(ExtractFileNameOnly(InputFileNameEdit.Text))
                 + '.bmp';
  TargetImageMaskFileName := IncludeTrailingPathDelimiter(OutputDirectoryEdit.Text)
                 + ExtractFileNameWithoutExt(ExtractFileNameOnly(InputFileNameEdit.Text))
                 + '_mask.bmp';

  InputImage := TBGRABitmap.Create(InputFileNameEdit.Text);
  TargetBitmap := TBitmap.Create;
  TargetBitmapMask := TBitmap.Create;
  try
    InputImage.LoadFromFile(InputFileNameEdit.Text);

    ImgRect.SetLocation(0,0);
    ImgRect.Width  := InputImage.Width;
    ImgRect.Height := InputImage.Height;

    TargetBitmap.PixelFormat := pf24bit;
    TargetBitmap.Width  := InputImage.Width;
    TargetBitmap.Height := InputImage.Height;

    TargetBitmap.Canvas.Brush.Color := clWhite;
    TargetBitmap.Canvas.FillRect(ImgRect);
    TargetBitmap.Canvas.CopyRect(ImgRect, InputImage.Canvas, ImgRect);
    TargetBitmap.SaveToFile(TargetImageFileName);

    TargetBitmapMask.PixelFormat := pf24bit;
    TargetBitmapMask.Width  := InputImage.Width;
    TargetBitmapMask.Height := InputImage.Height;

    for X := 0 to InputImage.Width - 1 do
    begin
      for Y := 0 to InputImage.Height - 1 do
      begin
         Alpha := InputImage.ScanAt(X, Y).alpha;
         Col := RGBToColor(Alpha, Alpha, Alpha);
         TargetBitmapMask.Canvas.Pixels[X, Y] := Col;
      end;
    end;
    TargetBitmapMask.SaveToFile(TargetImageMaskFileName);
  finally
    InputImage.Free;
    TargetBitmap.Free;
    TargetBitmapMask.Free;
  end;

end;

procedure TForm1.InputFileNameEditChange(Sender: TObject);
begin
  if (InputFileNameEdit.Text <> '') and (OutputDirectoryEdit.Text = '') then
    OutputDirectoryEdit.Text := ExtractFileDir(InputFileNameEdit.Text);
end;

end.

