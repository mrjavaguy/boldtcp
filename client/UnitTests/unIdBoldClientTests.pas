unit unIdBoldClientTests;

interface
uses
  Classes,
  SysUtils,
  TestFramework,
  unPropagatorServer,
  IdBoldClient;

type
  TTestBoldClient = class(TTestCase)
  private
    FServer:TPropagatorServer;
    FClient:TIdBoldClient;
  protected
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestLogin;
    procedure TestLogOut;
    procedure TestTransmit;
    procedure TestPolling;
  end;

implementation

uses BoldTCPGlobals;

{ TTestBoldServer }

procedure TTestBoldClient.Setup;
begin
  inherited;
  FServer := TPropagatorServer.Create;
  FClient := TIdBoldClient.Create(nil);
  FClient.Port := IdPORT_BOLD;
  FClient.Connect;
  FClient.GetResponse(220);
  FClient.Greeting.Assign(FClient.LastCmdResult);
end;

procedure TTestBoldClient.TearDown;
begin
  inherited;
  FreeAndNil(FClient);
  FreeAndNil(FServer);
end;

procedure TTestBoldClient.TestLogin;
begin
  CheckNotEquals(InvalidClientNumber,FClient.Login('Eric',DEFAULT_LEASE_DURATION));
end;

procedure TTestBoldClient.TestLogOut;
var
  ClientID:Integer;
begin
  ClientID := FClient.Login('Eric',DEFAULT_LEASE_DURATION);
  CheckTrue(FClient.LogOut(ClientID));
end;

procedure TTestBoldClient.TestPolling;
const
  NoOfEvents = 10;
var
  ClientID2,
  ClientID1:Integer;
  i:integer;
begin
  ClientID1 := FClient.Login('Test1',DEFAULT_LEASE_DURATION);
  ClientID2 := FClient.Login('Test2',DEFAULT_LEASE_DURATION);
  for I := 1 to NoOfEvents do    // Iterate
  begin
     FClient.Transmit(ClientID1,Format('E:%d',[i]));
  end;    // for
  sleep(100);
  FClient.Polling(ClientID2);
  CheckEquals(NoOfEvents,FClient.Events.Count,'Wrong Number of Events');
  for I := 1 to NoOfEvents do    // Iterate
  begin
    CheckEquals(Format('E:%d',[i]),FClient.Events[i-1],'Invalid Event');

  end;    // for
  CheckTrue(FClient.LogOut(ClientID1));
  CheckTrue(FClient.LogOut(ClientID2));
end;

procedure TTestBoldClient.TestTransmit;
var
  ClientID:Integer;
begin
  ClientID := FClient.Login('Eric',DEFAULT_LEASE_DURATION);
  FClient.Transmit(ClientID,'E:1');
  CheckTrue(FClient.LogOut(ClientID));
end;

initialization
  RegisterTest('BoldTCPClient', TTestBoldClient.Suite);


end.
