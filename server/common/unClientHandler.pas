unit unClientHandler;

interface

uses
  Classes,
  extctrls,
  BoldSubscription,
  BoldContainers,
  BoldGuard,
  BoldUtils,
  BoldThreadSafeLog,
  BoldLoggableCriticalSection,
  syncobjs,
  BoldTCPGlobals,
  SysUtils;


type

  TClientInfo = class
  private
    FClientID:Integer;
    FClientIDString:String;
    FRegisterTime:TTimestamp;
    FLeaseDuration:Integer;
    FLeaseTimeOut:TTimestamp;
    FEvents:TThreadList;
    FInitialized: Boolean;
    procedure SetInitialized(const Value: Boolean);
  public
    constructor Create(aClientID:Integer; aLeaseDuration:Integer; aClientIDString:String);
    destructor Destroy; override;
    function LeaseIsExpired: Boolean;
    procedure AddEvent(Event:TClientEvent);
    procedure GetEvents(var Events:TStrings);
    procedure ExtendLease(aLeaseDuraion:Integer);
    property ClientID: Integer read FClientID write FClientID;
    property ClientIDString:String read FClientIDString write FClientIDString;
    property RegistrationTime:TTimeStamp read FRegisterTime write FRegisterTime;
    property LeaseDuration:Integer read FLeaseDuration write FLeaseDuration;
    property LeaseTimeOut:TTimeStamp read FLeaseTimeOut write FLeaseTimeOut;
    property Initialized:Boolean read FInitialized write SetInitialized;
  end;

  TClientInfoList = class
    fList: TBoldObjectArray;
    fFreeClientIDs: TList;
    function GetItem(Index: Integer): TClientInfo;
    procedure SetItem(Index: Integer; AObject: TClientInfo);
    function getCount: integer;
    procedure EnsureListCapacity(const Index: integer);
  protected
    function GetFreeClientID: Integer;
    procedure ReturnFreeClientID(const ClientID: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function Add(AObject: TClientInfo): Integer;
    procedure Clear;
    function Remove(AObject: TClientInfo): Integer;
    function IndexOf(AObject: TClientInfo): Integer;
    procedure Insert(Index: Integer; AObject: TClientInfo);
    function Last: TClientInfo;
    procedure Delete(Index: Integer);
    function GetExistingClientInfo(Index: integer): TClientInfo;
    property Items[Index: Integer]: TClientInfo read GetItem write SetItem; default;
    property Count: Integer read getCount;
  end;

  TClientHandler = class(TBoldPublisher)
  private
    fClientInfoList: TClientInfoList;
    fNOConnectedClients: integer;
    fEnabled: Boolean;
    fLockTime: TDateTime;
    FClientHandlerLock: TBoldLoggableCriticalSection;
    fTotalLostEvents: integer;
    fTotalClients: integer;
    fPeakClients: integer;
    fTimer:TTimer;
    function InternalRemoveClient(ClientId: Integer): Boolean;
    procedure AddClient(const LeaseDuration: Integer; const ClientIDString: WideString; out ClientId: integer);
    procedure SetEnabled(Value: Boolean);
    procedure SetNOConnectedClients(const Value: integer);
    function InfoForClient(ClientID: Integer; out ClientInfo: TClientInfo): Boolean;
    procedure NotifyLeaseChanged;
    function GetFirstLeaseTimeOutClient: TClientInfo;
    function GetEnabled: Boolean;
    procedure RemoveExpiredLease(const ClientID: Integer; const RegistrationTime: TTimeStamp);
    procedure CheckAndRemoveExpiredClients;
    procedure AcquireLock;
    procedure ReleaseLock;
  protected
    procedure OnTimerEvent(Sender:TObject);
  public
    constructor Create; virtual;
    destructor Destroy; override;    {IBoldClientHandler}
    function RegisterClient(LeaseDuration: Integer; const ClientIDString: WideString; out BoldClientID: Integer): HResult; stdcall;
    function ExtendLease(BoldClientID: Integer; out ExtensionOK: WordBool): HResult;
        stdcall;
    function UnRegisterClient(BoldClientID: Integer): HResult; stdcall;

    {thread safe methods}
    function HasInfoForClient(ClientId: Integer;
              out ClientIdentifierString: string; out LeaseDuration: integer;
              out LeaseTimeOut: TTimeStamp; out Initialized: Boolean): Boolean;
    function GetRegistrationTime(const ClientID: Integer; out RegistrationTime: TTimeStamp): Boolean;
    function IsRegistered(const ClientId: Integer): Boolean;
    function DisconnectClient(const BoldClientId: Integer): Boolean;
    function IsThereAClientTimingOutSoon(out ClientId: Integer): Boolean;
    procedure GetRegisteredClientIDs(ClientIds: TStringList);
    procedure GetRegisteredClientInfos(ClientInfo: TStringList);
    function GetClientByID(ClientID:Integer):TClientInfo;
    procedure SendEvents(ClientID:Integer; Event:TClientEvent);
    procedure GetEvents(ClientID:Integer; var Events:TStrings);
    property NOConnectedClients: integer read fNOConnectedClients write SetNOConnectedClients;
    property Enabled: Boolean read GetEnabled write SetEnabled;
  end;




implementation



{ TClientInfo }

procedure TClientInfo.AddEvent(Event: TClientEvent);
begin
  FEvents.Add(Event);
end;

constructor TClientInfo.Create;
begin
  inherited Create;
  FClientID := aClientID;
  FLeaseDuration := aLeaseDuration;
  FClientIDString := AClientIDString;
  FEvents := TThreadList.Create;
  FRegisterTime := DateTimeToTimeStamp(Now);
  ExtendLease(aLeaseDuration);
end;

destructor TClientInfo.Destroy;
begin
  FreeAndNil(FEvents);
  inherited;
end;

procedure TClientInfo.ExtendLease(aLeaseDuraion: Integer);
var
  LeaseLength: TTimeStamp;
begin
  fLeaseDuration := LeaseDuration;

  LeaseLength.Time := LeaseDuration;
  LeaseLength.Date := DateTimeToTimeStamp(0).Date;
  fLeaseTimeOut := DateTimetoTimeStamp(now + TimestampToDateTime(LeaseLength));
end;

procedure TClientInfo.GetEvents(var Events: TStrings);
begin
  Events.Clear;
  with FEvents.LockList do
  begin
    try
     while Count > 0 do    // Iterate
      begin
        Events.Add(TClientEvent(Items[0]).Event);
        Delete(0);
      end;    // for
    finally
      FEvents.UnlockList;
    end;
  end;
end;


function TClientInfo.LeaseIsExpired: Boolean;
var
  CurrentTime: TTimeStamp;
begin
  Result := True;
  try
    CurrentTime := DateTimetoTimeStamp(Now);
    Result := TimeStampComp(LeaseTimeOut, CurrentTime) <= 0;
  except on E: Exception do
    BoldLogError('%s.LeaseIsExpired Error: [ID=%d] %s', [ClassName, ClientID, E.Message]);
  end;
end;

procedure TClientInfo.SetInitialized(const Value: Boolean);
begin
  FInitialized := Value;
end;

{ TClientInfoList }

function TClientInfoList.Add(AObject: TClientInfo): Integer;
begin
  Result := fList.Add(AObject);
end;

procedure TClientInfoList.Clear;
begin
  fList.Clear;
end;

constructor TClientInfoList.Create;
begin
  inherited;
  fList := TBoldObjectArray.Create(MINIMAL_CLIENT_INFO_LIST_GROWTH, [bcoDataOwner, bcoThreadSafe]);
  fFreeClientIDs := TList.Create;
end;

procedure TClientInfoList.Delete(Index: Integer);
begin
  fList.Delete(Index);
end;

destructor TClientInfoList.Destroy;
begin
  FreeAndNil(fFreeClientIDs);
  FreeAndNil(fList);
  inherited;
end;

procedure TClientInfoList.EnsureListCapacity(const Index: integer);
var
  i, cnt: integer;
begin
  if (Index >= fList.Count) then
  begin
    cnt := (Index - fList.Count) + 1;
    if cnt < MINIMAL_CLIENT_INFO_LIST_GROWTH  then
      cnt := MINIMAL_CLIENT_INFO_LIST_GROWTH;
    for i:= 0 to cnt - 1 do
      ReturnFreeClientID(fList.Add(nil));
  end;
end;

function TClientInfoList.getCount: integer;
begin
  Result := fList.Count;
end;

function TClientInfoList.GetExistingClientInfo(
  Index: integer): TClientInfo;
begin
  Result := nil;
  try
    if ((Index >= 0) and (Index < fList.Count)) then
      Result := (fList[Index] as TClientInfo);
  except on E: Exception do
    BoldLogError('%s.GetExistingClientInfo Error: [ID=%d] %s', [ClassName, index, E.message]);
  end;
end;

function TClientInfoList.GetFreeClientID: Integer;
begin
  EnsureListCapacity(fList.Count + MINIMAL_FREE_CLIENTID_COUNT - fFreeClientIds.Count);
  Result := Integer(fFreeClientIDs.First);
  fFreeClientIDs.Delete(0);
end;

function TClientInfoList.GetItem(Index: Integer): TClientInfo;
begin
  try
    EnsureListCapacity(Index);
    Result := TClientInfo(fList[Index]);
  except
    Result := nil;
  end;

end;

function TClientInfoList.IndexOf(AObject: TClientInfo): Integer;
begin
  Result := fList.IndexOf(AObject);
end;

procedure TClientInfoList.Insert(Index: Integer; AObject: TClientInfo);
begin
  fList.Insert(Index, AObject);
end;

function TClientInfoList.Last: TClientInfo;
begin
  Result := TClientInfo(fList[fList.Count - 1]);
end;

function TClientInfoList.Remove(AObject: TClientInfo): Integer;
begin
  Result := fList.Remove(AObject);
end;

procedure TClientInfoList.ReturnFreeClientID(
  const ClientID: Integer);
begin
  fFreeClientIds.Add(Pointer(ClientId));
end;

procedure TClientInfoList.SetItem(Index: Integer; AObject: TClientInfo);
begin
  EnsureListCapacity(Index);
  fList[Index] := AObject;
end;

{ TClientHandler }

procedure TClientHandler.AcquireLock;
begin
  fClientHandlerLock.Acquire;
end;

procedure TClientHandler.AddClient(const LeaseDuration: Integer;
    const ClientIDString: WideString; out ClientId: integer);
var
  NewClientInfo: TClientInfo;
  NewClientID: Integer;
begin
  try
    NewClientID := fClientInfoList.GetFreeClientID;
    NewClientInfo := fClientInfoList[NewClientID];
    if not Assigned(NewClientInfo) then
    begin
      fClientInfoList[NewClientID] := TClientInfo.Create(NewClientID,LeaseDuration,ClientIDString);
    end;
    fClientInfoList[NewClientID].Initialized := True;
    ClientId := NewClientID;
    NOConnectedClients := NOConnectedClients + 1;
  except on E: Exception do
    BoldLogError('%s.AddClient: %s', [ClassName, E.Message]);
  end;
end;

procedure TClientHandler.CheckAndRemoveExpiredClients;
var
  Client:TClientInfo;
begin
  if not Enabled then Exit;
  AcquireLock;
  try
    Client := GetFirstLeaseTimeOutClient;
    if assigned(Client) and Client.LeaseIsExpired then
      RemoveExpiredLease(Client.ClientID,Client.RegistrationTime);
  finally
    ReleaseLock;
  end;  // try/finally


end;

constructor TClientHandler.Create;
begin
  inherited Create;
  fClientInfoList := TClientInfoList.Create;
  fClientHandlerLock := TBoldLoggableCriticalSection.Create('CH');
  fNOConnectedClients := 0;
  fLockTime := 0;
  fTimer := TTimer.Create(nil);
  FTimer.OnTimer := OnTimerEvent;
  AcquireLock;
  try
    fEnabled := true;
  finally
    ReleaseLock;
  end;
end;

destructor TClientHandler.Destroy;
begin
  try
    NotifySubscribersAndClearSubscriptions(self);
    AcquireLock;
    try
      fEnabled := false;
      FreeAndNil(fClientInfoList);
    finally
      ReleaseLock;
    end;
    FreeAndNil(fClientHandlerLock);
    FreeAndNil(FTimer);
  except on E: Exception do
    BoldLogError('%s.Destroy Error: %s)', [ClassName, E.Message]);
  end;
  inherited;
end;

function TClientHandler.DisconnectClient(const BoldClientId: Integer): Boolean;
var
  ClientInfo: TClientInfo;
  IdString: string;
begin
  Result := false;
  if not Enabled then Exit;
  try
    AcquireLock;
    try
      if InfoForClient(BoldClientId, ClientInfo) then
      begin
        IdString := ClientInfo.ClientIdString;
        if InternalRemoveClient(BoldClientID) then
        begin
          Result := true;
          SendExtendedEvent(self, BOLD_PROPAGATOR_CLIENT_CONNECTION_LOST, [BoldClientID]);
          NotifyLeaseChanged;
            BoldLog('Disconnected: %s [ID=%d] Login: %s (%s ago) ', [
              IdString, BoldClientId,
              DateTimeToStr(TimeStampToDateTime(ClientInfo.RegistrationTime)),
              TimeToStr(now - TimeStampToDateTime(ClientInfo.RegistrationTime))
            ])
        end;
      end;
    finally
      ReleaseLock;
    end;
  except on E: Exception do
    BoldLogError('%s.DisconnectClient Error: [ID=%d] %s)', [ClassName, BoldClientId, E.Message]);
  end;
end;


function TClientHandler.ExtendLease(BoldClientID: Integer; out ExtensionOK:
    WordBool): HResult;
var
  LeaseDuration: Integer;
  ClientInfo: TClientInfo;
begin
  Result := S_FALSE;
  ExtensionOK := false;
  if not Enabled then Exit;
  try
    AcquireLock;
    try
      if InfoForClient(BoldClientID, ClientInfo) then
      begin
        LeaseDuration := ClientInfo.LeaseDuration;
        ClientInfo.ExtendLease(LeaseDuration);
        ExtensionOK := true;
        Result := S_OK;
        SendExtendedEvent(self, BOLD_PROPAGATOR_CLIENT_LEASE_EXTENDED,
          [BoldClientID,TimeStampToMSecs( ClientInfo.LeaseTimeOut)]);

        NotifyLeaseChanged;
      end
      else
        BoldLog('ExtendLease failed: [ID=%d] Client already disconnected ', [BoldClientId]);
    finally
      ReleaseLock;
    end;
  except on E: Exception do
    BoldLogError('%s.ExtendLease Error: [ID=%d] %s', [ClassName, BoldClientId, E.Message]);
  end;
end;

function TClientHandler.GetClientByID(ClientID: Integer): TClientInfo;
begin
  AcquireLock;
  try
    InfoForClient(ClientID,Result);
  finally
    ReleaseLock;
  end;

end;

function TClientHandler.GetEnabled: Boolean;
begin
  AcquireLock;
  try
    Result := fEnabled;
  finally
    ReleaseLock;
  end;
end;

procedure TClientHandler.GetEvents(ClientID: Integer;
  var Events: TStrings);
var
  aClient:TClientInfo;
begin
  AcquireLock;
  try
    if InfoForClient(ClientID,aClient) then
    begin
      aClient.GetEvents(Events);
    end;
  finally
    ReleaseLock;
  end;
end;

function TClientHandler.GetFirstLeaseTimeOutClient: TClientInfo;
var
  i: integer;
  aTemp: TClientInfo;
begin
  Result := nil;
  if not Enabled then Exit;
  try
    if (NoConnectedClients <> 0) then
      for i:= 0 to fClientInfoList.Count - 1 do
      begin
        aTemp := fClientInfoList[i];
        if Assigned(aTemp) then
        begin
          if not Assigned(Result) then
            Result := aTemp;
          if (TimeStampComp(Result.LeaseTimeOut, aTemp.LeaseTimeOut) = 1) and (aTemp.Initialized) then
            Result := aTemp;
        end;
      end;
  except on E: Exception do
    BoldLogError('%s.GetFirstLeaseTimeOutClient Error: %s', [ClassName, E.Message]);
  end;
end;

procedure TClientHandler.GetRegisteredClientIDs(ClientIds: TStringList);
var
  i: Integer;
begin
  AcquireLock;
  try
    if Assigned(ClientIds) then
      for i:= 0 to fClientInfoList.Count - 1 do
        if Assigned(fClientInfoList[i]) then
          ClientIds.Add(Format('%d=%s', [fClientInfoList[i].ClientId, fClientInfoList[i].ClientIdString]));
  finally
    ReleaseLock;
  end;
end;

procedure TClientHandler.GetRegisteredClientInfos(ClientInfo: TStringList);
var
  i: integer;
  ClientInfoItem: TClientInfo;
  Guard: IBoldGuard;
  temp: TStringList;
begin
  if not Enabled then Exit;
  AcquireLock;
  try
    Guard := TBoldGuard.Create(Temp);
    Temp := TStringList.Create;
    Temp.Add('TotalClients='+IntToStr(fTotalClients));
    Temp.Add('PeakClients='+IntToStr(fPeakClients));
    Temp.Add('TotalLostEvents='+IntToStr(fTotalLostEvents));
    ClientInfo.Add(temp.CommaText);
    if Assigned(ClientInfo) then
      for i:= 0 to fClientInfoList.Count - 1 do
        if Assigned(fClientInfoList[i]) then
        begin
          ClientInfoItem := fClientInfoList[i];
          temp.Clear;
          Temp.Add('ID='                +IntToStr(ClientInfoItem.ClientId));
          Temp.Add('IDString='          +ClientInfoItem.ClientIdString);
          Temp.Add('RegistrationTime='  +FormatDateTime('yyyy-mm-dd hh:nn:ss', TimeStampToDateTime(ClientInfoItem.RegistrationTime)));
          Temp.Add('LeaseTimeout='      +FormatDateTime('yyyy-mm-dd hh:nn:ss', TimeStampToDateTime(ClientInfoItem.LeaseTimeOut)));
          ClientInfo.Add(Temp.CommaText);
        end;
  finally
    ReleaseLock;
  end;
end;

function TClientHandler.GetRegistrationTime(const ClientID: Integer;
  out RegistrationTime: TTimeStamp): Boolean;
var
  ClientInfo: TClientInfo;
begin
  Result := False;
  try
    AcquireLock;
    try
      Result := InfoForClient(ClientID, ClientInfo);
      if Result then
        RegistrationTime := ClientInfo.RegistrationTime;
    finally
      ReleaseLock;
    end;
  except on E: Exception do
    BoldLogError('%s.GetRegistrationTime Error: [ID=%d] %s)', [ClassName, ClientID, E.Message]);
  end;
end;


function TClientHandler.HasInfoForClient(ClientId: Integer;
  out ClientIdentifierString: string; out LeaseDuration: integer; out LeaseTimeOut: TTimeStamp;
  out Initialized: Boolean): Boolean;
var
 ClientInfo: TClientInfo;
begin
  Result := false;
  if not Enabled then Exit;
  AcquireLock;
  try
    Result := InfoForClient(ClientId, ClientInfo);
    Initialized := Result;;
    if Result then
    begin
      ClientIdentifierString := ClientInfo.ClientIdString;
      LeaseDuration := ClientInfo.LeaseDuration;
      LeaseTimeout := ClientInfo.LeaseTimeOut;
    end;
  finally
    ReleaseLock;
  end;
end;

function TClientHandler.InfoForClient(ClientID: Integer;
  out ClientInfo: TClientInfo): Boolean;
begin
  Result := Enabled;
  try
    if Result then
    begin
      ClientInfo := fClientInfoList.GetExistingClientInfo(ClientID);
      Result := Assigned(ClientInfo);
    end;
  except on E: Exception do
    BoldLogError('%s.InfoForClient Error: [ID=%d] %s)', [ClassName, ClientId, E.message]);
  end;
end;

function TClientHandler.InternalRemoveClient(
  ClientId: Integer): Boolean;
var
  ClientInfo: TClientInfo;
begin
  Result := false;
  if InfoForClient(ClientID, ClientInfo)  then
  begin
    Result := true;
    ClientInfo.RegistrationTime :=  DateTimetoTimeStamp(0);
    CLientInfo.Initialized := False;
    fClientInfoList.ReturnFreeClientId(ClientId);
    NOConnectedClients := NOConnectedClients - 1;
    SendExtendedEvent(self, BOLD_PROPAGATOR_CLIENT_REMOVED, [ClientID]);
  end;
end;

function TClientHandler.IsRegistered(
  const ClientId: Integer): Boolean;
begin
  Result := false;
  if not Enabled then Exit;
  AcquireLock;
  try
   Result := (ClientId >= 0) and (ClientId < fClientInfoList.fList.Count);
   if Result then
   begin
     Result := Assigned(fClientInfoList.fList[ClientId]) and ((fClientInfoList.fList[ClientId] as TClientInfo).Initialized);
   end;
  finally
    ReleaseLock;
  end;
end;

function TClientHandler.IsThereAClientTimingOutSoon(out ClientId: Integer):
    Boolean;
var
  i: integer;
  CurrentClientInfo, aTemp: TClientInfo;
begin
  result := false;
  CurrentClientInfo := nil;
  if not Enabled then Exit;
  try
    AcquireLock;
    try
      if (NoConnectedClients <> 0) then
      begin
        for i:= 0 to fClientInfoList.Count - 1 do
        begin
          aTemp := fClientInfoList[i];
          if Assigned(aTemp)  then
          begin
            if not Assigned(CurrentClientInfo) then
              CurrentClientInfo := aTemp;
            if CurrentClientInfo.Initialized and
              (TimeStampComp(CurrentClientInfo.LeaseTimeOut, aTemp.LeaseTimeOut) = 1) then
              CurrentClientInfo := aTemp;
          end;
        end;
        ClientId := CurrentClientInfo.ClientID;
//        RegistrationTime := CurrentClientInfo.RegistrationTime;
//        LeaseTimeOut := CurrentClientInfo.LeaseTimeOut;
      end;
    finally
      ReleaseLock;
    end;
  except on E: Exception do
    BoldLogError('%s.IsThereAClientTimingOutSoon Error: %s', [ClassName, E.Message]);
  end;
end;


procedure TClientHandler.NotifyLeaseChanged;
var
  TimeOutClient: TClientInfo;
  RegistrationTime, LeaseTimeOut: extended;
begin
  TimeOutClient := GetFirstLeaseTimeOutClient;
  if Assigned(TimeOutClient) then
  begin
    RegistrationTime := TimeStampToMSecs(TimeOutClient.RegistrationTime);
    LeaseTimeOut := TimeStampToMSecs(TimeOutClient.LeaseTimeOut);
    SendExtendedEvent(self, BOLD_PROPAGATOR_CLIENT_LEASE_CHANGED,
      [TimeOutClient.ClientID, RegistrationTime, LeaseTimeOut]);
  end;
end;

procedure TClientHandler.OnTimerEvent(Sender: TObject);
begin
  FTimer.Enabled := False;
  try
    CheckAndRemoveExpiredClients;
  finally // wrap up
    FTimer.Enabled := True;
  end;    // try/finally
end;

function TClientHandler.RegisterClient(LeaseDuration:Integer;
  const ClientIDString: WideString; out BoldClientID: Integer): HResult;
begin
  Result := S_FALSE;
  if not Enabled then
    Exit;

  AcquireLock;
  try
    try
      AddClient(LeaseDuration, ClientIDString, BoldClientID);
//      RegistrationTime := fClientInfoList[BoldClientId].RegistrationTime;
      SendExtendedEvent(self, BOLD_PROPAGATOR_CLIENT_REGISTERED, [BoldClientID]);
      NotifyLeaseChanged;
      BoldLog('Log In: %s [ID=%d]', [ClientIdString, BoldClientId]);
      inc(fTotalClients);
      if NoConnectedClients > fPeakClients then
        fPeakClients := NoConnectedClients;
      Result := S_OK;
    except on E: Exception do
      BoldLogError('%s.RegisterClient Error: [ID=%d] %s)', [ClassName, BOldClientID, E.Message]);
    end;
  finally
    ReleaseLock;
  end;
end;

procedure TClientHandler.ReleaseLock;
begin
  fClientHandlerLock.Release;
end;

procedure TClientHandler.RemoveExpiredLease(const ClientID: Integer;
  const RegistrationTime: TTimeStamp);
var
  ClientInfo: TClientInfo;
  IdString: string;
begin
  if not Enabled then Exit;
  InfoForClient(ClientId, ClientInfo);
  if Assigned(ClientInfo) and
    (TimeStampComp(ClientInfo.RegistrationTime, RegistrationTime) = 0) and
    (ClientInfo.LeaseIsExpired) then
  begin
    IdString := ClientInfo.ClientIdString;
    InternalRemoveClient(ClientID);
    SendExtendedEvent(self, BOLD_PROPAGATOR_CLIENT_LEASE_EXPIRED, [ClientID]);
    BoldLog('Lease Expired: %s [ID=%d] [Login: %s (%s ago)]',
            [IdString, ClientID,
            DateTimeToStr(TimeStampToDateTime(ClientInfo.RegistrationTime)),
            TimeToStr(now - TimeStampToDateTime(ClientInfo.RegistrationTime))]);
    NotifyLeaseChanged;
  end;
end;


procedure TClientHandler.SendEvents(ClientID: Integer; Event: TClientEvent);
var
  I: Integer;
  aClient:TClientInfo;
begin
  AcquireLock;
  try
    for I := 0 to fClientInfoList.Count - 1 do    // Iterate
    begin
      aClient := fClientInfoList.Items[i];
      if assigned(aClient) and (aClient.ClientID <> ClientID) then
        aClient.AddEvent(Event);
        
    end;    // for
  finally // wrap up
    ReleaseLock;
  end;    // try/finally
end;

procedure TClientHandler.SetEnabled(Value: Boolean);
begin
  AcquireLock;
  try
    if (Value <> fEnabled) then
    begin
      fEnabled := Value;
      if not fEnabled and Assigned(fClientInfoList) then
      begin
        fClientInfoList.Clear;
      end;
    end;
  finally
    ReleaseLock;
  end;
end;

procedure TClientHandler.SetNOConnectedClients(const Value: integer);
begin
  AcquireLock;
  try
    if (fNoConnectedClients <> Value) then
      fNoConnectedClients := Value;
  finally
    ReleaseLock;
  end;
end;

function TClientHandler.UnRegisterClient(BoldClientID: Integer): HResult;
var
  ClientInfo: TClientInfo;
  IdString: string;
begin
  Result := S_FALSE;
  if not Enabled then Exit;
  try
    AcquireLock;
    try
      if InfoForClient(BoldClientId, ClientInfo) then
      begin
        IdString := ClientInfo.ClientIdString;
        if InternalRemoveClient(BoldClientID) then
        begin
          Result := S_OK;
          SendExtendedEvent(self, BOLD_PROPAGATOR_CLIENT_UNREGISTERED, [BoldClientID]);
          NotifyLeaseChanged;
          BoldLog('Log Off: %s [ID=%d] [Login: %s (%s ago) Status: %s]',
              [IdString, BoldClientId,
              DateTimeToStr(TimeStampToDateTime(ClientInfo.RegistrationTime)),
              TimeToStr(now - TimeStampToDateTime(ClientInfo.RegistrationTime))]);
        end;
      end;
    finally
      ReleaseLock;
    end;
  except on E: Exception do
    BoldLogError('%s.UnRegisterClient Error: [ID=%d] %s)', [ClassName, BoldClientId, E.Message]);
  end;
end;

end.
