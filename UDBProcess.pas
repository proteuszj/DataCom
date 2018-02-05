unit UDBProcess;

interface

uses
  SysUtils, Classes, DB, MemDS, DBAccess, Uni, UniProvider, OracleUniProvider, Dialogs,
  XMLIntf, XMLDoc, ImgList, Controls, CoolTrayIcon, Menus, TmriOutAccess, HTTPApp, DateUtils;

type
  TXMLType = (xt_inXml, xt_outXml);
  TDM = class(TDataModule)
    OracleUniProvider: TOracleUniProvider;
    DBConnect: TUniConnection;
    pubQuery: TUniQuery;
    spSql: TUniStoredProc;
  private
    { Private declarations }
    function ExecSql(var Query: TUniQuery; SqlStr: String; isGetRecord: Boolean = True): Boolean;
    function GetCurrXmlNode(parentNode: IXMLNode; subNode: String; xmlType: TXMLType=xt_inXml): IXMLNode;
    function UpdateResult(var parentNode: IXMLNode; resFlag: String; resMemo: string) : Integer;
    procedure HashArithmetic(StrTableName: string; StrWhere: string);
    function BuildInterfaceXML(exam_id: string; process_id: string; var jkid: string): string;
    function WebServicesInterface(exam_id: string; process_id: string): Boolean;
    //下载系统参数交易
    function _0_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    //车载子系统交易
    function _1001_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _1002_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _1003_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _1004_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _1005_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _1006_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _1007_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _1008_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _1009_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;

    //现场支付相关
    function _2001_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _2002_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    //音视频子系统交易
    function _3001_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    //测绘子系统交易
    function _4001_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _4002_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _4003_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    function _4004_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    //排队叫号子系统交易
    function _5001_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
    //闸机服务子系统交易
    function _6001_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;

    function Str2Time(timStr: string): Extended;
  public
    { Public declarations }
    constructor Create();reintroduce;
    destructor Destroy; override;
    procedure SetDBConnect(inDBConnect: TUniConnection);
    function XMLDocExecute(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Boolean;
  end;

var
  DM: TDM;

implementation

uses
  UPublic, Base64, EncdDecd, UMyHash, UMain;

{$R *.dfm}

{ TDM }

function TDM.UpdateResult(var parentNode: IXMLNode; resFlag,
  resMemo: string): Integer;
begin
  parentNode.ChildNodes.FindNode('res_flag').Text := resFlag;
  parentNode.ChildNodes.FindNode('res_memo').Text := resMemo;
  Result := 0;
end;

function TDM.WebServicesInterface(exam_id, process_id: string): Boolean;
var
  resXML, returnXML: string;
  debugPath, jkid, strSQL: string;
  inXMLDoc, outXMLDoc: IXMLDocument;
  rootNode, codeNode, mesgNode: IXMLNode;
  statusQuery:TmriOutAccess.TmriJaxRpcOutAccess;
  timestr: string;
begin
  Result := False;
  if claPublic.IsExamMode = '0' then
  begin
    Result := True;
    Exit;
  end else
  begin
    resXML := BuildInterfaceXML(exam_id,process_id,jkid);
    inXMLDoc := TXMLDocument.Create(nil);
    outXMLDoc := TXMLDocument.Create(nil);
    try
      if resXML = '' then
      begin
//        strRtn :=  '$E##无接口上报的数据记录';
        claPublic.WriteLog('WS','无接口上报的数据记录');
        frmMain.MemoLog.Lines.Add('$E##无接口上报的数据记录');
        Exit;
      end else
      begin
//        if claPublic.IsDebug = '1' then     //comment by zj
        begin
          inXMLDoc.LoadFromXML(AnsiString(resXML));
          debugPath := claPublic.GetFileDir('wsxml\send');
          DateTimeToString(timestr, 'yyyy-mm-dd-hh-nn-ss', now);
          inXMLDoc.SaveToFile(Format('%s%s-%s_send.xml',[debugPath,timestr,jkid]));
        end;
        try
          statusQuery:=GetTmriJaxRpcOutAccess;
          returnXML := statusQuery.writeObjectOut(claPublic.WEB_SYSCLASS,claPublic.WEB_SERIALNUMBER,claPublic.WEB_SYSCLASS+jkid,resXML);

          outXMLDoc.LoadFromXML(AnsiString(UTF8Decode(HTTPDecode(AnsiString(returnXML)))));
//          if claPublic.IsDebug = '1' then     //comment by zj
          begin
            debugPath := claPublic.GetFileDir('wsxml\receive');
            outXMLDoc.SaveToFile(Format('%s%s-%s_receive.xml',[debugPath,timestr,jkid]));
          end;

          rootNode := outXMLDoc.DocumentElement;
          codeNode :=  rootNode.ChildNodes['head'].ChildNodes['code'];     //回应状态
          mesgNode :=  rootNode.ChildNodes['head'].ChildNodes['message'];  //回应信息

          if (Trim(codeNode.Text) = '1') or (Trim(codeNode.Text)='-90') then
          begin
            Result := True;
          end else
            Result := False;
//          strRtn := NNode.text+'##'+cNode.Text;
          //更新接口返回结果
          strSQL := Format('update buz_exam_process set process_status=%s where id=%s and exam_id=%s',
                           [QuotedStr(Trim(codeNode.Text)),
                            QuotedStr(process_id),
                            QuotedStr(exam_id)]);
          ExecSql(pubQuery,strSQL,False);
        except
          on E:Exception do
          begin
//            strRtn :=  '$E##远程接口调用失败';
            claPublic.WriteLog('WS',Format('远程接口调用失败！异常信息：%s',[E.Message]));
            frmMain.MemoLog.Lines.Add(Format('远程接口调用失败！异常信息：%s',[E.Message]));
            Exit;
          end;
        end;
      end;
    finally
      inXMLDoc := nil;
      outXMLDoc := nil;
    end;
  end;
end;

function TDM.BuildInterfaceXML(exam_id, process_id: string; var jkid: string): string;
var
  strSQL, strXML, strPhoto: string;
  PhotoBuf: TMemoryStream;
begin
  strXML := '';
  jkid := '';
  strSQL := Format('select bei.id, bep.id,'+
                     '(select param_value from cfg_param where param_name = ''SYSTEM_SERIAL_NUMBER'') as ksxtbh,'+
                     'bb.sequencenumber as lsh, bei.subject as kskm,bs.idnumber as sfzmhm,'+
                     'to_char(to_date(bep.process_time, ''yyyy-MM-ddhh24:mi:ss''),''yyyy-MM-ddhh24:mi:ss'') as sj,'+
                     'bep.process_flag as pflag,bep.process_type as jkid,'+
                     'bep.exam_item as ksxm,bep.deduct_item as kfxm,'+
                     'bep.process_photo as zp,bd.sequencenumber as sbxh, '+
                     'bc.license_plate as kchp,bep.speed as cs,'+
                     'bei.current_exam_score as kscj,be1.idnumber as ksysfzmhm,'+
                     'be2.idnumber as ksy2sfzmhm,bep.record_type as czlx '+
                     'from buz_exam_info bei '+
                     'left join buz_exam_process bep  on bep.exam_id = bei.id '+
                     'left join bas_booking bb on bb.student_id = bei.student_id '+
                     'left join bas_student bs on bs.id = bei.student_id '+
                     'left join bas_car bc on bc.id = bei.car_id '+
                     'left join bas_examiner be1 on be1.id = bei.examiner1_id '+
                     'left join bas_examiner be2 on be2.id = bei.examiner2_id '+
                     'left join bas_device bd on bd.id = bep.device_id '+
                     'where bei.id = %s and bep.id = %s '+
                     'order by bep.id asc',[QuotedStr(exam_id),QuotedStr(process_id)]);
  ExecSql(pubQuery,strSQL);
  if pubQuery.RecordCount <> 1 then
  begin
    Exit;
  end else
  begin
    PhotoBuf := TMemoryStream.Create;
    try
      PhotoBuf.Clear;
      strPhoto := '';
      jkid := UpperCase(Trim(pubQuery.FieldByName('jkid').AsString));
      if jkid = 'C51' then
      begin
        TBlobField(pubQuery.FieldByName('zp')).SaveToStream(PhotoBuf);
        Base64Enc(PhotoBuf, strPhoto, PhotoBuf.Size);
        strXML := Format('<?xml version="1.0" encoding="GBK" ?><root><drvexam> '+
                         '<lsh>%s</lsh><kskm>%s</kskm><ksxtbh>%s</ksxtbh><sfzmhm>%s</sfzmhm>'+
                         '<ksysfzmhm>%s</ksysfzmhm><zp>%s</zp><kssj>%s</kssj><Ksy2sfzmhm>%s</Ksy2sfzmhm>'+
                         '</drvexam></root>',
                         [Trim(pubQuery.FieldByName('lsh').AsString),
                          Trim(pubQuery.FieldByName('kskm').AsString),
                          Trim(pubQuery.FieldByName('ksxtbh').AsString),
                          Trim(pubQuery.FieldByName('sfzmhm').AsString),
                          Trim(pubQuery.FieldByName('ksysfzmhm').AsString),
                          Trim(strPhoto),
                          Trim(pubQuery.FieldByName('sj').AsString),
                          Trim(pubQuery.FieldByName('Ksy2sfzmhm').AsString)
                         ]);
        claPublic.WriteLog('WS',Format('%s 身份信息比对',[jkid]));
      end
      else if jkid = 'C52' then
      begin
        strXML := Format('<?xml version="1.0" encoding="GBK" ?><root><drvexam> '+
                         '<lsh>%s</lsh><kskm>%s</kskm><sfzmhm>%s</sfzmhm>'+
                         '<ksxm>%s</ksxm><sbxh>%s</sbxh><kchp>%s</kchp><kssj>%s</kssj>'+
                         '</drvexam></root>',
                         [Trim(pubQuery.FieldByName('lsh').AsString),
                          Trim(pubQuery.FieldByName('kskm').AsString),
                          Trim(pubQuery.FieldByName('sfzmhm').AsString),
                          Trim(pubQuery.FieldByName('ksxm').AsString),
                          Trim(pubQuery.FieldByName('sbxh').AsString),
                          Trim(pubQuery.FieldByName('kchp').AsString),
                          Trim(pubQuery.FieldByName('sj').AsString)
                         ]);
        claPublic.WriteLog('WS',Format('%s 考试项目开始',[jkid]));
      end
      else if jkid = 'C53' then
      begin
        strXML := Format('<?xml version="1.0" encoding="GBK" ?><root><drvexam> '+
                         '<lsh>%s</lsh><kskm>%s</kskm><ksxm>%s</ksxm>'+
                         '<kfxm>%s</kfxm><sfzmhm>%s</sfzmhm><kfsj>%s</kfsj>'+
                         '</drvexam></root>',
                         [Trim(pubQuery.FieldByName('lsh').AsString),
                          Trim(pubQuery.FieldByName('kskm').AsString),
                          Trim(pubQuery.FieldByName('ksxm').AsString),
                          Trim(pubQuery.FieldByName('kfxm').AsString),
                          Trim(pubQuery.FieldByName('sfzmhm').AsString),
                          Trim(pubQuery.FieldByName('sj').AsString)
                         ]);
        claPublic.WriteLog('WS',Format('%s 考试扣分',[jkid]));
      end
      else if jkid = 'C54' then
      begin
        TBlobField(pubQuery.FieldByName('zp')).SaveToStream(PhotoBuf);
        Base64Enc(PhotoBuf, strPhoto, PhotoBuf.Size);
        strXML := Format('<?xml version="1.0" encoding="GBK" ?><root><drvexam> '+
                         '<lsh>%s</lsh><kskm>%s</kskm><ksxm>%s</ksxm>'+
                         '<sfzmhm>%s</sfzmhm><zpsj>%s</zpsj><zp>%s</zp><cs>%s</cs>'+
                         '</drvexam></root>',
                         [Trim(pubQuery.FieldByName('lsh').AsString),
                          Trim(pubQuery.FieldByName('kskm').AsString),
                          Trim(pubQuery.FieldByName('ksxm').AsString),
                          Trim(pubQuery.FieldByName('sfzmhm').AsString),
                          Trim(pubQuery.FieldByName('sj').AsString),
                          Trim(strPhoto),
                          Trim(pubQuery.FieldByName('cs').AsString)
                         ]);
        claPublic.WriteLog('WS',Format('%s 考试过程拍照',[jkid]));
      end
      else if jkid = 'C55' then
      begin
        strXML := Format('<?xml version="1.0" encoding="GBK" ?><root><drvexam> '+
                         '<lsh>%s</lsh><kskm>%s</kskm><sfzmhm>%s</sfzmhm>'+
                         '<ksxm>%s</ksxm><sbxh>%s</sbxh><jssj>%s</jssj><czlx>%s</czlx>'+
                         '</drvexam></root>',
                         [Trim(pubQuery.FieldByName('lsh').AsString),
                          Trim(pubQuery.FieldByName('kskm').AsString),
                          Trim(pubQuery.FieldByName('sfzmhm').AsString),
                          Trim(pubQuery.FieldByName('ksxm').AsString),
                          Trim(pubQuery.FieldByName('sbxh').AsString),
                          Trim(pubQuery.FieldByName('sj').AsString),
                          Trim(pubQuery.FieldByName('czlx').AsString)
                         ]);
        claPublic.WriteLog('WS',Format('%s 考试项目结束',[jkid]));
      end
      else if jkid = 'C56' then
      begin
        TBlobField(pubQuery.FieldByName('zp')).SaveToStream(PhotoBuf);
        Base64Enc(PhotoBuf, strPhoto, PhotoBuf.Size);
        strXML := Format('<?xml version="1.0" encoding="GBK" ?><root><drvexam> '+
                         '<lsh>%s</lsh><kskm>%s</kskm><sfzmhm>%s</sfzmhm>'+
                         '<zp>%s</zp><jssj>%s</jssj><kscj>%s</kscj>'+
                         '</drvexam></root>',
                         [Trim(pubQuery.FieldByName('lsh').AsString),
                          Trim(pubQuery.FieldByName('kskm').AsString),
                          Trim(pubQuery.FieldByName('sfzmhm').AsString),
                          Trim(strPhoto),
                          Trim(pubQuery.FieldByName('sj').AsString),
                          Trim(pubQuery.FieldByName('kscj').AsString)
                         ]);
        claPublic.WriteLog('WS',Format('%s 考试科目结束',[jkid]));
      end;
    finally
      PhotoBuf.Free;
    end;
  end;
  Result := strXML;
end;

constructor TDM.Create;
begin
  inherited Create(nil);
end;

destructor TDM.Destroy;
begin
  pubQuery.Close;
  DBConnect.Disconnect;
  DBConnect.Close;
  inherited;
end;

function TDM.ExecSql(var Query: TUniQuery; SqlStr: String;
  isGetRecord: Boolean): Boolean;
begin
  //SQL语句执行增、删、改、查等操作
  if Query.Active then Query.Close;
  Query.SQL.Clear;
  Query.SQL.Text := SqlStr;
//  PasPublic.WriteLog('DB',Format('Execute "%s"',[SqlStr]));
  try
    if isGetRecord then
      Query.Open
    else
      Query.ExecSQL;
    result := true;
  except
    on E: Exception do
    begin
      claPublic.WriteLog('DB',Format('Exception message: %s',[E.Message]));
      result := false;
    end;
  end;
end;

function TDM.GetCurrXmlNode(parentNode: IXMLNode; subNode: String;
  xmlType: TXMLType): IXMLNode;
begin
  Result := nil;
  Result := parentNode.ChildNodes[subNode];
  case xmlType of
    xt_outXml:
      begin
        if Result = nil then
          Result := parentNode.AddChild(subNode);
      end;
  end;
end;

procedure TDM.HashArithmetic(StrTableName, StrWhere: string);
var
  i: Integer;
  strSQL, hashStr, colNameStr: string;
begin
  if StrTableName = 'BUZ_PAYMENT_DETAIL' then
    strSQL := Format('select TRADE_NO,TRADE_TYPE,FEE_TIMES,FINAL_AMOUNT,PAY_TIME from %s %s',[StrTableName,StrWhere])
  else
    strSQL := Format('select * from %s %s',[StrTableName,StrWhere]);
  ExecSql(pubQuery,strSQL);
  hashStr := '';
  for I := 0 to pubQuery.FieldCount - 1 do
  begin
     colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
     if colNameStr <> LowerCase('hash') then
       hashStr := hashStr+Trim(pubQuery.Fields[i].AsString);
  end;
  hashStr := MyHash.SHA1(hashStr);

  strSQL := Format('update %s set hash=%s %s',[StrTableName,QuotedStr(hashStr),StrWhere]);
  ExecSql(pubQuery,strSQL,False);
end;

procedure TDM.SetDBConnect(inDBConnect: TUniConnection);
begin
  DBConnect := inDBConnect;
  DBConnect.SpecificOptions.Values['Direct'] := 'True';
  DBConnect.LoginPrompt := False;
  pubQuery.Connection := DBConnect;
end;

function TDM.XMLDocExecute(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Boolean;
var
  root: IXMLNode;
  xmlflag: Integer;
begin
  Result := False;
  root := inXMLDoc.ChildNodes.FindNode('root');
  if root <> nil then
  begin
    if root.ChildNodes.FindNode('xmlflag') = nil then
      Exit;
    try
      xmlflag := StrToInt(Trim(root.ChildNodes['xmlflag'].Text));
      case xmlflag of
        0:    _0_XMLEvent(inXMLDoc,outXMLDoc);
        //车载子系统交易类型
        1001: _1001_XMLEvent(inXMLDoc,outXMLDoc);
        1002: _1002_XMLEvent(inXMLDoc,outXMLDoc);
        1003: _1003_XMLEvent(inXMLDoc,outXMLDoc);
        1004: _1004_XMLEvent(inXMLDoc,outXMLDoc);
        1005: _1005_XMLEvent(inXMLDoc,outXMLDoc);
        1006: _1006_XMLEvent(inXMLDoc,outXMLDoc);
        1007: _1007_XMLEvent(inXMLDoc,outXMLDoc);
        1008: _1008_XMLEvent(inXMLDoc,outXMLDoc);
        1009: _1009_XMLEvent(inXMLDoc,outXMLDoc);
        //现场预约
        2001: _2001_XMLEvent(inXmldoc, outXMLDoc);
        2002: _2002_XMLEvent(inXmldoc, outXMLDoc);
        //音视频子系统交易类型
        3001: _3001_XMLEvent(inXMLDoc,outXMLDoc);
        //测绘子系统交易类型
        4001: _4001_XMLEvent(inXMLDoc,outXMLDoc);
        4002: _4002_XMLEvent(inXMLDoc,outXMLDoc);
        4003: _4003_XMLEvent(inXMLDoc,outXMLDoc);
        4004: _4004_XMLEvent(inXMLDoc,outXMLDoc);
        //排队叫号子系统交易类型
        5001: _5001_XMLEvent(inXMLDoc,outXMLDoc);
        //闸机服务子系统交易类型
        6001: _6001_XMLEvent(inXMLDoc,outXMLDoc);
      else
        Exit;
      end;
    except
      Exit;
    end;
    result := True;
  end;
end;

function TDM._0_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild, inSubChild: IXMLNode;
  outRoot, outChild, outChildResult, outChildList: IXMLNode;
  optype: Integer;
  sub_code, subject, param_info, dict_info, items_info, coach_info, strSQL: string;
  function BuildParam(var NodeList : IXMLNode; var tmpQuery: TUniQuery; sqlStr : String) : Integer;
  var
    Child: IXMLNode;
    colNameStr: String;
    i: Integer;
  begin
    try
      ExecSql(tmpQuery,sqlStr);
      tmpQuery.First;
      while not tmpQuery.Eof do
      begin
        Child := NodeList.AddChild('param_item');
        for I := 0 to tmpQuery.FieldCount - 1 do
        begin
          colNameStr := LowerCase(tmpQuery.Fields[i].FieldName);
          Child.AddChild(colNameStr);
          Child.ChildValues[colNameStr] := Trim(tmpQuery.Fields[i].AsString);
        end;
        tmpQuery.Next;
      end;
      Result := 0;
    except
      Result := -1;
    end;
  end;
  function BuildDict(var NodeList : IXMLNode; var tmpQuery: TUniQuery; sqlStr : String) : Integer;
  var
    Child, subChild: IXMLNode;
    colNameStr, Previous_type: String;
    i: Integer;
  begin
    try
      Previous_type := '';
      ExecSql(tmpQuery,sqlStr);
      tmpQuery.First;
      while not tmpQuery.Eof do
      begin
        if Previous_type <> Trim(tmpQuery.Fields[0].AsString) then
        begin
          Previous_type := Trim(tmpQuery.Fields[0].AsString);
          Child := NodeList.AddChild('dict_item');

          for I := 0 to 1 do
          begin
            colNameStr := LowerCase(tmpQuery.Fields[i].FieldName);
            Child.AddChild(colNameStr);
            Child.ChildValues[colNameStr] := Trim(tmpQuery.Fields[i].AsString);
          end;
        end;
        subChild := Child.AddChild('sub_item');
        for i := 2 to tmpQuery.FieldCount - 1 do
        begin
          colNameStr := LowerCase(tmpQuery.Fields[i].FieldName);
          subChild.AddChild(colNameStr);
          subChild.ChildValues[colNameStr] := Trim(tmpQuery.Fields[i].AsString);
        end;
        tmpQuery.Next;
      end;
      Result := 0;
    except
      Result := -1;
    end;
  end;
  function BuildItems(var NodeList : IXMLNode; var tmpQuery: TUniQuery; sqlStr : String) : Integer;
  var
    Child, subChild: IXMLNode;
    colNameStr, Previous_ExamCode: String;
    i: Integer;
  begin
    try
      Previous_ExamCode := '';
      ExecSql(tmpQuery,sqlStr);
      tmpQuery.First;
      while not tmpQuery.Eof do
      begin
        if Previous_ExamCode <> Trim(tmpQuery.Fields[0].AsString) then
        begin
          Child := NodeList.AddChild('exam_item');
          Previous_ExamCode := Trim(tmpQuery.Fields[0].AsString);

          for I := 0 to 1 do
          begin
            colNameStr := LowerCase(tmpQuery.Fields[i].FieldName);
            Child.AddChild(colNameStr);
            Child.ChildValues[colNameStr] := Trim(tmpQuery.Fields[i].AsString);
          end;
        end;
        subChild := Child.AddChild('deduct_item');
        for i := 2 to tmpQuery.FieldCount - 1 do
        begin
          colNameStr := LowerCase(tmpQuery.Fields[i].FieldName);
          subChild.AddChild(colNameStr);
          subChild.ChildValues[colNameStr] := Trim(tmpQuery.Fields[i].AsString);
        end;
        tmpQuery.Next;
      end;
      Result := 0;
    except
      Result := -1;
    end;
  end;
  function BuildCoach(var NodeList : IXMLNode; var tmpQuery: TUniQuery; sqlStr : String) : Integer;
  var
    Child: IXMLNode;
    coachFinger: string;
  begin
    try
      ExecSql(tmpQuery,sqlStr);
      tmpQuery.First;
      while not tmpQuery.Eof do
      begin
        Child := NodeList.AddChild('coach_msg');
        Child.AddChild('coach_idnumber');
        Child.ChildValues['coach_idnumber'] := Trim(tmpQuery.Fields[0].AsString);
        Child.AddChild('coach_name');
        Child.ChildValues['coach_name'] := Trim(tmpQuery.Fields[1].AsString);
        Child.AddChild('finger');
        Child.ChildValues['finger'] := tmpQuery.Fields[2].AsString;

        tmpQuery.Next;
      end;
      Result := 0;
    except
      Result := -1;
    end;
  end;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    if inChild.ChildNodes.FindNode('sub_code') <> nil then
      sub_code := Trim(inChild.ChildNodes.FindNode('sub_code').Text);
    if inChild.ChildNodes.FindNode('subject') <> nil then
      subject := Trim(inChild.ChildNodes.FindNode('subject').Text);

    inSubChild := GetCurrXmlNode(inChild,'task_list');
    if inSubChild.ChildNodes.FindNode('param_info') <> nil then
      param_info := Trim(inSubChild.ChildNodes.FindNode('param_info').Text);
    if inSubChild.ChildNodes.FindNode('dict_info') <> nil then
      dict_info := Trim(inSubChild.ChildNodes.FindNode('dict_info').Text);
    if inSubChild.ChildNodes.FindNode('items_info') <> nil then
      items_info := Trim(inSubChild.ChildNodes.FindNode('items_info').Text);
    if inSubChild.ChildNodes.FindNode('coach_info') <> nil then //添加教练信息获取过程
      coach_info := Trim(inSubChild.ChildNodes.FindNode('coach_info').Text);
    case optype of
      1:
        begin
          if param_info = '1' then
          begin
            outChildList := GetCurrXmlNode(outChild,'param_list',xt_outXml);
            strSQL := Format('select param_name,param_type,param_value,display_name,'+
                             'param_grade from cfg_param '+
                             'where (subsys_id=%s or subsys_id=0) and IS_ADMIN_PARAM=0 '+
                             'order by param_name',[QuotedStr(sub_code)]);
            BuildParam(outChildList,pubQuery,strSQL);
          end;
          if dict_info = '1' then
          begin
            outChildList := GetCurrXmlNode(outChild,'dict_list',xt_outXml);
            strSQL := 'select cdd.dict_type,cd.dict_name as type_name,cdd.dict_code,cdd.dict_name,cdd.view_index '+
                      'from cfg_dict cd '+
                      'left join cfg_dict cdd on cd.dict_code = cdd.dict_type '+
                      'where cd.dict_type=-1 and cdd.dict_type<>0 and cdd.dict_type<3000 '+
                      'order by cdd.dict_type, cdd.view_index asc';
            BuildDict(outChildList,pubQuery,strSQL);
          end;
          if items_info = '1' then
          begin
            outChildList := GetCurrXmlNode(outChild,'items_list',xt_outXml);
            strSQL := Format('select (case ci.parent_code when ''10000'' then ci.parent_code '+
                             'when ''30000'' then ci.parent_code else ci.item_code end) as exam_code,'+
                             '(case ci.parent_code when ''10000'' then ''科二通用评判'' '+
                             'when ''30000'' then ''科三通用评判'' else ci.item_name end) as exam_name,'+
                             'cii.item_code as deduct_code,cii.item_name as deduct_name,cii.deduct_score '+
                             'from cfg_items ci '+
                             'left join cfg_items cii on ci.item_code=cii.parent_code '+
                             'where ci.grade=2 and ci.subject=%s '+
                             'order by cii.parent_code, cii.item_code asc',[QuotedStr(subject)]);
            BuildItems(outChildList,pubQuery,strSQL);
          end;

          //添加获取教练信息处理流程
          if coach_info = '1' then
          begin
            outChildList := GetCurrXmlNode(outChild,'coach_list',xt_outXml);
            //获取教练信息
            strSQL := 'select idnumber, user_name, fingerprint1 from sys_user where role_id=(select id from sys_role where name=''教练员'')';//教练信息获取的数据库查询语句
            BuildCoach(outChildList,pubQuery,strSQL);
          end;
        end;
    else
        begin
          UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
          Exit;
        end;
    end;
    UpdateResult(outChildResult,'0','成功');
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM._1001_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild: IXMLNode;
  outRoot, outChild, outChildResult, outChildList, outTmpChild, outSubTmpChild: IXMLNode;
  optype, i: Integer;
  subject, car_ip, colNameStr, strSQL, Previous_id, mapStr: string;
  mapbuf : TMemoryStream;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    mapbuf := TMemoryStream.Create;
    try
      if inChild.ChildNodes.FindNode('subject') <> nil then
        subject := Trim(inChild.ChildNodes.FindNode('subject').Text);
      if inChild.ChildNodes.FindNode('car_ip') <> nil then
        car_ip := Trim(inChild.ChildNodes.FindNode('car_ip').Text);
      case optype of
        1:
          begin
            outChildList := GetCurrXmlNode(outChild,'map_list',xt_outXml);
            Previous_id := '';
            strSQL := Format('select cm.id,cm.subject,cm.driver_license_type,cm.exam_item as exam_code,cm.mapnumber,'+
                             'cm.name as mapname,cm.map,vi.ip as video_ip,vi.port as video_port, '+
                             'vi.vuser as video_user,vi.password as video_password,vi.device_id '+
                             'from cfg_maps cm '+
                             'left join cfg_video vi on trim(vi.item)=to_char(cm.id) and cm.subject=vi.subject and vi.ascription=''M'' '+
                             'where cm.subject=%s order by cm.id asc', [QuotedStr(subject)]);
            ExecSql(pubQuery,strSQL);
            pubQuery.First;
            while not pubQuery.Eof do
            begin
              if Previous_id <> Trim(pubQuery.Fields[0].AsString) then
              begin
                outTmpChild := outChildList.AddChild('map');
                Previous_id := Trim(pubQuery.Fields[0].AsString);

                for i := 1 to 6 do
                begin
                  colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
                  outTmpChild.AddChild(colNameStr);
                  if colNameStr = LowerCase('MAP') then
                  begin
                    mapbuf.Clear;
                    mapStr := '';
                    TBlobField(pubQuery.FieldByName('MAP')).SaveToStream(mapbuf);
                    Base64Enc(mapbuf, mapStr, mapbuf.Size);
                    outTmpChild.ChildValues[colNameStr] := mapStr;
                  end
                  else
                    outTmpChild.ChildValues[colNameStr] := Trim(pubQuery.Fields[i].AsString);
                end;
              end;
              outSubTmpChild := outTmpChild.AddChild('video_list');
              for i := 7 to pubQuery.FieldCount - 1 do
              begin
                colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
                outSubTmpChild.AddChild(colNameStr);
                outSubTmpChild.ChildValues[colNameStr] := Trim(pubQuery.Fields[i].AsString);
              end;
              pubQuery.Next;
            end;
          end;
        2:
          begin
            outTmpChild := GetCurrXmlNode(outChild,'car',xt_outXml);
            Previous_id := '';
            strSQL := Format('select bc.id as car_id,bc.license_plate,bc.qualified_car_type,bc.car_map,vi.ip as video_ip,'+
                             'vi.port as video_port,vi.vuser as video_user, vi.password as video_password '+
                             'from bas_car bc '+
                             'left join cfg_video vi on Trim(bc.id)=Trim(vi.item) and bc.subject=vi.subject and vi.ascription=''C'' '+
                             'where bc.car_ip=%s and bc.subject=%s and bc.USE_STATUS=''A'' and bc.CAR_STATUS=''A'' order by bc.id asc',
                             [QuotedStr(car_ip),QuotedStr(subject)]);
            ExecSql(pubQuery,strSQL);
            if pubQuery.RecordCount = 0 then
            begin
              UpdateResult(outChildResult,'1',Format('无[%s]的车辆信息或该车辆已停止使用',[car_ip]));
              Exit;
            end;
            pubQuery.First;
            while not pubQuery.Eof do
            begin
              if Previous_id <> Trim(pubQuery.Fields[0].AsString) then
              begin
                Previous_id := Trim(pubQuery.Fields[0].AsString);

                for i := 0 to 3 do
                begin
                  colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
                  outTmpChild.AddChild(colNameStr);
                  if colNameStr = LowerCase('CAR_MAP') then
                  begin
                    mapbuf.Clear;
                    mapStr := '';
                    TBlobField(pubQuery.FieldByName('CAR_MAP')).SaveToStream(mapbuf);
                    Base64Enc(mapbuf, mapStr, mapbuf.Size);
                    outTmpChild.ChildValues[colNameStr] := mapStr;
                  end
                  else
                    outTmpChild.ChildValues[colNameStr] := Trim(pubQuery.Fields[i].AsString);
                end;
              end;
              outSubTmpChild := outTmpChild.AddChild('video_list');
              for i := 4 to pubQuery.FieldCount - 1 do
              begin
                colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
                outSubTmpChild.AddChild(colNameStr);
                outSubTmpChild.ChildValues[colNameStr] := Trim(pubQuery.Fields[i].AsString);
              end;
              pubQuery.Next;
            end;
          end;
      else
          begin
            UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
            Exit;
          end;
      end;
      UpdateResult(outChildResult,'0','成功');
    finally
      mapbuf.Free;
    end;
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM._1002_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild: IXMLNode;
  outRoot, outChild, outChildResult: IXMLNode;
  optype, i: Integer;
  license_plate, colNameStr, strSQL: string;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    if inChild.ChildNodes.FindNode('license_plate') <> nil then
      license_plate := Trim(inChild.ChildNodes.FindNode('license_plate').Text);
    case optype of
      1:
        begin
          strSQL := Format('select bs.id as student_id, bs.idnumber as student_idnumber, bgd.grouping_id '+
                           'from bas_grouping bg '+
                           'left join bas_grouping_detail bgd on bgd.grouping_id=bg.id '+
                           'left join BAS_BOOKING bb on bb.student_id=bgd.student_id and bb.booking_exam_date=to_char(sysdate,''YYYYMMDD'') '+
                           'left join bas_student bs on bs.id=bgd.student_id '+
                           'left join bas_car bc on bc.id=bg.car_id '+
                           'where bc.license_plate=%s and bgd.queue_status=''1'' '+
                           'and bb.sign_status=''1'' and bb.EXAM_STATUS = ''0'' and rownum=1 '+
                           'order by bgd.queue_order asc',
                           [QuotedStr(license_plate)]);
          ExecSql(pubQuery,strSQL);
          if pubQuery.RecordCount = 1 then
          begin
            for I := 0 to pubQuery.FieldCount - 1 do
            begin
              colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
              outChild.AddChild(colNameStr);
              outChild.ChildValues[colNameStr] := Trim(pubQuery.Fields[i].AsString);
            end;
          end
          else
          begin
            UpdateResult(outChildResult,'1',Format('无备考学员信息',[optype]));
            Exit;
          end;
        end;
    else
        begin
          UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
          Exit;
        end;
    end;
    UpdateResult(outChildResult,'0','成功');
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM._1003_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild: IXMLNode;
  outRoot, outChild, outChildResult, outChildList: IXMLNode;
  optype, i: Integer;
  student_idnumber, license_plate, is_grouping, grouping_id: string;
  password, colNameStr, strSQL, driver_license_type: string;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    if inChild.ChildNodes.FindNode('student_idnumber') <> nil then
      student_idnumber := Trim(inChild.ChildNodes.FindNode('student_idnumber').Text);
    if inChild.ChildNodes.FindNode('driver_license_type') <> nil then
      driver_license_type := Trim(inChild.ChildNodes.FindNode('driver_license_type').Text);
    if inChild.ChildNodes.FindNode('is_grouping') <> nil then
      is_grouping := Trim(inChild.ChildNodes.FindNode('is_grouping').Text);
    if inChild.ChildNodes.FindNode('grouping_id') <> nil then
      grouping_id := Trim(inChild.ChildNodes.FindNode('grouping_id').Text);
    if inChild.ChildNodes.FindNode('license_plate') <> nil then
      license_plate := Trim(inChild.ChildNodes.FindNode('license_plate').Text);
    if inChild.ChildNodes.FindNode('password') <> nil then
      password := Trim(inChild.ChildNodes.FindNode('password').Text);
    case optype of
      1:
        begin
          outChildList := GetCurrXmlNode(outChild,'finger_list',xt_outXml);
          if is_grouping = '0' then
            //无考试安排
            strSQL := Format('select bs.DRIVER_LICENSE_TYPE,bs.id as student_id, bs.fingerprint1, bs.fingerprint2,'+
                             'bs.fingerprint3, bs.fingerprint4 '+
                             'from bas_student bs '+
                             'where bs.idnumber = %s ',[QuotedStr(student_idnumber)])
          else if is_grouping = '1' then
            //有考试安排
            strSQL := Format('select bs.id as student_id, bs.fingerprint1, bs.fingerprint2,'+
                             'bs.fingerprint3, bs.fingerprint4 '+
                             'from bas_booking bb '+
                             'left join bas_student bs on bs.id=bb.student_id '+
                             'left join bas_grouping_detail bgd on bgd.student_id=bs.id '+
                             'left join bas_grouping bg on bg.id=bgd.grouping_id '+
                             'left join bas_car bc on bc.id=bg.car_id '+
                             'where bb.booking_exam_date=to_char(sysdate,''yyyymmdd'') '+
                             'and bs.idnumber=%s and bc.license_plate=%s and bg.id=%s ',
                             [QuotedStr(student_idnumber),QuotedStr(license_plate),QuotedStr(grouping_id)])
          else
          begin
            UpdateResult(outChildResult,'1',Format('备考学员是否分组情况不明',[optype]));
            Exit;
          end;
          ExecSql(pubQuery,strSQL);
          if pubQuery.RecordCount = 1 then
          begin
            if driver_license_type <> Trim(pubQuery.Fields[0].AsString) then
            begin
              UpdateResult(outChildResult,'1',Format('该学员准驾车型[%s]与当前车辆[%s]不符',
                           [Trim(pubQuery.Fields[0].AsString),driver_license_type]));
              Exit;
            end;
            for I := 1 to pubQuery.FieldCount - 1 do
            begin
              colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
              if colNameStr = LowerCase('student_id') then
              begin
                outChild.AddChild(colNameStr);
                outChild.ChildNodes[colNameStr].Text := Trim(pubQuery.Fields[i].AsString);
              end else
              begin
                outChildList.AddChild('finger');
                outChildList.ChildValues['finger'] := Trim(pubQuery.Fields[i].AsString);
              end;
            end;
          end
          else
          begin
            UpdateResult(outChildResult,'1',Format('学员信息不存在',[optype]));
            Exit;
          end;
        end;
      2:
        begin
          if password = '' then
          begin
            UpdateResult(outChildResult,'1',Format('密码为空',[optype]));
            Exit;
          end;
          strSQL := Format('select bs.id as student_id, bs.idnumber, bs.password '+
                           'from bas_student bs '+
                           'where bs.idnumber=%s',[QuotedStr(student_idnumber)]);
          ExecSql(pubQuery,strSQL);
          if pubQuery.RecordCount > 0 then
          begin
            if Trim(pubQuery.FieldByName('password').AsString) <> password then   //todo:这里需要进行加解密操作
            begin
              UpdateResult(outChildResult,'1',Format('密码错误',[optype]));
              Exit;
            end;
            outChild.AddChild('student_id');
            outChild.ChildValues['student_id'] := Trim(pubQuery.FieldByName('student_id').AsString);
          end else
          begin
            UpdateResult(outChildResult,'1',Format('学员信息不存在',[optype]));
            Exit;
          end;
        end;
    else
        begin
          UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
          Exit;
        end;
    end;
    UpdateResult(outChildResult,'0','成功');
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM._1004_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild: IXMLNode;
  outRoot, outChild, outChildResult, outTmpChild,outSubTmpChild: IXMLNode;
  optype, i: Integer;
  student_id, book_id, Previous_name, colNameStr, PhotoStr, strSQL: string;
  PhotoBuf: TMemoryStream;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    if inChild.ChildNodes.FindNode('student_id') <> nil then
      student_id := Trim(inChild.ChildNodes.FindNode('student_id').Text);
    if inChild.ChildNodes.FindNode('book_id') <> nil then
      book_id := Trim(inChild.ChildNodes.FindNode('book_id').Text);
    case optype of
      1,2:
        begin
          if optype = 1 then
            strSQL := Format('select bb.id as book_id, bs.name as student_name, bs.idnumber as student_idnumber, bb.examnumber,'+
                               'bs.photo1 as photo, bb.exam_times, be1.name as examiner1, be2.name as examiner2,'+
                               'bp.code as place_code, cdli.exam_item '+
                               'from bas_booking bb '+
                               'left join bas_student bs on bs.id=bb.student_id '+
                               'left join bas_examiner be1 on be1.id=bb.examiner1_id '+
                               'left join bas_examiner be2 on be2.id=bb.examiner2_id '+
                               'left join bas_place bp on bp.id=bb.place_id '+
                               'left join cfg_driver_license_items cdli on cdli.driver_license_type=bb.driver_license_type '+
                               'where bb.booking_exam_date=to_char(sysdate,''yyyymmdd'') '+
                               'and bb.student_id=%s and bb.id=%s',[QuotedStr(student_id),QuotedStr(book_id)])
          else if optype = 2 then
            strSQL := Format('select bbb.id as book_id,bs.name as student_name, bs.idnumber as student_idnumber, bbb.examnumber,'+
                             'bs.photo1 as photo, bbb.exam_times, be1.name as examiner1, be2.name as examiner2,'+
                             'bp.code as place_code, cdli.exam_item '+
                             'from '+
                             '(select * '+
                             'from bas_booking bb '+
                             'where bb.booking_exam_date=to_char(sysdate,''yyyymmdd'') '+
                             'and rownum = 1 and bb.student_id=%s '+
                             'order by bb.booking_datetime asc) bbb '+
                             'left join bas_student bs on bs.id=bbb.student_id '+
                             'left join bas_examiner be1 on be1.id=bbb.examiner1_id '+
                             'left join bas_examiner be2 on be2.id=bbb.examiner2_id '+
                             'left join bas_place bp on bp.id=bbb.place_id '+
                             'left join cfg_driver_license_items cdli on cdli.driver_license_type=bbb.driver_license_type',
                             [QuotedStr(student_id)]);
          ExecSql(pubQuery,strSQL);
          if pubQuery.RecordCount = 0 then
          begin
            UpdateResult(outChildResult,'1',Format('获得当日约考学员信息记录为空',[optype]));
            Exit;
          end;
          PhotoBuf := TMemoryStream.Create;
          try
            Previous_name := '';
            pubQuery.First;
            while not pubQuery.Eof do
            begin
              if Previous_name <> Trim(pubQuery.Fields[0].AsString) then
              begin
                Previous_name := Trim(pubQuery.Fields[0].AsString);
                outChild.AddChild(LowerCase(pubQuery.Fields[0].FieldName));
                outChild.ChildNodes[LowerCase(pubQuery.Fields[0].FieldName)].Text := Trim(pubQuery.Fields[0].AsString);
                for i := 1 to pubQuery.FieldCount - 2 do
                begin
                  colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
                  outChild.AddChild(colNameStr);
                  if colNameStr = LowerCase('photo') then
                  begin
                    PhotoBuf.Clear;
                    PhotoStr := '';
                    TBlobField(pubQuery.FieldByName('photo')).SaveToStream(PhotoBuf);
                    Base64Enc(PhotoBuf, PhotoStr, PhotoBuf.Size);
                    outChild.ChildValues[colNameStr] := PhotoStr;
                  end
                  else
                    outChild.ChildValues[colNameStr] := Trim(pubQuery.Fields[i].AsString);
                end;
                outTmpChild := GetCurrXmlNode(outChild,'exam_item',xt_outXml);
              end;
              outSubTmpChild := outTmpChild.AddChild('exam_code');
              outSubTmpChild.NodeValue := Trim(pubQuery.Fields[pubQuery.FieldCount-1].AsString);

              pubQuery.Next;
            end;
          finally
            PhotoBuf.Free;
          end;
        end;
    else
        begin
          UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
          Exit;
        end;
    end;
    UpdateResult(outChildResult,'0','成功');
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM._1005_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild: IXMLNode;
  outRoot, outChildResult,outChild: IXMLNode;
  optype, id: Integer;
  exam_id, book_id, student_id, process_flag, process_type, exam_code, deduct_code, deduct_score: string;
  device_id, process_photo, speed, process_time, strSQL, car_id, current_score, EXAM_STATUS: string;
  contrail_path: string;
  PhotoBuf: TMemoryStream;
  tmpStrStream:TStringStream;
  retBoolWS: Boolean;
  fee_type: string;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    if inChild.ChildNodes.FindNode('exam_id') <> nil then
      exam_id := Trim(inChild.ChildNodes.FindNode('exam_id').Text);
    if inChild.ChildNodes.FindNode('student_id') <> nil then
      student_id := Trim(inChild.ChildNodes.FindNode('student_id').Text);
    if inChild.ChildNodes.FindNode('book_id') <> nil then
      book_id := Trim(inChild.ChildNodes.FindNode('book_id').Text);
    if inChild.ChildNodes.FindNode('car_id') <> nil then
      car_id := Trim(inChild.ChildNodes.FindNode('car_id').Text);
    if inChild.ChildNodes.FindNode('process_flag') <> nil then
      process_flag := Trim(inChild.ChildNodes.FindNode('process_flag').Text);
    if inChild.ChildNodes.FindNode('process_type') <> nil then
      process_type := Trim(inChild.ChildNodes.FindNode('process_type').Text);
    if inChild.ChildNodes.FindNode('exam_code') <> nil then
      exam_code := Trim(inChild.ChildNodes.FindNode('exam_code').Text);
    if inChild.ChildNodes.FindNode('deduct_code') <> nil then
      deduct_code := Trim(inChild.ChildNodes.FindNode('deduct_code').Text);
    if inChild.ChildNodes.FindNode('deduct_score') <> nil then
      deduct_score := Trim(inChild.ChildNodes.FindNode('deduct_score').Text);
    if deduct_score = '' then deduct_score := '0';
    if inChild.ChildNodes.FindNode('device_id') <> nil then
      device_id := Trim(inChild.ChildNodes.FindNode('device_id').Text);
    if inChild.ChildNodes.FindNode('process_photo') <> nil then
      process_photo := Trim(inChild.ChildNodes.FindNode('process_photo').Text);
    if inChild.ChildNodes.FindNode('speed') <> nil then
      speed := Trim(inChild.ChildNodes.FindNode('speed').Text);
    if speed = '' then speed := '0';
    if inChild.ChildNodes.FindNode('process_time') <> nil then
      process_time := Trim(inChild.ChildNodes.FindNode('process_time').Text);
    if inChild.ChildNodes.FindNode('current_score') <> nil then
      current_score := Trim(inChild.ChildNodes.FindNode('current_score').Text);
    if inChild.ChildNodes.FindNode('contrail_path') <> nil then
      contrail_path := Trim(inChild.ChildNodes.FindNode('contrail_path').Text);
    if inChild.ChildNodes.FindNode('fee_type') <> nil then
      fee_type := Trim(inChild.ChildNodes.FindNode('fee_type').Text);

    case optype of
      1,2,3,4,5,6,7:
         begin
           id := 0;
           if (optype = 7) then
           begin
             strSQL := Format('select count(*) as total  from bas_booking bb '+
                             'where bb.booking_exam_date=to_char(sysdate, ''YYYYMMDD'') '+
                             'and bb.student_id=%s and bb.id=%s' ,[QuotedStr(student_id),QuotedStr(book_id)]);
             ExecSql(pubQuery,strSQL);
             if pubQuery.FieldByName('total').AsInteger = 0 then
             begin
               UpdateResult(outChildResult,'1',Format('无学员预约信息',[optype]));
               Exit;
             end;

             //因为type7是在确认有未完成的训练的情况下上报的，所以此处不再进行未完成确认
             strSQL := Format('select * from(select * from buz_exam_info '
                     + 'where (substr(exam_start_time, 0, 8)=to_char(sysdate, ''YYYYMMDD'') '
                     + 'and booking_id=%s) '
                     + 'order by id desc) where rownum=1 ', [QuotedStr(book_id)]);
             if ExecSql(pubQuery,strSQL) then
             begin
               id := pubQuery.Fields[0].AsInteger;
               exam_id := IntToStr(id);
               outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);
               outChild.AddChild('exam_id');
               outChild.ChildValues['exam_id'] := exam_id;
               UpdateResult(outChildResult,'0','成功');
             end else
             begin
               UpdateResult(outChildResult,'1',Format('操作数据库错误',[optype]));
               Exit;
             end;

             Exit;
           end else
           begin
             if (optype = 1) and (exam_id='') then
             begin
               strSQL := Format('select count(*) as total  from bas_booking bb '+
                               'where bb.booking_exam_date=to_char(sysdate, ''YYYYMMDD'') '+
                               'and bb.student_id=%s and bb.id=%s' ,[QuotedStr(student_id),QuotedStr(book_id)]);
               ExecSql(pubQuery,strSQL);
               if pubQuery.FieldByName('total').AsInteger = 0 then
               begin
                 UpdateResult(outChildResult,'1',Format('无学员预约信息可写入',[optype]));
                 Exit;
               end;
               strSQL := 'select SEQU_BUZ_EXAM_INFO_ID.Nextval as id from dual';
               if ExecSql(pubQuery,strSQL) then
                 id := pubQuery.FieldByName('id').AsInteger;
               strSQL := Format('insert into buz_exam_info '+
                                '(ID,SUBJECT,BOOKING_ID,'+
                                'CAR_ID,EXAM_START_TIME,CURRENT_EXAM_TIMES,CURRENT_EXAM_SCORE,HASH)'+
                                'select %d,bb.subject,bb.id as booking_id,'+
                                '%s as car_id,%s as EXAM_START_TIME,'+
                                '(select count(CURRENT_EXAM_TIMES)+1 from buz_exam_info where booking_id=bb.id '+
                                'and to_char(sysdate,''YYYYMMDD'')=substr(exam_start_time,0,8)) as CURRENT_EXAM_TIMES,'+
                                '0 as CURRENT_EXAM_SCORE,'' '' as HASH '+
                                'from bas_booking bb '+
                                'where bb.booking_exam_date = to_char(sysdate,''YYYYMMDD'') '+
                                'and bb.student_id=%s and bb.id=%s',
                                [id,QuotedStr(car_id),QuotedStr(process_time), QuotedStr(student_id), QuotedStr(book_id)]);
               if ExecSql(pubQuery,strSQL,False) then
               begin
                 //buz_exam_info表进行hasd运算
                 HashArithmetic('buz_exam_info',Format('where id=%d',[id]));
                 exam_id := IntToStr(id);
                 outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);
                 outChild.AddChild('exam_id');
                 outChild.ChildValues['exam_id'] := exam_id;
               end else
               begin
                 UpdateResult(outChildResult,'1',Format('学员考试信息写入错误',[optype]));
                 Exit;
               end;
             end;

             //写入考试过程
             strSQL := 'select SEQU_BUZ_EXAM_PROCESS_ID.Nextval as id from dual';
             if ExecSql(pubQuery,strSQL) then
               id := pubQuery.FieldByName('id').AsInteger;
             try
               strSQL := 'select * from BUZ_EXAM_PROCESS where 1=2';
               ExecSql(pubQuery,strSQL);
               pubQuery.Append;
               pubQuery.FieldByName('id').AsInteger := id;
               pubQuery.FieldByName('EXAM_ID').AsString := exam_id;
               pubQuery.FieldByName('PROCESS_FLAG').AsString := process_flag;
               pubQuery.FieldByName('PROCESS_TYPE').AsString := process_type;
               if (optype=2) or (optype=3) or (optype=4) or (optype=5) then
               begin
                 pubQuery.FieldByName('EXAM_ITEM').AsString := exam_code;
                 pubQuery.FieldByName('DEVICE_ID').AsString := device_id;
               end;
               if (optype=3) then
               begin
                 pubQuery.FieldByName('DEDUCT_ITEM').AsString := deduct_code;
                 pubQuery.FieldByName('DEDUCT_SCORE').AsString := deduct_score;
               end;

               if (optype=1) or (optype=4) or (optype=6) then
               begin
                 PhotoBuf := TMemoryStream.Create;
                 try
                   tmpStrStream := TStringStream.Create(process_photo);
                   DecodeStream(tmpStrStream,PhotoBuf);
                   PhotoBuf.Position := 0;
                   TBlobField(pubQuery.FieldByName('PROCESS_PHOTO')).LoadFromStream(PhotoBuf);
                 finally
                   //tmpStrStream.Free;
                   PhotoBuf.Free;
                 end;
               end;
               pubQuery.FieldByName('SPEED').AsString := speed;
               //pubQuery.FieldByName('RECORD_TYPE').AsString := '1';
               pubQuery.FieldByName('PROCESS_TIME').AsString := process_time;
               //pubQuery.FieldByName('VIDEO_PATH').AsString := id;
               //pubQuery.FieldByName('PROCESS_STATUS').AsString := id;
               pubQuery.FieldByName('HASH').AsString := ' ';
               pubQuery.Post;
             except
               UpdateResult(outChildResult,'1',Format('操作数据库错误',[optype]));
               Exit;
             end;

             //公安网接口上传
             retBoolWS := WebServicesInterface(exam_id,IntToStr(id));

             if optype = 6 then
             begin
               try
                 if StrToInt(current_score) < 80 then
                    EXAM_STATUS := '2'
                 else
                    EXAM_STATUS := '1';
               except
                 current_score := '0';
               end;
               strSQL := Format('update buz_exam_info bei set bei.CURRENT_EXAM_SCORE=%s,'+
                                'bei.exam_end_time=%s,bei.exam_status=%s, bei.CONTRAIL_PATH=%s where bei.id = %s',
                                [QuotedStr(current_score),
                                 QuotedStr(process_time),
                                 QuotedStr(EXAM_STATUS),
                                 QuotedStr(contrail_path),
                                 QuotedStr(exam_id)]);
               ExecSql(pubQuery,strSQL,False);
               //buz_exam_info表进行hasd运算
               HashArithmetic('buz_exam_info',Format('where id=%s',[QuotedStr(exam_id)]));
               //更行bas_booking表exam_status
               strSQL := Format('update  bas_booking bb set bb.exam_status = %s '+
                                'where bb.booking_exam_date = to_char(sysdate, ''yyyymmdd'') '+
                                'and bb.booking_times = '+
                                '(select count(*) from buz_exam_info bei where bei.booking_id = bb.id) '+
                                'and bb.id = '+
                                '(select bei.booking_id '+
                                'from buz_exam_info bei, buz_exam_process bep '+
                                'where bep.exam_id = bei.id '+
                                'and bep.id = %d '+
                                'and (bep.process_flag = ''SE'' or bep.process_type = ''C56''))',
                                [QuotedStr(EXAM_STATUS),id]);
               ExecSql(pubQuery,strSQL,False);
             end;
             //BUZ_EXAM_PROCESS表进行hasd运算
             HashArithmetic('BUZ_EXAM_PROCESS',Format('where id=%d',[id]));
           end;
         end
         else
         begin
           UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
           Exit;
         end;
    end;
    if not retBoolWS then
      UpdateResult(outChildResult,'1',Format('[%s]接口调用失败',[process_type]))
    else
      UpdateResult(outChildResult,'0','成功');
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM._1006_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild: IXMLNode;
  outRoot, outChildResult, outChild, outSubChild: IXMLNode;
  optype, i: Integer;
  strSQL: string;
  colNameStr, is_free_single: string;
  fee_type, student_id: string;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    if inChild.ChildNodes.FindNode('fee_type') <> nil then
      fee_type := Trim(inChild.ChildNodes.FindNode('fee_type').Text);
    if inChild.ChildNodes.FindNode('student_id') <> nil then
      student_id := Trim(inChild.ChildNodes.FindNode('student_id').Text);
    case optype of
      1:
        begin
          strSQL := Format('select is_free_single,fee_times,fee_amount,rebate_type,rebate_rate,decrease_sum,total_fee '+
                           'from view_payment where student_id=%s and fee_type=%s and view_type=''W'' order by fee_times asc',
                           [QuotedStr(student_id),QuotedStr(fee_type)]);
          ExecSql(pubQuery,strSQL);
          if pubQuery.RecordCount = 0 then
          begin
            strSQL := Format('select is_free_single,fee_times,fee_amount,rebate_type,rebate_rate,decrease_sum,total_fee '+
                             'from view_payment where student_id=%s and fee_type=%s and view_type=''B'' order by fee_times asc',
                             [QuotedStr(student_id),QuotedStr(fee_type)]);
            ExecSql(pubQuery,strSQL);
            if pubQuery.RecordCount = 0 then
            begin
              UpdateResult(outChildResult,'1',Format('无支付项目信息',[optype]));
              Exit;
            end;
          end;
          pubQuery.First;
          while not pubQuery.Eof do
          begin
            if is_free_single <> Trim(pubQuery.Fields[0].AsString) then
            begin
              is_free_single := Trim(pubQuery.Fields[0].AsString);
              colNameStr := LowerCase(pubQuery.Fields[0].FieldName);
              outChild.AddChild(colNameStr);
              outChild.ChildValues[colNameStr] := Trim(pubQuery.Fields[0].AsString);
            end;
            outSubChild := outChild.AddChild('pay_list');
            for i := 1 to pubQuery.FieldCount - 1 do
            begin
              colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
              outSubChild.AddChild(colNameStr);
              outSubChild.ChildValues[colNameStr] := Trim(pubQuery.Fields[i].AsString);
            end;
            pubQuery.Next;
          end;
        end;
    else
        begin
          UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
          Exit;
        end;
    end;
    UpdateResult(outChildResult,'0','成功');
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM.Str2Time(timStr: string): Extended;
begin
  Result := StrToDateTime(copy(timStr,1,4)+'/'+copy(timStr,5,2)+
            '/'+copy(timStr,7,2)+' '+copy(timStr,9,2)+':'
            +copy(timStr,11,2)+':'+copy(timStr,13,2))
end;

function TDM._1007_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild: IXMLNode;
  outRoot, outChildResult, outChild, outSubChild: IXMLNode;
  outChildList: IXMLNode;
  optype, i: Integer;
  strSQL: string;
  currBookId: string;
  colNameStr: string;
  index: Integer;
  studyTime: Integer;
  useTime: Integer;
  bookingId: string;
  fee_type, student_id: string;
  function BuildBookMsg(var NodeList : IXMLNode; var tmpQuery: TUniQuery) : Integer;
  var
    Child: IXMLNode;
    strSQL: string;
    subChild: IXMLNode;
  begin
    try
      tmpQuery.First;
      while not pubQuery.Eof do
      begin
        Child := NodeList.AddChild('book_info');
        Child.AddChild('book_id');
        Child.ChildValues['book_id'] := tmpQuery.Fields[0].AsString;
        Child.AddChild('flow_id');
        Child.ChildValues['flow_id'] := Trim(tmpQuery.FieldByName('flow_id').AsString);
        Child.AddChild('trade_no');
        Child.ChildValues['trade_no'] := Trim(tmpQuery.FieldByName('trade_no').AsString);
        Child.AddChild('fee_type');
        Child.ChildValues['fee_type'] := Trim(tmpQuery.FieldByName('fee_type').AsString);
        Child.AddChild('times');
        Child.ChildValues['times'] := Trim(tmpQuery.FieldByName('times').AsString);
        Child.AddChild('use_times');
        Child.ChildValues['use_times'] := Trim(tmpQuery.FieldByName('use_times').AsString);

        tmpQuery.Next;
      end;
      Result := 0;
    except
      Result := -1;
    end;
  end;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    if inChild.ChildNodes.FindNode('fee_type') <> nil then
      fee_type := Trim(inChild.ChildNodes.FindNode('fee_type').Text);
    if inChild.ChildNodes.FindNode('student_id') <> nil then
      student_id := Trim(inChild.ChildNodes.FindNode('student_id').Text);
    case optype of
      1:
        begin
          //查询预约类型(计时/计次)---保留此处的查询语句，后续的多次预约可直接使用
          strSQL := Format('select bb.study_time from bas_booking bb where bb.student_id = %s '
                          + 'and bb.booking_exam_date = to_char(sysdate, ''yyyymmdd'')',
                           [QuotedStr(student_id)]);
          ExecSql(pubQuery,strSQL); //查找当天有预约且学习时间不为空的记录
          if pubQuery.RecordCount > 0 then
          begin
            studyTime := 0;
            while not pubQuery.Eof do
            begin
              //将所有有记录的时间累加
              studyTime := studyTime + pubQuery.Fields[0].AsInteger;
              pubQuery.Next;
            end;
          end;

          //找到指定学员当天的最后一次预约是否是一次未结束的训练
          strSQL := Format('select id from bas_booking where id = '
                  + '(select * from (select booking_id from buz_exam_info '
                  + 'where exam_end_time is null and substr(exam_start_time, 1, 8)'
                  + '= to_char(sysdate, ''yyyymmdd'') order by exam_start_time desc) '
                  + 'where rownum=1) and student_id = %s and '
                  +'booking_exam_date = to_char(sysdate, ''yyyymmdd'')', [QuotedStr(student_id)] );
          ExecSql(pubQuery,strSQL);

          if pubQuery.RecordCount = 1 then
          begin
            bookingId := pubQuery.Fields[0].AsString; //获取未完成的ID

            //取最后处理的时间,并将buz_exam_info补充完整
            strSQL := Format('update buz_exam_info set exam_end_time = '
                  + '(select * from (select bepv.process_time from buz_exam_process_view bepv '
                  + 'where bepv.student_idnumber = (select bs.idnumber from bas_student bs where bs.id = %s) '
                  + 'order by bepv.process_time desc) where rownum=1) where substr(exam_start_time,1,8)'
                  + '= to_char(sysdate, ''yyyymmdd'') and exam_end_time is null',
                  [QuotedStr(student_id)] );
            ExecSql(pubQuery,strSQL,False);
          end;

          //计算已经使用的时长
          strSQL := Format('select beiv.exam_start_time, beiv.exam_end_time from buz_exam_info_view beiv '
                  + 'where beiv.student_idnumber =(select bs.idnumber from bas_student bs where bs.id = %s) '
                  + 'and substr(beiv.exam_start_time, 1, 8)=to_char(sysdate, ''yyyymmdd'')',
                  [QuotedStr(student_id)]);
          ExecSql(pubQuery,strSQL);

          useTime := 0;
          while not pubQuery.Eof do
          begin
            //将所有有记录的时间累加
            useTime := useTime +  MinutesBetween(Str2Time(pubQuery.Fields[1].AsString), Str2Time(pubQuery.Fields[0].AsString));
            pubQuery.Next;
          end;

          if studyTime > useTime then //计时过程
          begin
            outChild.AddChild('study_time');
            outChild.ChildValues['study_time'] := studyTime - useTime;

            if bookingId = '' then //如果没有未完成的训练,查找未开始的预约
            begin
              strSQL := Format('select bb.id from bas_booking bb where bb.student_id=%s and '
                      + 'bb.booking_exam_date=to_char(sysdate, ''yyyymmdd'') and bb.id not '
                      + 'in (select bei.booking_id from buz_exam_info bei where '
                      + 'substr(bei.exam_end_time, 1,8)=to_char(sysdate, ''yyyymmdd''))',
                      [QuotedStr(student_id), QuotedStr(student_id)]);
              ExecSql(pubQuery,strSQL);
              if pubQuery.RecordCount > 0 then
                bookingId := pubQuery.Fields[0].AsString
              else
              begin
                outChild.AddChild('status_flag');
                outChild.ChildValues['status_flag'] := 0;
                Exit;
              end;
            end;

            strSQL := Format('select * from ('+
                     'select bb.id as book_id,bpd.id as flow_id,bpd.trade_no,bpd.fee_type,bpd.times,'+
                     '(select count(*) from buz_exam_info bei where bei.booking_id = bb.id ' +
                     'and bei.exam_end_time is not null) as use_times '+
                     'from bas_booking bb,buz_payment_detail bpd '+
                     'where bb.booking_exam_date = to_char(sysdate, ''yyyymmdd'')'+
                     'and bb.study_time > 0 '+
                     'and bb.id = %s ' +
                     'and bb.student_id = %s '+
                     'and bpd.booking_id = bb.id '+
                     'and bpd.fee_type = %s '+
                     'order by bb.booking_datetime asc)',
                     [QuotedStr(bookingId),QuotedStr(student_id),QuotedStr(fee_type)]);
          end else //计次过程
          begin
            outChild.AddChild('study_time');
            outChild.ChildValues['study_time'] := 0;//计次过程直接将学习时长赋值为0

            strSQL := Format('select tb.* from (select bb.id as book_id from bas_booking bb '
                     + 'where bb.booking_exam_date = to_char(sysdate, ''yyyymmdd'')'
                     + 'and bb.booking_times > (select count(*) from buz_exam_info bei '
                     + 'where bei.booking_id = bb.id and bei.exam_end_time is not null)'
                     + 'and bb.student_id = %s order by bb.booking_datetime asc'
                     + ') tb where rownum = 1',[QuotedStr(student_id)]);
            ExecSql(pubQuery,strSQL);
            if pubQuery.RecordCount = 1 then
            begin
              currBookId := pubQuery.Fields[0].AsString;

              strSQL := Format('select * from (select exam_end_time from buz_exam_info '
                      + 'where substr(exam_start_time, 0, 8)=to_char(sysdate, ''yyyymmdd'')'
                      + 'and booking_id=%s order by exam_start_time desc) '
                      + 'where rownum=1', [QuotedStr(currBookId)]);
              ExecSql(pubQuery,strSQL);

              outChild.AddChild('repeat_flag');
              outChild.ChildValues['repeat_flag'] := 0;
              if pubQuery.RecordCount > 0 then
              begin
                if pubQuery.Fields[0].AsString = '' then
                  outChild.ChildValues['repeat_flag'] := 1;
              end;
            end else
              outChild.ChildValues['repeat_flag'] := 0;

            strSQL := Format('select * from ('+
                               'select bb.id as book_id,bpd.id as flow_id,bpd.trade_no,bpd.fee_type,bpd.times,'+
                               '(select count(*) from buz_exam_info bei where bei.booking_id = bb.id ' +
                               'and bei.exam_end_time is not null) as use_times '+
                               'from bas_booking bb,buz_payment_detail bpd '+
                               'where bb.booking_exam_date = to_char(sysdate, ''yyyymmdd'')'+
                               'and bb.booking_times > (select count(*) from buz_exam_info bei where bei.booking_id = bb.id ' +
                               'and bei.exam_end_time is not null) '+
                               'and bb.student_id = %s '+
                               'and bpd.booking_id = bb.id '+
                               'and bpd.fee_type = %s '+
                               'order by bb.booking_datetime asc)', [QuotedStr(student_id),QuotedStr(fee_type)]);
          end;
          ExecSql(pubQuery,strSQL);

          outChild.AddChild('status_flag');
          if pubQuery.RecordCount = 0 then
            outChild.ChildValues['status_flag'] := 0
          else
          begin
            outChild.ChildValues['status_flag'] := 1;
            outChildList := GetCurrXmlNode(outChild,'book_list',xt_outXml);
            BuildBookMsg(outChildList, pubQuery);
          end;
        end;
//        begin
//          strSQL := Format('select tb.* from ('+
//                             'select bb.id as book_id,bpd.id as flow_id,bpd.trade_no,bpd.fee_type,bpd.times,'+
//                             '(select count(*) from buz_exam_info bei where bei.booking_id = bb.id) as use_times '+
//                             'from bas_booking bb,buz_payment_detail bpd '+
//                             'where bb.booking_exam_date = to_char(sysdate, ''yyyymmdd'')'+
//                             'and bb.booking_times > (select count(*) from buz_exam_info bei where bei.booking_id = bb.id) '+
//                             'and bb.student_id = %s '+
//                             'and bpd.booking_id = bb.id '+
//                             'and bpd.fee_type = %s '+
//                             'order by bb.booking_datetime asc'+
//                             ') tb where rownum = 1',[QuotedStr(student_id),QuotedStr(fee_type)]);
//          ExecSql(pubQuery,strSQL);
//          outChild.AddChild('status_flag');
//          if pubQuery.RecordCount = 0 then
//            outChild.ChildValues['status_flag'] := 0
//          else
//          begin
//            outChild.ChildValues['status_flag'] := 1;
//            outChild.AddChild('book_id');
//            outChild.ChildValues['book_id'] := pubQuery.Fields[0].AsString;
//            outSubChild := outChild.AddChild('pay_list');
//            for i := 1 to pubQuery.FieldCount - 1 do
//            begin
//              colNameStr := LowerCase(pubQuery.Fields[i].FieldName);
//              outSubChild.AddChild(colNameStr);
//              outSubChild.ChildValues[colNameStr] := Trim(pubQuery.Fields[i].AsString);
//            end;
//          end;
//        end;
    else
        begin
          UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
          Exit;
        end;
    end;
    UpdateResult(outChildResult,'0','成功');
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM._1008_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild: IXMLNode;
  outRoot, outChildResult, outChild: IXMLNode;
  optype,bookid: Integer;
  subject, trade_no, trade_type, goods_body, student_id, fee_type, fee_times: string;
  fee_amount, rebate_type, rebate_rate, decrease_sum, final_amount, pay_time, memo: string;
  SEQUENCENUMBER,EXAMNUMBER, coach_name, coach_idnumber, coach_id: string;
  strSQL: string;
begin
  Result := 0;
  bookid := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    if inChild.ChildNodes.FindNode('subject') <> nil then
      subject := Trim(inChild.ChildNodes.FindNode('subject').Text);
    if inChild.ChildNodes.FindNode('trade_no') <> nil then
      trade_no := Trim(inChild.ChildNodes.FindNode('trade_no').Text);
    if inChild.ChildNodes.FindNode('trade_type') <> nil then
      trade_type := Trim(inChild.ChildNodes.FindNode('trade_type').Text);
    if inChild.ChildNodes.FindNode('goods_body') <> nil then
      goods_body := Trim(inChild.ChildNodes.FindNode('goods_body').Text);
    if inChild.ChildNodes.FindNode('student_id') <> nil then
      student_id := Trim(inChild.ChildNodes.FindNode('student_id').Text);
    if inChild.ChildNodes.FindNode('fee_type') <> nil then
      fee_type := Trim(inChild.ChildNodes.FindNode('fee_type').Text);
    if inChild.ChildNodes.FindNode('fee_times') <> nil then
      fee_times := Trim(inChild.ChildNodes.FindNode('fee_times').Text);
    if inChild.ChildNodes.FindNode('fee_amount') <> nil then
      fee_amount := Trim(inChild.ChildNodes.FindNode('fee_amount').Text);

    if inChild.ChildNodes.FindNode('rebate_type') <> nil then
      rebate_type := Trim(inChild.ChildNodes.FindNode('rebate_type').Text);
    if inChild.ChildNodes.FindNode('rebate_rate') <> nil then
      rebate_rate := Trim(inChild.ChildNodes.FindNode('rebate_rate').Text);
    if inChild.ChildNodes.FindNode('decrease_sum') <> nil then
      decrease_sum := Trim(inChild.ChildNodes.FindNode('decrease_sum').Text);

    if inChild.ChildNodes.FindNode('final_amount') <> nil then
      final_amount := Trim(inChild.ChildNodes.FindNode('final_amount').Text);

    if inChild.ChildNodes.FindNode('pay_time') <> nil then
      pay_time := Trim(inChild.ChildNodes.FindNode('pay_time').Text);

    if inChild.ChildNodes.FindNode('memo') <> nil then
      memo := Trim(inChild.ChildNodes.FindNode('memo').Text);

    if inChild.ChildNodes.FindNode('coach_name') <> nil then
      coach_name := Trim(inChild.ChildNodes.FindNode('coach_name').Text);
    if inChild.ChildNodes.FindNode('coach_idnumber') <> nil then
      coach_idnumber := Trim(inChild.ChildNodes.FindNode('coach_idnumber').Text);

    strSQL := Format('select * from bas_examiner where idnumber=%s',[QuotedStr(coach_idnumber)]);
    ExecSql(pubQuery,strSQL);
    coach_id := Trim(pubQuery.FieldByName('id').AsString);
    if coach_id = '' then
    begin
      UpdateResult(outChildResult,'1',Format('无该名[%s:%s]教练员信息，请前往后台管理进行身份核实',[coach_name,coach_idnumber]));
      Exit;
    end;
    case optype of
      1:
         begin
           strSQL := 'select SEQU_BAS_BOOKING_ID.Nextval as id from dual';
           if ExecSql(pubQuery,strSQL) then
             bookid := pubQuery.FieldByName('id').AsInteger;
           SEQUENCENUMBER := Format('%s%s',[FormatDateTime('yymmddhhmm',Now),claPublic.GetRandomStr(3,False)]);
           EXAMNUMBER := Format('%s%s',[FormatDateTime('yymmddhhmm',Now),claPublic.GetRandomStr(2,False)]);

           strSQL := Format('insert into BAS_BOOKING '+
                            '(ID,SEQUENCENUMBER,SUBJECT,EXAMNUMBER,STUDENT_ID,'+
                            'BOOKING_DATETIME,BOOKING_TIMES,BOOKING_EXAM_DATE,DRIVER_LICENSE_TYPE,'+
                            'PLACE_ID,OPERATOR_NAME,BRANCH_ADMINISTRATION,examiner1_id,coach,'+
                            'BRANCH_BUSINESS,SIGN_STATUS,UPDATE_TIME) '+
                            'select %d,%s,%s,%s,bs.id,to_char(sysdate, ''yyyymmddhh24miss''),'+
                            '%s,to_char(sysdate, ''yyyymmdd''),bs.DRIVER_LICENSE_TYPE,0,%s,'+
                            '''120000000000'',%s,%s,''120000000000'',''1'',to_char(sysdate, ''yyyymmddhh24miss'') '+
                            'from bas_student bs where bs.id=%s',
                            [bookid,QuotedStr(SEQUENCENUMBER),QuotedStr(subject),
                             QuotedStr(EXAMNUMBER),QuotedStr(fee_times),
                             QuotedStr(coach_name),QuotedStr(coach_id),
                             QuotedStr(coach_idnumber),QuotedStr(student_id)]);
           if not ExecSql(pubQuery,strSQL,False) then
           begin
             UpdateResult(outChildResult,'1',Format('预约信息写入错误',[optype]));
             Exit;
           end;
           strSQL := Format('insert into buz_payment_detail'+
                            '(id,trade_no,trade_type,goods_body,booking_id,fee_type,'+
                            ' fee_times,fee_amount,rebate_type,rebate_rate,decrease_sum,final_amount,'+
                            ' pay_time,memo,hash) '+
                            'values'+
                            '(SEQU_BUZ_PAYMENT_DETAIL_ID.Nextval,'+
                            '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,'' '')',
                            [QuotedStr(trade_no),QuotedStr(trade_type),QuotedStr(goods_body),
                             QuotedStr(IntToStr(bookid)),QuotedStr(fee_type),QuotedStr(fee_times),QuotedStr(fee_amount),
                             QuotedStr(rebate_type),QuotedStr(rebate_rate),QuotedStr(decrease_sum),QuotedStr(final_amount),
                             QuotedStr(pay_time),QuotedStr(memo)]);
           if not ExecSql(pubQuery,strSQL,False) then
           begin
             UpdateResult(outChildResult,'1',Format('支付信息写入错误',[optype]));
             Exit;
           end;

           outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);
           outChild.AddChild('book_id');
           outChild.ChildValues['book_id'] := bookid;
         end;
    else
         begin
           UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
           Exit;
         end;
    end;
    //BUZ_PAYMENT_DETAIL表进行hasd运算
    HashArithmetic('BUZ_PAYMENT_DETAIL',Format('where trade_no=%s',[QuotedStr(trade_no)]));
    UpdateResult(outChildResult,'0','成功');
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM._1009_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot: IXMLNode;
  outRoot, outChildResult, outChild: IXMLNode;
  optype: Integer;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  case optype of
    1:
     begin
       outChild.AddChild('server_time');
       outChild.ChildValues['server_time'] := FormatDateTime('yyyymmddhhmmss',Now);
     end
    else
     begin
       UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
       Exit;
     end;
  end;
  UpdateResult(outChildResult,'0','成功');
end;

function TDM._2001_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
var
  inRoot: IXMLNode;
  inChild: IXMLNode;
  outRoot, outChildResult, outChild: IXMLNode;
  optype: Integer;
  bookTimes: Integer;
  money: Extended;
  student_idNum: string;
  sql : string;
  sp: TUniStoredProc;
  param: TParam;
  currTim: string;
  recvStr: string;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  case optype of
    1:
       begin
         inChild := GetCurrXmlNode(inRoot,'info');
         if inChild <> nil then
         begin
          if inChild.ChildNodes.FindNode('student_idnumber') <> nil then
            student_idNum := Trim(inChild.ChildNodes.FindNode('student_idnumber').Text);
          if inChild.ChildNodes.FindNode('train_times') <> nil then
            bookTimes := StrToInt(Trim(inChild.ChildNodes.FindNode('train_times').Text));

          sql:='select * from bas_student where idnumber='+QuotedStr(student_idNum);
          if ExecSql(pubQuery, sql, True) then
          if pubQuery.RecordCount=0 then
          begin
             UpdateResult(outChildResult,'1','学员未注册');
             exit;
          end;

          if not DBConnect.Connected then
            DBConnect.Connect;

          spSql.Close;
          spSql.Connection.Server := DBConnect.Server;
          spSql.Connection.ProviderName :=DBConnect.ProviderName;
          spSql.Connection.Password := DBConnect.Password;
          spSql.Connection.Username := DBConnect.Username;
          spSql.Connection.Connect;
          spSql.CreateProcCall('GetPriceByTimes');
          spSql.Prepare;

          spSql.ParamByName('result').ParamType := TParamType.ptResult;
          spSql.ParamByName('message').ParamType := TParamType.ptOutput;
          spSql.ParamByName('times').ParamType := TParamType.ptInput;
          spSql.ParamByName('startTime').ParamType := TParamType.ptInput;
          spSql.ParamByName('schoolName').ParamType := TParamType.ptInput;
          spSql.ParamByName('studentIDNumber').ParamType := TParamType.ptInput;

          DateTimeToString(currTim, 'yyyymmddhhnnss', Now);
          spSql.ParamByName('startTime').Value := currTim;
          spSql.ParamByName('times').Value := bookTimes;
          spSql.ParamByName('schoolName').Value := '';
          spSql.ParamByName('studentIDNumber').Value := student_idNum;

          spSql.ExecProc;
          DBConnect.Disconnect;

          recvStr := spSql.ParamByName('message').Value;
          //查询价钱
          money := StrToFloat(spSql.ParamByName('result').Value);

          outChild.AddChild('student_idnumber');
          outChild.ChildValues['student_idnumber'] := student_idNum;
          outChild.AddChild('times');
          outChild.ChildValues['times'] := bookTimes;
          outChild.AddChild('cost');
          outChild.ChildValues['cost'] := money;//

          UpdateResult(outChildResult,'0','查询成功');
         end else
         begin
          UpdateResult(outChildResult,'1','请求信息缺失');
          Exit
         end;
       end
  else
       begin
         UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
         Exit;
       end;
  end;
  UpdateResult(outChildResult,'0','成功');
end;

function TDM._2002_XMLEvent(inXmldoc : IXMLDocument; var outXMLDoc : IXMLDocument) : Integer;
var
  inRoot: IXMLNode;
  inChild: IXMLNode;
  outRoot, outChildResult, outChild: IXMLNode;
  optype: Integer;
  coachIdNum: string;
  password: string;
  bookInfo: string;
  studIDNum: string;
  subjectName: string;
  times: string;
  amount: string;
  paymentWay: string;
  hostIP: string;
  hostMAC: string;
  param: TParam;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);
  outChild := GetCurrXmlNode(outRoot,'info',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  case optype of
    1,2:
       begin
         inChild := GetCurrXmlNode(inRoot,'info');
         if inChild <> nil then
         begin
           if (inChild.ChildNodes.FindNode('coach_idnumber') <> nil) then
            coachIdNum := Trim(inChild.ChildNodes.FindNode('coach_idnumber').Text);
           if (inChild.ChildNodes.FindNode('password') <> nil) then
            password := Trim(inChild.ChildNodes.FindNode('password').Text);
            if (inChild.ChildNodes.FindNode('studentIdNum') <> nil) then
            studIDNum := Trim(inChild.ChildNodes.FindNode('studentIdNum').Text);
            if (inChild.ChildNodes.FindNode('subjectName') <> nil) then
            subjectName := Trim(inChild.ChildNodes.FindNode('subjectName').Text);
            if (inChild.ChildNodes.FindNode('times') <> nil) then
            times := Trim(inChild.ChildNodes.FindNode('times').Text);
            if (inChild.ChildNodes.FindNode('amount') <> nil) then
            amount := Trim(inChild.ChildNodes.FindNode('amount').Text);
            if (inChild.ChildNodes.FindNode('paymentWay') <> nil) then
            paymentWay := Trim(inChild.ChildNodes.FindNode('paymentWay').Text);
            if (inChild.ChildNodes.FindNode('hostIP') <> nil) then
            hostIP := Trim(inChild.ChildNodes.FindNode('hostIP').Text);
            if (inChild.ChildNodes.FindNode('hostMAC') <> nil) then
            hostMAC := Trim(inChild.ChildNodes.FindNode('hostMAC').Text);

            if not DBConnect.Connected then
              DBConnect.Connect;

            spSql.Close;
            spSql.Connection.Server := DBConnect.Server;
            spSql.Connection.ProviderName :=DBConnect.ProviderName;
            spSql.Connection.Password := DBConnect.Password;
            spSql.Connection.Username := DBConnect.Username;
            spSql.Connection.Connect;
            if optype = 2 then
              spSql.CreateProcCall('BookFromVehicle')
            else
              spSql.CreateProcCall('BookFromVehicleNoPassword');
            spSql.Prepare;

            spSql.ParamByName('result').ParamType := TparamType.ptResult;
            spSql.ParamByName('message').ParamType := TparamType.ptOutput;
            spSql.ParamByName('bookingID').ParamType := TparamType.ptOutput;
            spSql.ParamByName('operatorIDNumber').ParamType := TparamType.ptInput;
            spSql.ParamByName('operatorIDNumber').Value := coachIdNum;
            if optype = 2 then
            begin
              spSql.ParamByName('operatorPasswordSha1').ParamType := TparamType.ptInput;
              spSql.ParamByName('operatorPasswordSha1').Value := password;
            end;
            spSql.ParamByName('studentIDNumber').ParamType := TparamType.ptInput;
            spSql.ParamByName('studentIDNumber').Value := studIDNum;
            spSql.ParamByName('subjectName').ParamType := TparamType.ptInput;
            spSql.ParamByName('subjectName').Value := '科目二';
            spSql.ParamByName('times').ParamType := TparamType.ptInput;
            spSql.ParamByName('times').Value := times;
            spSql.ParamByName('amount').ParamType := TparamType.ptInput;
            spSql.ParamByName('amount').Value := amount;
            spSql.ParamByName('paymentWay').ParamType := TparamType.ptInput;
            spSql.ParamByName('paymentWay').Value := '微信支付';
            spSql.ParamByName('hostIP').ParamType := TparamType.ptInput;
            spSql.ParamByName('hostIP').Value := hostIP;
            spSql.ParamByName('hostMAC').ParamType := TparamType.ptInput;
            spSql.ParamByName('hostMAC').Value := hostMAC;

            spSql.ExecProc;
            DBConnect.Disconnect;
           if Trim(spSql.ParamByName('result').Value) = '-1' then
           begin
             UpdateResult(outChildResult,'1','操作员不存在');
             Exit
           end
           else if Trim(spSql.ParamByName('result').Value) = '-2' then
           begin
             UpdateResult(outChildResult,'2','密码不正确');
             Exit
           end
           else if Trim(spSql.ParamByName('result').Value) = '-3' then
           begin
             UpdateResult(outChildResult,'3','学员不存在');
             Exit
           end
           else if Trim(spSql.ParamByName('result').Value) = '-4' then
           begin
             UpdateResult(outChildResult,'3','金额不正确');
             Exit
           end;

           //查询支付信息
           bookInfo := Trim(spSql.ParamByName('message').Value);//返回支付信息

           outChild.AddChild('coach_idnumber');
           outChild.ChildValues['coach_idnumber'] := coachIdNum;
           outChild.AddChild('book_id');
           outChild.ChildValues['book_id'] := Trim(spSql.ParamByName('bookingID').Value);
           outChild.AddChild('book_info');
           outChild.ChildValues['book_info'] := bookInfo;

           UpdateResult(outChildResult,'0','预约成功');
         end else
         begin
          UpdateResult(outChildResult,'1','请求信息缺失');
          Exit
         end;
       end;
  else
       begin
         UpdateResult(outChildResult,'1',Format('操作类型不符:%d',[optype]));
         Exit;
       end;
  end;
  UpdateResult(outChildResult,'0','成功');
end;

function TDM._3001_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
begin
  Result := 0;
end;

function TDM._4001_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
var
  inRoot, inChild: IXMLNode;
  outRoot, outChildResult: IXMLNode;
//  optype: Integer;
begin
  Result := 0;
  outRoot := outXMLDoc.ChildNodes.FindNode('root');
  outChildResult := GetCurrXmlNode(outRoot,'result',xt_outXml);

  inRoot := inXMLDoc.ChildNodes.FindNode('root');
  try
//    optype := StrToInt(Trim(inRoot.ChildNodes['optype'].Text));
  except
    UpdateResult(outChildResult,'1','操作类型异常');
    Exit;
  end;
  inChild := GetCurrXmlNode(inRoot,'info');
  if inChild <> nil then
  begin
    //
  end else
  begin
    UpdateResult(outChildResult,'1','请求信息缺失');
    Exit;
  end;
end;

function TDM._4002_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
begin
  Result := 0;
end;

function TDM._4003_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
begin
  Result := 0;
end;

function TDM._4004_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
begin
  Result := 0;
end;

function TDM._5001_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
begin
  Result := 0;
end;

function TDM._6001_XMLEvent(inXmldoc: IXMLDocument;
  var outXMLDoc: IXMLDocument): Integer;
begin
  Result := 0;
end;

end.
