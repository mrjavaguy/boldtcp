unit unClientNotifier;

interface

uses
  SysUtils,
  Classes,
  Windows,
  Messages,
  unClientHandler,
  BoldTCPGlobals,
  BoldThread;

type
  TClientNotifier = class(TBoldNotifiableThread)
  private
    FClientHandler:TClientHandler;
  protected
    procedure ProcessEvents(ClientID:Integer; Event:TClientEvent);
    procedure CheckLease;
    property ClientHandler:TClientHandler read FClientHandler;
  public
    constructor Create(aClientHandler:TClientHandler);
    procedure Execute; override;
    procedure NotifyClientsOfEvent(ClientID:Integer; Event:String);
  end;


implementation

uses
  BoldThreadSafeLog;


{ TClientNotifier }

procedure TClientNotifier.CheckLease;
var
  ClientID:Integer;
begin
  FClientHandler.IsThereAClientTimingOutSoon(ClientID);
  if (ClientID <> InvalidClientNumber) and (FClientHandler.GetClientByID(ClientID).LeaseIsExpired) then
    FClientHandler.DisconnectClient(ClientID)
end;

constructor TClientNotifier.Create(aClientHandler: TClientHandler);
begin
  inherited Create(True);
  FClientHandler := aClientHandler;
end;

procedure TClientNotifier.Execute;
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
           ProcessEvents(rMsg.wParam,TClientEvent(rMsg.lParam))
        else
        if rMsg.message = TM_CHECK_LEASE then
           CheckLease
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

procedure TClientNotifier.NotifyClientsOfEvent(ClientID: Integer;
  Event: String);
var
  aEvent:TClientEvent;
begin
  if Event <> '' then
  begin
    aEvent := TClientEvent.Create(Event);
    PostThreadMessage(ThreadID, TM_CLIENT_EVENT , ClientID, Integer(aEvent));
  end;
end;

procedure TClientNotifier.ProcessEvents(ClientID: Integer;
  Event: TClientEvent);
begin
  FClientHandler.SendEvents(ClientID,Event);
end;


end.
