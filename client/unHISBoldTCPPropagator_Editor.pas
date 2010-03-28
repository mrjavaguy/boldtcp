{ $HDR$}
{**********************************************************************}
{(c) 2003 Holton Integration Systems}
{}
{Web: http://www.holtonsystems.com}
{eMail: support@holtonsystems.com}
{}
{ $Author:Supervisor$ }
{}
{Last Modified On $ModDate:4/17/2004 5:54:52 PM$}
{}
{**********************************************************************}
{}
{ $Log:  10095: unHISBoldTCPPropagator_Editor.pas 
{
{   Rev 1.0    3/24/2005 4:01:14 PM  Supervisor
{ Initial Check-In
}
{
{   Rev 1.0    4/22/2004 11:23:30 AM  Eric
{ Initial Check-In
}
unit unHISBoldTCPPropagator_Editor;

interface
uses
  DesignEditors, DesignIntf, VCLEditors, Windows, Classes, Graphics, SysUtils,
  Dialogs, HISBoldTCPPropagator;

type
  TBoldPersistenceHandleProperty = class(TComponentProperty)
  private
    FProc: TGetStrProc;
    procedure InnerProc(const S: string);
  public
    procedure GetValues(Proc: TGetStrProc); override;
  end;

implementation

{ TBoldPersistenceHandleProperty }

procedure TBoldPersistenceHandleProperty.GetValues(Proc: TGetStrProc);
begin
  FProc := Proc;
  inherited GetValues(InnerProc);
end;

procedure TBoldPersistenceHandleProperty.InnerProc(const S: string);
var
  Component: TComponent;
begin
  Component := Designer.GetComponent(S);
  if Component <> GetComponent(0) then
    FProc(S);
end;

end.
