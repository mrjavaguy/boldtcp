program BoldTCPServerTests;

{$IFDEF GUITESTS}
{$APPTYPE GUI}
{$ELSE}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
  GUITestRunner,
  TextTestRunner,
  TestFramework,
  IdBoldServerTest,
  SysUtils,
  IdBoldServer in '..\common\IdBoldServer.pas',
  BoldTCPResourceStrings in '..\..\common\BoldTCPResourceStrings.pas',
  BoldTCPGlobals in '..\..\common\BoldTCPGlobals.pas',
  unClientHandler in '..\common\unClientHandler.pas',
  ClientHandlerTests in 'ClientHandlerTests.pas',
  unClientNotifier in '..\common\unClientNotifier.pas',
  unPropagatorServer in '..\common\unPropagatorServer.pas',
  PropagatorServerTests in 'PropagatorServerTests.pas',
  unLockHandler in '..\common\unLockHandler.pas',
  unUIManager in '..\common\unUIManager.pas';

{$R *.res}

begin
{$IFDEF GUITESTS}
   Application.Initialize;
   GUITestRunner.RunRegisteredTests;
{$ELSE}
   TextTestRunner.RunRegisteredTests(rxbHaltOnFailures);
{$ENDIF}
end.

