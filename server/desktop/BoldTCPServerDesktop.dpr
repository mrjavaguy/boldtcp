program BoldTCPServerDesktop;

uses
  Forms,
  fmMonitor in '..\common\fmMonitor.pas' {BoldTCPMonitor},
  dmMonitor in '..\common\dmMonitor.pas' {MonitorDM: TDataModule},
  BoldTCPResourceStrings in '..\..\common\BoldTCPResourceStrings.pas',
  BoldTCPGlobals in '..\..\common\BoldTCPGlobals.pas',
  unPropagatorServer in '..\common\unPropagatorServer.pas',
  IdBoldServer in '..\common\IdBoldServer.pas',
  unUIManager in '..\common\unUIManager.pas',
  unClientHandler in '..\common\unClientHandler.pas',
  unClientNotifier in '..\common\unClientNotifier.pas',
  unLockHandler in '..\common\unLockHandler.pas';

{$R *.res}

begin
  Application.Initialize;
  TPropagatorServer.Instance;
  Application.CreateForm(TBoldTCPMonitor, BoldTCPMonitor);
  Application.Run;
  TPropagatorServer.Instance.Free;
end.
