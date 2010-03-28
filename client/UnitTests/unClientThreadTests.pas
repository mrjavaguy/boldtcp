unit unClientThreadTests;

interface

uses
  Forms,
  RecieverTestForm,
  Classes,
  Controls,
  Messages,
  SysUtils,
  BoldTCPGlobals,
  TestFramework,
  NotificationUnit,
  unPropagatorServer,
  unClientThread;

type

  TTestClientThread = class(TTestCase)
  private
    FServer:TPropagatorServer;
    FClient:TClientThread;
    FReciever:TThreadReceive;
    FNotificationManager:TNotificationManager;
  protected
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestLogin;
    procedure TestLogOut;
    procedure TestTransmit;
  end;

implementation


{ TTestClientThread }

procedure TTestClientThread.Setup;
begin
  inherited;
  FReciever := TThreadReceive.Create(nil);
  FServer := TPropagatorServer.Create;
  FNotificationManager := TNotificationManager.Create(nil);
  FClient := TClientThread.Create(FNotificationManager);
  FClient.Port := IdPORT_BOLD;
  FClient.Resume;
end;

procedure TTestClientThread.TearDown;
begin
  inherited;
  fClient.Quit(True);
  FreeAndNil(FClient);
  FreeAndNil(FNotificationManager);
  FreeAndNil(FReciever);
  FreeAndNil(FServer);
end;

procedure TTestClientThread.TestLogin;
begin
  CheckNotEquals(InvalidClientNumber,FClient.Login('Eric',DEFAULT_LEASE_DURATION));
  CheckTrue(FClient.LogedIn);
end;

procedure TTestClientThread.TestLogOut;
var
  ClientID:Integer;
begin
  ClientID := FClient.Login('Eric',DEFAULT_LEASE_DURATION);
  FClient.LogOut(ClientID);
  CheckFalse(FClient.LogedIn);
end;


procedure TTestClientThread.TestTransmit;
var
  ClientID:Integer;
begin
  ClientID := FClient.Login('Eric',DEFAULT_LEASE_DURATION);
  FClient.Transmit(ClientID,'E:1');
  FClient.LogOut(ClientID);
  CheckFalse(FClient.LogedIn);
end;

initialization
  RegisterTest('BoldTCPClient', TTestClientThread.Suite);


end.
