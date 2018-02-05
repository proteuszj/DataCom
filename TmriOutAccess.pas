// ************************************************************************ //
// The types declared in this file were generated from data read from the
// WSDL File described below:
// WSDL     : http://192.168.1.254:9080/monweb/services/TmriOutAccess?wsdl
// Encoding : UTF-8
// Version  : 1.0
// (2017/11/15 17:04:53 - - $Rev: 34800 $)
// ************************************************************************ //

unit TmriOutAccess;

interface

uses InvokeRegistry, SOAPHTTPClient, Types, XSBuiltIns;

type

  // ************************************************************************ //
  // The following types, referred to in the WSDL document are not being represented
  // in this file. They are either aliases[@] of other types represented or were referred
  // to but never[!] declared in the document. The types from the latter category
  // typically map to predefined/known XML or Embarcadero types; however, they could also 
  // indicate incorrect WSDL documents that failed to declare or import a schema type.
  // ************************************************************************ //
  // !:string          - "http://www.w3.org/2001/XMLSchema"[]


  // ************************************************************************ //
  // Namespace : http://endpoint.axis.framework.tmri.com
  // transport : http://schemas.xmlsoap.org/soap/http
  // style     : rpc
  // use       : encoded
  // binding   : TmriOutAccessSoapBinding
  // service   : TmriJaxRpcOutAccessService
  // port      : TmriOutAccess
  // URL       : http://192.168.1.254:9080/monweb/services/TmriOutAccess
  // ************************************************************************ //
  TmriJaxRpcOutAccess = interface(IInvokable)
  ['{FBDA5CCB-D0AF-7262-42E9-2A41B6214390}']
    function  queryObjectOut(const xtlb: string; const jkxlh: string; const jkid: string; const UTF8XmlDoc: string): string; stdcall;
    function  writeObjectOut(const xtlb: string; const jkxlh: string; const jkid: string; const UTF8XmlDoc: string): string; stdcall;
  end;

function GetTmriJaxRpcOutAccess(UseWSDL: Boolean=System.False; Addr: string=''; HTTPRIO: THTTPRIO = nil): TmriJaxRpcOutAccess;


implementation
  uses SysUtils;

function GetTmriJaxRpcOutAccess(UseWSDL: Boolean; Addr: string; HTTPRIO: THTTPRIO): TmriJaxRpcOutAccess;
const
  defWSDL = 'http://192.168.1.254:9080/monweb/services/TmriOutAccess?wsdl';
  defURL  = 'http://192.168.1.254:9080/monweb/services/TmriOutAccess';
  defSvc  = 'TmriJaxRpcOutAccessService';
  defPrt  = 'TmriOutAccess';
var
  RIO: THTTPRIO;
begin
  Result := nil;
  if (Addr = '') then
  begin
    if UseWSDL then
      Addr := defWSDL
    else
      Addr := defURL;
  end;
  if HTTPRIO = nil then
    RIO := THTTPRIO.Create(nil)
  else
    RIO := HTTPRIO;
  try
    Result := (RIO as TmriJaxRpcOutAccess);
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
  { TmriJaxRpcOutAccess }
  InvRegistry.RegisterInterface(TypeInfo(TmriJaxRpcOutAccess), 'http://endpoint.axis.framework.tmri.com', 'UTF-8');
  InvRegistry.RegisterDefaultSOAPAction(TypeInfo(TmriJaxRpcOutAccess), '');

end.