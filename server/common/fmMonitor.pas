unit fmMonitor;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Grids, DBGrids, ExtCtrls, dmMonitor;

type
  TBoldTCPMonitor = class(TForm)
    PageControl1: TPageControl;
    tsClients: TTabSheet;
    tsLocks: TTabSheet;
    Label1: TLabel;
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    MonitorButton: TButton;
    procedure MonitorButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FMonitorDM: TMonitorDM;
    FPort: Integer;
    FHost: string;
    procedure SetHost(const Value: string);
    procedure SetPort(const Value: Integer);
 protected
    procedure StartMonitor;
    procedure PauseMonitor;
    function isMonitorRunnning:Boolean;
    procedure ReadCommandLine;
  public
    { Public declarations }
    property Host:string read FHost write SetHost;
    property Port:Integer read FPort write SetPort;
  end;

var
  BoldTCPMonitor: TBoldTCPMonitor;

implementation

uses BoldTCPResourceStrings, BoldTCPGlobals;


{$R *.dfm}

procedure TBoldTCPMonitor.MonitorButtonClick(Sender: TObject);
begin
  TButton(Sender).Enabled := False;
  if isMonitorRunnning then
  begin
    TButton(Sender).Caption := RSSTARTBUTTON;
    PauseMonitor;
  end
  else
  begin
    StartMonitor;
    TButton(Sender).Caption := RSPAUSEBUTTON;
  end;
  TButton(Sender).Enabled := True;
end;

function TBoldTCPMonitor.isMonitorRunnning: Boolean;
begin
  Result :=  Assigned(FMonitorDM) and (FMonitorDM.MonitorTimer.Enabled);
end;

procedure TBoldTCPMonitor.PauseMonitor;
begin
  if assigned(FMonitorDM) then
   FMonitorDM.MonitorTimer.Enabled := False;
end;

procedure TBoldTCPMonitor.SetHost(const Value: string);
begin
  FHost := Value;
end;

procedure TBoldTCPMonitor.SetPort(const Value: Integer);
begin
  FPort := Value;
end;

procedure TBoldTCPMonitor.StartMonitor;
begin
  if not assigned(FMonitorDM) then
    FMonitorDM := TMonitorDM.Create(nil);
  FMonitorDM.MonitorTimer.Enabled := False;
  FMonitorDM.Port := Port;
  FMonitorDM.Host := Host;
  FMonitorDM.MonitorTimer.Enabled := True;
end;

procedure TBoldTCPMonitor.FormCreate(Sender: TObject);
begin
  Port := IdPORT_BOLD;
  Host := 'localhost';
  ReadCommandLine;
end;

procedure TBoldTCPMonitor.FormDestroy(Sender: TObject);
begin
  PauseMonitor;
end;

procedure TBoldTCPMonitor.ReadCommandLine;
begin

end;

end.
