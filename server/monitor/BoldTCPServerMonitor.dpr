program BoldTCPServerMonitor;

uses
  Forms,
  fmMonitor in '..\common\fmMonitor.pas' {BoldTCPMonitor},
  dmMonitor in '..\common\dmMonitor.pas' {MonitorDM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TBoldTCPMonitor, BoldTCPMonitor);
  Application.Run;
end.
