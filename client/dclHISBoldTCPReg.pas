{ $HDR$}
{**********************************************************************}
{(c) 2003 Holton Integration Systems}
{}
{Web: http://www.holtonsystems.com}
{eMail: support@holtonsystems.com}
{}
{ $Author:Supervisor$ }
{}
{Last Modified On $ModDate:4/17/2004 5:53:38 PM$}
{}
{**********************************************************************}
{}
{ $Log:  10045: dclHISBoldTCPReg.pas 
{
{   Rev 1.0    3/24/2005 4:01:10 PM  Supervisor
{ Initial Check-In
}
{
{   Rev 1.0    4/22/2004 11:23:30 AM  Eric
{ Initial Check-In
}
unit dclHISBoldTCPReg;

interface

uses
  Classes,
  DesignEditors,
  DesignIntf,
  Windows,
  SysUtils,
  Messages,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  Menus,
  StdCtrls,
  ExtCtrls,
  BoldPersistenceHandlePassthrough,
  //PeteM
  unHISBoldTCPPropagator_Editor,
  BoldPersistenceHandle,
  //-PeteM
  HISBoldTCPPropagator;

procedure Register;

implementation

{$R dclHISBoldTCPReg.dcr}

procedure Register;
begin
  RegisterComponents('HIS', [THISBoldTCPPropagator]);
  //PeteM
  RegisterPropertyEditor(TypeInfo(TBoldPersistenceHandle), THISBoldAbstractTCPPropagator,
    'NextPersistenceHandle', TBoldPersistenceHandleProperty);
  //-PeteM
end;    { Register }

end.

