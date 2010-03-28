unit unPropagatorServer;

interface

uses
  Forms,
  INIFiles,
  Classes,
  SysUtils,
  idBoldServer,
  IdTCPClient,
  IdThread,
  IdTCPServer,
  unClientHandler,
  unLockHandler,
  unUIManager,
  unClientNotifier;

type
  TPropagatorServer = class
  private
    FClientHandler:TClientHandler;
    FClientNotifier:TClientNotifier;
    FBoldTCPServer:TIdBoldTCPServer;
    FLockManager: TLockManager;
    FUIManager: TUIManager;
  protected
     procedure Login(ASender: TIdCommand; LeaseDuration: Integer; const ClientIDString:String;
       var AClientID: Integer);
     procedure Logout(ASender: TIdCommand; AClientID: Integer);
     procedure Transmit(ASender: TIdCommand; AClientID: Integer);
     procedure Polling(ASender: TIdCommand; AClientID: Integer; var PollEvents:TStrings);
     procedure Locking(ASender: TIdCommand; AClientID: Integer; var Locked:Boolean; var LockedItems:Tstrings);
     procedure CheckLocks(ASender: TIdCommand; AClientID: Integer; var Locked:Boolean);
     procedure UnLock(ASender: TIdCommand; AClientID: Integer; var Locked:Boolean);
     procedure ClientMonitor(ASender: TIdCommand; var ClientEvents:TStrings);
  public
    constructor Create;
    destructor Destroy; override;
    class function Instance:TPropagatorServer;
    property ClientHandler:TClientHandler read FClientHandler;
    property LockManager:TLockManager read FLockManager;
    property UIManager:TUIManager read FUIManager;
  end;



implementation

uses
  GmXml,
  BoldTCPGlobals;

var
  PropagatorSingleton: TPropagatorServer;

{ TPropagatorServer }

procedure TPropagatorServer.CheckLocks(ASender: TIdCommand;
  AClientID: Integer; var Locked: Boolean);
var
  I: Integer;
  XMLDoc:TGmXML;
  ExLocks:TStringList;
  SharedLocks:TStringList;
  LockedItems:TStringList;
  aNode: TGmXmlNode;
begin
  XMLDoc := TGmXML.Create(nil);
  ExLocks := TStringList.Create;
  SharedLocks := TStringList.Create;
  LockedItems := TStringList.Create;
  try
    LockedItems.Clear;
    LockedItems.AddStrings(ASender.Params);
    LockedItems.Delete(0);
    XMLDoc.Text := LockedItems.Text;
    aNode := XMLDoc.Nodes.Root.Children.NodeByName['Exclusive'];
    for I := 0 to aNode.Children.Count - 1 do    // Iterate
      ExLocks.Add(aNode.Children[i].AsString);
    aNode := XMLDoc.Nodes.Root.Children.NodeByName['Shared'];
    for I := 0 to aNode.Children.Count - 1 do    // Iterate
      SharedLocks.Add(aNode.Children[i].AsString);
    Locked := LockManager.EnsureLocks(AClientID,ExLocks,SharedLocks)
  finally
    FreeAndNil(XMLDoc);
    FreeAndNil(ExLocks);
    FreeAndNil(SharedLocks);
    FreeAndNil(LockedItems);
  end;
end;

procedure TPropagatorServer.ClientMonitor(ASender: TIdCommand;
  var ClientEvents: TStrings);
var
  aClientID:Integer;
begin
  ClientEvents.AddStrings(UIManager.UIEvents);
  UIManager.UIEvents.Clear;
  FClientHandler.IsThereAClientTimingOutSoon(aClientID)
end;

constructor TPropagatorServer.Create;
var
  Setup:TIniFile;
  Port:Integer;
begin
  inherited;
  Port := IdPORT_BOLD;
  if FileExists(ChangeFileExt( Application.ExeName, '.INI' )) then
  begin
    Setup := TIniFile.Create(ChangeFileExt( Application.ExeName, '.INI' ));
    try
      Port := Setup.ReadInteger('Server','Port',IdPORT_BOLD);
    finally // wrap up
      Setup.Free;
    end;    // try/finally
  end;
  FBoldTCPServer := TIdBoldTCPServer.Create(nil);
  FBoldTCPServer.OnClientLoginEvent := Login;
  FBoldTCPServer.OnClientLogoutEvent := Logout;
  FBoldTCPServer.OnPollingEvent := Polling;
  FBoldTCPServer.OnTransmitEvents := Transmit;
  FBoldTCPServer.OnLockingEvent := Locking;
  FBoldTCPServer.OnCheckLocksEvent := CheckLocks;
  FBoldTCPServer.OnUnlockEvent := UnLock;
  FBoldTCPServer.OnClientMonitorEvents := ClientMonitor;
  FBoldTCPServer.DefaultPort := Port;
  FClientHandler := TClientHandler.Create;
  FClientNotifier := TClientNotifier.Create(FClientHandler);
  FClientNotifier.Resume;
  FClientNotifier.WaitUntilReady(TIMEOUT);
  FLockManager := TLockManager.Create(FClientHandler);
  FBoldTCPServer.Active := True;
  FUIManager := TUIManager.Create;
  FUIManager.ClientHandler := FClientHandler;
end;

destructor TPropagatorServer.Destroy;
begin
  FreeAndNil(FBoldTCPServer);
  fClientNotifier.Quit(True);
  FreeAndNil(fClientNotifier);
  FreeAndNil(FLockManager);
  FreeAndNil(fClientHandler);
  FreeAndNil(FUIManager);
  inherited;
end;

class function TPropagatorServer.Instance: TPropagatorServer;
begin
  if not assigned(PropagatorSingleton) then
     PropagatorSingleton := TPropagatorServer.Create;
  Result := PropagatorSingleton;
end;

procedure TPropagatorServer.Locking(ASender: TIdCommand;
  AClientID: Integer; var Locked: Boolean; var LockedItems: Tstrings);
var
  I: Integer;
  XMLDoc:TGmXML;
  ExLocks:TStringList;
  SharedLocks:TStringList;
  HeldLocks:TStringList;
  ClientHoldingLocks:TStringList;
  aNode: TGmXmlNode;
begin
  XMLDoc := TGmXML.Create(nil);
  ExLocks := TStringList.Create;
  SharedLocks := TStringList.Create;
  HeldLocks := TStringList.Create;
  ClientHoldingLocks := TStringList.Create;
  try
    LockedItems.Clear;
    LockedItems.AddStrings(ASender.Params);
    LockedItems.Delete(0);
    XMLDoc.Text := LockedItems.Text;
    aNode := XMLDoc.Nodes.Root.Children.NodeByName['Exclusive'];
    for I := 0 to aNode.Children.Count - 1 do    // Iterate
      ExLocks.Add(aNode.Children[i].AsString);
    aNode := XMLDoc.Nodes.Root.Children.NodeByName['Shared'];
    for I := 0 to aNode.Children.Count - 1 do    // Iterate
      SharedLocks.Add(aNode.Children[i].AsString);
    Locked := LockManager.GetLocks(AClientID,1000*60*30,ExLocks,SharedLocks,HeldLocks,ClientHoldingLocks);
    LockedItems.Clear;
    if not Locked then
    begin
      XMLDoc.Nodes.Clear;
      XMLDoc.Nodes.AddOpenTag('LOCKFAILED');
      XMLDoc.Nodes.AddOpenTag('HELDLOCKS');
      for I := 0 to HeldLocks.Count - 1 do    // Iterate
      begin
        XMLDoc.Nodes.AddLeaf('LOCK').asString := HeldLocks[i];
      end;    // for
      XMLDoc.Nodes.AddCloseTag;
      XMLDoc.Nodes.AddOpenTag('CLIENTS');
      for I := 0 to ClientHoldingLocks.Count - 1 do    // Iterate
      begin
        XMLDoc.Nodes.AddLeaf('LOCK').asString := ClientHoldingLocks[i];
      end;    // for
      XMLDoc.Nodes.AddCloseTag;
      XMLDoc.Nodes.AddCloseTag;
      LockedItems.Text := XMLDoc.Text;
    end;
  finally
    FreeAndNil(XMLDoc);
    FreeAndNil(ExLocks);
    FreeAndNil(SharedLocks);
    FreeAndNil(HeldLocks);
    FreeAndNil(ClientHoldingLocks);
  end;
end;

procedure TPropagatorServer.Login(ASender: TIdCommand;
  LeaseDuration: Integer; const ClientIDString: String;
  var AClientID: Integer);
begin
  FClientHandler.RegisterClient(LeaseDuration,ClientIDString,AClientID);
end;

procedure TPropagatorServer.Logout(ASender: TIdCommand;
  AClientID: Integer);
begin
  FClientHandler.UnRegisterClient(AClientid)
end;

procedure TPropagatorServer.Polling(ASender: TIdCommand;
  AClientID: Integer; var PollEvents: TStrings);
var
  Extended: Wordbool;
begin
  FClientHandler.GetEvents(AClientID,PollEvents);
  FClientHandler.ExtendLease(AClientID,Extended);
end;

procedure TPropagatorServer.Transmit(ASender: TIdCommand;
  AClientID: Integer);
var
  I: Integer;
  Extend:WordBool;
begin
  for I := 1 to ASender.Params.Count - 1 do    // Iterate
  begin
   fClientNotifier.NotifyClientsOfEvent(AClientID,ASender.Params[i]);
  end;    // for
  FClientHandler.ExtendLease(AClientID,Extend);
end;

procedure TPropagatorServer.UnLock(ASender: TIdCommand; AClientID: Integer;
  var Locked: Boolean);
var
  I: Integer;
  XMLDoc:TGmXML;
  Locks:TStringList;
  LockedItems:TStringList;
  aNode: TGmXmlNode;
begin
  Locked := False;
  XMLDoc := TGmXML.Create(nil);
  Locks := TStringList.Create;
  LockedItems := TStringList.Create;
  try
    LockedItems.Clear;
    LockedItems.AddStrings(ASender.Params);
    LockedItems.Delete(0);
    XMLDoc.Text := LockedItems.Text;
    aNode := XMLDoc.Nodes.Root.Children.NodeByName['Exclusive'];
    for I := 0 to aNode.Children.Count - 1 do    // Iterate
      Locks.Add(aNode.Children[i].AsString);
    aNode := XMLDoc.Nodes.Root.Children.NodeByName['Shared'];
    for I := 0 to aNode.Children.Count - 1 do    // Iterate
      Locks.Add(aNode.Children[i].AsString);
    LockManager.ReleaseLocks(AClientID,Locks);
    Locked := True;
  finally
    FreeAndNil(XMLDoc);
    FreeAndNil(Locks);
    FreeAndNil(LockedItems);
  end;
end;

end.
