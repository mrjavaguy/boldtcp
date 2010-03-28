unit idBoldClient;

interface

uses
  Classes,
  SysUtils,
  IdAssignedNumbers,
  IdException,
  IdTCPClient,
  IdTCPConnection,
  IdThread,
  IdRFCReply;

type
  TidBoldClient = class(TidTCPClient)
  private
    FEvents:TStrings;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Login(ClientIDString:String; LeaseDuration:Integer):integer;
    function LogOut(ClientID:Integer): boolean;
    procedure Polling(ClientID:Integer);
    procedure Transmit(ClientID:Integer;Event:String);
    function EnsureLocks(ClientID:Integer; ExclusiveLocks:TStringList; SharedLocks:TStringList):Boolean;
    function GetLocks(ClientID:Integer;ExclusiveLocks, SharedLocks, HeldLocks, ClientsHoldingRequestedLocks: TStringList):Boolean;
    procedure ReleaseLocks(ClientID:Integer; Locks:TStringList);
    property Events:TStrings read FEvents;
  end;



implementation

uses
  GMXml,
  BoldTCPGlobals,
  BoldTCPResourceStrings;

{ TidBoldClient }


constructor TidBoldClient.Create(AOwner: TComponent);
begin
  inherited;
  FEvents := TStringList.Create;
end;

destructor TidBoldClient.Destroy;
begin
  FreeAndNil(FEvents);
  inherited;
end;

function TidBoldClient.EnsureLocks(ClientID: Integer; ExclusiveLocks,
  SharedLocks: TStringList): Boolean;
var
  I: Integer;
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
      for I := 0 to ExclusiveLocks.Count - 1 do    // Iterate
      begin
        AddLeaf('Lock').asString := ExclusiveLocks[i];
      end;    // for
      AddCloseTag;
      AddOpenTag('Shared');
      for I := 0 to SharedLocks.Count - 1 do    // Iterate
      begin
        AddLeaf('Lock').asString := SharedLocks[i];
      end;    // for
      AddCloseTag;
      AddCloseTag;
    end;
    tmpStrings.Text := XMLDoc.Text;
    tmpStrings.Delimiter := ' ';
    SendCmd(Format('%s %d %s',[RSCHECKLOCK,ClientID,tmpStrings.DelimitedText]),[400,500]);
    Result := LastCmdResult.NumericCode = 400;
  finally
    FreeAndNil(XMLDoc);
    FreeAndNil(tmpStrings);
  end;  // try/finally
end;

function TidBoldClient.GetLocks(ClientID: Integer; ExclusiveLocks,
  SharedLocks, HeldLocks,
  ClientsHoldingRequestedLocks: TStringList): Boolean;
var
  I: Integer;
  XMLDoc:TGmXML;
  tmpStrings:TStrings;
  aNode :TGmXMLNode;
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
      for I := 0 to ExclusiveLocks.Count - 1 do    // Iterate
      begin
        AddLeaf('Lock').asString := ExclusiveLocks[i];
      end;    // for
      AddCloseTag;
      AddOpenTag('Shared');
      for I := 0 to SharedLocks.Count - 1 do    // Iterate
      begin
        AddLeaf('Lock').asString := SharedLocks[i];
      end;    // for
      AddCloseTag;
      AddCloseTag;
    end;
    tmpStrings.Text := XMLDoc.Text;
    tmpStrings.Delimiter := ' ';
    SendCmd(Format('%s %d %s',[RSLOCK,ClientID,tmpStrings.DelimitedText]),[400,500]);
    Result := LastCmdResult.NumericCode = 400;
    if not Result then
    begin
      XMLDoc.Nodes.Clear;
      XMLDoc.Text := LastCmdResult.Text.Text;
      aNode := XMLDoc.Nodes.Root.Children.NodeByName['HELDLOCKS'];
      for I := 0 to aNode.Children.Count - 1 do    // Iterate
      begin
        HeldLocks.Add(aNode.Children[i].asString)
      end;    // for
      aNode := XMLDoc.Nodes.Root.Children.NodeByName['CLIENTS'];
      for I := 0 to aNode.Children.Count - 1 do    // Iterate
      begin
        ClientsHoldingRequestedLocks.Add(aNode.Children[i].asString)
      end;    // for
    end;
  finally
    FreeAndNil(XMLDoc);
    FreeAndNil(tmpStrings);
  end;  // try/finally
end;

function TidBoldClient.Login(ClientIDString:String; LeaseDuration:Integer): integer;
begin
  SendCmd(Format('%s %s %d',[RSLOGIN, ClientIDString,LeaseDuration]),[220]);
  Result := StrtoIntDef(LastCmdResult.Text[0],InvalidClientNumber);
end;

function TidBoldClient.LogOut(ClientID:Integer): boolean;
begin
  SendCmd(Format('%s %d',[RSLOGOUT,ClientID]),[220]);
  Result := True;
end;

procedure TidBoldClient.Polling(ClientID:Integer);
begin
  FEvents.Clear;
  SendCmd(Format('%s %d',[RSPOLLING,CLientID]),[220]);
  if LastCmdResult.Text[0] <> '' then
    FEvents.AddStrings(LastCmdResult.Text);
end;

procedure TidBoldClient.ReleaseLocks(ClientID: Integer;
  Locks: TStringList);
var
  I: Integer;
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
      for I := 0 to Locks.Count - 1 do    // Iterate
      begin
        AddLeaf('Lock').asString := Locks[i];
      end;    // for
      AddCloseTag;
      AddOpenTag('Shared');
      for I := 0 to Locks.Count - 1 do    // Iterate
      begin
        AddLeaf('Lock').asString := Locks[i];
      end;    // for
      AddCloseTag;
      AddCloseTag;
    end;
    tmpStrings.Text := XMLDoc.Text;
    tmpStrings.Delimiter := ' ';
    SendCmd(Format('%s %d %s',[RSUNLOCK,ClientID,tmpStrings.DelimitedText]),[400,500]);
  finally
    FreeAndNil(XMLDoc);
    FreeAndNil(tmpStrings);
  end;  // try/finally
end;

procedure TidBoldClient.Transmit(ClientID:Integer;Event: String);
begin
  if Connected then
    SendCmd(Format('%s %d %s',[RSTRANSMIT,ClientID,Event]),[220]);
end;

end.
