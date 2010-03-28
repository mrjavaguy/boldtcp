unit dmFullBold;

interface

uses
  SysUtils, Classes, BoldPersistenceHandlePassthrough,
  BoldPersistenceHandlePTWithModel, BoldSnooperHandle, BoldAbstractModel,
  BoldModel, BoldHandles, BoldSystemHandle, BoldSubscription, BoldHandle,
  BoldPersistenceHandle, BoldPersistenceHandleFile,
  BoldPersistenceHandleFileXML, HISBoldTCPPropagator, DB, IBDatabase,
  BoldAbstractPersistenceHandleDB, BoldPersistenceHandleDB,
  BoldAbstractDatabaseAdapter, BoldDatabaseAdapterIB, BoldAbstractDequeuer,
  BoldExternalObjectSpaceEventHandler, BoldRootedHandles,
  BoldAbstractListHandle, BoldCursorHandle, BoldListHandle;

type
  TDataModule1 = class(TDataModule)
    BoldSystemHandle1: TBoldSystemHandle;
    BoldSystemTypeInfoHandle1: TBoldSystemTypeInfoHandle;
    BoldModel1: TBoldModel;
    BoldExternalObjectSpaceEventHandler1: TBoldExternalObjectSpaceEventHandler;
    BoldDatabaseAdapterIB1: TBoldDatabaseAdapterIB;
    BoldPersistenceHandleDB1: TBoldPersistenceHandleDB;
    IBDatabase1: TIBDatabase;
    BoldListHandle1: TBoldListHandle;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
    FPropagator: THISBoldTCPPropagator;
  public
    { Public declarations }
  end;

var
  DataModule1: TDataModule1;

implementation

{$R *.dfm}

procedure TDataModule1.DataModuleCreate(Sender: TObject);
begin
  FPropagator := THISBoldTCPPropagator.Create(Self);
  FPropagator.Dequeuer := BoldExternalObjectSpaceEventHandler1;
  FPropagator.NextPersistenceHandle := BoldPersistenceHandleDB1;
  FPropagator.SystemHandle := BoldSystemHandle1;
  FPropagator.Locking := True;
  BoldSystemHandle1.PersistenceHandle := FPropagator;
  BoldSystemHandle1.Active := True;
end;

procedure TDataModule1.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(FPropagator);
end;

end.
