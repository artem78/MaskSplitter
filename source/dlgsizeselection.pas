unit DlgSizeSelection;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ButtonPanel;

type

  { TImgSizeSelectionDialog }

  TImgSizeSelectionDialog = class(TForm)
    ButtonPanel1: TButtonPanel;
    Label1: TLabel;
    ListBox1: TListBox;
    procedure FormShow(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
  private
    function GetSizeSelectedIdx: integer;
    procedure SortList;
  public
    procedure AddSize(AWidth, AHeight: integer);
    property SelectedSizeIdx: integer read GetSizeSelectedIdx;
  end;

var
  ImgSizeSelectionDialog: TImgSizeSelectionDialog;

implementation

{$R *.lfm}

function CompareSizes(AList: TStringList; AIndex1, AIndex2: Integer): Integer;
  function StrToPixels(const AStr: string): integer;
  var
    Arr: array of string;
  begin
    arr := AStr.Split(['x', ' ']);
    Result := StrToInt(arr[0]) * StrToInt(arr[1]);
    //FreeAndNil(arr);
    SetLength(Arr, 0);
  end;

var
  S1, S2: string;
  Px1, Px2: integer;
begin
  s1 := AList[AIndex1];
  s2 := AList[AIndex2];

  px1 := StrToPixels(s1);
  px2 := StrToPixels(s2);

  if px1 < px2 then
    Result := -1
  else if px1 > px2 then
    Result := 1
  else
    Result := 0;
end;

{ TImgSizeSelectionDialog }

procedure TImgSizeSelectionDialog.ListBox1DblClick(Sender: TObject);
begin
  ModalResult:=mrOK;
end;

procedure TImgSizeSelectionDialog.FormShow(Sender: TObject);
begin
  SortList;

  // выделям последний размер (самый большой)
  ListBox1.ItemIndex:=ListBox1.Count-1;
end;

function TImgSizeSelectionDialog.GetSizeSelectedIdx: integer;
begin
  result:= PtrInt(ListBox1.Items.Objects[ListBox1.ItemIndex]);
end;

procedure TImgSizeSelectionDialog.SortList;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Assign(ListBox1.Items);
    sl.CustomSort(@CompareSizes);
    ListBox1.Items.Assign(sl);
  finally
    sl.Free
  end;
end;

procedure TImgSizeSelectionDialog.AddSize(AWidth, AHeight: integer);
var
  Idx: {integer} PtrUInt;
begin
  Idx := ListBox1.Count;
  ListBox1.AddItem(Format('%dx%d px', [AWidth, AHeight]), TObject(Idx));
end;

end.

