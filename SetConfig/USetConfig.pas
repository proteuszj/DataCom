unit USetConfig;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XMLIntf, XMLDoc, RzButton, ExtCtrls, RzPanel, RzLabel, RzSpnEdt,
  StdCtrls, Mask, RzEdit, UniProvider, OracleUniProvider, DB, DBAccess, Uni,
  ImgList;
const
  con_ConfigFile  = '.\Config.xml';
type
  TfrmSetConfig = class(TForm)
    PanelBottom: TRzPanel;
    btnSave: TRzBitBtn;
    btnCancel: TRzBitBtn;
    PanelClient: TRzPanel;
    gbDB: TRzGroupBox;
    labAddress: TLabel;
    labPort: TLabel;
    labDatabase: TLabel;
    labUser: TLabel;
    labpwd: TLabel;
    edtServer: TRzEdit;
    edtDatabase: TRzEdit;
    edtUser: TRzEdit;
    edtpwd: TRzEdit;
    btnDBConn: TRzBitBtn;
    edtPort: TRzSpinEdit;
    gbTCP: TRzGroupBox;
    labTCPPort: TRzLabel;
    edtTCPPort: TRzSpinEdit;
    labDBMaxconn: TRzLabel;
    edtDBMaxconn: TRzSpinEdit;
    labConnTimeOut: TRzLabel;
    edtConnTimeOut: TRzSpinEdit;
    labTCPMaxConn: TRzLabel;
    edtTCPMaxConn: TRzSpinEdit;
    dbconn: TUniConnection;
    OracleUniProvider1: TOracleUniProvider;
    ImageList1: TImageList;
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnDBConnClick(Sender: TObject);
    procedure edtTCPPortKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
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
    IsExamMode: string;                 //是否为考试模式(0:否；1:是)
    function GetConfigParam() : Integer;
    function SetConfigParam() : Integer;
    function ConnectDB(): Boolean;
  public
    { Public declarations }
  end;

var
  frmSetConfig: TfrmSetConfig;

implementation

uses
  UEncryptSDK;

{$R *.dfm}

{ TForm1 }

procedure TfrmSetConfig.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSetConfig.btnDBConnClick(Sender: TObject);
begin
  if not ConnectDB then
  begin
    btnDBConn.ImageIndex := 2;
  end
  else
  begin
    btnDBConn.ImageIndex := 1;
  end;
end;

procedure TfrmSetConfig.btnSaveClick(Sender: TObject);
begin
  if SetConfigParam = 0 then
  begin
    MessageBox(0,PWideChar('保存参数成功'),PWideChar('提示'),MB_ICONINFORMATION+MB_OK);
    Close;
  end else
  begin
    MessageBox(0,PWideChar('保存参数失败'),PWideChar('警告'),MB_ICONWARNING+MB_OK);
  end;
end;

function TfrmSetConfig.ConnectDB: Boolean;
begin
  dbConn.LoginPrompt := False;
  dbConn.Server := Format('%s:%d:%s',[Trim(edtServer.Text),
                                    edtPort.IntValue,
                                    Trim(edtDatabase.Text)]);
  dbConn.Database := Trim(edtDatabase.Text);
  dbConn.Username := Trim(edtUser.Text);
  dbConn.Password := Trim(edtpwd.Text);
  try
    if not dbConn.Connected then
      dbConn.Connect;
  except
  end;
  Result := dbConn.Connected;
end;

procedure TfrmSetConfig.edtTCPPortKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = 13 then
  begin
    PostMessage(self.Handle , WM_KEYDOWN, 9, 0);
  end;
end;

procedure TfrmSetConfig.FormCreate(Sender: TObject);
begin
  if GetConfigParam = 0 then
  begin
    edtTCPPort.Value := TcpPort;
    edtTCPMaxConn.Value := TcpMaxConnections;
    edtServer.Text := DBIP;
    edtPort.Value := DBPort;
    edtDatabase.Text := DBSID;
    edtUser.Text := DBUser;
    edtpwd.Text := DBPwd;
    edtDBMaxconn.Value := DBMaxConnections;
    edtConnTimeOut.Value := DBConnectionTimeout;
  end else
  begin
    edtTCPPort.Value := 0;
    edtTCPMaxConn.Value := 10;
    edtServer.Text := '';
    edtPort.Value := 0;
    edtDatabase.Text := '';
    edtUser.Text := '';
    edtpwd.Text := '';
    edtDBMaxconn.Value := 10;
    edtConnTimeOut.Value := 10;
  end;
end;

function TfrmSetConfig.GetConfigParam: Integer;
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
              IsExamMode := Trim(child.ChildNodes['exammode'].Text)
            else
              IsExamMode := '0';
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

function TfrmSetConfig.SetConfigParam: Integer;
var
  ConfigXmlDoc: IXMLDocument;
  RootNode, SubNode, ChildNode: IXMLNode;
  DBPort: Integer;
begin
  Result := -1;
  ConfigXmlDoc := TXMLDocument.Create(nil);
  try
    ConfigXmlDoc.Active := true;
    ConfigXmlDoc.Version := '1.0';
    ConfigXmlDoc.Encoding := 'UTF-8';
    ConfigXmlDoc.Options := [doNodeAutoIndent];
    RootNode := nil;
    RootNode := ConfigXmlDoc.ChildNodes.FindNode('root');
    if RootNode = nil then
      RootNode := ConfigXmlDoc.AddChild('root');
    try
      //tcp node
      SubNode := nil;
      SubNode := RootNode.ChildNodes.FindNode('tcp');
      if SubNode = nil then
        SubNode := RootNode.AddChild('tcp');

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('port');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('port');
      ChildNode.NodeValue := edtTCPPort.Value;

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('maxconnections');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('maxconnections');
      ChildNode.NodeValue := edtTCPMaxConn.Value;

      //database node
      SubNode := nil;
      SubNode := RootNode.ChildNodes.FindNode('database');
      if SubNode = nil then
        SubNode := RootNode.AddChild('database');

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('dbip');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('dbip');
      ChildNode.NodeValue := Des_Encrypt(Trim(edtServer.Text));

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('dbport');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('dbport');
      ChildNode.NodeValue := Des_Encrypt(Trim(edtPort.Text));

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('dbsid');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('dbsid');
      ChildNode.NodeValue := Des_Encrypt(Trim(edtDatabase.Text));

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('dbuser');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('dbuser');
      ChildNode.NodeValue := Des_Encrypt(Trim(edtUser.Text));

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('dbpwd');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('dbpwd');
      ChildNode.NodeValue := Des_Encrypt(Trim(edtpwd.Text));

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('maxconnections');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('maxconnections');
      ChildNode.NodeValue := edtDBMaxconn.Value;

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('connectiontimeout');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('connectiontimeout');
      ChildNode.NodeValue := edtConnTimeOut.Value;

      //mode node
      SubNode := nil;
      SubNode := RootNode.ChildNodes.FindNode('mode');
      if SubNode = nil then
        SubNode := RootNode.AddChild('mode');

      ChildNode := nil;
      ChildNode := SubNode.ChildNodes.FindNode('exammode');
      if ChildNode = nil then
        ChildNode := SubNode.AddChild('exammode');
      ChildNode.NodeValue := 0;
    except
      Exit;
    end;
    ConfigXmlDoc.SaveToFile(con_ConfigFile);
    Result := 0;
  finally
    ConfigXmlDoc := nil;
  end;
end;

end.
