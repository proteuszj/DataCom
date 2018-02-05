unit uConnectionPool;

interface

uses
  Classes, DB, SyncObjs, SysUtils;

type
  TPoolConnectionClass = class of TPoolConnection;
  TCustomConnectionPool = class;

  TPoolConnection = class(TCollectionItem)
  private
    FBusy: Boolean;
    FConnection: TCustomConnection;
  protected
    procedure Lock; virtual;
    procedure Unlock; virtual;
    function Connected: Boolean; virtual;
    function CreateConnection: TCustomConnection; virtual; abstract;
  public
    property Busy: Boolean read FBusy;
    property Connection: TCustomConnection read FConnection;
    constructor Create(aCollection: TCollection); override;
    destructor Destroy; override;
  end;

  TPoolConnections = class(TOwnedCollection)
  private
    function GetItem(aIndex: Integer): TPoolConnection;
    procedure SetItem(aIndex: Integer; const Value: TPoolConnection);
  public
    property Items[aIndex: LongInt]: TPoolConnection read GetItem write SetItem; default;
    function Add: TPoolConnection;
  {$IFNDEF VER140}
    function Owner: TPersistent;
  {$ENDIF}
  end;
  TExceptionEvent = procedure (Sender: TObject; E: Exception) of object;

  TCustomConnectionPool = class(TComponent)
  private
    FCS: TCriticalSection;
    FConnections: TPoolConnections;
    FMaxConnections: LongInt;
    FOnLockConnection: TNotifyEvent;
    FOnLockFail: TExceptionEvent;
    FOnUnLockConnection: TNotifyEvent;
    FOnCreateConnection: TNotifyEvent;
    FOnFreeConnection: TNotifyEvent;
    function GetUnusedConnections: LongInt;
    function GetTotalConnections: LongInt;
  protected
    function GetPoolItemClass: TPoolConnectionClass; virtual; abstract;
    procedure DoLock; virtual;
    procedure DoLockFail(E: Exception); virtual;
    procedure DoUnlock; virtual;
    procedure DoCreateConnection; virtual;
    procedure DoFreeConnection; virtual;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
    procedure AssignTo(Dest: TPersistent); override;
    property MaxConnections: LongInt read FMaxConnections write FMaxConnections default -1;
    function GetConnection: TCustomConnection;
    procedure FreeConnection(aConnection: TCustomConnection);
    property UnusedConnections: LongInt read GetUnusedConnections;
    property TotalConnections: LongInt read GetTotalConnections;
    property OnLockConnection: TNotifyEvent read FOnLockConnection write FOnLockConnection;
    property OnUnlockConnection: TNotifyEvent read FOnUnlockConnection write FOnUnlockConnection;
    property OnCreateConnection: TNotifyEvent read FOnCreateConnection write FOnCreateConnection;
    property OnLockFail: TExceptionEvent read FOnLockFail write FOnLockFail;
    property OnFreeConnection: TNotifyEvent read FOnFreeConnection write FOnFreeConnection;
  end;

implementation

{$IFDEF TRIAL}
uses
  Windows;
{$ENDIF}

{ TPoolConnection }
{- protected ----------------------------------------------------------------- }
procedure TPoolConnection.Lock;
begin
  FBusy:= true;
  if not Connected then Connection.Open;
  TCustomConnectionPool(TPoolConnections(Collection).Owner).DoLock;
end;

procedure TPoolConnection.Unlock;
begin
  FBusy:= false;
  TCustomConnectionPool(TPoolConnections(Collection).Owner).DoUnLock;
end;

function TPoolConnection.Connected: Boolean;
begin
  Result:= Connection.Connected;
end;

{ - public ------------------------------------------------------------------- }
constructor TPoolConnection.Create(aCollection: TCollection);
begin
  inherited;
  FConnection:= CreateConnection;
  TCustomConnectionPool(TPoolConnections(Collection).Owner).DoCreateConnection;
end;

destructor TPoolConnection.Destroy;
begin
  if Busy then Unlock;
  FreeAndNil(FConnection);
  TCustomConnectionPool(TPoolConnections(Collection).Owner).DoFreeConnection;
  inherited;
end;

{ TPoolConnections }
{ - private ------------------------------------------------------------------ }
function TPoolConnections.GetItem(aIndex: Integer): TPoolConnection;
begin
  Result:= inherited GetItem(aIndex) as TPoolConnection;
end;

procedure TPoolConnections.SetItem(aIndex: Integer;
  const Value: TPoolConnection);
begin
  inherited SetItem(aIndex, Value);
end;

{ - public ------------------------------------------------------------------- }
function TPoolConnections.Add: TPoolConnection;
begin
  Result:= inherited Add as TPoolConnection;
end;

{$IFNDEF VER140}
function TPoolConnections.Owner: TPersistent;
begin
  Result:= GetOwner;
end;
{$ENDIF}

{ TCustomConnectionPool }
{ - private ------------------------------------------------------------------ }
function TCustomConnectionPool.GetUnusedConnections: LongInt;
var
  I: LongInt;
begin
  FCS.Enter;
  Result:= 0;
  try
    for I:= 0 to FConnections.Count - 1 do
      if not FConnections[I].Busy then
        Inc(Result);
  finally
    FCS.Leave;
  end;
end;

function TCustomConnectionPool.GetTotalConnections: LongInt;
begin
  Result:= FConnections.Count;
end;

{ - public ------------------------------------------------------------------- }
constructor TCustomConnectionPool.Create(aOwner: TComponent);
begin
  inherited;
  FCS:= TCriticalSection.Create;
  FConnections:= TPoolConnections.Create(Self, GetPoolItemClass);
  FMaxConnections:= -1;
end;

destructor TCustomConnectionPool.Destroy;
begin
  FCS.Enter;
  try
    FConnections.Free;
//    FreeAndNil(FConnections);
  finally
    FCS.Leave;
  end;
  FreeAndNil(FCS);
  inherited;
end;

procedure TCustomConnectionPool.AssignTo(Dest: TPersistent);
begin
  if Dest is TCustomConnectionPool then
    TCustomConnectionPool(Dest).MaxConnections:= MaxConnections
  else
    inherited AssignTo(Dest);
end;

function TCustomConnectionPool.GetConnection: TCustomConnection;
var
  I: LongInt;
begin
  Result:= nil;
  FCS.Enter;
  try
    try
      I:= 0;
      while I < FConnections.Count do
      begin
        if not FConnections[I].Busy then
        begin
          Result:= FConnections[I].Connection;
          try
            FConnections[I].Lock;
            Break;
          except
            FConnections.Delete(I);
            Continue;
          end;
        end;
        Inc(I);
      end;
      if Result = nil then
        if ((FConnections.Count < MaxConnections) or (MaxConnections = -1))
{$IFDEF TRIAL}
          and ((FindWindow('TAppBuilder', nil) <> 0) or (FConnections.Count  < 3)) {$ENDIF}
        then
        begin
          with FConnections.Add do
          begin
            Result:= Connection;
            Lock;
          end;
        end
        else
          raise Exception.Create('Connection pool limit exceeded.');
    except
      On E: Exception do
        DoLockFail(E);
    end;
  finally
    FCS.Leave;
  end;
end;

procedure TCustomConnectionPool.FreeConnection(aConnection: TCustomConnection);
var
  I: LongInt;
begin
  FCS.Enter;
  try
    for I:= 0 to FConnections.Count - 1 do
      if FConnections[I].Connection = aConnection then
      begin
        FConnections[I].Unlock;
        Break;
      end;
  finally
    FCS.Leave;
  end;
end;

procedure TCustomConnectionPool.DoLock;
begin
  if Assigned(FOnLockConnection) then
    FOnLockConnection(Self);
end;

procedure TCustomConnectionPool.DoUnlock;
begin
  if Assigned(FOnUnLockConnection) then
    FOnUnLockConnection(Self);
end;

procedure TCustomConnectionPool.DoCreateConnection;
begin
  if Assigned(FOnCreateConnection) then
    FOnCreateConnection(Self);
end;

procedure TCustomConnectionPool.DoLockFail(E: Exception);
begin
  if Assigned(FOnLockFail) then
    FOnLockFail(Self, E);
end;

procedure TCustomConnectionPool.DoFreeConnection;
begin
  if Assigned(FOnFreeConnection) then
    FOnFreeConnection(Self);
end;

end.
