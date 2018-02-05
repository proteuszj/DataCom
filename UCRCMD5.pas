unit UCRCMD5;

interface

uses
  Classes, IdHashMessageDigest, IdHashCRC;

  { 获取文件CRC校验码 }
  function GetFileCRC(const iFileName: string): String;
  { 获取字符串CRC校验码 }
  function GetStringCRC(const Str: string): Cardinal;
  { 取文件MD5码 }
  function GetFileMD5(const iFileName: string): String;

implementation

{ 获取文件CRC校验码 }
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

{ 获取字符串CRC校验码 }
function GetStringCRC(const Str: string): Cardinal;
var
  MyCRC: TIdHashCRC32;
begin
  MyCRC  := TIdHashCRC32.Create;
  Result := MyCRC.HashValue(Str);
  MyCRC.Free;
end;

{ 取文件MD5码 }
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
