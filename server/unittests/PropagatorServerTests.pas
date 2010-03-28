unit PropagatorServerTests;

interface

uses
  Classes,
  SysUtils,
  TestFramework,
  IdTCPClient,
  unPropagatorServer;

type
  TPropagatorServerTest = class(TTestCase)
  private
    FServer:TPropagatorServer;
    FClient1,
    FClient2:TIdTCPClient;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestLogin;
    procedure TestLogOut;
    procedure TestPolling;
    procedure TestLocking;
    procedure TestCheckLocks;
    procedure TestUnlock;
    procedure TestClientMonitor;
  end;


implementation

uses
  BoldTCPGlobals,
  BoldTCPResourceStrings,
  GmXml,
  unClientHandler;

{ TPropagatorServerTest }

procedure TPropagatorServerTest.Setup;
begin
  inherited;
  FServer := TPropagatorServer.Create;
  FClient1 := TIdTCPClient.Create(nil);
  FClient1.Port := IdPORT_BOLD;
  FClient1.Connect;
  FClient1.GetResponse(220);
  FClient1.Greeting.Assign(FClient1.LastCmdResult);
  FClient2 := TIdTCPClient.Create(nil);
  FClient2.Port := IdPORT_BOLD;
  FClient2.Connect;
  FClient2.GetResponse(220);
  FClient2.Greeting.Assign(FClient2.LastCmdResult);

end;

procedure TPropagatorServerTest.TearDown;
begin
  inherited;
  FreeAndNil(FClient2);
  FreeAndNil(FClient1);
  FreeAndNil(FServer);
end;

procedure TPropagatorServerTest.TestCheckLocks;
var
  ClientID1:Integer;
  XMLDoc:TGmXML;
  tmpStrings:TStrings;
begin
  XMLDoc := TGmXML.Create(nil);
  tmpStrings := TStringList.Create;
  try
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
      AddLeaf('Lock').asString := 'DBLock2';
      AddLeaf('Lock').asString := 'E:2';
      AddCloseTag;
      AddCloseTag;
    end;
    tmpStrings.Text := XMLDoc.Text;
    tmpStrings.Delimiter := ' ';
    FClient1.LastCmdResult.Clear;
    FClient1.SendCmd(RSLOGIN+' ERIC 20000',[220]);
    ClientID1 := StrtoIntDef(FClient1.LastCmdResult.Text[0],InvalidClientNumber);
    FClient1.LastCmdResult.Clear;
    FClient1.SendCmd(RSLOCK + ' '+IntToStr(ClientID1)+' '+tmpStrings.DelimitedText,[400,500]);
    FClient1.SendCmd(RSCHECKLOCK + ' '+IntToStr(ClientID1)+' '+tmpStrings.DelimitedText,[400,500]);
    CheckEquals(400,FClient1.LastCmdResult.NumericCode,'Check Failed');
    FClient1.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID1),[220]);
  finally
    FreeAndNil(XMLDoc);
    FreeAndNil(tmpStrings);
  end;  // try/finally
end;

procedure TPropagatorServerTest.TestClientMonitor;
var
  ClientID1,
  ClientID2 :Integer;
begin
  FClient1.LastCmdResult.Clear;
  FClient1.SendCmd(RSLOGIN+' ERIC 20000',[220]);
  ClientID1 := StrtoIntDef(FClient1.LastCmdResult.Text[0],InvalidClientNumber);
  FClient2.SendCmd(RSLOGIN+' ERIC 20000',[220]);
  ClientID2 := StrtoIntDef(FClient2.LastCmdResult.Text[0],InvalidClientNumber);
  FClient1.SendCmd(RSMONITOR,[220]);
  CheckEquals(2,FClient1.LastCmdResult.Text.Count,'Wrong # of Events');
  FClient2.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID2),[220]);
  FClient1.SendCmd(RSMONITOR,[220]);
  CheckEquals(1,FClient1.LastCmdResult.Text.Count,'Wrong # of Events');
  FClient1.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID1),[220]);

end;

procedure TPropagatorServerTest.TestLocking;
var
  ClientID1,
  ClientID2 :Integer;
  XMLDoc:TGmXML;
  tmpStrings:TStrings;
  aNode: TGmXmlNode;
begin
  XMLDoc := TGmXML.Create(nil);
  tmpStrings := TStringList.Create;
  try
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
    FClient1.LastCmdResult.Clear;
    FClient1.SendCmd(RSLOGIN+' ERIC 20000',[220]);
    ClientID1 := StrtoIntDef(FClient1.LastCmdResult.Text[0],InvalidClientNumber);
    FClient2.SendCmd(RSLOGIN+' ERIC 20000',[220]);
    ClientID2 := StrtoIntDef(FClient2.LastCmdResult.Text[0],InvalidClientNumber);
    FClient1.LastCmdResult.Clear;
    FClient1.SendCmd(RSLOCK + ' '+IntToStr(ClientID1)+' '+tmpStrings.DelimitedText,[400,500]);
    CheckEquals(400,FClient1.LastCmdResult.NumericCode,'Locked Failed');
    FClient2.LastCmdResult.Clear;
    FClient2.SendCmd(RSLOCK + ' '+IntToStr(ClientID2)+' '+tmpStrings.DelimitedText,[400,500]);
    CheckEquals(500,FClient2.LastCmdResult.NumericCode,'Locked Failed');
    XMLDoc.Nodes.Clear;
    XMLDoc.Text := FClient2.LastCmdResult.Text.Text;
    aNode := XMLDoc.Nodes.Root.Children.NodeByName['CLIENTS'];
    CheckEquals(Format('%d=ERIC',[ClientID1]),aNode.Children[0].AsString);
    FClient2.LastCmdResult.Clear;
    FClient2.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID2),[220]);
    FClient1.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID1),[220]);
  finally
    FreeAndNil(XMLDoc);
    FreeAndNil(tmpStrings);
  end;  // try/finally
end;

procedure TPropagatorServerTest.TestLogin;
var
  ClientID: Integer;
begin
  FClient1.LastCmdResult.Clear;
  FClient1.SendCmd(RSLOGIN +' ERIC 20000',[220]);
  ClientID := StrtoIntDef(FClient1.LastCmdResult.Text[0],InvalidClientNumber);
  Self.CheckNotEquals(InvalidClientNumber,ClientID);
end;

procedure TPropagatorServerTest.TestLogOut;
var
  ClientID: Integer;
begin
  FClient1.LastCmdResult.Clear;
  FClient1.SendCmd(RSLOGIN + ' ERIC 20000',[220]);
  ClientID := StrtoIntDef(FClient1.LastCmdResult.Text[0],InvalidClientNumber);
  Self.CheckNotEquals(InvalidClientNumber,ClientID);
  CheckTrue(FServer.ClientHandler.IsRegistered(ClientID));
  FClient1.LastCmdResult.Clear;
  FClient1.SendCmd(RSLOGOUT +' '+IntToStr(ClientID),[220]);
  CheckFalse(FServer.ClientHandler.IsRegistered(ClientID));
end;

procedure TPropagatorServerTest.TestPolling;
var
  ClientID1,
  ClientID2 :Integer;
begin
  FClient1.LastCmdResult.Clear;
  FClient1.SendCmd(RSLOGIN+' ERIC 20000',[220]);
  ClientID1 := StrtoIntDef(FClient1.LastCmdResult.Text[0],InvalidClientNumber);
  FClient2.SendCmd(RSLOGIN+' ERIC 20000',[220]);
  ClientID2 := StrtoIntDef(FClient2.LastCmdResult.Text[0],InvalidClientNumber);
  FClient1.LastCmdResult.Clear;
  FClient1.SendCmd(RSTRANSMIT + ' '+IntToStr(ClientID1)+ ' E:1 E:2',[220]);
  sleep(100);
  FClient2.LastCmdResult.Clear;
  FClient2.SendCmd(RSPOLLING + ' '+IntToStr(ClientID2),[220]);
  CheckEquals(2,FClient2.LastCmdResult.Text.Count,'Wrong # of Events');
  CheckEquals('E:2',FClient2.LastCmdResult.Text[1]);
  FClient2.LastCmdResult.Clear;
  FClient2.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID2),[220]);
  FClient1.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID1),[220]);
end;


procedure TPropagatorServerTest.TestUnlock;
var
  ClientID1,
  ClientID2 :Integer;
  XMLDoc:TGmXML;
  tmpStrings:TStrings;
begin
  XMLDoc := TGmXML.Create(nil);
  tmpStrings := TStringList.Create;
  try
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
    FClient1.LastCmdResult.Clear;
    FClient1.SendCmd(RSLOGIN+' ERIC 20000',[220]);
    ClientID1 := StrtoIntDef(FClient1.LastCmdResult.Text[0],InvalidClientNumber);
    FClient2.SendCmd(RSLOGIN+' ERIC 20000',[220]);
    ClientID2 := StrtoIntDef(FClient2.LastCmdResult.Text[0],InvalidClientNumber);
    FClient1.LastCmdResult.Clear;
    FClient1.SendCmd(RSLOCK + ' '+IntToStr(ClientID1)+' '+tmpStrings.DelimitedText,[400,500]);
    CheckEquals(400,FClient1.LastCmdResult.NumericCode,'Locked Failed');
    FClient2.LastCmdResult.Clear;
    FClient2.SendCmd(RSLOCK + ' '+IntToStr(ClientID2)+' '+tmpStrings.DelimitedText,[400,500]);
    CheckEquals(500,FClient2.LastCmdResult.NumericCode,'Locked Failed');
    FClient1.SendCmd(RSUNLOCK + ' '+IntToStr(ClientID1)+' '+tmpStrings.DelimitedText,[400,500]);
    FClient2.SendCmd(RSLOCK + ' '+IntToStr(ClientID2)+' '+tmpStrings.DelimitedText,[400,500]);
    CheckEquals(400,FClient2.LastCmdResult.NumericCode,'Locked Failed');
    FClient2.LastCmdResult.Clear;
    FClient2.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID2),[220]);
    FClient1.SendCmd(RSLOGOUT + ' '+IntToStr(ClientID1),[220]);
  finally
    FreeAndNil(XMLDoc);
    FreeAndNil(tmpStrings);
  end;  // try/finally
end;

initialization
  RegisterTest('PropagatorServer', TPropagatorServerTest.Suite);

end.
