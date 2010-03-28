unit unLockHolder;

interface

uses
  Classes,
  BoldBase,
  BoldAbstractDequeuer,
  BoldHashIndexes,
  BoldDefs,
  BoldLockHolder,
  unClientThread,
  SyncObjs;


type

  TLockHolder = class(TBoldAbstractLockHolder)
  private
    fHeldExclusive: TBoldLockList;
    fHeldShared: TBoldLockList;
    fTimeOut: Integer;
    fDequeuer: TBoldAbstractDequeuer;
    FClientThread : TClientThread;
    FClientID:Integer;
    procedure LockListToStringList(aLockList: TBoldLockList;
      aStringList: TStringList);
  protected
    function GetHeldExclusive: TBoldLockList; override;
    function GetHeldShared: TBoldLockList; override;
  public
    constructor Create(aClientThread:TClientThread; aDequeuer: TBoldAbstractDequeuer);
    destructor Destroy; override;
    function Lock(Shared: TBoldLockList; Exclusive: TBoldLockList; HeldLocks, ClientsHoldingRequestedLocks: TStringList): Boolean; override;
    procedure Release(Locks: TBoldLockList); override;
    function EnsureLocks: Boolean; override;
    function LockDatabase: Boolean;
    procedure GetPropagationEvents(EventList: TStringList); override;
    property TimeOut: Integer read fTimeOut write fTimeOut;
    property ClientThread:TClientThread read FClientThread;
    property ClientID:Integer read FClientID write FClientID;
  end;


implementation

uses
  BoldIndex,
  SysUtils;

{ TLockHolder }

constructor TLockHolder.Create;
begin
  inherited Create;
  fHeldExclusive := TBoldLockList.Create;
  fHeldShared := TBoldLockList.Create;
  fDequeuer := aDequeuer;
  FClientThread := aClientThread;
end;

destructor TLockHolder.Destroy;
begin
  FreeAndNil(fHeldExclusive);
  FreeAndNil(fHeldShared);
  inherited;
end;


procedure TLockHolder.LockListToStringList(aLockList:TBoldLockList; aStringList:TStringList);
var
  aTraverser: TBoldIndexTraverser;
  aString:String;
begin
  aStringList.Clear;
  aTraverser := aLockList.CreateTraverser;
  try
    while not aTraverser.EndOfList do
    begin
      aString := (aTraverser.Item as TBoldLock).Name;
      aStringList.Add( aString);
      aTraverser.Next;
    end;
  finally
    aTraverser.Free;
  end;
end;


function TLockHolder.EnsureLocks: Boolean;
var
  ExLocks:TStringList;
  SharedLocks:TStringList;
begin
  result := assigned(ClientThread);
  if not result then
    exit;
  if (fHeldExclusive.Count > 0) or (fHeldShared.Count > 0) then
  begin
    ExLocks := TStringList.Create;
    SharedLocks := TStringList.Create;
    try
      LockListToStringList(fHeldExclusive,ExLocks);
      LockListToStringList(fHeldShared,SharedLocks);
      result := ClientThread.EnsureLocks(ClientID, ExLocks, SharedLocks);
    finally
      FreeAndNil(ExLocks);
      FreeAndNil(SharedLocks);
    end;  // try/finally
  end;
end;

function TLockHolder.GetHeldExclusive: TBoldLockList;
begin
  Result := fHeldExclusive;
end;

function TLockHolder.GetHeldShared: TBoldLockList;
begin
  Result := fHeldShared;
end;

function TLockHolder.Lock(Shared, Exclusive: TBoldLockList; HeldLocks,
  ClientsHoldingRequestedLocks: TStringList): Boolean;
var
  ExLocks:TStringList;
  SharedLocks:TStringList;
begin
  result := assigned(ClientThread);
  if not result then
    exit;
  Shared.RemoveList(fHeldShared);
  Shared.RemoveList(fHeldExclusive);
  Exclusive.RemoveList(fHeldExclusive);
  Shared.RemoveList(Exclusive);
  if (Exclusive.Count > 0) or (Shared.Count > 0) then
  begin
    ExLocks := TStringList.Create;
    SharedLocks := TStringList.Create;
    try
      LockListToStringList(Exclusive,ExLocks);
      LockListToStringList(Shared,SharedLocks);
      result := ClientThread.GetLocks(ClientID,  ExLocks, SharedLocks, HeldLocks, ClientsHoldingRequestedLocks);
    finally
      FreeAndNil(ExLocks);
      FreeAndNil(SharedLocks);
    end;  // try/finally
    if result then
    begin
      fHeldShared.AddList(Shared);
      fHeldExclusive.AddList(Exclusive);
      fHeldShared.RemoveList(Exclusive);
    end;
  end;
end;

function TLockHolder.LockDatabase: Boolean;
var
  SharedLocks: TBoldLockList;
  ExclusiveLocks: TBoldLockList;
  Conflicts: TStringList;
  ConflictingUsers: TStringList;
begin
  if not assigned(fDequeuer) then
    raise EBold.CreateFmt('%s.LockDatabase: there is no dequeuer available', [classname]);
  SharedLocks := TBoldLockList.Create;
  ExclusiveLocks := TBoldLockList.Create;
  Conflicts := TStringList.Create;
  ConflictingUsers := TStringList.Create;
  try
    ExclusiveLocks.AddLock('DBLOCK');
    result := Lock(SharedLocks, ExclusiveLocks, Conflicts, ConflictingUsers);
    if result then
      fHeldExclusive.AddLock('DBLOCK');
    fDequeuer.DequeueAll;
  finally
    SharedLocks.Free;
    ExclusiveLocks.Free;
    Conflicts.Free;
    ConflictingUsers.Free;
  end;
end;

procedure TLockHolder.Release(Locks: TBoldLockList);
var
  LockStrings:TStringList;
begin
  if assigned(ClientThread) then
  begin
    LockStrings := TStringList.Create;
    try
      if (Locks.Count > 0) then
      begin
        LockListToStringList(Locks,LockStrings);
        ClientThread.ReleaseLocks(ClientID, LockStrings);
        fHeldExclusive.RemoveList(Locks);
        fHeldShared.RemoveList(Locks);
      end;
    finally // wrap up
      FreeAndNil(LockStrings);
    end;    // try/finally
  end;
end;

procedure TLockHolder.GetPropagationEvents(EventList: TStringList);
begin
end;

end.
