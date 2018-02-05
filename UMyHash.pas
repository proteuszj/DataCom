unit UMyHash;

interface

uses
  Windows, SysUtils, Variants, Classes, IdHashSHA, IdHashMessageDigest, TypInfo;

type
  TSHA_TYPE = (SHA_1, SHA_2, SHA_3);
  TMD5_TYPE = (MD5_1, MD5_2, MD5_3);

  TMyHash = class
  public
    //返回字符型SHA1加密密文(Input:传入明文; Encrypt:SHA加密类型[默认SHA_1])
    function SHA1(Input: String; Encrypt: TSHA_TYPE = SHA_1): String;
    //返回字符型MD5加密密文(Input:传入明文; Encrypt:SHA加密类型[默认MD5_1])
    function MD5(Input: String; Encrypt: TMD5_TYPE = MD5_1): String;
    //返回布尔型SHA1校验结果(source:明文; target:密文)
    function Check_SHA1(source: string; target: string): Boolean;
    //返回布尔型MD5校验结果(source:明文; target:密文)
    function Check_MD5(source: string; target: string): Boolean;
  end;
var
  MyHash: TMyHash = nil;

implementation

{ TMyHash }

function TMyHash.Check_MD5(source, target: string): Boolean;
var
  i: Integer;
  pi: PTypeInfo;
  tmpStr: string;
  tmpMD5_Type: TMD5_TYPE;
begin
  Result := False;
  pi := TypeInfo(TMD5_TYPE);
  with GetTypeData(pi)^ do
  begin
    for i := MinValue to MaxValue do
    begin
      tmpStr := GetEnumName(pi,i);
      tmpMD5_Type := TMD5_TYPE(GetEnumValue(pi, tmpStr));
      if MD5(source,tmpMD5_Type) = target then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function TMyHash.Check_SHA1(source, target: string): Boolean;
var
  i: Integer;
  pi: PTypeInfo;
  tmpStr: string;
  tmpSHA_Type: TSHA_TYPE;
begin
  Result := False;
  pi := TypeInfo(TSHA_TYPE);
  with GetTypeData(pi)^ do
  begin
    for i := MinValue to MaxValue do
    begin
      tmpStr := GetEnumName(pi,i);
      tmpSHA_Type := TSHA_TYPE(GetEnumValue(pi, tmpStr));
      if SHA1(source,tmpSHA_Type) = target then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

function TMyHash.MD5(Input: String; Encrypt: TMD5_TYPE): String;
begin
  with TIdHashMessageDigest5.Create do
  try
    case Encrypt of
      MD5_1: Result := UpperCase(HashStringAsHex(Input,TEncoding.UTF8));
      MD5_2: Result := UpperCase(HashBytesAsHex(HashString(Input,TEncoding.UTF8)));
      MD5_3: Result := UpperCase(HashBytesAsHex(HashBytes(HashString(Input,TEncoding.UTF8))));
    end;
  finally
    Free;
  end;
end;

function TMyHash.SHA1(Input: String; Encrypt: TSHA_TYPE): String;
begin
  with TIdHashSHA1.Create do
  try
    case Encrypt of
      SHA_1: Result := UpperCase(HashStringAsHex(Input,TEncoding.UTF8));
      SHA_2: Result := UpperCase(HashBytesAsHex(HashString(Input,TEncoding.UTF8)));
      SHA_3: Result := UpperCase(HashBytesAsHex(HashBytes(HashString(Input,TEncoding.UTF8))));
    end;
  finally
    Free;
  end;
end;

initialization
  MyHash := TMyHash.Create;

finalization
  MyHash.Free;

end.
