unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, EditBtn, StdCtrls,
  ExtCtrls, BGRABitmap, LazFileUtils;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    CheckBox1: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    ImagePreview: TImage;
    Label3: TLabel;
    MaskPreview: TImage;
    Label1: TLabel;
    Label2: TLabel;
    OutputDirectoryEdit: TDirectoryEdit;
    InputFileNameEdit: TFileNameEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure InputFileNameEditChange(Sender: TObject);
  private
    procedure LoadSettings;
    procedure SaveSettings;
    //procedure UpdatePreviews;
    procedure LoadImage;
    procedure SaveResult;
  public

  end;

var
  Form1: TForm1;

implementation

uses  fileinfo
  , winpeimagereader {need this for reading exe info}
  , elfreader {needed for reading ELF executables}
  , Registry, StrUtils, BGRASVG;

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  SaveResult;
end;

procedure TForm1.LoadImage;
var
  InputImage: TBGRABitmap = nil;
  svg: TBGRASVG = nil;
  TargetBitmap, TargetBitmapMask: TBitmap;
  ImgRect: TRect;
  X, Y: Integer;
  Alpha: Byte;
  Col: TColor;
  IsSvg: Boolean;
begin
  // FIXME: в linux при выборе svg файла ошибка "unknown picture extension"
  // https://ibb.co/xShYjxzM

  Label3.Caption:='';

  if (InputFileNameEdit.Text = '') {or (OutputDirectoryEdit.Text = '')} then
    exit;

  //IsSvg := InputFileNameEdit.Text.EndsWith('.svg', True);
  IsSvg:=EndsText('.svg', InputFileNameEdit.Text);
  if IsSvg then
  begin
    // исправление некорректных размеров для некоторых svg файлов
    svg := TBGRASVG.Create(InputFileNameEdit.Text);
    try
      svg.ConvertToUnit(cuCustom); // <----
      InputImage := TBGRABitmap.Create(Round(svg.WidthAsPixel), Round(svg.HeightAsPixel));
      svg.StretchDraw(InputImage.Canvas2D, 0, 0, cuCustom);
    finally
      FreeAndNil(svg);
    end;
  end
  else
    InputImage := TBGRABitmap.Create(InputFileNameEdit.Text);

  TargetBitmap := TBitmap.Create;
  TargetBitmapMask := TBitmap.Create;
  try
    //InputImage.LoadFromFile(InputFileNameEdit.Text);

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

    ImagePreview.Picture.Assign(TargetBitmap);
    MaskPreview.Picture.Assign(TargetBitmapMask);
    Label3.Caption:=format('%dx%d px', [InputImage.Width, InputImage.Height]);
  finally
    FreeAndNil(InputImage);
    //FreeAndNil(svg);
    TargetBitmap.Free;
    TargetBitmapMask.Free;
  end;
end;

procedure TForm1.SaveResult;
var
  TargetImageFileName, TargetImageMaskFileName: String;
begin
  if (InputFileNameEdit.Text = '') or (OutputDirectoryEdit.Text = '') then
    exit;

  TargetImageFileName := IncludeTrailingPathDelimiter(OutputDirectoryEdit.Text)
                 + ExtractFileNameWithoutExt(ExtractFileNameOnly(InputFileNameEdit.Text))
                 + '.bmp';
  TargetImageMaskFileName := IncludeTrailingPathDelimiter(OutputDirectoryEdit.Text)
                 + ExtractFileNameWithoutExt(ExtractFileNameOnly(InputFileNameEdit.Text))
                 + '_mask.bmp';

  ImagePreview.Picture.SaveToFile(TargetImageFileName);
  MaskPreview.Picture.SaveToFile(TargetImageMaskFileName);

  if CheckBox1.Checked then
    DeleteFile(InputFileNameEdit.Text);

  ShowMessage('Done!');
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SaveSettings;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  VersionStr: string;
  FileVerInfo: TFileVersionInfo;
  I: Integer;
begin
  Label3.Caption:='';

  // включаем поддержку svg
  BGRASVG.RegisterSvgFormat;

  LoadSettings;


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
      Delete(VersionStr, VersionStr.Length - 2 + 1, 2);
  end;

  Caption := Caption + ' - v' + VersionStr;
end;

procedure TForm1.InputFileNameEditChange(Sender: TObject);
begin
  ImagePreview.Canvas.Clear;
  MaskPreview.Canvas.Clear;

  if (InputFileNameEdit.Text <> '') and (OutputDirectoryEdit.Text = '') then
    OutputDirectoryEdit.Text := ExtractFileDir(InputFileNameEdit.Text);

  if (InputFileNameEdit.Text <> '') then
  begin
    try
       LoadImage;
    except
    end;
  end
end;

procedure TForm1.LoadSettings;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := {HKEY_LOCAL_MACHINE} HKEY_CURRENT_USER;
    if Registry.OpenKeyReadOnly('\Software\artem78\MaskSplitter\') then
    begin
      if Registry.ValueExists('SourceFile') and FileExists(Registry.ReadString('SourceFile')) then
        InputFileNameEdit.Text := Registry.ReadString('SourceFile');

      if Registry.ValueExists('TargetDir') and DirectoryExists(Registry.ReadString('TargetDir')) then
        OutputDirectoryEdit.Text := Registry.ReadString('TargetDir');

      if Registry.ValueExists('DeleteSourceFile') then
        CheckBox1.Checked := Registry.ReadBool('DeleteSourceFile');

      Registry.CloseKey;
    end;
  finally
    Registry.Free;
  end;
end;

procedure TForm1.SaveSettings;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := {HKEY_LOCAL_MACHINE} HKEY_CURRENT_USER;
    if Registry.OpenKey('\Software\artem78\MaskSplitter\', True) then
    begin
      Registry.WriteString('SourceFile', InputFileNameEdit.Text);
      Registry.WriteString('TargetDir', OutputDirectoryEdit.Text);
      Registry.WriteBool('DeleteSourceFile', CheckBox1.Checked);
      Registry.CloseKey;
    end;
  finally
    Registry.Free;  // In non-Windows operating systems this flushes the reg.xml file to disk
  end;
end;

{procedure TForm1.UpdatePreviews;
begin

end;}

end.

