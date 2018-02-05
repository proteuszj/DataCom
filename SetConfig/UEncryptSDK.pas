unit UEncryptSDK;

interface

uses
  Windows, SysUtils, Variants, Classes, StdCtrls;

{***加解密库***}
////////////////////////////////////////////////////////////////////////////////
const
  DllEncrypt = 'Encrypt.dll';            //加解密态库

  //des加解密
  function Des_Encrypt(str: WideString):WideString; stdcall;external DllEncrypt name 'Des_EncryptStr';
  function Des_Decrypt(str: WideString):WideString; stdcall;external DllEncrypt name 'Des_DecryptStr';
  //文件加解密
  function Comp_EncryptFile(SourceFile: WideString; TargetFile: WideString): Integer; stdcall; external DllEncrypt name 'Comp_EncryptFile';
  function Comp_DecryptFile(SourceFile: WideString; TargetFile: WideString): Integer; stdcall; external DllEncrypt name 'Comp_DecryptFile';
  //获取磁盘序列号
  function Get_DiskSerialNo(): WideString; stdcall; external DllEncrypt name 'Get_DiskSerialNo';
  //获取IP地址列表
  function Get_IPList(): WideString; stdcall; external DllEncrypt name 'Get_IPList';

{***软件注册***}
////////////////////////////////////////////////////////////////////////////////
const
  DllRegAuth = 'RegAuth.dll';    //软注册动态库

  function regAccredit(AppFlag: string): Boolean; stdcall;external DllRegAuth name 'reg_accredit';

implementation

end.

