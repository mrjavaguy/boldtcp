unit dmMonitor;

interface

uses
  SysUtils, Classes, DB, DBClient, ExtCtrls, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient;

type
  TMonitorDM = class(TDataModule)
    cdsClients: TClientDataSet;
    dsClients: TDataSource;
    cdsClientscdsClientsClientID: TIntegerField;
    cdsClientscdsClientsClientIDString: TStringField;
    cdsClientscdsClientsLeaseDuration: TIntegerField;
    cdsClientscdsClientsLeaseExpires: TStringField;
    IdTCPClientMonitor: TIdTCPClient;
    MonitorTimer: TTimer;
    procedure DataModuleCreate(Sender: TObject);
    procedure MonitorTimerTimer(Sender: TObject);
  private
    { Private declarations }
    procedure DeleteClient(ClientID:Integer);
    procedure AddClient(ClientInfo:TStrings);
    procedure UpdateClient(ClientInfo:TStrings);
    function GetHost: string;
    function GetPort: Integer;
    procedure SetHost(const Value: string);
    procedure SetPort(const Value: Integer);
  protected
    procedure GetClientInfo;
    procedure UpdateDataSet(ClientList:TStrings);
  public
    { Public declarations }
    property Port:Integer read GetPort write SetPort;
    property Host:string read GetHost write SetHost;
  end;

implementation

uses BoldTCPGlobals, BoldTCPResourceStrings;

{$R *.dfm}

procedure TMonitorDM.AddClient(ClientInfo: TStrings);
begin
  if ClientInfo.Count <> 4 then
    exit;
  cdsClients.Insert;
  cdsClientscdsClientsClientID.AsString := ClientInfo.Values['ID'];
  cdsClientscdsClientsClientIDString.AsString := ClientInfo.Values['IDString'];
  cdsClientscdsClientsLeaseDuration.AsString := ClientInfo.Values['LeaseDuration'];
  cdsClientscdsClientsLeaseExpires.AsString := ClientInfo.Values['LeaseTimeout'];
  cdsClients.Post;
end;

procedure TMonitorDM.DataModuleCreate(Sender: TObject);
begin
  cdsClients.CreateDataSet;
end;

procedure TMonitorDM.DeleteClient(ClientID: Integer);
begin
  if ClientID = InvalidClientNumber then
    exit;
  if cdsClients.FindKey([ClientID]) then
  begin
    cdsClients.Delete;
  end;
end;

procedure TMonitorDM.GetClientInfo;
begin
  IdTCPClientMonitor.Connect;
  IdTCPClientMonitor.GetResponse(220);
  IdTCPClientMonitor.Greeting.Assign(IdTCPClientMonitor.LastCmdResult);

  try
    IdTCPClientMonitor.SendCmd(RSMONITOR,[220]);
    UpdateDataSet(IdTCPClientMonitor.LastCmdResult.Text);
  finally // wrap up
    IdTCPClientMonitor.Disconnect;
  end;    // try/finally
end;

function TMonitorDM.GetHost: string;
begin
  Result := IdTCPClientMonitor.Host;
end;

function TMonitorDM.GetPort: Integer;
begin
  Result := IdTCPClientMonitor.Port;
end;

procedure TMonitorDM.MonitorTimerTimer(Sender: TObject);
begin
  MonitorTimer.Enabled := False;
  GetClientInfo;
  MonitorTimer.Enabled := True;
end;

procedure TMonitorDM.SetHost(const Value: string);
begin
  IdTCPClientMonitor.Host := Value;
end;

procedure TMonitorDM.SetPort(const Value: Integer);
begin
  IdTCPClientMonitor.Port := Value;
end;

procedure TMonitorDM.UpdateClient(ClientInfo: TStrings);
var
  ClientID: Integer;
begin
  if ClientInfo.Count <> 2 then
    exit;
  ClientID := StrtoIntDef(ClientInfo.Values['ID'],InvalidClientNumber);
  if ClientID = InvalidClientNumber then
    exit;
  if cdsClients.FindKey([ClientID]) then
  begin
  cdsClients.Edit;
  cdsClientscdsClientsLeaseExpires.AsString := ClientInfo.Values['LeaseTimeout'];
  cdsClients.Post;
  end;
end;

procedure TMonitorDM.UpdateDataSet(ClientList: TStrings);
var
  I: Integer;
  temp:TStringList;
begin
  temp := TStringList.Create;
  try
    for I := 0 to ClientList.Count - 1 do    // Iterate
    begin
      temp.Clear;
      temp.CommaText := ClientList[i];
      case temp.Count of    //
        1: DeleteClient(StrtoIntDef(temp.Values['ID'],InvalidClientNumber));
        2: UpdateClient(temp);
        4: AddClient(temp);
      end;    // case
    end;    // for
  finally // wrap up
    FreeAndNil(temp);
  end;    // try/finally
end;

end.
