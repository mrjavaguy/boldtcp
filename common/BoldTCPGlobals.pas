unit BoldTCPGlobals;

interface

uses
  Messages;

const
  IdPORT_BOLD = 9000;
  DEFAULT_LEASE_DURATION = 1000*60*5;
  MINIMAL_CLIENT_INFO_LIST_GROWTH = 100;
  MINIMAL_FREE_CLIENTID_COUNT = 100;
  DEFAULT_NAME_STRING = '<Name>';

  {events that can be subscribed to}
  BOLD_PROPAGATOR_CLIENT_UNREGISTERED = 45;
  BOLD_PROPAGATOR_CLIENT_LIST_NOT_EMPTY = 46;
  BOLD_PROPAGATOR_CLIENT_LIST_EMPTY = 47;
  BOLD_PROPAGATOR_CLIENT_LEASE_CHANGED = 48;
  BOLD_PROPAGATOR_CLIENT_REGISTERED = 49;
  BOLD_PROPAGATOR_CLIENT_LEASE_EXPIRED = 50;
  BOLD_PROPAGATOR_CLIENT_LEASE_EXTENDED = 51;
  BOLD_PROPAGATOR_CLIENT_REMOVED = 52;
  BOLD_PROPAGATOR_CLIENT_CONNECTION_LOST = 53;

  breClientAdded = 150;
  breClientRemoved = 151;


  TIMEOUT = 1000;

  InvalidClientNumber = -1;

  TM_CLIENT_EVENT = WM_USER + 100;
  TM_CHECK_LEASE = WM_USER + 101;
  TM_POLL_EVENT = WM_USER + 102;

type
  TClientEvent = class
  private
    FEvent:String;
  public
    constructor Create(aEvent:String);
    property Event:String read FEvent;
  end;



implementation
{ TClientEvent }

constructor TClientEvent.Create(aEvent: String);
begin
  inherited Create;
  FEvent := aEvent;
end;

end.
