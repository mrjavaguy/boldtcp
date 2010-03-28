unit unClientThread;

interface

uses
  SysUtils,
  Classes,
  Windows,
  Messages,
  syncobjs,
  idBoldClient,
  NotificationUnit,
  BoldThread;


type
  TClientThread = class(TBoldNotifiableThread)
  private
    FNotificationManager : Pointer;
    FBoldClient:TidBoldClient;
    FLock:TCriticalSection;
    FLogedIn: Boolean;
    FStateless: Boolean;
    function GetPort: Integer;
    procedure SetPort(const Value: Integer);
    procedure SetStateless(const Value: Boolean);
    procedure InternalConnect;
    function GetStateless: Boolean;
    function GetHost: String;
    procedure SetHost(const Value: String);
  protected
    procedure AquireLock;
    procedure ReleaseLock;
    procedure DoPolling(ClientID:integer);
    procedure DoTransmit(ClientID:integer; Event:String);
    property BoldClient:TidBoldClient read FBoldClient;
  public
    constructor Create(const aNotificationManager : INotificationManager);
    destructor Destroy; override;
    procedure Execute; override;
    procedure Connect;
    procedure Disconnect;
    function Login(ClientIDString:String; LeaseDuration:Integer):integer;
    procedure Logout(ClientID:Integer);
    procedure Transmit(ClientID:Integer;Event:String);
    procedure Polling(ClientID:Integer);
    function EnsureLocks(ClientID:Integer;ExclusiveLocks:TStringList; SharedLocks:TStringList):Boolean;
    function GetLocks(ClientID:Integer;ExclusiveLocks, SharedLocks, HeldLocks, ClientsHoldingRequestedLocks: TStringList):Boolean;
    procedure ReleaseLocks(ClientID:Integer; Locks:TStringList);
    property Port:Integer read GetPort write SetPort;
    property Host:String read GetHost write SetHost;
    property LogedIn:Boolean read FLogedIn;
    property Stateless:Boolean read GetStateless write SetStateless;
  end;

  THISBoldPropagatorEvent = class(TNotification)
  public
    Events:TStrings;
    constructor Create (const aNotificationQueue : INotificationQueue); override;
    destructor Destroy; override;
  end;

implementation

uses
  Forms,
  Controls,
  BoldTCPGlobals,
  BoldThreadSafeLog;

{ TClientThread }

procedure TClientThread.AquireLock;
begin
  FLock.Acquire;
end;

procedure TClientThread.Connect;
begin
  AquireLock;
  try
    InternalConnect;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

constructor TClientThread.Create;
begin
  inherited Create(True);
  FBoldClient := TidBoldClient.Create(nil);
  FLock := TCriticalSection.Create;
  FNotificationManager := Pointer(aNotificationManager);
end;

destructor TClientThread.Destroy;
begin
  Disconnect;
  FreeAndNil(FBoldClient);
  FreeAndNil(FLock);
  inherited;
end;

procedure TClientThread.Disconnect;
begin
  AquireLock;
  try
    BoldClient.Disconnect;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

procedure TClientThread.DoPolling(ClientID: integer);
begin
  AquireLock ;
  try
    if FStateless then
      InternalConnect;
    BoldClient.Polling(ClientID);
    if FStateless then
      BoldClient.Disconnect;
    if BoldClient.Events.Count > 0 then
    begin
      with INotificationManager(FNotificationManager).NewQueue do
      begin
        THISBoldPropagatorEvent.Create(ThisQueue).Events.AddStrings(BoldClient.Events);
        Send;
      end;
    end;
  finally
    ReleaseLock;
  end;  // try/finally
end;

procedure TClientThread.DoTransmit(ClientID: integer; Event: String);
begin
  AquireLock;
  try
   if FStateless then
     Connect;
   BoldClient.Transmit(ClientID,Event);
   if FStateless then
      BoldClient.Disconnect;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

function TClientThread.EnsureLocks(ClientID: Integer; ExclusiveLocks,
  SharedLocks: TStringList):Boolean;
begin
  AquireLock;
  try
    if FStateless then
      InternalConnect;
    result := BoldClient.EnsureLocks(ClientID,ExclusiveLocks,SharedLocks);
    if FStateless then
      BoldClient.Disconnect;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

procedure TClientThread.Execute;
var
  rMsg: TMsg;
begin
  try
    EnsureMessageQueue;
    SignalReady;
    while not Terminated do
    begin
      if PeekMessage(rMsg, 0, 0, 0, PM_REMOVE) then
      begin
        if rMsg.Message = WM_QUIT then
          Terminate
        else
        if rMsg.message = TM_CLIENT_EVENT then
        begin
          DoTransmit(rMsg.wParam,TClientEvent(rMsg.lParam).Event);
          TClientEvent(rMsg.lParam).Free;
        end
        else
        if rMsg.message = TM_POLL_EVENT then
           DoPolling(rMsg.wParam)
        else
          DispatchMessage(rMsg);
      end
      else
        WaitMessage;
    end;
  except on E: Exception do
    BoldLogError('%s.Execute (Error: %s)', [ClassName, E.Message]);
  end;
end;

function TClientThread.GetHost: String;
begin
  AquireLock;
  try
    result := BoldClient.Host;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally

end;

function TClientThread.GetLocks(ClientID: Integer; ExclusiveLocks,
  SharedLocks, HeldLocks,
  ClientsHoldingRequestedLocks: TStringList): Boolean;
begin
  AquireLock;
  try
    if FStateless then
      InternalConnect;
    result := BoldClient.GetLocks(ClientID,ExclusiveLocks,SharedLocks,HeldLocks,ClientsHoldingRequestedLocks);
    if FStateless then
      BoldClient.Disconnect;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

function TClientThread.GetPort: Integer;
begin
  AquireLock;
  try
    result := BoldClient.Port;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally

end;

function TClientThread.GetStateless: Boolean;
begin
  AquireLock;
  try
    result := FStateless;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

procedure TClientThread.InternalConnect;
begin
  if not FBoldClient.Connected then
  begin
    BoldClient.Connect;
    BoldClient.GetResponse(220);
    BoldClient.Greeting.Assign(BoldClient.LastCmdResult);
  end;
end;

function TClientThread.Login(ClientIDString:String; LeaseDuration:Integer): integer;
begin
   AquireLock;
   try
     if not BoldClient.Connected then
     Connect;
     result := BoldClient.Login(ClientIDString,LeaseDuration);
     FLogedIn := Result <> InvalidClientNumber;
    if FStateless then
      BoldClient.Disconnect;
   finally // wrap up
     ReleaseLock;
   end;    // try/finally

end;

procedure TClientThread.Logout(ClientID:Integer);
begin
   AquireLock;
   try
     Connect;
     FLogedIn := not BoldClient.Logout(ClientID);
     Disconnect;
   finally // wrap up
     ReleaseLock;
   end;    // try/finally
end;

procedure TClientThread.Polling(ClientID: Integer);
begin
  PostThreadMessage(ThreadID, TM_POLL_EVENT , ClientID, 0);
end;

procedure TClientThread.ReleaseLock;
begin
  FLock.Release;
end;


procedure TClientThread.ReleaseLocks(ClientID: Integer; Locks: TStringList);
begin
  AquireLock;
  try
    if FStateless then
      InternalConnect;
    BoldClient.ReleaseLocks(ClientID,Locks);
    if FStateless then
      BoldClient.Disconnect;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

procedure TClientThread.SetHost(const Value: String);
begin
  AquireLock;
  try
    BoldClient.Host := Value;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally

end;

procedure TClientThread.SetPort(const Value: Integer);
begin
  AquireLock;
  try
    BoldClient.Port := Value;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

procedure TClientThread.SetStateless(const Value: Boolean);
begin
  AquireLock;
  try
    FStateless := Value;
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

procedure TClientThread.Transmit(ClientID: Integer; Event: String);
var
  aEvent:TClientEvent;
begin
  aEvent := TClientEvent.Create(Event);
  PostThreadMessage(ThreadID, TM_CLIENT_EVENT , ClientID, Integer(aEvent));

end;

{ THISBoldPropagatorEvent }

constructor THISBoldPropagatorEvent.Create(
  const aNotificationQueue: INotificationQueue);
begin
  Events := TStringList.Create;
  inherited;
end;

destructor THISBoldPropagatorEvent.Destroy;
begin
  Events.Free;
  inherited;
end;

end.
