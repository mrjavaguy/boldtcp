program ClientUnitTests;

{$IFDEF GUITESTS}
{$APPTYPE GUI}
{$ELSE}
{$APPTYPE CONSOLE}
{$ENDIF}

{%File 'BusinessClasses_Interface.inc'}

uses
  Forms,
  GUITestRunner,
  TextTestRunner,
  TestFramework,
  SysUtils,
  idBoldClient in '..\idBoldClient.pas',
  unIdBoldClientTests in 'unIdBoldClientTests.pas',
  unPropagatorServer in '..\..\server\common\unPropagatorServer.pas',
  unClientNotifier in '..\..\server\common\unClientNotifier.pas',
  IdBoldServer in '..\..\server\common\IdBoldServer.pas',
  unClientHandler in '..\..\server\common\unClientHandler.pas',
  BoldTCPResourceStrings in '..\..\common\BoldTCPResourceStrings.pas',
  BoldTCPGlobals in '..\..\common\BoldTCPGlobals.pas',
  unClientThread in '..\unClientThread.pas',
  unClientThreadTests in 'unClientThreadTests.pas',
  RecieverTestForm in 'RecieverTestForm.pas' {ThreadReceive},
  HISBoldTCPPropagator in '..\HISBoldTCPPropagator.pas',
  dmFullBold in 'dmFullBold.pas' {DataModule1: TDataModule},
  unPropagatorTests in 'unPropagatorTests.pas',
  BusinessClasses in 'BusinessClasses.pas',
  unLockHolder in '..\unLockHolder.pas',
  unLockHandler in '..\..\server\common\unLockHandler.pas',
  unUIManager in '..\..\server\common\unUIManager.pas';

begin
   Application.Initialize;
{$IFDEF GUITESTS}
   GUITestRunner.RunRegisteredTests;
{$ELSE}
   TextTestRunner.RunRegisteredTests(rxbHaltOnFailures);
{$ENDIF}
end.
