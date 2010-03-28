{ $HDR$}
{**********************************************************************}
{(c) 2003 Holton Integration Systems}
{}
{Web: http://www.holtonsystems.com}
{eMail: support@holtonsystems.com}
{}
{ $Author:Supervisor$ }
{}
{Last Modified On $ModDate:11/19/2003 3:03:46 PM$}
{}
{**********************************************************************}
{}
{ $Log:  10051: DispatcherUnit.pas 
{
{   Rev 1.0    3/24/2005 4:01:10 PM  Supervisor
{ Initial Check-In
}
{
{   Rev 1.0    5/3/2004 9:33:10 AM  Eric
{ Initial Check-in
}
{
{   Rev 1.0    11/14/2003 10:34:26 AM  Eric
{ Initial Check-in
}
unit DispatcherUnit;

interface

uses Classes;

type TDispatchEvent = procedure (const aObject : TObject) of object;

     TDispatchRecord = record
      rClass : TClass;
      rEvent : TDispatchEvent;
     end;

     TDispatcher = class (TComponent)
     private
      FDispatchTable : array of TDispatchRecord;
     public
      procedure Execute     (const aObject : TObject);

      procedure AddDispatch (const aClass  : TClass;
                             const aMethod : Pointer;
                             const aObject : TObject);
     end;

implementation

uses SysUtils;

procedure TDispatcher.Execute (const aObject : TObject);
 var aIndex : Integer;
     aClass : TClass;
begin
 if   aObject = Nil
 then Exit;

 aClass := aObject.ClassType;

 for aIndex := Low (FDispatchTable) to High (FDispatchTable) do
 begin
  with FDispatchTable [aIndex] do
  begin
   if rClass = aClass then
   begin
    rEvent (aObject);

    Exit;
   end;
  end;
 end;

 raise Exception.Create ('Cannot dispatch ' + aClass.ClassName);
end;

procedure TDispatcher.AddDispatch (const aClass  : TClass;
                                   const aMethod : Pointer;
                                   const aObject : TObject);
begin
 SetLength (FDispatchTable, Length (FDispatchTable) + 1);

 with FDispatchTable [High (FDispatchTable)] do
 begin
  rClass := aClass;

  with TMethod (rEvent) do
  begin
   Code := aMethod;
   Data := aObject;
  end; 
 end;
end;

end.
