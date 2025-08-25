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
    CheckBox1: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    OutputDirectoryEdit: TDirectoryEdit;
    InputFileNameEdit: TFileNameEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure InputFileNameEditChange(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

uses  fileinfo
  , winpeimagereader {need this for reading exe info}
  , elfreader; {needed for reading ELF executables}

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

    {TargetBitmap.Canvas.Brush.Color := clWhite;
    TargetBitmap.Canvas.FillRect(ImgRect);}

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
         TargetBitmap.Canvas.Pixels[X, Y] := InputImage.ScanAt(X, Y).ToColor();
      end;
    end;
    TargetBitmap.SaveToFile(TargetImageFileName);
    TargetBitmapMask.SaveToFile(TargetImageMaskFileName);

    ShowMessage('Выполнено!');
  finally
    InputImage.Free;
    TargetBitmap.Free;
    TargetBitmapMask.Free;
  end;

  if CheckBox1.Checked then
    DeleteFile(InputFileNameEdit.Text);

end;

procedure TForm1.FormCreate(Sender: TObject);
var
  VersionStr: string;
  FileVerInfo: TFileVersionInfo;
  I: Integer;
begin
  FileVerInfo:=TFileVersionInfo.Create(nil);
  try
    FileVerInfo.ReadFileInfo;
    VersionStr := FileVerInfo.VersionStrings.Values[{'ProductVersion'} 'FileVersion'];
  finally
    FileVerInfo.Free;
  end;

  for I := 0 to 1 do
  begin
    if VersionStr.EndsWith('.0') then
      Delete(VersionStr, VersionStr.Length - 2, 2);
  end;

  Caption := Caption + ' - v' + VersionStr;
end;

procedure TForm1.InputFileNameEditChange(Sender: TObject);
begin
  if (InputFileNameEdit.Text <> '') and (OutputDirectoryEdit.Text = '') then
    OutputDirectoryEdit.Text := ExtractFileDir(InputFileNameEdit.Text);
end;

end.

