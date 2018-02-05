unit UMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OracleUniProvider, SQLServerUniProvider, DB, DBAccess, Uni, ActiveX,
  IdContext, IdBaseComponent, IdComponent, IdCustomTCPServer, IdTCPServer,
  uConnectionPool, uUniConnectionPool, StdCtrls, ExtCtrls, ComCtrls, RzPrgres,
  RzStatus, jpeg, XMLIntf, XMLDoc, Grids, DBGrids, MemDS, UniProvider,
  CoolTrayIcon, Menus, ImgList;

const
  con_ConfigFile  = '.\Config.xml';
  CM_RESTORE = WM_USER + $1000; {自定义的"恢复"消息}
  APPNAME = 'DCOMM-V2.0.1031.1';

type
  TfrmMain = class(TForm)
    TCPServer: TIdTCPServer;
    pnlImage: TPanel;
    pnlClient: TPanel;
    StatusBar: TStatusBar;
    pnlState: TPanel;
    labNote: TLabel;
    labThreadState: TLabel;
    labThreadMax: TLabel;
    labDBPoolState: TLabel;
    ShapeLine: TShape;
    labDBPoolMax: TLabel;
    MemoLog: TMemo;
    pbThreadState: TRzProgressBar;
    pbDBPoolState: TRzProgressBar;
    ImgBackground: TImage;
    TimerSecurity: TTimer;
    TimerClearLocalFile: TTimer;
    ImgListF: TImageList;
    ImgListJ: TImageList;
    pmMenu: TPopupMenu;
    nShowWindow: TMenuItem;
    nLine: TMenuItem;
    nExit: TMenuItem;
    Icon: TCoolTrayIcon;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerSecurityTimer(Sender: TObject);
    procedure TCPServerConnect(AContext: TIdContext);
    procedure TCPServerDisconnect(AContext: TIdContext);
    procedure TCPServerExecute(AContext: TIdContext);
    procedure TimerClearLocalFileTimer(Sender: TObject);
    procedure IconStartup(Sender: TObject; var ShowMainForm: Boolean);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure IconMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure nShowWindowClick(Sender: TObject);
    procedure nExitClick(Sender: TObject);
    procedure TCPServerException(AContext: TIdContext; AException: Exception);
    procedure TCPServerListenException(AThread: TIdListenerThread;
      AException: Exception);
  private
    { Private declarations }
    TcpPort: Integer;                   //TCP通讯端口
    TcpMaxConnections: Integer;         //TCP最大连接数
    DBIP: string;                       //数据库地址
    DBPort: Integer;                    //数据库端口
    DBSID: string;                      //数据库实例名
    DBUser: string;                     //数据库用户
    DBPwd: string;                      //数据库用户登录密码
    DBMaxConnections : Integer;         //数据库最大数据库连接数
    DBConnectionTimeout : Integer;      //数据库连接超时时长(单位:秒)
    SysSecurityTime: Integer;           //系统安全运行时间(单位:时)
    UniConnectPool: TUniConnectionPool; //数据库连接池
    boolDBConnect: Boolean;             //数据库连接状态 true-已连接 false-未连接
    //获取支撑系统运行的配置参数
    function GetConfigParam() : Integer;
    //初始窗口资源
    procedure InitFormResource();
    //保持系统安全运行时间 StateFlag: 0-初始状态；1-累计状态
    procedure KeepSysSecurityTime(StateFlag: Integer);
    //初始TCP通讯
    function InitTCPCommunication(): Boolean;
    //释放TCP通讯
    procedure FreeTCPCommunication();
    //初始数据库连接池
    function InitDBPoolConnnect(): Boolean;
    //释放数据库连接池
    procedure FreeDBPoolConnnect();
    //注册的数据库连接时事件
    procedure CreateConnection(Sender: TObject);
    procedure LockConnection(Sender: TObject);
    procedure UnlockConnection(Sender: TObject);
    procedure Log(const title: string; const message: string);
  public
    { Public declarations }
    SessionEnding: Boolean;
    DefaultformHide: string;    // 窗口是否显示 0-显示 1-隐藏

    {*****防止二次启动******}
    procedure CreateParams(var Params: TCreateParams); override;           //指定窗口名称
    Procedure RestoreRequest(var message: TMessage); message CM_RESTORE;   //处理"恢复"消息

    procedure WMQueryEndSession(var Message: TMessage); message WM_QUERYENDSESSION;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  UThreadProcess, UPublic, UEncryptSDK;

{$R *.dfm}

procedure TfrmMain.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WinClassName := APPNAME;
end;

procedure TfrmMain.RestoreRequest(var message: TMessage);
begin
  if IsIconic(Application.Handle) = TRUE then
    Application.Restore
  else
    Application.BringToFront;
end;

procedure TfrmMain.CreateConnection(Sender: TObject);
var
  tmpLog: string;
begin
  with Sender as TCustomConnectionPool do
  begin
    tmpLog := Format('DB Connection created. Free %d from %d connections.',
                     [UnusedConnections, TotalConnections]);
//    MemoLog.Lines.Add(tmpLog);
//    claPublic.WriteLog('DBPool',tmpLog);
    Log('DBPool',tmpLog);
  end;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := SessionEnding;
  if not CanClose then
  begin
    icon.HideMainForm;
    icon.IconVisible := True;
    Exit;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  InfoSize: Integer;
  Wnd: DWORD;
  VerBuf: Pointer;
  VerInfo: ^VS_FIXEDFILEINFO;
begin
  InfoSize:=GetFileVersionInfoSize(PChar(Application.ExeName), Wnd);
  if InfoSize<>0 then
  begin
    GetMem(VerBuf, InfoSize);
    try
      if GetFileVersionInfo(PChar(Application.ExeName), Wnd, InfoSize, VerBuf) then
      begin
        VerInfo:=nil;
        VerQueryValue(VerBuf, '\', Pointer(VerInfo), Wnd);
        if VerInfo<>nil then
          Caption:=Format('%s v%d.%d.%d.%d', [Caption, VerInfo^.dwFileVersionMS shr 16, VerInfo^.dwFileVersionMS and $ffff, VerInfo^.dwFileVersionLS shr 16, VerInfo^.dwFileVersionLS and $FFFF]);
      end;      
    finally
      FreeMem(VerBuf, InfoSize);
    end;
  end;

  Icon.CycleIcons := False; //  Icon.CycleIcons := True;
  Icon.IconList := nil;     //  Icon.IconList := ImgListF;
  ImgListJ.GetIcon(0, Icon.Icon);

  TimerClearLocalFile.Enabled := True;
  boolDBConnect := False;
  if GetConfigParam = 0 then
  begin
    InitFormResource;
    InitTCPCommunication;
    InitDBPoolConnnect;
  end;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeTCPCommunication;
  FreeDBPoolConnnect;
end;

procedure TfrmMain.FreeDBPoolConnnect;
begin
  UniConnectPool.Free;
end;

procedure TfrmMain.FreeTCPCommunication;
begin
  TCPServer.Active := False;
end;

function TfrmMain.GetConfigParam: Integer;
var
  ConfigXmlDoc: IXMLDocument;
  root, child: IXMLNode;
begin
  Result := -1;
  if FileExists(con_ConfigFile) then
  begin
    ConfigXmlDoc := TXMLDocument.Create(nil);
    try
      ConfigXmlDoc.XML.Clear;
      ConfigXmlDoc.Active := true;
      ConfigXmlDoc.LoadFromFile(con_ConfigFile);
      root := ConfigXmlDoc.ChildNodes.FindNode('root');
      if root <> nil then
      begin
        try
          //TCP Param
          child := root.ChildNodes.FindNode('tcp');
          if child <> nil then
          begin
            if child.ChildNodes.FindNode('port') <> nil then
              TcpPort := StrToInt(Trim(child.ChildNodes['port'].Text))
            else
              TcpPort := 8899;
            if child.ChildNodes.FindNode('maxconnections') <> nil then
              TcpMaxConnections := StrToInt(Trim(child.ChildNodes['maxconnections'].Text))
            else
              TcpMaxConnections := 10;
          end;
          //DB Param
          child := root.ChildNodes.FindNode('database');
          if child <> nil then
          begin
            if child.ChildNodes.FindNode('dbip') <> nil then
              DBIP := Des_Decrypt(Trim(child.ChildNodes['dbip'].Text))
            else
              DBIP := '127.0.0.1';
            if child.ChildNodes.FindNode('dbport') <> nil then
              DBPort := StrToInt(Des_Decrypt(Trim(child.ChildNodes['dbport'].Text)))
            else
              DBPort := 1521;
            if child.ChildNodes.FindNode('dbsid') <> nil then
              DBSID := Des_Decrypt(Trim(child.ChildNodes['dbsid'].Text))
            else
              DBSID := 'orcl';
            if child.ChildNodes.FindNode('dbuser') <> nil then
              DBUser := Des_Decrypt(Trim(child.ChildNodes['dbuser'].Text))
            else
              DBUser := '';
            if child.ChildNodes.FindNode('dbpwd') <> nil then
              DBPwd := Des_Decrypt(Trim(child.ChildNodes['dbpwd'].Text))
            else
              DBPwd := '';
            if child.ChildNodes.FindNode('maxconnections') <> nil then
              DBMaxConnections := StrToInt(Trim(child.ChildNodes['maxconnections'].Text))
            else
              DBMaxConnections := 10;
            if child.ChildNodes.FindNode('connectiontimeout') <> nil then
              DBConnectionTimeout := StrToInt(Trim(child.ChildNodes['connectiontimeout'].Text))
            else
              DBConnectionTimeout := 10;
          end;
          //Other Param
          child := root.ChildNodes.FindNode('mode');
          if child <> nil then
          begin
            if child.ChildNodes.FindNode('exammode') <> nil then
              claPublic.IsExamMode := Trim(child.ChildNodes['exammode'].Text)
            else
              claPublic.IsExamMode := '0';
            if child.ChildNodes.FindNode('debug') <> nil then
              claPublic.IsDebug := Trim(child.ChildNodes['debug'].Text)
            else
              claPublic.IsDebug := '0';
          end;
          Result := 0;
        except
          Exit;
        end;
      end;
    finally
      ConfigXmlDoc := nil;
    end;
  end;
end;

procedure TfrmMain.IconMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(pmMenu) then
    if not pmMenu.AutoPopup then
    begin
      SetForegroundWindow(Application.Handle);
    end;
end;

procedure TfrmMain.IconStartup(Sender: TObject; var ShowMainForm: Boolean);
begin
  if DefaultformHide <> '0' then
    ShowMainForm := True
  else
    ShowMainForm := False;
end;

function TfrmMain.InitDBPoolConnnect: Boolean;
var
  UniConnection : TCustomConnection;
  NeedUninitialize : Boolean;
  tmpLog: string;
  Query : TUniQuery;
begin
  NeedUninitialize:= Succeeded(CoInitialize(nil));
  try
    Result := False;
    try
      if UniConnectPool = nil then
        UniConnectPool := TUniConnectionPool.Create(nil);
      UniConnectPool.OnCreateConnection := CreateConnection;
      UniConnectPool.OnLockConnection := LockConnection;
      UniConnectPool.OnUnlockConnection := UnlockConnection;
      UniConnectPool.MaxConnections := DBMaxConnections;
      UniConnectPool.ProviderName := 'oracle';
      UniConnectPool.ConnectionTimeOut := IntToStr(DBConnectionTimeout);
      UniConnectPool.Server := Format('%s:%d:%s',[DBIP,DBPort,DBSID]);
      UniConnectPool.Username := DBUser;
      UniConnectPool.Password := DBPwd;
    except
    end;

    try
      UniConnection := UniConnectPool.GetConnection;
      boolDBConnect := False;
      if not UniConnection.Connected then
      begin
        tmpLog := Format('Connect DataBase Fail at Time [%s]', [FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz', now)]);
//        MemoLog.Lines.Add(tmpLog);
//        claPublic.WriteLog('DBPool',tmpLog);
        Log('DBPool',tmpLog);
        exit;
      end;
    except
      tmpLog := Format('Connect DataBase Error at Time [%s]', [FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz', now)]);
//      MemoLog.Lines.Add(tmpLog);
//      claPublic.WriteLog('DBPool',tmpLog);
      Log('DBPool',tmpLog);
      Exit;
    end;
    boolDBConnect := True;
    Result := True;

    if Assigned(UniConnection) then
    begin
      Query := TUniQuery.Create(nil);
      with Query do
      begin
        Connection := UniConnection as TUniConnection;
        if claPublic.IsExamMode = '0' then
        begin
//          SQL.Text := 'update bas_booking bb set bb.booking_exam_date=to_char(sysdate,''yyyymmdd'')';
//          ExecSQL;
//          Close;
        end else
        begin
          Close;
          SQL.Clear;
          SQL.Text := 'select param_name,param_value from cfg_param where subsys_id=2 and is_admin_param=1';
          Open;
          First;
          while not Eof do
          begin
            if UpperCase(Trim(Fields[0].AsString)) = 'WEB_SYSCLASS' then
              claPublic.WEB_SYSCLASS := Trim(Fields[1].AsString);
            if UpperCase(Trim(Fields[0].AsString)) = 'WEB_SERIALNUMBER' then
              claPublic.WEB_SERIALNUMBER := Trim(Fields[1].AsString);
            if UpperCase(Trim(Fields[0].AsString)) = 'WEB_URL' then
              claPublic.WEB_URL := Trim(Fields[1].AsString);
            if UpperCase(Trim(Fields[0].AsString)) = 'WEB_SYSNUMBER' then
              claPublic.WEB_SYSNUMBER := Trim(Fields[1].AsString);
            Next;
          end;
        end;
      end;
      FreeAndNil(Query);
    end;
  finally
    if boolDBConnect then
      UniConnectPool.FreeConnection(UniConnection);
    if NeedUninitialize then
      CoUninitialize;
  end;
end;

procedure TfrmMain.InitFormResource;
begin
  labThreadMax.Caption := Format(labThreadMax.Caption,[TcpMaxConnections]);
  labDBPoolMax.Caption := Format(labDBPoolMax.Caption,[DBMaxConnections]);
  pbThreadState.Percent := 0;
  pbDBPoolState.Percent := 0;
  StatusBar.Panels[0].Text := Format(StatusBar.Panels[0].Text,[FormatDateTime('yyyy-mm-dd hh:mm:ss',Now)]);
//  claPublic.WriteLog('Start',Trim(StatusBar.Panels[0].Text));
  Log('Start',Trim(StatusBar.Panels[0].Text));
  SysSecurityTime := 0;
  KeepSysSecurityTime(0);
end;

function TfrmMain.InitTCPCommunication: Boolean;
begin
  try
    TCPServer.DefaultPort := TcpPort;
    TCPServer.Active := True;
    Result := True;
  except
    Result := False;
  end;
end;

procedure TfrmMain.KeepSysSecurityTime(StateFlag: Integer);
begin
  case StateFlag of
    1 : Inc(SysSecurityTime);
  end;
  StatusBar.Panels[1].Text := Format(StatusBar.Panels[1].Text,[IntToStr(SysSecurityTime)]);
//  claPublic.WriteLog('Run',Trim(StatusBar.Panels[1].Text));
  Log('Run',Trim(StatusBar.Panels[1].Text));
end;

procedure TfrmMain.LockConnection(Sender: TObject);
var
  tmpLog: string;
begin
  with Sender as TCustomConnectionPool do
  begin
    pbDBPoolState.Percent := TotalConnections;
    tmpLog := Format('DB Connection locked. Free %d from %d connections.',
                     [UnusedConnections, TotalConnections]);
//    MemoLog.Lines.Add(tmpLog);
//    claPublic.WriteLog('DBPool',tmpLog);
    Log('DBPool',tmpLog);
  end;
end;

procedure TfrmMain.nExitClick(Sender: TObject);
begin
  icon.IconVisible := False;
  SessionEnding := True;
  Close;
end;

procedure TfrmMain.nShowWindowClick(Sender: TObject);
begin
  if nShowWindow.Visible then
    icon.ShowMainForm;
end;

procedure TfrmMain.TCPServerConnect(AContext: TIdContext);
var
  CurrThread : TThreadProcess;
  tmpLog: string;
begin
  CurrThread := TThreadProcess.Create(AContext);
  AContext.Data := CurrThread;
  tmpLog := Format('TCP Connect Time[%s] Handle[%.6d] IP[%s]',
                  [FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz', now),
                   AContext.Connection.Socket.Binding.Handle,
                   AContext.Connection.Socket.Binding.PeerIP]);
  pbThreadState.Percent := TThreadProcess.GetThreadCount;
//  claPublic.WriteLog('Thread',tmpLog);
  Log('Thread',tmpLog);
end;

procedure TfrmMain.TCPServerDisconnect(AContext: TIdContext);
var
  tmpLog: string;
begin
  tmpLog := Format('TCP Disconnect Time[%s] Handle[%.6d] IP[%s]',
                  [FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz', now),
                   AContext.Connection.Socket.Binding.Handle,
                   AContext.Connection.Socket.Binding.PeerIP]);
//  claPublic.WriteLog('Thread',tmpLog);
  Log('Thread',tmpLog);
  TThreadProcess(AContext.Data).Free;
  pbThreadState.Percent := TThreadProcess.GetThreadCount;
  AContext.Data := Nil;
end;

procedure TfrmMain.TCPServerException(AContext: TIdContext;
  AException: Exception);
var
  tmpLog: string;
begin
  tmpLog := Format('TCP Exception Time[%s] Handle[%.6d] IP[%s]: [%s]',
                  [FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz', now),
                   AContext.Connection.Socket.Binding.Handle,
                   AContext.Connection.Socket.Binding.PeerIP,
                   AException.Message]);
  Log('Thread', tmpLog);
end;

procedure TfrmMain.TCPServerExecute(AContext: TIdContext);
var
  NeedUninitialize : Boolean;
  CurrUniConnection: TCustomConnection;
  tmpLog: string;
begin
  NeedUninitialize:= Succeeded(CoInitialize(nil));
  try
    try
      CurrUniConnection := UniConnectPool.GetConnection;
    except
    end;
    if (CurrUniConnection = nil) or ( not boolDBConnect) then
    begin
      if InitDBPoolConnnect then
         CurrUniConnection := UniConnectPool.GetConnection;
    end;
    try
      if Assigned(CurrUniConnection) then
      begin
        {------开启线程------}
        tmpLog := Format('TCP Execute Time[%s] Handle[%.6d] IP[%s]',
                        [FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz', now),
                         AContext.Connection.Socket.Binding.Handle,
                         AContext.Connection.Socket.Binding.PeerIP]);
//        if MemoLog.Lines.Count > 100 then
//          MemoLog.Lines.Clear;
//        MemoLog.Lines.Add(tmpLog);
//        claPublic.WriteLog('Thread',tmpLog);
        Log('Thread',tmpLog);
        TThreadProcess(AContext.Data).Process(CurrUniConnection as TUniConnection);
        pbThreadState.Percent := TThreadProcess.GetThreadCount;
      end;
    finally
      UniConnectPool.FreeConnection(CurrUniConnection);
    end;
  finally
    if NeedUninitialize then
      CoUninitialize;
  end;
end;

procedure TfrmMain.TCPServerListenException(AThread: TIdListenerThread;
  AException: Exception);
var
  tmpLog: string;
begin
  tmpLog := Format('TCP Exception Time[%s] Handle[%.6d] IP[%s]: [%s]',
                  [FormatDateTime('yyyy-mm-dd hh:mm:ss:zzz', now),
                   AThread.Handle,
                   AThread.Binding.PeerIP,
//                   AContext.Connection.Socket.Binding.Handle,
//                   AContext.Connection.Socket.Binding.PeerIP,
                   AException.Message]);
  Log('Thread', tmpLog);
end;

procedure TfrmMain.TimerClearLocalFileTimer(Sender: TObject);
begin
  TimerClearLocalFile.Enabled := False;
  claPublic.ClearLocalFile(crd_Part,'logs','*.log');
end;

procedure TfrmMain.TimerSecurityTimer(Sender: TObject);
begin
  KeepSysSecurityTime(1);
end;

procedure TfrmMain.UnlockConnection(Sender: TObject);
var
  tmpLog: string;
begin
  with Sender as TCustomConnectionPool do
  begin
    pbDBPoolState.Percent := TotalConnections;
    tmpLog := Format('DB Connection unlocked. Free %d from %d connections.',
                     [UnusedConnections, TotalConnections]);
//    MemoLog.Lines.Add(tmpLog);
//    claPublic.WriteLog('DBPool',tmpLog);
    Log('DBPool',tmpLog);
  end;
end;

procedure TfrmMain.WMQueryEndSession(var Message: TMessage);
begin
  SessionEnding := True;
  Message.Result := 1;
end;

procedure TfrmMain.Log(const title: string; const message: string);
begin
  if MemoLog.Lines.Count > 100 then
    MemoLog.Lines.Clear;
  MemoLog.Lines.Add(message);
  claPublic.WriteLog(title,message);
end;

end.
