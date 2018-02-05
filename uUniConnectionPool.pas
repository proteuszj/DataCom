unit uUniConnectionPool;

interface

uses
  Classes, DB, uConnectionPool, Uni;

type
  TUniPoolConnection = class(TPoolConnection)
  protected
    procedure Lock; override;
    procedure Unlock; override;
    function CreateConnection: TCustomConnection; override;
  end;

  TUniConnectionPool = class(TCustomConnectionPool)
  private
    FProviderName: string;
    FPassword: string;
    FUsername: string;
    FServer: string;
    FConnectionTimeOut: string;
    FUnicodeEnvironment: string;
    FCharset: string;
    FuseUnicode: string;
    FDirect: string;
    FConnectMode: string;
  protected
    function GetPoolItemClass: TPoolConnectionClass; override;
  public
    constructor Create(aOwner: TComponent); override;
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
   published
      property Direct: string read FDirect write FDirect;
      property ConnectMode: string read FConnectMode write FConnectMode;
      property ConnectionTimeOut: string read FConnectionTimeOut write FConnectionTimeOut;
      property Charset: string read FCharset write FCharset;
      property UnicodeEnvironment: string read FUnicodeEnvironment write FUnicodeEnvironment;
      property useUnicode: string read FuseUnicode write FuseUnicode;
      property ProviderName: string read FProviderName write FProviderName;
      property Server: string read FServer write FServer;
      property Username: string read FUsername write FUsername;
      property Password: string read FPassword write FPassword;

      property MaxConnections;
      property OnLockConnection;
      property OnUnlockConnection;
      property OnCreateConnection;
      property OnLockFail;
      property OnFreeConnection;
  end;

implementation

uses
  SysUtils;

{ TUniPoolConnection }

function TUniPoolConnection.CreateConnection: TCustomConnection;
begin
  Result:= TUniConnection.Create(nil);
  with Result as TUniConnection do
  begin
    LoginPrompt := false;
    ProviderName :=  TUniConnectionPool(TPoolConnections(Collection).Owner).ProviderName;
    SpecificOptions.Values['Direct'] := TUniConnectionPool(TPoolConnections(Collection).Owner).Direct;
    SpecificOptions.Values['ConnectMode'] := TUniConnectionPool(TPoolConnections(Collection).Owner).ConnectMode;
    SpecificOptions.Values['ConnectionTimeOut'] := TUniConnectionPool(TPoolConnections(Collection).Owner).ConnectionTimeOut;
    SpecificOptions.Values['Charset'] := TUniConnectionPool(TPoolConnections(Collection).Owner).Charset;
    SpecificOptions.Values['UnicodeEnvironment'] := TUniConnectionPool(TPoolConnections(Collection).Owner).UnicodeEnvironment;
    SpecificOptions.Values['useUnicode'] := TUniConnectionPool(TPoolConnections(Collection).Owner).useUnicode;
    Password := TUniConnectionPool(TPoolConnections(Collection).Owner).Password;
    Username := TUniConnectionPool(TPoolConnections(Collection).Owner).Username;
    Server   := TUniConnectionPool(TPoolConnections(Collection).Owner).Server;
  end;
end;

procedure TUniPoolConnection.Lock;
begin
  inherited;
  (Connection as TUniConnection).StartTransaction;
end;

procedure TUniPoolConnection.Unlock;
begin
  inherited;
  if (Connection as TUniConnection).InTransaction then
  try
    (Connection as TUniConnection).Commit;
  except
    (Connection as TUniConnection).Rollback;
  end;
end;

{ TUniConnectionPool }

procedure TUniConnectionPool.Assign(Source: TPersistent);
begin
  if Source is TUniConnection then
  begin
    Direct := TUniConnection(Source).SpecificOptions.Values['Direct'];
    ConnectMode := TUniConnection(Source).SpecificOptions.Values['ConnectMode'];
    ConnectionTimeOut := TUniConnection(Source).SpecificOptions.Values['ConnectionTimeOut'];
    Charset := TUniConnection(Source).SpecificOptions.Values['Charset'];
    UnicodeEnvironment := TUniConnection(Source).SpecificOptions.Values['UnicodeEnvironment'];
    useUnicode := TUniConnection(Source).SpecificOptions.Values['useUnicode'];
    ProviderName := TUniConnection(Source).ProviderName;
    Password := TUniConnection(Source).Password;
    Username := TUniConnection(Source).Username;
    Server   := TUniConnection(Source).Server;
  end
  else
    inherited;
end;

procedure TUniConnectionPool.AssignTo(Dest: TPersistent);
begin
  if Dest is TUniConnectionPool then
  begin
    TCustomConnectionPool(Dest).MaxConnections:= MaxConnections;
    TUniConnectionPool(Dest).Direct := Direct;
    TUniConnectionPool(Dest).ConnectMode := ConnectMode;
    TUniConnectionPool(Dest).ConnectionTimeOut := ConnectionTimeOut;
    TUniConnectionPool(Dest).Charset := Charset;
    TUniConnectionPool(Dest).UnicodeEnvironment := UnicodeEnvironment;
    TUniConnectionPool(Dest).useUnicode := useUnicode;
    TUniConnectionPool(Dest).ProviderName:= ProviderName;
    TUniConnectionPool(Dest).Password:= Password;
    TUniConnectionPool(Dest).Username:= Username;
    TUniConnectionPool(Dest).Server:= Server;
  end
  else
  if Dest is TUniConnection then
  begin
    TUniConnection(Dest).SpecificOptions.Values['Direct'] := Direct;
    TUniConnection(Dest).SpecificOptions.Values['ConnectMode'] := ConnectMode;
    TUniConnection(Dest).SpecificOptions.Values['ConnectionTimeOut'] := ConnectionTimeOut;
    TUniConnection(Dest).SpecificOptions.Values['Charset'] := Charset;
    TUniConnection(Dest).SpecificOptions.Values['UnicodeEnvironment'] := UnicodeEnvironment;
    TUniConnection(Dest).SpecificOptions.Values['useUnicode'] := useUnicode;
    TUniConnection(Dest).ProviderName := ProviderName;
    TUniConnection(Dest).Password := Password;
    TUniConnection(Dest).Username := Username;
    TUniConnection(Dest).Server := Server;
  end
  else
    inherited;
end;

constructor TUniConnectionPool.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FDirect := 'True';
  FConnectMode := 'cmNormal';
  FConnectionTimeOut := '0';
  FCharset := 'ZHS16GBK';
  FUnicodeEnvironment := 'True';
  FuseUnicode := 'True';
  FProviderName := '';
  FPassword := '';
  FUsername := '';
  FServer   := '';
end;

function TUniConnectionPool.GetPoolItemClass: TPoolConnectionClass;
begin
  Result:= TUniPoolConnection;
end;

end.
