unit IdBoldServerTest;

interface

uses
  Classes,
  SysUtils,
  TestFramework,
  IdTCPClient,
  IdThread,
  IdTCPServer,
  IdBoldServer;

type
  TTestBoldServer = class(TTestCase)
  private
    FUnlockCalled: boolean;
    FServer:TIdBoldTCPServer;
    FClient:TIdTCPClient;
    FLogOutCalled:Boolean;
    FTransmitCount:Integer;
    FCheckLockCalled:Boolean;
  protected
     procedure Login(ASender: TIdCommand; LeaseDuration: Integer; const ClientIDString:String;
       var AClientID: Integer);
     procedure Logout(ASender: TIdCommand; AClientID: Integer);
     procedure Transmit(ASender: TIdCommand; AClientID: Integer);
     procedure Polling(ASender: TIdCommand; AClientID: Integer; var PollEvents:TStrings);
     procedure Locking(ASender: TIdCommand; AClientID: Integer; var Locked:Boolean; var LockedItems:Tstrings);
     procedure CheckLocks(ASender: TIdCommand; AClientID: Integer; var Locked:Boolean);
     procedure UnLock(ASender: TIdCommand; AClientID: Integer; var Locked:Boolean);
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestLogin;
    procedure TestLogOut;
    procedure TestTransmit;
    procedure TestPolling;
    procedure TestLock;
    procedure TestCheckLocks;
    procedure TestUnLock;
  end;

implementation

uses
  GmXml,
  BoldTCPGlobals,
  BoldTCPResourceStrings;

procedure TTestBoldServer.CheckLocks(ASender: TIdCommand;
  AClientID: Integer; var Locked: Boolean);
begin
  FCheckLockCalled := True;
end;

procedure TTestBoldServer.Locking(ASender: TIdCommand; AClientID: Integer;
  var Locked: Boolean; var LockedItems: Tstrings);
begin
  LockedItems.Clear;
  LockedItems.AddStrings(ASender.Params);
  LockedItems.Delete(0);
end;

procedure TTestBoldServer.Login(ASender: TIdCommand;
  LeaseDuration: Integer; const ClientIDString: String;
  var AClientID: Integer);
begin
  AClientID := 1;
end;

procedure TTestBoldServer.Logout(ASender: TIdCommand; AClientID: Integer);
begin
  FLogOutCalled := True;
end;

procedure TTestBoldServer.Polling(ASender: TIdCommand; AClientID: Integer;
  var PollEvents: TStrings);
begin
  PollEvents.Add('E:1');
  PollEvents.Add('E:2');
end;

procedure TTestBoldServer.Setup;
begin
  FServer := TIdBoldTCPServer.Create(nil);
  FServer.Active := True;
  FClient := TIdTCPClient.Create(nil);
  FClient.Port := IdPORT_BOLD;
  FClient.Connect;
  FClient.GetResponse(220);
  FClient.Greeting.Assign(FClient.LastCmdResult);
end;

procedure TTestBoldServer.TearDown;
begin
  FreeAndNil(FServer);
  FreeAndNil(FClient);
end;

procedure TTestBoldServer.TestCheckLocks;
var
  ClientID:Integer;
  XMLDoc:TGmXML;
  tmpStrings:TStrings;
begin
  XMLDoc := TGmXML.Create(nil);
  tmpStrings := TStringList.Create;
  try
    FServer.OnCheckLocksEvent := CheckLocks;
    XMLDoc.IncludeHeader := False;
    XMLDoc.AutoIndent := False;
    with XMLDoc.Nodes do
    begin
      AddOpenTag('Locks');
      AddOpenTag('Exclusive');
      AddLeaf('Lock').asString := 'DBLock';
      AddLeaf('Lock').asString := 'E:1';
      AddCloseTag;
      AddOpenTag('Shared');
      AddLeaf('Lock').asString := 'DBLock';
      AddLeaf('Lock').asString := 'E:1';
      AddCloseTag;
      AddCloseTag;
    end;
    tmpStrings.Text := XMLDoc.Text;
    tmpStrings.Delimiter := ' ';
    FClient.LastCmdResult.Clear;
    FClient.SendCmd(RSLOGIN+' ERIC 20000',[220]);
    ClientID := StrtoIntDef(FClient.LastCmdResult.Text[0],InvalidClientNumber);
    FTransmitCount := 0;
    FClient.LastCmdResult.Clear;
    FClient.SendCmd(RSCHECKLOCK + ' '+IntToStr(ClientID)+' '+tmpStrings.DelimitedText,[400,500]);
    CHeckTrue(FCheckLockCalled);
    FClient.LastCmdResult.Clear;
    FClient.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID),[220]);

  finally // wrap up
    FreeAndNil(XMldoc);
    FreeAndNil(tmpStrings);
  end;    // try/finally
end;

procedure TTestBoldServer.TestLock;
var
  ClientID:Integer;
  XMLDoc:TGmXML;
  tmpStrings:TStrings;
begin
  XMLDoc := TGmXML.Create(nil);
  tmpStrings := TStringList.Create;
  try
    FServer.OnLockingEvent := Locking;
    XMLDoc.IncludeHeader := False;
    XMLDoc.AutoIndent := False;
    with XMLDoc.Nodes do
    begin
      AddOpenTag('Locks');
      AddOpenTag('Exclusive');
      AddLeaf('Lock').asString := 'DBLock';
      AddLeaf('Lock').asString := 'E:1';
      AddCloseTag;
      AddOpenTag('Shared');
      AddLeaf('Lock').asString := 'DBLock';
      AddLeaf('Lock').asString := 'E:1';
      AddCloseTag;
      AddCloseTag;
    end;
    tmpStrings.Text := XMLDoc.Text;
    tmpStrings.Delimiter := ' ';
    FClient.LastCmdResult.Clear;
    FClient.SendCmd(RSLOGIN+' ERIC 20000',[220]);
    ClientID := StrtoIntDef(FClient.LastCmdResult.Text[0],InvalidClientNumber);
    FTransmitCount := 0;
    FClient.LastCmdResult.Clear;
    FClient.SendCmd(RSLOCK + ' '+IntToStr(ClientID)+' '+tmpStrings.DelimitedText,[400,500]);
    CheckEquals(XMLDoc.Text,FClient.LastCmdResult.Text.Text,'Locked not working');
    FClient.LastCmdResult.Clear;
    FClient.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID),[220]);

  finally // wrap up
    FreeAndNil(XMldoc);
    FreeAndNil(tmpStrings);
  end;    // try/finally
end;

procedure TTestBoldServer.TestLogin;
var
  ClientID:Integer;
begin
  FServer.OnClientLoginEvent := Login;
  FClient.LastCmdResult.Clear;
  FClient.SendCmd(RSLOGIN +' ERIC 20000',[220]);
  ClientID := StrtoIntDef(FClient.LastCmdResult.Text[0],InvalidClientNumber);
  Self.CheckNotEquals(InvalidClientNumber,ClientID);
end;

procedure TTestBoldServer.TestLogOut;
var
  ClientID:Integer;
begin
  FServer.OnClientLoginEvent := Login;
  FServer.OnClientLogoutEvent := Logout;
  FClient.LastCmdResult.Clear;
  FClient.SendCmd(RSLOGIN + ' ERIC 20000',[220]);
  ClientID := StrtoIntDef(FClient.LastCmdResult.Text[0],InvalidClientNumber);
  Self.CheckNotEquals(InvalidClientNumber,ClientID);
  FClient.LastCmdResult.Clear;
  FLogOutCalled := false;
  FClient.SendCmd(RSLOGOUT +' '+IntToStr(ClientID),[220]);
  Self.CheckTrue(FLogOutCalled,'Logout Event Not Called');

end;

procedure TTestBoldServer.TestPolling;
var
  ClientID:Integer;
begin
  FServer.OnPollingEvent := Polling;
  FClient.LastCmdResult.Clear;
  FClient.SendCmd(RSLOGIN+' ERIC 20000',[220]);
  ClientID := StrtoIntDef(FClient.LastCmdResult.Text[0],InvalidClientNumber);
  FTransmitCount := 0;
  FClient.LastCmdResult.Clear;
  FClient.SendCmd(RSPOLLING + ' '+IntToStr(ClientID),[220]);
  CheckEquals(2,FClient.LastCmdResult.Text.Count,'Wrong # of Events');
  CheckEquals('E:2',FClient.LastCmdResult.Text[1]);
  FClient.LastCmdResult.Clear;
  FLogOutCalled := false;
  FClient.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID),[220]);
end;

procedure TTestBoldServer.TestTransmit;
var
  ClientID:Integer;
begin
  FServer.OnTransmitEvents := Transmit;
  FClient.LastCmdResult.Clear;
  FClient.SendCmd(RSLOGIN+' ERIC 20000',[220]);
  ClientID := StrtoIntDef(FClient.LastCmdResult.Text[0],InvalidClientNumber);
  FTransmitCount := 0;
  FClient.LastCmdResult.Clear;
  FClient.SendCmd(RSTRANSMIT + ' '+IntToStr(ClientID)+ ' E:1 E:2',[220]);
  sleep(100); //Allow time for the event handler to be called
  CheckEquals(2,FTransmitCount,'Wrong # of Events');
  FClient.LastCmdResult.Clear;
  FLogOutCalled := false;
  FClient.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID),[220]);
end;

procedure TTestBoldServer.TestUnLock;
var
  ClientID:Integer;
  XMLDoc:TGmXML;
  tmpStrings:TStrings;
begin
  XMLDoc := TGmXML.Create(nil);
  tmpStrings := TStringList.Create;
  try
    FServer.OnUnlockEvent := UnLock;
    XMLDoc.IncludeHeader := False;
    XMLDoc.AutoIndent := False;
    with XMLDoc.Nodes do
    begin
      AddOpenTag('Locks');
      AddOpenTag('Exclusive');
      AddLeaf('Lock').asString := 'DBLock';
      AddLeaf('Lock').asString := 'E:1';
      AddCloseTag;
      AddOpenTag('Shared');
      AddLeaf('Lock').asString := 'DBLock';
      AddLeaf('Lock').asString := 'E:1';
      AddCloseTag;
      AddCloseTag;
    end;
    tmpStrings.Text := XMLDoc.Text;
    tmpStrings.Delimiter := ' ';
    FClient.LastCmdResult.Clear;
    FClient.SendCmd(RSLOGIN+' ERIC 20000',[220]);
    ClientID := StrtoIntDef(FClient.LastCmdResult.Text[0],InvalidClientNumber);
    FTransmitCount := 0;
    FClient.LastCmdResult.Clear;
    FClient.SendCmd(RSUNLOCK + ' '+IntToStr(ClientID)+' '+tmpStrings.DelimitedText,[400,500]);
    CHeckTrue(FUnlockCalled);
    FClient.LastCmdResult.Clear;
    FClient.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID),[220]);

  finally // wrap up
    FreeAndNil(XMldoc);
    FreeAndNil(tmpStrings);
  end;    // try/finally
end;

procedure TTestBoldServer.Transmit(ASender: TIdCommand;
  AClientID: Integer);
var
  Events:TStrings;
begin
  Events := TStringList.Create;
  try
    Events.AddStrings(ASender.Params);
    EVents.Delete(0);
    FTransmitCount := Events.COunt;
  finally // wrap up
    FreeAndNil(Events);
  end;    // try/finally
end;

procedure TTestBoldServer.UnLock(ASender: TIdCommand; AClientID: Integer;
  var Locked: Boolean);
begin
  FUnlockCalled := True;
end;

initialization
  RegisterTest('BoldTCPServer', TTestBoldServer.Suite);

end.

