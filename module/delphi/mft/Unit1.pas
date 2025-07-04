unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.IniFiles, System.SysUtils, System.StrUtils, System.Types, System.Classes, System.IOUtils, Vcl.Controls, Vcl.Forms, Vcl.ComCtrls, Vcl.StdCtrls,
  Unit2, Unit3, Vcl.ExtCtrls;

type
  TfrmNTFSScan = class(TForm)
    lvFiles: TListView;
    mmoLog: TMemo;
    tmrStart: TTimer;
    procedure lvFilesData(Sender: TObject; Item: TListItem);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure tmrStartTimer(Sender: TObject);
  private
    FintStartTime      : Cardinal;
    FintThreadCount    : Integer;
    FlstFiles          : array of TList;
    FLogicalDriveHandle: THashedStringList;
    { 销毁驱动器列表 }
    procedure FreeDriveList;
    { 销毁文件列表 }
    procedure FreeFileList;
    { 开始全盘搜索文件 }
    procedure SearchMFT;
    { 获取全路径文件名称 }
    function GetFileFullName(const intFileID: UInt64; const intIndex: Integer; var intFileLength: UInt64): string;
  protected
    { 搜索单磁盘结束 }
    procedure WMSEARCHDRIVEFILEFINISHED(var msg: TMessage); message WM_SEARCHDRIVEFILEFINISHED;
  end;

implementation

{$R *.dfm}

procedure TfrmNTFSScan.tmrStartTimer(Sender: TObject);
begin
  tmrStart.Enabled := False;
  FintThreadCount  := 0;
  SearchMFT;
end;

{ 销毁驱动器列表 }
procedure TfrmNTFSScan.FreeDriveList;
var
  I: Integer;
begin
  for I := 0 to FLogicalDriveHandle.Count - 1 do
  begin
    CloseHandle(StrToInt(FLogicalDriveHandle.ValueFromIndex[I]));
  end;
  FLogicalDriveHandle.Free;
end;

{ 销毁文件列表 }
procedure TfrmNTFSScan.FreeFileList;
var
  I      : Integer;
  lstData: TList;
  J      : Integer;
begin
  { 先销毁内存 }
  for I := Low(FlstFiles) to High(FlstFiles) do
  begin
    lstData := FlstFiles[I];
    for J   := lstData.Count - 1 downto 0 do
    begin
      FreeMem(lstData.Items[J]);
      lstData.Delete(J);
    end;
  end;

  { 再释放变量 }
  for I := Low(FlstFiles) to High(FlstFiles) do
  begin
    lstData := FlstFiles[I];
    lstData.Free;
  end;
end;

procedure TfrmNTFSScan.FormDestroy(Sender: TObject);
begin
  lvFiles.Items.Count := 0;     // 停止界面绘制
  lvFiles.OwnerData   := False; // 停止界面绘制
  FreeDriveList;                // 销毁驱动器列表
  FreeFileList;                 // 销毁文件列表
end;

procedure TfrmNTFSScan.FormResize(Sender: TObject);
begin
  lvFiles.Columns[1].Width := Width - 240;
end;

{ 开始全盘搜索文件 }
procedure TfrmNTFSScan.SearchMFT;
var
  lstDrivers  : TStringList;
  arrlist     : TStringDynArray;
  strDriver   : String;
  intLen      : DWORD;
  sysFlags    : DWORD;
  strNTFS     : array [0 .. 255] of Char;
  I           : Integer;
  hRootHandle : THandle;
  chrDriveName: Char;
  strTip      : String;
begin
  lstDrivers := TStringList.Create;
  try
    arrlist := TDirectory.GetLogicalDrives;
    for strDriver in arrlist do
    begin
      { 判断是否是 NTFS 格式的磁盘 }
      if not GetVolumeInformation(PChar(strDriver), nil, 0, nil, intLen, sysFlags, strNTFS, 256) then
        Continue;

      if not SameText(strNTFS, 'NTFS') then
        Continue;

      { 加入到待搜索列表 }
      lstDrivers.Add(strDriver[1]);
    end;

    if lstDrivers.Count = 0 then
      Exit;

    { 信息提示 }
    strTip := '';
    for I  := 0 to lstDrivers.Count - 1 do
    begin
      strTip := strTip + ',' + lstDrivers.Strings[I][1];
    end;
    mmoLog.Lines.Add(Format('%s 共计 %d 个逻辑盘待搜索', [RightStr(strTip, Length(strTip) - 1), lstDrivers.Count]));
    mmoLog.Lines.Add('搜索中，请稍等﹒﹒﹒﹒﹒﹒');

    { 多线程搜索所有 NTFS 磁盘所有文件 }
    FintThreadCount := lstDrivers.Count;
    SetLength(FlstFiles, FintThreadCount);
    FLogicalDriveHandle := THashedStringList.Create;
    FintStartTime       := GetTickCount;
    for I               := 0 to lstDrivers.Count - 1 do
    begin
      FlstFiles[I] := TList.Create;
      chrDriveName := lstDrivers.Strings[I][1];
      hRootHandle  := CreateFileA(PAnsiChar(AnsiString('\\.\' + chrDriveName + ':')), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
      FLogicalDriveHandle.Add(Format('%s=%d', [chrDriveName, hRootHandle]));
      TSearchMFT.Create(chrDriveName, Handle, FlstFiles[I], hRootHandle);
    end;
  finally
    lstDrivers.Free;
  end;
end;

{ 搜索单磁盘结束 }
procedure TfrmNTFSScan.WMSEARCHDRIVEFILEFINISHED(var msg: TMessage);
var
  I          : Integer;
  Count      : Integer;
  intStopTime: Cardinal;
  strTip     : String;
begin
  Dec(FintThreadCount);

  intStopTime := GetTickCount;
  strTip      := Format('%s:\ 搜索完毕。文件总数：%0.8d。用时：%0.3d 秒', [Chr(msg.WParam), msg.LParam, (intStopTime - FintStartTime) div 1000]);
  mmoLog.Lines.Add(strTip);

  if FintThreadCount = 0 then
  begin
    Count := 0;
    for I := Low(FlstFiles) to High(FlstFiles) do
    begin
      Count := Count + FlstFiles[I].Count;
    end;
    lvFiles.Items.Count := Count;
    mmoLog.Lines.Add(Format('全部搜索完毕。文件总数：%0.8d', [Count]));
  end;
end;

procedure TfrmNTFSScan.lvFilesData(Sender: TObject; Item: TListItem);
var
  I, intIndex, Count: Integer;
  FileInfo          : pFileInfo;
  intFileID         : UInt64;
  intFileLength     : UInt64;
begin
  intIndex     := Item.Index;
  Count        := 0;
  Item.Caption := IntToStr(intIndex + 1);

  for I := Low(FlstFiles) to High(FlstFiles) do
  begin
    Count := Count + FlstFiles[I].Count;
    if intIndex <= Count then
    begin
      FileInfo  := pFileInfo(FlstFiles[I].Items[intIndex - (Count - FlstFiles[I].Count)]);
      intFileID := FileInfo^.intFileID;
      Item.SubItems.Add(GetFileFullName(intFileID, I, intFileLength));
      Item.SubItems.Add(UIntToStr(intFileLength));
      Break;
    end;
  end;
end;

{ 获取全路径文件名称 }
function TfrmNTFSScan.GetFileFullName(const intFileID: UInt64; const intIndex: Integer; var intFileLength: UInt64): string;
var
  hRootHandle : THandle;
  strDriveName: String;
begin
  strDriveName := FLogicalDriveHandle.Names[intIndex];
  hRootHandle  := StrToInt(FLogicalDriveHandle.ValueFromIndex[intIndex]);
  Result       := GetFilelNameByID(hRootHandle, intFileID, intFileLength, strDriveName);
end;

end.
