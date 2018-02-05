unit UThreadProcess;

interface

uses
  Windows, SysUtils, Classes, IdTCPServer, IdContext, IdBaseComponent, IdComponent,
  IdCustomTCPServer, DB, DBAccess, Uni, XMLIntf, XMLDoc, StrUtils;

const
  TRANS_BLOCK_SIZE = 65000;             //每次收发包的大小
  CHECKHEADER = 'TNZC';                 //校验头
  HEADERLENGTH = 15;                    //头信息大小

type
  TThreadProcess = Class
  private
    ownerThread : TIdContext;
    ownerDBConn : TUniConnection;
    ReceiveSize : Integer;       //要接收的字节数
    RecStream   : TMemoryStream;
//    function CompressXMLToStream(inXmlDoc : IXMLDocument; var outStream : TMemoryStream) : Integer; //压缩
//    function ExpandStreamToXML(var outXmlDoc : IXMLDocument; inStream : TMemoryStream) : Integer;   //解压缩
    function DataInterchange(RecStream : TMemoryStream; var outStream : TMemoryStream): Integer;      //数据交换
  public
    constructor Create(InThread : TIdContext);reintroduce;
    destructor Destroy; override;
    procedure Process(DBConn : TUniConnection);
    class function GetThreadCount : integer;
  End;

implementation

uses
  UDBProcess, UPublic;

var
  ThreadCount : Integer;

{ TThreadProcess }

constructor TThreadProcess.Create(InThread: TIdContext);
begin
  inherited Create();
  ownerThread := InThread;
  ReceiveSize := 0;
  Inc(ThreadCount);
  RecStream := TMemoryStream.Create;
end;

function TThreadProcess.DataInterchange(RecStream: TMemoryStream;
  var outStream: TMemoryStream): Integer;
var
  inXMLDoc, outXMLDoc: IXMLDocument;
  root, child: IXMLNode;
  ret: Integer;
  tmpDM: TDM;
begin
  tmpDM := TDM.Create;
  inXMLDoc := TXMLDocument.Create(nil);
  outXMLDoc := TXMLDocument.Create(nil);
  try
    outXMLDoc.Active := true;
    outXMLDoc.Version := '1.0';
    outXMLDoc.Encoding := 'UTF-8';
    root := outXMLDoc.AddChild('root');
    child := root.AddChild('result');
    if child.ChildNodes.FindNode('res_flag') = nil then
      child.AddChild('res_flag');
    if child.ChildNodes.FindNode('res_memo') = nil then
      child.AddChild('res_memo');
    child.ChildValues['res_flag'] := '1';

    ret := 1;
    try
      inXMLDoc.LoadFromStream(TStream(RecStream));   //ExpandStreamToXML
    except
      ret := -1;
    end;
    if ret = 1 then
    begin
      if not ownerDBConn.Connected then
      begin
        ret := -2;
      end else
      begin
        tmpDM.SetDBConnect(ownerDBConn);
        if not tmpDM.XMLDocExecute(inXMLDoc,outXMLDoc) then
        begin
          ret := -3;
        end else
          ret := 0;
      end;
    end;

    case ret of
      -1: child.ChildValues['res_memo'] := '解析数据包失败';
      -2: child.ChildValues['res_memo'] := '数据库连接失败';
      -3: child.ChildValues['res_memo'] := '未知交易类型';
    end;

    outXMLDoc.SaveToStream(TStream(outStream));    //CompressXMLToStream
    Result := ret;
  finally
    inXMLDoc := nil;
    outXMLDoc := nil;
    tmpDM.Free;
  end;
end;

destructor TThreadProcess.Destroy;
begin
  RecStream.Free;
  Dec(ThreadCount);
  inherited;
end;

class function TThreadProcess.GetThreadCount: integer;
begin
  Result := ThreadCount;
end;

procedure TThreadProcess.Process(DBConn : TUniConnection);
var
  HeadStr, tmpLog: String;
  i, iBlockTotal, iLastBlockSize: Integer;
  tmpStream: TMemoryStream;
begin
  HeadStr := '';
  tmpStream := TMemoryStream.Create;
  try
    Self.ownerDBConn := DBConn;
    ownerThread.Connection.Socket.ReadTimeout := 30000;
    try
      HeadStr := ownerThread.Connection.Socket.ReadString(HEADERLENGTH);
    except
      tmpLog := Format('A illegitimate Connection Handle[%.6d] IP[%s] has been disconnected!',
                       [ownerThread.Connection.Socket.Binding.Handle,
                        ownerThread.Connection.Socket.Binding.PeerIP]);
      claPublic.WriteLog('Thread',tmpLog);
      Exit;
    end;
    if (Length(HeadStr) = HEADERLENGTH) and (LeftStr(HeadStr, Length(CHECKHEADER)) = CHECKHEADER) then
    begin
      try
        //通过数据头传入的数据体大小，设置接收流大小
        ReceiveSize := StrToInt(MidStr(HeadStr, Length(CHECKHEADER) + 2, Length(HeadStr) - Length(CHECKHEADER) - 1));
        RecStream.Clear;
        RecStream.SetSize(ReceiveSize);
        //按每次收发包的大小分块
        iBlockTotal := (ReceiveSize - 1) div TRANS_BLOCK_SIZE;
        i := 0;
        while iBlockTotal > i do
        begin
          tmpStream.Clear;
          ownerThread.Connection.Socket.ReadStream(tmpStream, TRANS_BLOCK_SIZE, False);
          CopyMemory(Pointer(Integer(RecStream.Memory) + i * TRANS_BLOCK_SIZE),
                     tmpStream.Memory, TRANS_BLOCK_SIZE);
          Inc(i);
        end;
        //接收剩余部分
        iLastBlockSize := ReceiveSize mod TRANS_BLOCK_SIZE;
        if iLastBlockSize = 0 then
            iLastBlockSize := TRANS_BLOCK_SIZE;
        tmpStream.Clear;
        ownerThread.Connection.Socket.ReadStream(tmpStream, iLastBlockSize);
        CopyMemory(Pointer(Integer(RecStream.Memory) + i * TRANS_BLOCK_SIZE),
                     tmpStream.Memory, iLastBlockSize);
        //清理内存流，做数据交换
        tmpStream.Clear;
        DataInterchange(RecStream,tmpStream);
        //发出交换后的数据
        HeadStr := Format('TNZC|%.10d', [tmpStream.size]);
        ownerThread.Connection.Socket.Write(HeadStr);
        ownerThread.Connection.Socket.Write(tmpStream);
      except
        tmpLog := Format('A Connection Handle[%.6d] IP[%s] has been disconnected when it is executing with error!',
                        [ownerThread.Connection.Socket.Binding.Handle,
                         ownerThread.Connection.Socket.Binding.PeerIP]);
        claPublic.WriteLog('Thread',tmpLog);
        Exit;
      end;
    end else
    begin
      tmpLog := Format('A illegitimate Connection Header, Handle[%.6d] IP[%s] has been disconnected!',
                      [ownerThread.Connection.Socket.Binding.Handle,
                       ownerThread.Connection.Socket.Binding.PeerIP]);
      claPublic.WriteLog('Thread',tmpLog);
      Exit;
    end;
  finally
    tmpStream.Free;
    ownerThread.Connection.Disconnect;
  end;
end;

{
function TThreadProcess.ExpandStreamToXML(var outXmlDoc: IXMLDocument;
  inStream: TMemoryStream): Integer;
var
  tmpStream : TMemoryStream;
begin

  tmpStream := TMemoryStream.Create;
  try
    try
      //解压缩
      if CompressType = 'lz77' then
        lz77Expand(inStream, tmpStream)
      else if CompressType = 'Gzip' then
        GZDecompressStream(inStream, tmpStream);
      outxmlDoc.LoadFromStream(TStream(tmpStream));
      result := 0;
    except
      Result := -1;     //解压缩失败
    end;
  finally
    tmpStream.Free;
  end;

end;
}
{
function TThreadProcess.CompressXMLToStream(inXmlDoc: IXMLDocument;
  var outStream: TMemoryStream): Integer;
var
  tmpStream : TMemoryStream;
begin

  tmpStream := TMemoryStream.Create;
  inXmlDoc.SaveToStream(TStream(tmpStream));
  tmpStream.Seek(0, 0);
  try
    try
      //压缩
      if CompressType = 'lz77' then
        lz77Compress(tmpStream, outStream)
      else if CompressType = 'Gzip' then
        GZCompressStream(tmpStream, outStream);
      Result := outStream.Size;
    except
      Result := -1;        //压包失败
    end;
  finally
    tmpStream.Free;
  end;
end;
}
initialization
  ThreadCount := 0;           //初始化

finalization
  ThreadCount := 0;

end.
