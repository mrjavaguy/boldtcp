unit unLockHandler;

interface

uses
  Variants,
  BoldLockList,
  BoldDefs,
  SysUtils,
  BoldUtils,
  BoldSubscription,
  BoldPropagatorSubscriptions,
  BoldLockingDefs,
  unClientHandler,
  Classes;


type

  TLockManager = class(TBoldPassthroughSubscriber)
  private
    fHandedLocks: TBoldLockList;
    fSuspended: Boolean;
    FClientHandler:TClientHandler;
  protected
    function CanAcquireLocks(const ClientId: TBoldClientId; const Locks: TStringList; const LockType: TBoldLockType;
            ClientsHoldingRequestedLocks: TBoldSortedIntegerList; HeldLocks: TStringList): Boolean;
    procedure AcquireLocks(const ClientId: TBoldClientID; const TimeOut: integer;
                           const Locks: TStringList; const LockType: TBoldLockType);
  public
    constructor Create(aClientHandler:TClientHandler);
    destructor Destroy; override;
    function GetLocks( const ClientID: TBoldClientID; const TimeOut: integer;
                       const RequestedExclusiveLocks, RequestedSharedLocks: TStringList;
                       out HeldLocks: TStringList; out ClientsHoldingRequestedLocks: TStringList): Boolean;
    procedure ReleaseLocks(const ClientID: TBoldClientID; const RequestedLocks: TStringList);
    function EnsureLocks(const ClientID: TBoldClientID; const RequestedExclusiveLocks, RequestedSharedLocks: TStringList): Boolean;
    procedure ReleaseAllLocksForClient(const ClientID: TBoldClientId);
    procedure _Receive(Originator: TObject; OriginalEvent: TBoldEvent;
            RequestedEvent: TBoldRequestedEvent; const Args: array of const);
    function HasLocks(const ClientId: TBoldClientId): Boolean;
    property HandedLocks: TBoldLockList read fHandedLocks write fHandedLocks;
    property ClientHandler:TClientHandler read FClientHandler;
    property Suspended: Boolean read fSuspended write fSuspended;
  end;


implementation

uses
  BoldRev,
  BoldPropagatorConstants,
  BoldObjectSpaceExternalEvents
  ;


{ TLockManager }

procedure TLockManager._Receive(Originator: TObject;
  OriginalEvent: TBoldEvent; RequestedEvent: TBoldRequestedEvent;
  const Args: array of const);
var
  ClientId: TBoldClientId;
begin
  if (RequestedEvent = breReleaseClientLocks) then
  begin
    ClientID := Args[0].VInteger;
    ReleaseAllLocksForClient(ClientId);
  end;
end;

procedure TLockManager.AcquireLocks(const ClientId: TBoldClientID;
  const TimeOut: integer; const Locks: TStringList;
  const LockType: TBoldLockType);
var
  i: integer;
  CurrentTime: TTimeStamp;
begin
  CurrentTime := DateTimeToTimeStamp(Now);
  if Assigned(Locks) then
    for i:= 0 to Locks.Count - 1 do
      HandedLocks.AddLock(ClientId, TimeOut, CurrentTime, Locks[i], LockType);
end;

function TLockManager.CanAcquireLocks(const ClientId: TBoldClientId;
  const Locks: TStringList; const LockType: TBoldLockType;
  ClientsHoldingRequestedLocks: TBoldSortedIntegerList;
  HeldLocks: TStringList): Boolean;
var
  i: integer;
  INode: TBoldLockNameIndexNode;
  CurrentNode, Temp: TBoldLockNode;
  LockLostEvent: String;
begin
  Result := True;
  if Assigned (Locks) then
    for i:= 0 to Locks.Count - 1 do
    begin
      INode := HandedLocks.Locks[Locks[i]];
      if Assigned(INode) then
        if (LockType = bltExclusive) or ((LockType = bltShared) and (INode.ExclusiveLock)) then
        begin
          CurrentNode := (INode.Next as TBoldLockNode);
          While Assigned(CurrentNode) do
          begin
            if (CurrentNode.ClientId <> ClientId) then
              if CurrentNode.HasTimedOut  then
              begin
                Temp := CurrentNode;
                CurrentNode := CurrentNode.Next[HandedLocks.LockNameIndexOrder] as TBoldLockNode;
                Temp.Remove;
                LockLostEvent := TBoldObjectSpaceExternalEvent.EncodeExternalEvent(bsLockLost, '', '',Locks[i] ,nil);
 //               Propagator.Enqueuer.SendLockEvent(Temp.ClientId, LockLostEvent, False);
                FreeAndNil(Temp);
              end
              else
              begin
                if Result then Result:= false;
                if (HeldLocks.IndexOf(Locks[i]) = -1) then
                  HeldLocks.Add(Locks[i]);
                ClientsHoldingRequestedLocks.Add(CurrentNode.ClientId);
                CurrentNode := CurrentNode.Next[HandedLocks.LockNameIndexOrder] as TBoldLockNode;
              end
            else
              CurrentNode := CurrentNode.Next[HandedLocks.LockNameIndexOrder] as TBoldLockNode;
          end;
        end
    end;
end;

constructor TLockManager.Create;
begin
  inherited CreateWithExtendedReceive(_Receive);
  fHandedLocks := TBoldLockList.Create;
  fClientHandler := aClientHandler;
  ClientHandler.AddSubscription(self, BOLD_PROPAGATOR_CLIENT_REMOVED, breReleaseClientLocks);
end;

destructor TLockManager.Destroy;
begin
  CancelAllSubscriptions;
  FreeAndNil(fHandedLocks);
  inherited;
end;

function TLockManager.EnsureLocks(const ClientID: TBoldClientID;
  const RequestedExclusiveLocks,
  RequestedSharedLocks: TStringList): Boolean;
var
  i: integer;
  CurrentLock: TBoldLockNode;
begin
  Result := not Suspended;
  i:= 0;
  if Assigned(RequestedExclusiveLocks) then
    while (i < RequestedExclusiveLocks.Count) and Result do
    begin
      CurrentLock := HandedLocks.Items[ClientID, RequestedExclusiveLocks[i]];
      Result := Assigned(CurrentLock) and (CurrentLock.LockType = bltExclusive);
      inc(i);
    end;
  i:= 0;
  if Assigned(RequestedSharedLocks) then
    while (i < RequestedSharedLocks.Count) and Result do
    begin
      CurrentLock := HandedLocks.Items[ClientID, RequestedSharedLocks[i]];
      Result := Assigned(CurrentLock) and (CurrentLock.LockType = bltShared);
      inc(i);
    end;
end;

function TLockManager.GetLocks(const ClientID: TBoldClientID;
  const TimeOut: integer; const RequestedExclusiveLocks,
  RequestedSharedLocks: TStringList; out HeldLocks,
  ClientsHoldingRequestedLocks: TStringList): Boolean;
var
  ClientIds: TBoldSortedIntegerList;
  i: integer;
  resCanAcquireExclusive, resCanAcquireShared: Boolean;
  ClientIdString: string;
  CurrentClientId: TBoldClientId;
  LeaseDuration: integer;
  LeaseTimeout: TTimeStamp;
  Initialized: Boolean;
begin
  Result := false;
  ClientIds := TBoldSortedIntegerList.Create;
  HeldLocks := TStringList.Create;
  ClientsHoldingRequestedLocks := TStringList.Create;
  resCanAcquireExclusive := CanAcquireLocks(ClientId, RequestedExclusiveLocks, bltExclusive, ClientIds, HeldLocks);
  resCanAcquireShared := CanAcquireLocks(ClientId, RequestedSharedLocks, bltShared, ClientIds, HeldLocks);
  try
    if not Suspended and ClientHandler.IsRegistered(ClientId) and resCanAcquireExclusive and resCanAcquireShared then
    begin
      AcquireLocks(ClientId, TimeOut, RequestedExclusiveLocks, bltExclusive);
      AcquireLocks(ClientId, TimeOut, RequestedSharedLocks, bltShared);
//      Propagator.Enqueuer.SendLockEvent(ClientId, TBoldObjectSpaceExternalEvent.EncodeExternalEvent(bsGotLocks, '', '', '', nil), True);
      Result := True;
    end;
  finally
    if not Result then
    begin
      if (ClientIds.Count > 0) then
      begin
        for i:= 0 to ClientIds.Count - 1 do
        begin
          CurrentClientId := TBoldClientId(ClientIds[i]);
          ClientHandler.HasInfoForClient(CurrentClientId, ClientIdString, LeaseDuration,
              LeaseTimeOut, Initialized);
          ClientsHoldingRequestedLocks.Add(Format('%d=%s', [CurrentClientId, ClientIdString]));
        end;
      end;
    end;
    FreeAndNil(ClientIds);
  end;
end;

function TLockManager.HasLocks(const ClientId: TBoldClientId): Boolean;
begin
  Result := Assigned(HandedLocks.Clients[ClientId]) and
            Assigned(HandedLocks.Clients[ClientId].Next);
end;

procedure TLockManager.ReleaseAllLocksForClient(
  const ClientID: TBoldClientId);
begin
  if not Suspended then
    fHandedLocks.RemoveClient(ClientId);
end;

procedure TLockManager.ReleaseLocks(const ClientID: TBoldClientID;
  const RequestedLocks: TStringList);
var
  i: integer;
begin
  if not Suspended then
    for i:= 0 to RequestedLocks.Count - 1 do
      fHandedLocks.RemoveLockForClient(ClientID, RequestedLocks[i]);
end;

end.
