// ************************************************************************ //
// The types declared in this file were generated from data read from the
// WSDL File described below:
// WSDL     : http://localhost:8308/monweb/services/TmriOutAccess?wsdl
//  >Import : http://localhost:8308/monweb/services/TmriOutAccess?wsdl>0
//  >Import : http://localhost:8308/monweb/services/TmriOutAccess?xsd=1
// Encoding : UTF-8
// Version  : 1.0
// (2016-09-13 10:42:23 - - $Rev: 34800 $)
// ************************************************************************ //

unit TmriOutNewAccess;

interface

uses InvokeRegistry, SOAPHTTPClient, Types, XSBuiltIns;

const
  IS_OPTN = $0001;
  IS_UNQL = $0008;

type

  // ************************************************************************ //
  // The following types, referred to in the WSDL document are not being represented
  // in this file. They are either aliases[@] of other types represented or were referred
  // to but never[!] declared in the document. The types from the latter category
  // typically map to predefined/known XML or Embarcadero types; however, they could also 
  // indicate incorrect WSDL documents that failed to declare or import a schema type.
  // ************************************************************************ //
  // !:string          - "http://www.w3.org/2001/XMLSchema"[Gbl]

  // ************************************************************************ //
  // Namespace : http://service.jk.com/
  // transport : http://schemas.xmlsoap.org/soap/http
  // style     : document
  // use       : literal
  // binding   : TmriOutAccessPortBinding
  // service   : TmriOutAccessService
  // port      : TmriOutAccessPort
  // URL       : http://localhost:8308/monweb/services/TmriOutAccess
  // ************************************************************************ //
  TmriOutAccess = interface(IInvokable)
  ['{11D76957-D587-74E7-4DFD-D1CAE77B4C7A}']
    function  getValue(const arg0: string): string; stdcall;
    function  queryObjectOut(const arg0: string; const arg1: string; const arg2: string; const arg3: string): string; stdcall;
    function  writeObjectOut(const arg0: string; const arg1: string; const arg2: string; const arg3: string): string; stdcall;
  end;

function GetTmriOutAccess(UseWSDL: Boolean=System.False; Addr: string=''; HTTPRIO: THTTPRIO = nil): TmriOutAccess;


implementation

uses
  SysUtils, StrUtils, UPublic;

function GetTmriOutAccess(UseWSDL: Boolean; Addr: string; HTTPRIO: THTTPRIO): TmriOutAccess;
const
  defWSDL = 'http://localhost:8308/trffweb/services/TmriOutAccess?wsdl';
  defURL  = 'http://localhost:8308/trffweb/services/TmriOutAccess';
  defSvc  = 'TmriOutAccessService';
  defPrt  = 'TmriOutAccessPort';
var
  RIO: THTTPRIO;
begin
  Result := nil;
  if (Addr = '') then
  begin
    if UseWSDL then
      Addr := claPublic.WEB_URL //defWSDL
    else
      Addr := LeftStr(claPublic.WEB_URL,pos('?',claPublic.WEB_URL)-1);   //defURL
  end;
  if HTTPRIO = nil then
    RIO := THTTPRIO.Create(nil)
  else
    RIO := HTTPRIO;
  try
    Result := (RIO as TmriOutAccess);
    if UseWSDL then
    begin
      RIO.WSDLLocation := Addr;
      RIO.Service := defSvc;
      RIO.Port := defPrt;
    end else
      RIO.URL := Addr;
  finally
    if (Result = nil) and (HTTPRIO = nil) then
      RIO.Free;
  end;
end;


initialization
  { TmriOutAccess }
  InvRegistry.RegisterInterface(TypeInfo(TmriOutAccess), 'http://service.jk.com/', 'UTF-8');
  InvRegistry.RegisterDefaultSOAPAction(TypeInfo(TmriOutAccess), '');
  InvRegistry.RegisterInvokeOptions(TypeInfo(TmriOutAccess), ioDocument);
  { TmriOutAccess.getValue }
  InvRegistry.RegisterMethodInfo(TypeInfo(TmriOutAccess), 'getValue', '',
                                 '[ReturnName="return"]', IS_OPTN or IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'getValue', 'arg0', '',
                                '', IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'getValue', 'return', '',
                                '', IS_UNQL);
  { TmriOutAccess.queryObjectOut }
  InvRegistry.RegisterMethodInfo(TypeInfo(TmriOutAccess), 'queryObjectOut', '',
                                 '[ReturnName="return"]', IS_OPTN or IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'queryObjectOut', 'arg0', '',
                                '', IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'queryObjectOut', 'arg1', '',
                                '', IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'queryObjectOut', 'arg2', '',
                                '', IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'queryObjectOut', 'arg3', '',
                                '', IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'queryObjectOut', 'return', '',
                                '', IS_UNQL);
  { TmriOutAccess.writeObjectOut }
  InvRegistry.RegisterMethodInfo(TypeInfo(TmriOutAccess), 'writeObjectOut', '',
                                 '[ReturnName="return"]', IS_OPTN or IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'writeObjectOut', 'arg0', '',
                                '', IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'writeObjectOut', 'arg1', '',
                                '', IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'writeObjectOut', 'arg2', '',
                                '', IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'writeObjectOut', 'arg3', '',
                                '', IS_UNQL);
  InvRegistry.RegisterParamInfo(TypeInfo(TmriOutAccess), 'writeObjectOut', 'return', '',
                                '', IS_UNQL);

end.