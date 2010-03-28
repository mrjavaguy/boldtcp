unit IdBoldServer;

interface

uses
  Classes,
  SysUtils,
  IdAssignedNumbers,
  IdException,
  IdTCPServer,
  IdTCPConnection,
  IdThread,
  IdRFCReply;


type

  TOnClientLoginEvent = procedure(ASender: TIdCommand; LeaseDuration: Integer; const ClientIDString:String;
    var AClientID: Integer) of object;

  TOnCommandEvent = procedure(ASender: TIdCommand; AClientID: Integer) of object;
  TOnPollingEvent = procedure(ASender: TIdCommand; AClientID: Integer; var PollingEvents:TStrings) of object;
  TOnLockEvent = procedure(ASender: TIdCommand; AClientID: Integer; var Locked:Boolean; var LockedItems:TStrings) of object;
  TOnCheckLocksEvent = procedure(ASender: TIdCommand; AClientID: Integer; var Locked:Boolean) of object;
  TOnClientMonitorEvent = procedure(ASender: TIdCommand; var ClientEvents:TStrings) of object;


  TIdBoldTCPServer = class(TIdTCPServer)
  private
    FOnClientLoginEvent : TOnClientLoginEvent;
    FOnClientLogoutEvent : TOnCommandEvent;
    FOnTransmitEvent: TOnCommandEvent;
    FOnPollingEvent: TOnPollingEvent;
    FOnLockingEvent:TOnLockEvent;
    FOnCheckLocksEvent:TOnCheckLocksEvent;
    FOnUnLockEvent:TOnCheckLocksEvent;
    FOnClientMonitorEvent:TOnClientMonitorEvent;
  //  Commands
    procedure CommandLOGIN(ASender: TIdCommand);
    procedure CommandLOGOUT(ASender: TIdCommand);
    procedure CommandTRANSMIT(ASender: TIdCommand);
    procedure CommandPOLLING(ASender: TIdCommand);
    procedure CommandLOCK(ASender:TidCommand);
    procedure CommandCHECKLOCK(ASender:TidCommand);
    procedure CommandUNLOCK(ASender:TidCommand);
    procedure CommandCLIENTEVENTS(ASender:TidCommand);

    procedure DoClientLogin(ASender: TIdCommand; var AClientID: Integer);
    procedure DoClientLogout(ASender: TIdCommand);
    procedure DoTransmitEvents(ASender: TIdCommand);
    procedure DoPollingEvents(ASender: TIdCommand; var PollingEvents: TStrings);
    procedure DoLockEvents(ASender:TidCommand; var Locked:Boolean; var LockedItems:TStrings);
    procedure DoCheckLocks(ASender:TidCommand; var Locked:Boolean);
    procedure DoUnlock(ASender:TidCommand; var Locked:Boolean);
    procedure DoClientEvents(ASender: TidCommand; var Events:TStrings);
  protected
    procedure InitializeCommandHandlers; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property OnClientLoginEvent:TOnClientLoginEvent read FOnClientLoginEvent write FOnClientLoginEvent;
    property OnClientLogoutEvent:TOnCommandEvent read FOnClientLogoutEvent write FOnClientLogoutEvent;
    property OnTransmitEvents:TOnCommandEvent read FOnTransmitEvent write FOnTransmitEvent;
    property OnPollingEvent:TOnPollingEvent read FOnPollingEvent write FOnPollingEvent;
    property OnLockingEvent:TOnLockEvent read FOnLockingEvent write FOnLockingEvent;
    property OnCheckLocksEvent:TOnCheckLocksEvent read FOnCheckLocksEvent write FOnCheckLocksEvent;
    property OnUnlockEvent:TOnCheckLocksEvent read FOnUnLockEvent write FOnUnLockEvent;
    property OnClientMonitorEvents:TOnClientMonitorEvent read FOnClientMonitorEvent write FOnClientMonitorEvent;
  end;

implementation

uses BoldTCPGlobals, BoldTCPResourceStrings;

{ TIdBoldTCPServer }

procedure TIdBoldTCPServer.CommandCHECKLOCK(ASender: TidCommand);
var
  Locked:Boolean;
begin
  DoCheckLocks(ASender,Locked);
  if Locked then
  begin
    ASender.Reply.NumericCode := 400;
    ASender.SendReply;
  end
  else
  begin
    ASender.Reply.NumericCode := 500;
    ASender.SendReply;
  end;
end;

procedure TIdBoldTCPServer.CommandCLIENTEVENTS(ASender: TidCommand);
var
  tempStrings:TStrings;
begin
  tempStrings := ASender.Reply.Text;
  DoClientEvents(ASender, tempStrings);
  ASender.Reply.NumericCode := 220;
  ASender.SendReply;
end;

procedure TIdBoldTCPServer.CommandLOCK(ASender: TidCommand);
var
  Locked:Boolean;
  tempStrings:TStrings;
begin
  tempStrings := ASender.Reply.Text;
  DoLockEvents(ASender,Locked,tempStrings);
  if Locked then
  begin
    ASender.Reply.NumericCode := 400;
    ASender.SendReply;
  end
  else
  begin
    ASender.Reply.NumericCode := 500;
    ASender.SendReply;
  end;
end;

procedure TIdBoldTCPServer.CommandLOGIN(ASender: TIdCommand);
var
  aClientID:Integer;
begin
  DoClientLogin(ASender,aClientID);
  ASender.Reply.NumericCode := 220;
  ASender.Reply.Text.Add(IntToStr(AClientID));
  ASender.SendReply;
end;

procedure TIdBoldTCPServer.CommandLOGOUT(ASender: TIdCommand);
begin
  DoClientLogout(ASender);
  ASender.Reply.NumericCode := 220;
  ASender.SendReply;
end;

procedure TIdBoldTCPServer.CommandPOLLING(ASender: TIdCommand);
var
  tempStrings:TStrings;
begin
  tempStrings := ASender.Reply.Text;
  DoPollingEvents(ASender, tempStrings);
  ASender.Reply.NumericCode := 220;
  ASender.SendReply;
end;

procedure TIdBoldTCPServer.CommandTRANSMIT(ASender: TIdCommand);
begin
  ASender.Reply.NumericCode := 220;
  ASender.SendReply;
  DoTransmitEvents(ASender);
end;

procedure TIdBoldTCPServer.CommandUNLOCK(ASender: TidCommand);
var
  Locked:Boolean;
begin
  DoUnlock(ASender,Locked);
  if Locked then
  begin
    ASender.Reply.NumericCode := 400;
    ASender.SendReply;
  end
  else
  begin
    ASender.Reply.NumericCode := 500;
    ASender.SendReply;
  end;
end;

constructor TIdBoldTCPServer.Create(AOwner: TComponent);
begin
  inherited;
  Greeting.NumericCode := 220;
  Greeting.Text.Text := RSBoldDefaultGreeting;
  DefaultPort := IdPORT_BOLD;
end;

destructor TIdBoldTCPServer.Destroy;
begin

  inherited;
end;

procedure TIdBoldTCPServer.DoCheckLocks(ASender: TidCommand;
  var Locked: Boolean);
var
  ClientID:Integer;
begin
  ClientID := StrtoIntDef(ASender.Params[0],InvalidClientNumber);
  Locked := False;
  if assigned(FOnCheckLocksEvent) then
    FOnCheckLocksEvent(ASender,ClientID,Locked);
end;

procedure TIdBoldTCPServer.DoClientEvents(ASender: TidCommand;
  var Events: TStrings);
begin
  if assigned(FOnClientMonitorEvent) then
    FOnClientMonitorEvent(ASender, Events);
end;

procedure TIdBoldTCPServer.DoClientLogin(ASender: TIdCommand;
    var AClientID: Integer);
var
  LeaseDuration:Integer;
  ClientIDString:String;
begin
  AClientID := InvalidClientNumber;
  LeaseDuration := StrToIntDef(ASender.Params[1],DEFAULT_LEASE_DURATION);
  ClientIDString := ASender.Params[0];
  if assigned(FOnClientLoginEvent) then
    FOnClientLoginEvent(ASender,LeaseDuration,ClientIDString,AClientID);
end;

procedure TIdBoldTCPServer.DoClientLogout(ASender: TIdCommand);
var
  ClientID:Integer;
begin
  ClientID := StrtoIntDef(ASender.Params[0],InvalidClientNumber);
  if assigned(FOnClientLogoutEvent) then
    FOnClientLogoutEvent(ASender,ClientID);
end;

procedure TIdBoldTCPServer.DoLockEvents(ASender:TidCommand; var Locked:Boolean; var LockedItems:TStrings);
var
  ClientID:Integer;
begin
  ClientID := StrtoIntDef(ASender.Params[0],InvalidClientNumber);
  Locked := False;
  LockedItems.Text := 'No Lock Handler assigned';
  if assigned(FOnLockingEvent) then
    FOnLockingEvent(ASender,ClientID,Locked,LockedItems);
end;

procedure TIdBoldTCPServer.DoPollingEvents(ASender: TIdCommand;
  var PollingEvents: TStrings);
var
  ClientID:Integer;
begin
  ClientID := StrtoIntDef(ASender.Params[0],InvalidClientNumber);
  if assigned(FOnPollingEvent) then
    FOnPollingEvent(ASender,ClientID, PollingEvents);

end;

procedure TIdBoldTCPServer.DoTransmitEvents(ASender: TIdCommand);
var
  ClientID:Integer;
begin
  ClientID := StrtoIntDef(ASender.Params[0],InvalidClientNumber);
  if assigned(FOnTransmitEvent) then
    FOnTransmitEvent(ASender,ClientID);
end;

procedure TIdBoldTCPServer.DoUnlock(ASender: TidCommand;
  var Locked: Boolean);
var
  ClientID:Integer;
begin
  ClientID := StrtoIntDef(ASender.Params[0],InvalidClientNumber);
  Locked := False;
  if assigned(FOnUnlockEvent) then
    FOnUnlockEvent(ASender,ClientID,Locked);
end;

procedure TIdBoldTCPServer.InitializeCommandHandlers;
begin
  inherited;
  with CommandHandlers.Add do begin
    Command := RSLOGIN;
    OnCommand := CommandLOGIN;
  end;
  with CommandHandlers.Add do begin
    Command := RSLOGOUT;
    OnCommand := CommandLOGOUT;
  end;
  with CommandHandlers.Add do begin
    Command := RSTRANSMIT;
    OnCommand := CommandTRANSMIT;
  end;
  with CommandHandlers.Add do begin
    Command := RSPOLLING;
    OnCommand := CommandPOLLING;
  end;
  with CommandHandlers.Add do begin
    Command := RSLOCK;
    OnCommand := CommandLOCK;
  end;
  with CommandHandlers.Add do begin
    Command := RSCHECKLOCK;
    OnCommand := CommandCHECKLOCK;
  end;
  with CommandHandlers.Add do begin
    Command := RSUNLOCK;
    OnCommand := CommandUNLOCK;
  end;
  with CommandHandlers.Add do begin
    Command := RSMONITOR;
    OnCommand := CommandCLIENTEVENTS;
  end;

end;

end.
