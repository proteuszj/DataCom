unit UEncryptSDK;

interface

uses
  Windows, SysUtils, Variants, Classes, StdCtrls;

{***�ӽ��ܿ�***}
////////////////////////////////////////////////////////////////////////////////
const
  DllEncrypt = 'Encrypt.dll';            //�ӽ���̬��

  //des�ӽ���
  function Des_Encrypt(str: WideString):WideString; stdcall;external DllEncrypt name 'Des_EncryptStr';
  function Des_Decrypt(str: WideString):WideString; stdcall;external DllEncrypt name 'Des_DecryptStr';
  //�ļ��ӽ���
  function Comp_EncryptFile(SourceFile: WideString; TargetFile: WideString): Integer; stdcall; external DllEncrypt name 'Comp_EncryptFile';
  function Comp_DecryptFile(SourceFile: WideString; TargetFile: WideString): Integer; stdcall; external DllEncrypt name 'Comp_DecryptFile';
  //��ȡ�������к�
  function Get_DiskSerialNo(): WideString; stdcall; external DllEncrypt name 'Get_DiskSerialNo';
  //��ȡIP��ַ�б�
  function Get_IPList(): WideString; stdcall; external DllEncrypt name 'Get_IPList';

{***���ע��***}
////////////////////////////////////////////////////////////////////////////////
const
  DllRegAuth = 'RegAuth.dll';    //��ע�ᶯ̬��

  function regAccredit(AppFlag: string): Boolean; stdcall;external DllRegAuth name 'reg_accredit';

implementation

end.

