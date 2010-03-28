unit dMain;

interface

uses
  Classes,
  Controls,
  Forms,
  Messages,
  ActnList,
  BoldHandle,
  BoldHandles,
  BoldPersistenceHandle,
  BoldPersistenceHandleDB,
  BoldModel,
  BoldSystem,
  BoldSubscription,
  BoldSystemHandle,
  BoldUMLModelLink,
  BoldUMLRose98Link,
  BoldHandleAction,
  BoldActions,
  BoldDBActions, BoldAbstractModel, DB, IBDatabase,
  BoldAbstractDatabaseAdapter, BoldDatabaseAdapterIB,
  BoldAbstractPersistenceHandleDB, BoldIBDatabaseAction,
  BoldAbstractDequeuer, BoldExternalObjectSpaceEventHandler,
  BoldPersistenceHandlePassthrough, BoldAbstractModificationPropagator,
  HISBoldTCPPropagator;

type
  TdmMain = class(TDataModule)
    bshMain: TBoldSystemHandle;
    stiMain: TBoldSystemTypeInfoHandle;
    bmoMain: TBoldModel;
    ActionList1: TActionList;
    BoldUpdateDBAction1: TBoldUpdateDBAction;
    BoldActivateSystemAction1: TBoldActivateSystemAction;
    BoldIBDatabaseAction1: TBoldIBDatabaseAction;
    BoldPersistenceHandleDB1: TBoldPersistenceHandleDB;
    BoldDatabaseAdapterIB1: TBoldDatabaseAdapterIB;
    IBDatabase1: TIBDatabase;
    HISBoldTCPPropagator1: THISBoldTCPPropagator;
    BoldExternalObjectSpaceEventHandler1: TBoldExternalObjectSpaceEventHandler;
    procedure BoldIBAliasAction1SchemaGenerated(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Lock;
    procedure Unlock;
    procedure Update(aList:TObject);
  end;

var
  dmMain: TdmMain;

implementation
{$R *.DFM}

uses Windows, fMain;

procedure TdmMain.BoldIBAliasAction1SchemaGenerated(Sender: TObject);
begin
  BoldActivateSystemAction1.ExecuteTarget(nil);
end;

procedure TdmMain.Lock;
begin
  HISBoldTCPPropagator1.Lock('NextNumber');
end;

procedure TdmMain.Unlock;
begin
  HISBoldTCPPropagator1.Unlock('NextNumber');
end;

procedure TdmMain.Update(aList: TObject);
begin
  PostMessage(frmMain.Handle,WM_USER + 1000,0,Integer(aList));
end;


end.
