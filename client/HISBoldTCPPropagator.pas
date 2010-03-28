unit HISBoldTCPPropagator;

interface

uses
  Classes,
  Controls,
  SysUtils,
  Messages,
  ExtCtrls,
  unClientThread,
  unLockHolder,
  unLockHandler,
  NotificationUnit,
  BoldSubscription,
  BoldThreadSafeQueue,
  BoldTCPGlobals,
  BoldAbstractSnooper,
  BoldLockHandler,
  BoldSystemHandle,
  BoldDefs,
  BoldAbstractModificationPropagator;


type
  THISBoldAbstractTCPPropagator = class(TBoldAbstractNotificationPropagator)
  private
    FNotificationManager: TNotificationManager;
    FLocking: boolean;
    FClientThread:TClientThread;
    FClientID: Integer;
    FPropagatorActive: Boolean;
    FLeaseDuration: Integer;
    FClientIDString: String;
    FTimer:TTimer;
    FPollingInterval: Integer;
    FLockHandler:TBoldTCPLockHandler;
    FLockHolder:TLockHolder;
    FSubscriber: TBoldPassthroughSubscriber;
    FLockingActive:Boolean;
    fOnProgress: TBoldLockManagerProgressEvent;
    fOnActivityStart: TNotifyEvent;
    fOnActivityEnd: TNotifyEvent;
    FEnsureRegions:Boolean;
    function GetPort: Integer;
    procedure SetPort(const Value: Integer);
    procedure SetClientID(const Value: Integer);
    procedure SetLeaseDuration(const Value: Integer);
    procedure SetPropagatorActive(const Value: Boolean);
    procedure SetClientIDString(const Value: String);
    procedure SetPollingInterval(const Value: Integer);
    function GetStateless: Boolean;
    procedure SetStateless(const Value: Boolean);
    function GetSystemHandle: TBoldSystemHandle;
    procedure SetSystemHandle(const Value: TBoldSystemHandle);
    function GetHost: String;
    procedure SetHost(const Value: String);
    function GetEnsureRegion: Boolean;
    procedure SetEnsureRegion(const Value: Boolean);
  protected
    procedure OnTimer(Sender: TObject);
    procedure SetTimer(Interval:Integer);
    procedure SetActive(Value: Boolean); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure OnSendQueueNotEmpty(Sender: TBoldThreadSafeQueue); override;
    procedure _Receive(Originator: TObject; OriginalEvent: TBoldEvent;
        RequestedEvent: TBoldRequestedEvent);
    procedure AdjustActive;
    procedure Activate;
    procedure Deactivate;
    procedure PollingEvent(const aNotification : THISBoldPropagatorEvent);
    property Port:Integer read GetPort write SetPort default IdPORT_BOLD;
    property Host:String read GetHost write SetHost;
    property LeaseDuration: Integer read FLeaseDuration write SetLeaseDuration default DEFAULT_LEASE_DURATION;
    property PropagatorActive: Boolean read FPropagatorActive write SetPropagatorActive default True;
    property ClientID:Integer read FClientID write SetClientID;
    property ClientIDString:String read FClientIDString write SetClientIDString;
    property PollingInterval:Integer read FPollingInterval write SetPollingInterval default 500;
    property Stateless:Boolean read GetStateless write SetStateless default true;
    property Locking:Boolean read FLocking write FLocking default false;
    property SystemHandle: TBoldSystemHandle read GetSystemHandle write SetSystemHandle;
    property LockingActive:Boolean read FLockingActive;
    property OnActivityStart: TNotifyEvent read fOnActivityStart write fOnActivityStart;
    property OnActivityEnd: TNotifyEvent read fOnActivityEnd write fOnActivityEnd;
    property OnProgress: TBoldLockManagerProgressEvent read fOnProgress write fOnProgress;
    property UseEnsureRegions:Boolean read GetEnsureRegion write SetEnsureRegion default true;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Lock(LockName:String):boolean;
    procedure Unlock(LockName:String);
  end;

  THISBoldTCPPropagator = class(THISBoldAbstractTCPPropagator)
  published
    property Host;
    property Port;
    property PollingInterval;
    property Stateless;
    property LeaseDuration;
    property PropagatorActive;
    property ClientIDString;
    property NextPersistenceHandle;
    property Active;
    property Dequeuer;
    property OnReceiveEvent;
    property SystemHandle;
    property Locking;
    property OnActivityStart;
    property OnActivityEnd;
    property OnProgress;
    property UseEnsureRegions;
  end;

implementation

{$IFDEF Shareware}

uses
  dialogs,
  windows;

function DelphiIsRunning: Boolean;
  { CDK: You may want to encrypt the following strings (and
    decrypt at run-time) to discourage reverse-engineering.
    If you do this, make sure you save your work befor testing. }
const
  A1: array[0..12] of char = 'TApplication'#0;
  A2: array[0..15] of char = 'TAlignPalette'#0;
  A3: array[0..11] of char = 'TAppBuilder'#0;
  {$ifdef Win32}
  {$ifdef Ver90}
    T1: array[0..10] of char = 'Delphi 2.0'#0;
  {$endif}
  {$ifdef Ver100}
    T1: array[0..10] of char = 'Delphi 3.0'#0;
  {$endif}
  {$ifdef Ver120}
    T1: array[0..10] of char = 'Delphi 4.0'#0;
  {$endif}
  {$ifdef Ver130}
    T1: array[0..10] of char = 'Delphi 5.0'#0;
  {$endif}
  {$ifdef Ver140}
    T1: array[0..10] of char = 'Delphi 6'#0;
  {$endif}
  {$ifdef Ver150}
  T1: array[0..10] of char = 'Delphi 7'#0;
  {$endif}
  {$endif}
begin
  Result := (FindWindow(A1, T1) <> 0) and (FindWindow(A2, nil) <> 0) and
            (FindWindow(A3, nil) <> 0);
end;		{ DelphiIsRunning }
{$ENDIF}



{ THISBoldAbstractTCPPropagator }


procedure THISBoldAbstractTCPPropagator.Activate;
begin
  {$IFDEF Shareware}
  if not DelphiIsRunning then
  begin
    ShowMessage('Bold TCP Propagator Not Licensed');
  end;
  {$ENDIF}
  if not assigned(SystemHandle) then
    raise EBoldInternal.CreateFmt('%s.Activate: Cannot activate Locking without a SystemHandle. Set the Systemhandle property of the %0:s', [classname]);
  if not assigned(SystemHandle.System) then
    raise EBoldInternal.CreateFmt('%s.Activate: Cannot activate Locking. The system is not active.', [classname]);

  if PropagatorActive then
  begin
    ClientID := FClientThread.Login(ClientIDString,LeaseDuration);
    SetTimer(PollingInterval);
    if (not LockingActive) and (FLocking) then //XM
    begin
      if not assigned(FLockHolder) then
        FLockHolder := TLockHolder.Create(FClientThread,Dequeuer);
      FLockHolder.ClientID := ClientID;
      fLockHandler := TBoldTCPLockHandler.CreateWithLockHolder(SystemHandle.System, FLockHolder);
      fLockHandler.OnActivityStart := OnActivityStart;
      fLockHandler.OnActivityEnd := OnActivityEnd;
      fLockHandler.OnProgress := OnProgress;
      FLockHandler.UseEnsureRegions := FEnsureRegions;
      fLockingActive := True;
    end;
  end;
end;


procedure THISBoldAbstractTCPPropagator.AdjustActive;
begin
  if assigned(SystemHandle) and SystemHandle.Active then
  begin
    Activate;
  end else
    Deactivate;
end;

constructor THISBoldAbstractTCPPropagator.Create(AOwner: TComponent);
begin
  inherited;
  FNotificationManager := TNotificationManager.Create(Self);
  FNotificationManager.AddDispatch(THISBoldPropagatorEvent,@THISBoldAbstractTCPPropagator.PollingEvent,Self);
  FClientThread := TClientThread.Create(FNotificationManager);
  Stateless := true;
  Port := IdPORT_BOLD;
  LeaseDuration := DEFAULT_LEASE_DURATION;
  ClientIDString := DEFAULT_NAME_STRING;
  PropagatorActive := True;
  FPollingInterval := 500;
  FLocking := False;
  FSubscriber := TBoldPassthroughSubscriber.Create(_Receive);
  UseEnsureRegions := true;
end;


procedure THISBoldAbstractTCPPropagator.Deactivate;
begin
  if FClientThread.LogedIn then
    FClientThread.Logout(ClientID);
  SetTimer(0);
  FreeAndNil(fLockHolder);
  FreeAndNil(fLockHandler);
  FLockingActive := false;
end;


destructor THISBoldAbstractTCPPropagator.Destroy;
begin
  if not SendQueue.Empty then
    OnSendQueueNotEmpty(SendQueue);
  Deactivate;
  FreeAndNil(FTimer);
  FClientThread.Quit(True);
  FreeAndNil(FClientThread);
  FreeAndNil(FLockHandler);
  FreeAndNil(FLockHolder);
  FreeAndNil(FSubscriber);
  inherited;
end;

function THISBoldAbstractTCPPropagator.GetEnsureRegion: Boolean;
begin
  if assigned(FLockHandler) then
    Result := FLockHandler.UseEnsureRegions
  else
    Result := FEnsureRegions;
end;

function THISBoldAbstractTCPPropagator.GetHost: String;
begin
  Result := FClientThread.Host;
end;

function THISBoldAbstractTCPPropagator.GetPort: Integer;
begin
  Result := FClientThread.Port;
end;

function THISBoldAbstractTCPPropagator.GetStateless: Boolean;
begin
  result := FClientThread.Stateless;
end;

function THISBoldAbstractTCPPropagator.GetSystemHandle: TBoldSystemHandle;
begin
  result := inherited SystemHandle;
end;

function THISBoldAbstractTCPPropagator.Lock(LockName: String):Boolean;
begin
  result := FLockHandler.LockByName(LockName);
end;

procedure THISBoldAbstractTCPPropagator.Notification(
  AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = Dequeuer then Dequeuer := nil;
    if AComponent = NextPersistenceHandle then NextPersistenceHandle := nil;
    if AComponent = SystemHandle then SystemHandle := nil;
  end;
end;

procedure THISBoldAbstractTCPPropagator.OnSendQueueNotEmpty(
  Sender: TBoldThreadSafeQueue);
begin
  if PropagatorActive then
    while not SendQueue.Empty do
      FClientThread.Transmit(ClientID,SendQueue.Dequeue);
end;

procedure THISBoldAbstractTCPPropagator.OnTimer(Sender: TObject);
begin
  if PropagatorActive then
    FClientThread.Polling(ClientID);
end;

procedure THISBoldAbstractTCPPropagator.PollingEvent(
  const aNotification : THISBoldPropagatorEvent);
var
  I: Integer;
begin
  with aNotification do
  begin
    for I := 0 to Events.Count - 1 do    // Iterate
    begin
      ReceiveEvent(Events[I]);
    end;    // for
  end;  // with
end;

procedure THISBoldAbstractTCPPropagator.SetActive(Value: Boolean);
begin
  inherited;
  if Value then
  begin
    if FClientThread.Suspended then
      FClientThread.Resume;
  end
  else
    if not FClientThread.Suspended then
      FClientThread.Suspend;
end;

procedure THISBoldAbstractTCPPropagator.SetClientID(const Value: Integer);
begin
  FClientID := Value;
end;

procedure THISBoldAbstractTCPPropagator.SetClientIDString(
  const Value: String);
begin
  if Value = '' then
    FClientIDString := DEFAULT_NAME_STRING
  else
    FClientIDString := Value;
end;

procedure THISBoldAbstractTCPPropagator.SetEnsureRegion(
  const Value: Boolean);
begin
  if Assigned(FLockHandler) then
    FLockHandler.UseEnsureRegions := Value
  else
    FEnsureRegions := Value;
end;

procedure THISBoldAbstractTCPPropagator.SetHost(const Value: String);
begin
  if not FClientThread.LogedIn then
    FClientThread.Host := Value
    
end;

procedure THISBoldAbstractTCPPropagator.SetLeaseDuration(
  const Value: Integer);
begin
  FLeaseDuration := Value;
end;

procedure THISBoldAbstractTCPPropagator.SetPollingInterval(
  const Value: Integer);
begin
  FPollingInterval := Value;
end;

procedure THISBoldAbstractTCPPropagator.SetPort(const Value: Integer);
begin
  if not FClientThread.LogedIn then
  begin
    FClientThread.Port := Value;
  end;
end;

procedure THISBoldAbstractTCPPropagator.SetPropagatorActive(
  const Value: Boolean);
begin
  FPropagatorActive := Value;
end;

procedure THISBoldAbstractTCPPropagator.SetStateless(const Value: Boolean);
begin
  FClientThread.Stateless := Value;
end;

procedure THISBoldAbstractTCPPropagator.SetSystemHandle(
  const Value: TBoldSystemHandle);
begin
  inherited SystemHandle := Value;
  if assigned(Value) then
  begin
    Value.FreeNotification(Self);
    Value.AddSubscription(FSubscriber,beValueIdentityChanged,beValueIdentityChanged);
  end;
  AdjustActive;
end;

procedure THISBoldAbstractTCPPropagator.SetTimer(Interval:Integer);
begin
  if not Assigned(FTimer) then
  begin
    FTimer := TTimer.Create(nil);
    FTimer.OnTimer := OnTimer;
  end;
  FTimer.Enabled := False;
  FTimer.Interval := Interval;
  if Interval > 0 then
    FTimer.Enabled := True;
end;


procedure THISBoldAbstractTCPPropagator.Unlock(LockName: String);
begin
  FLockHandler.UnlockByName(LockName);
end;

procedure THISBoldAbstractTCPPropagator._Receive(Originator: TObject;
  OriginalEvent: TBoldEvent; RequestedEvent: TBoldRequestedEvent);
begin
  if Originator = SystemHandle then
  begin
    case OriginalEvent of
      beValueIdentityChanged:
        AdjustActive;
      beDestroying:
      begin
        Deactivate;
        SystemHandle := nil;
      end;
    end;
  end;

end;

end.
