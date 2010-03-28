unit ClientHandlerTests;

interface
uses
  Classes,
  SysUtils,
  TestFramework,
  unClientNotifier,
  unClientHandler;


type
  TClientInfoTest = class(TTestCase)
  private
    FClientInfo: TClientInfo;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestGetEvents;
  end;

  TClientHandlerTest  = class(TTestCase)
  private
    FClientHandler:TClientHandler;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestSendEvents;
  end;

  TClientNotifierTest  = class(TTestCase)
  private
    FClientHandler:TClientHandler;
    fClientNotifierHandler: TClientNotifier;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestSendEvents;
    procedure TestClientTimedOut;
  end;


implementation

uses BoldTCPGlobals;

{ TClientInfoTest }

procedure TClientInfoTest.Setup;
begin
  inherited;
  FClientInfo := TClientInfo.Create(1,DEFAULT_LEASE_DURATION,'Test');
end;

procedure TClientInfoTest.TearDown;
begin
  inherited;
  FreeAndNil(FClientInfo);
end;

procedure TClientInfoTest.TestGetEvents;
var
  I: Integer;
  Events:TStrings;
begin
  Events := TStringList.Create;
  try
    FCLientInfo.AddEvent(TClientEvent.Create('E:1'));
    FClientInfo.GetEvents(Events);
    CheckEquals(1,Events.Count);
    FCLientInfo.AddEvent(TClientEvent.Create('E:1'));
    FCLientInfo.AddEvent(TClientEvent.Create('E:2'));
    FClientInfo.GetEvents(Events);
    CheckEquals(2,Events.Count);
    FCLientInfo.AddEvent(TClientEvent.Create('E:1'));
    FCLientInfo.AddEvent(TClientEvent.Create('E:2'));
    FCLientInfo.AddEvent(TClientEvent.Create('E:3'));
    FClientInfo.GetEvents(Events);
    CheckEquals(3,Events.Count);
    for I := 0 to Events.Count - 1 do    // Iterate
    begin
      CheckEquals(Format('E:%d',[i+1]),Events[i]);
    end;    // for
  finally
  	Events.Free;
  end;  // try/finally
end;

{ TClientHandlerTest }

procedure TClientHandlerTest.Setup;
begin
  inherited;
  fClientHandler := TClientHandler.Create;
end;

procedure TClientHandlerTest.TearDown;
begin
  inherited;
  FreeAndNil(FClientHandler);
end;

procedure TClientHandlerTest.TestSendEvents;
var
  ClientID1,
  ClientID2:Integer;
  aClient:TClientInfo;
  I: Integer;
  Events:TStrings;
begin
  Events := TStringList.Create;
  try
    FClientHandler.RegisterClient(DEFAULT_LEASE_DURATION,'Client 1',ClientID1);
    FClientHandler.RegisterClient(DEFAULT_LEASE_DURATION,'Client 2',ClientID2);
    FClientHandler.SendEvents(ClientID1,TClientEvent.Create('E:1'));
    aClient := FClientHandler.GetClientByID(ClientID2);
    AClient.GetEvents(Events);
    CheckEquals(1,Events.Count);
    FClientHandler.SendEvents(ClientID1,TClientEvent.Create('E:1'));
    FClientHandler.SendEvents(ClientID1,TClientEvent.Create('E:1'));
    AClient.GetEvents(Events);
    CheckEquals(2,Events.Count);
    FClientHandler.SendEvents(ClientID1,TClientEvent.Create('E:1'));
    FClientHandler.SendEvents(ClientID1,TClientEvent.Create('E:2'));
    FClientHandler.SendEvents(ClientID1,TClientEvent.Create('E:3'));
    AClient.GetEvents(Events);
    CheckEquals(3,Events.Count);
    for I := 0 to Events.Count - 1 do    // Iterate
    begin
      CheckEquals(Format('E:%d',[i+1]),Events[i]);
    end;    // for
  finally
  	Events.Free;
  end;  // try/finally
end;

{ TClientNotifierTest }

procedure TClientNotifierTest.Setup;
begin
  inherited;
  fClientHandler := TClientHandler.Create;
  fClientNotifierHandler:= TClientNotifier.Create(fClientHandler);
  fClientNotifierHandler.Resume;
  fClientNotifierHandler.WaitUntilReady(TIMEOUT);
end;

procedure TClientNotifierTest.TearDown;
begin
  inherited;
  fClientNotifierHandler.Quit(True);
  FreeAndNil(fClientNotifierHandler);
  FreeAndNil(fClientHandler);
end;

procedure TClientNotifierTest.TestClientTimedOut;
var
  ClientID1,
  ClientID2:Integer;
  aClient:TClientInfo;
begin
  FClientHandler.RegisterClient(DEFAULT_LEASE_DURATION,'Client 1',ClientID1);
  FClientHandler.RegisterClient(100,'Client 2',ClientID2);
  aClient := FClientHandler.GetClientByID(ClientID2);
  CheckTrue(FClientHandler.IsRegistered(ClientID2));
  sleep(200);
  fClientNotifierHandler.Notify(TM_CHECK_LEASE);
  sleep(200);
  fClientNotifierHandler.Notify(TM_CHECK_LEASE);
  CheckFalse(FClientHandler.IsRegistered(ClientID2));

end;

procedure TClientNotifierTest.TestSendEvents;
var
  ClientID1,
  ClientID2:Integer;
  aClient:TClientInfo;
  I: Integer;
  Events:TStrings;
begin
  Events := TStringList.Create;
  try
    FClientHandler.RegisterClient(DEFAULT_LEASE_DURATION,'Client 1',ClientID1);
    FClientHandler.RegisterClient(DEFAULT_LEASE_DURATION,'Client 2',ClientID2);
    aClient := FClientHandler.GetClientByID(ClientID2);

    fClientNotifierHandler.NotifyClientsOfEvent(ClientID1,'E:1');
    fClientNotifierHandler.NotifyClientsOfEvent(ClientID1,'E:2');
    fClientNotifierHandler.NotifyClientsOfEvent(ClientID1,'E:3');

    Sleep(100); // Wait for Messages

    AClient.GetEvents(Events);
    CheckEquals(3,Events.Count);
    for I := 0 to Events.Count - 1 do    // Iterate
    begin
      CheckEquals(Format('E:%d',[i+1]),Events[i]);
    end;    // for
  finally
  	Events.Free;
  end;  // try/finally
end;

initialization
  RegisterTest('ClientHandler', TClientInfoTest.Suite);
  RegisterTest('ClientHandler', TClientHandlerTest.Suite);
  RegisterTest('ClientNotifier', TClientNotifierTest.Suite);
end.
