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
    //д�������ļ� {********����ļ���¼**********}
    procedure WriteToFile(sFile: string; sData: string);
    //ɾ��Ŀ¼��
    procedure DelTree(const ASourceDir: String);
    //����ļ���·�����������򴴽�
    function CheckFileDir(const FilePath: string): Boolean;
  public
    IsExamMode: string;                 //�Ƿ�Ϊ����ģʽ(0:��1:��)
    IsDebug: string;                    //�빫�����Խ�ʱ�Ƿ�Ϊ����ģʽ(0:��1:��)
    WEB_SYSCLASS: string;               //ϵͳ���
    WEB_SERIALNUMBER: string;           //�ӿ����к�
    WEB_URL: string;                    //�ӿڷ��ʵ�ַ
    WEB_SYSNUMBER: string;              //����ϵͳ���
    //��������
    function KillTask(ExeFileName: string): Integer;
    //�����ڴ�
    procedure ClearMemory;
    //��ȡ�ļ��о���·��
    function GetFileDir(fForderName: string): string;
    //��¼��־
    procedure WriteLog(const LogCode: string; LogMsg: string);
    //�����ļ�
    function ClearLocalFile(ciRDM: TClearRunDataMode; dirName: string;
       filetype: string; ciday: Integer = 7): Boolean;
    //��ȡ�����
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
      try  //Ϊ�Ѵ��ڵ��ļ������µ���־����
        try //�����쳣�������
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
      //�ļ����棬����list��¼���ݣ������
      tmplist := TStringList.Create;
      try
        try //�����쳣�������
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
