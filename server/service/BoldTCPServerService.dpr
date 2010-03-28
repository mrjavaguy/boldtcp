program BoldTCPServerService;

uses
  SvcMgr,
  unBoldTCPService in 'unBoldTCPService.pas' {BoldTCPService: TService},
  unUIManager in '..\common\unUIManager.pas',
  IdBoldServer in '..\common\IdBoldServer.pas',
  unClientHandler in '..\common\unClientHandler.pas',
  unClientNotifier in '..\common\unClientNotifier.pas',
  unLockHandler in '..\common\unLockHandler.pas',
  unPropagatorServer in '..\common\unPropagatorServer.pas',
  BoldTCPGlobals in '..\..\common\BoldTCPGlobals.pas',
  BoldTCPResourceStrings in '..\..\common\BoldTCPResourceStrings.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TBoldTCPService, BoldTCPService);
  Application.Run;
end.
