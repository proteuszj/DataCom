unit UPublic;

interface

{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}

uses
  windows, SysUtils, StrUtils, Classes, Controls, Graphics, Forms, ShellAPI,
  Printers, Winsock, ExtCtrls, TlHelp32, UEncryptSDK;

type
  TClearRunDataMode = (crd_All, crd_Part);
  TPublic = class(TObject)
  private
    //写数据至文件 {********落地文件记录**********}
    procedure WriteToFile(sFile: string; sData: string);
    //删除目录树
    procedure DelTree(const ASourceDir: String);
    //检测文件夹路径，不存在则创建
    function CheckFileDir(const FilePath: string): Boolean;
  public
    IsExamMode: string;                 //是否为考试模式(0:否；1:是)
    IsDebug: string;                    //与公安网对接时是否为调试模式(0:否；1:是)
    WEB_SYSCLASS: string;               //系统类别
    WEB_SERIALNUMBER: string;           //接口序列号
    WEB_URL: string;                    //接口访问地址
    WEB_SYSNUMBER: string;              //考试系统编号
    //结束进程
    function KillTask(ExeFileName: string): Integer;
    //清理内存
    procedure ClearMemory;
    //获取文件夹绝对路径
    function GetFileDir(fForderName: string): string;
    //记录日志
    procedure WriteLog(const LogCode: string; LogMsg: string);
    //清理文件
    function ClearLocalFile(ciRDM: TClearRunDataMode; dirName: string;
       filetype: string; ciday: Integer = 7): Boolean;
    //获取随机数
    function GetRandomStr(len: Integer; lowercase: Boolean=True; num: Boolean=True;
          uppercase: Boolean=False; other: Boolean=false): string;
  end;

var
  claPublic: TPublic = nil;

implementation

{ TPublic }

function TPublic.CheckFileDir(const FilePath: string): Boolean;
begin
  Result := True;
  try
    if not DirectoryExists(FilePath) then
    begin
      if not ForceDirectories(FilePath) then
        Result := False;
    end;
  except
    Result := False;
  end;
end;

function TPublic.ClearLocalFile(ciRDM: TClearRunDataMode; dirName,
  filetype: string; ciday: Integer): Boolean;
var
  FileRec: TSearchrec;
  filepath,tmpLogName: string;
  tmpDate: TDateTime;
  tmpdt: Double;
begin
  Result := False;
  try
    filepath := GetFileDir(dirName);
    if FindFirst(filepath + filetype, faAnyfile, FileRec) = 0 then
    repeat
      if (Trim(FileRec.Name) = '.') or (Trim(FileRec.Name) = '..') then
        Continue;
      if (FileRec.Attr and faDirectory) = 0 then
      begin
        case ciRDM  of
          crd_All : Deletefile(PChar(filepath + FileRec.Name));
          crd_Part:
             begin
                tmpLogName := MidStr(FileRec.Name,Pos('_',FileRec.Name)+1,Pos('.',FileRec.Name)-Pos('_',FileRec.Name)-1);
                tmpDate := StrToDate(leftstr(tmpLogName,4) + FormatSettings.DateSeparator +
                                     midstr(tmpLogName,5,2) + FormatSettings.DateSeparator +
                                     midstr(tmpLogName,7,2) );
                tmpdt := Trunc(Now - tmpdate);
                if tmpdt >= ciday then
                  Deletefile(PChar(filepath+FileRec.Name));
             end;
        end;
      end;
    until FindNext(FileRec)<>0;
    SysUtils.FindClose(FileRec);
    Result := True;
  except
  end;
end;

procedure TPublic.ClearMemory;
begin
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    SetProcessWorkingSetSize(GetCurrentProcess, $FFFFFFFF, $FFFFFFFF);
    Application.ProcessMessages;
  end;
end;

procedure TPublic.DelTree(const ASourceDir: String);
var
  FileRec: TSearchrec;
  Sour: String;
begin
  try
    Sour := ASourceDir;
    if Sour[Length(Sour)] <> '\' then
      Sour := Format('%s\',[Sour]);
    if FindFirst(Sour+'*.*',faAnyfile,FileRec) = 0 then
    repeat
      if ((FileRec.Attr and faDirectory) <> 0) then
      begin
        if (FileRec.Name <> '.') and (FileRec.Name <> '..') then
        begin
          DelTree(Sour+FileRec.Name);
          FileSetAttr(Sour+FileRec.Name,faArchive);
          RemoveDir(Sour+FileRec.Name);
        end;
      end
      else
      begin
        FileSetAttr(Sour+FileRec.Name,faArchive);
        deletefile(PChar(Sour+FileRec.Name));
      end;
    until FindNext(FileRec)<>0;
    SysUtils.FindClose(FileRec);
    FileSetAttr(Sour,faArchive);
    RemoveDir(Sour);
  except
  end;
end;

function TPublic.GetFileDir(fForderName: string): string;
var
  tmpPath: string;
begin
  tmpPath := Format('%s\%s\',[ExtractFileDir(ParamStr(0)),fForderName]);
  if not CheckFileDir(tmpPath) then
    tmpPath := '';
  Result := tmpPath;
end;

function TPublic.GetRandomStr(len: Integer; lowercase, num, uppercase,
  other: Boolean): string;
const
  upperStr = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  lowerStr = 'abcdefghijklmnopqrstuvwxyz';
  numStr   = '0123456789';
  otherStr = '_-|*@';
var
  sourceStr : string;
  i : Integer;
begin
  sourceStr := '';
  Result := '';
  if uppercase = True then
    sourceStr := sourceStr + upperStr;
  if lowercase = True then
    sourceStr := sourceStr + lowerStr;
  if num = True then
    sourceStr := sourceStr + numStr;
  if other = True then
    sourceStr := sourceStr + otherStr;
  if (sourceStr = '') or (len<1) then
    exit;

  Randomize;
  for i := 1 to len do
  begin
    Result := Result + sourceStr[Random(Length(sourceStr)-1)+1];
  end;
end;

function TPublic.KillTask(ExeFileName: string): Integer;
const
    PROCESS_TERMINATE = $0001;
var
    ContinueLoop: BOOL;
    FSnapshotHandle: THandle;
    FProcessEntry32: TProcessEntry32;
begin
    Result := 0;
    FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
    ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
    while Integer(ContinueLoop) <> 0 do
    begin
      if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
        UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
        UpperCase(ExeFileName))) then
        Result := Integer(TerminateProcess(
                          OpenProcess(PROCESS_TERMINATE,
                                      BOOL(0),
                                      FProcessEntry32.th32ProcessID),
                                      0));
        ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
    end;
    CloseHandle(FSnapshotHandle);
end;

procedure TPublic.WriteLog(const LogCode: string; LogMsg: string);
var
  LogFile, LogInfo: string;
begin
  try
    LogInfo := Format('%s [%s] %s',[FormatDateTime('hh:mm:ss',now),LogCode,LogMsg]);
    LogFile := GetFileDir('logs') + Format('RecLog_%s.log',[FormatDateTime('yyyymmdd',Now)]);
    WriteToFile(LogFile,LogInfo);
  except
    Exit;
  end;
end;

procedure TPublic.WriteToFile(sFile, sData: string);
var
  txtFile: TextFile;
  tmplist: TStringList;
begin
  try
    if FileExists(sFile) then
    begin
      try  //为已存在的文件加入新的日志内容
        try //增加异常捕获机制
          AssignFile(txtFile, sFile);
          Append(txtFile);
          Writeln(txtFile,sData);
        except
        end;
      finally
        CloseFile(txtFile);
      end;
    end else
    begin
      //文件不存，则用list记录内容，并落地
      tmplist := TStringList.Create;
      try
        try //增加异常捕获机制
          tmplist.Add(sData);
          tmplist.SaveToFile(sFile);
        except
        end;
      finally
        tmplist.Free;
      end;
    end;
  except
    Exit;
  end;
end;

initialization
  claPublic := TPublic.Create;

finalization
  claPublic.Free;

end.
