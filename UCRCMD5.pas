unit UCRCMD5;

interface

uses
  Classes, IdHashMessageDigest, IdHashCRC;

  { ��ȡ�ļ�CRCУ���� }
  function GetFileCRC(const iFileName: string): String;
  { ��ȡ�ַ���CRCУ���� }
  function GetStringCRC(const Str: string): Cardinal;
  { ȡ�ļ�MD5�� }
  function GetFileMD5(const iFileName: string): String;

implementation

{ ��ȡ�ļ�CRCУ���� }
function GetFileCRC(const iFileName: string): String;
var
  MemSteam: TMemoryStream;
  MyCRC   : TIdHashCRC32;
begin
  MemSteam := TMemoryStream.Create;
  MemSteam.LoadFromFile(iFileName);
  MyCRC  := TIdHashCRC32.Create;
  Result := MyCRC.HashStreamAsHex(MemSteam);
  MyCRC.Free;
  MemSteam.Free;
end;

{ ��ȡ�ַ���CRCУ���� }
function GetStringCRC(const Str: string): Cardinal;
var
  MyCRC: TIdHashCRC32;
begin
  MyCRC  := TIdHashCRC32.Create;
  Result := MyCRC.HashValue(Str);
  MyCRC.Free;
end;

{ ȡ�ļ�MD5�� }
function GetFileMD5(const iFileName: string): String;
var
  MemSteam: TMemoryStream;
  MyMD5   : TIdHashMessageDigest5;
begin
  MemSteam := TMemoryStream.Create;
  MemSteam.LoadFromFile(iFileName);
  MyMD5  := TIdHashMessageDigest5.Create;
  Result := MyMD5.HashStreamAsHex(MemSteam);
  MyMD5.Free;
  MemSteam.Free;
end;

end.
