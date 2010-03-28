unit unUIManager;

interface

uses
  Classes,
  SysUtils,
  unClientHandler,
  BoldSubscription,
  BoldGuard,
  BoldDefs,
  syncobjs;


type
  TUIManager = class(TBoldPassthroughSubscriber)
  private
    fClientHandler: TClientHandler;
    fEnabled: Boolean;
    FClientEvents:TStrings;
    procedure setClientHandler(const Value: TClientHandler);
    function GetClientEvents: TStrings;
  protected
    procedure AddClientEvent(CLientID:Integer);
    procedure RemoveClientEvent(ClientID:Integer);
    procedure UpdateClient(CLientID:Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure OnGetExtendedEvent(Originator: TObject; OriginalEvent: TBoldEvent; RequestedEvent: TBoldRequestedEvent; const Args: array of const);
    property ClientHandler: TClientHandler read fClientHandler write setClientHandler;
    property Enabled: Boolean read fEnabled write fEnabled;
    property UIEvents:TStrings read GetClientEvents;
  end;

implementation

uses BoldTCPGlobals;

{ TUIManager }

procedure TUIManager.AddClientEvent(CLientID: Integer);
var
  ClientIDString:String;
  LeaseDuration:Integer;
  LeaseTimeOut:TTimestamp;
  Initialized:Boolean;
  temp: TStringList;
begin
  ClientHandler.HasInfoForClient(ClientID,ClientIDString,LeaseDuration,LeaseTimeOut,Initialized);
  temp := TStringList.Create;
  try
    Temp.Add('ID='                +IntToStr(ClientId));
    Temp.Add('IDString='          +ClientIdString);
    Temp.Add('LeaseDuration='     +InttoStr(LeaseDuration));
    Temp.Add('LeaseTimeout='      +FormatDateTime('yyyy-mm-dd hh:nn:ss', TimeStampToDateTime(LeaseTimeOut)));
    FClientEvents.Add(Temp.CommaText);
  finally // wrap up
    FreeAndNil(temp);
  end;    // try/finally
end;

constructor TUIManager.Create;
begin
  inherited CreateWithExtendedReceive(OnGetExtendedEvent);
  fEnabled := false;
  FClientEvents := TStringList.Create;

end;

destructor TUIManager.Destroy;
begin
  CancelAllSubscriptions;
  FreeAndNil(FClientEvents);
  inherited;
end;

function TUIManager.GetClientEvents: TStrings;
begin
  Result := FClientEvents;
end;

procedure TUIManager.OnGetExtendedEvent(Originator: TObject;
  OriginalEvent: TBoldEvent; RequestedEvent: TBoldRequestedEvent;
  const Args: array of const);
begin
  if fEnabled then
  begin
    if  (RequestedEvent = breClientAdded) then
    begin
      AddClientEvent(Args[0].VInteger);
    end;
    if (RequestedEvent = breClientRemoved) then
    begin
      RemoveClientEvent(Args[0].VInteger);
    end;
    if (RequestedEvent = BOLD_PROPAGATOR_CLIENT_LEASE_EXTENDED) then
    begin
      UpdateClient(Args[0].VInteger);
    end;
      
  end;

end;

procedure TUIManager.RemoveClientEvent(ClientID: Integer);
begin
  FClientEvents.Add('ID='                +IntToStr(ClientId));
end;

procedure TUIManager.setClientHandler(const Value: TClientHandler);
begin
  fClientHandler := Value;
  fEnabled := True;
  ClientHandler.AddSubscription(self, BOLD_PROPAGATOR_CLIENT_REGISTERED, breClientAdded);
  ClientHandler.AddSubscription(self, BOLD_PROPAGATOR_CLIENT_REMOVED, breClientRemoved);
  ClientHandler.AddSubscription(self, BOLD_PROPAGATOR_CLIENT_LEASE_EXTENDED, BOLD_PROPAGATOR_CLIENT_LEASE_EXTENDED);
end;

procedure TUIManager.UpdateClient(CLientID: Integer);
var
  ClientIDString:String;
  LeaseDuration:Integer;
  LeaseTimeOut:TTimestamp;
  Initialized:Boolean;
  temp: TStringList;
begin
  ClientHandler.HasInfoForClient(ClientID,ClientIDString,LeaseDuration,LeaseTimeOut,Initialized);
  temp := TStringList.Create;
  try
    Temp.Add('ID='                +IntToStr(ClientId));
    Temp.Add('LeaseTimeout='      +FormatDateTime('yyyy-mm-dd hh:nn:ss', TimeStampToDateTime(LeaseTimeOut)));
    FClientEvents.Add(Temp.CommaText);
  finally // wrap up
    FreeAndNil(temp);
  end;    // try/finally
end;

end.
