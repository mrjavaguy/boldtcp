unit unPropagatorTests;

interface

uses
  Forms,
  Classes,
  Controls,
  Messages,
  SysUtils,
  BoldTCPGlobals,
  TestFramework,
  unPropagatorServer,
  BoldSystem,
  dmFullBold;

type
  TTestPropagatorTests = class(TTestCase)
  private
    FServer:TPropagatorServer;
    FClient1,
    FClient2:TDataModule1;
    function GetObjectByBoldIDString(
      const aObjectIdString: String; aBoldSytems:TBoldSystem): TBoldObject;
  protected
    procedure Locking;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestNewClass;
    procedure TestLocking;
  end;


implementation

uses
  BoldLockHandler,
  BoldId,
  BoldDefaultId,
  BoldDefs,
  BoldElements,
  BusinessClasses;

{ TTestPropagatorTests }

procedure TTestPropagatorTests.Setup;
begin
  inherited;
  FServer := TPropagatorServer.Create;
  FClient1 := TDataModule1.Create(nil);
  FClient2 := TDataModule1.Create(nil);
end;

procedure TTestPropagatorTests.TearDown;
begin
  inherited;
  if FClient1.BoldSystemHandle1.System.BoldDirty then
     FClient1.BoldSystemHandle1.System.Discard;
  if FClient2.BoldSystemHandle1.System.BoldDirty then
     FClient2.BoldSystemHandle1.System.Discard;
  FreeAndNil(FClient2);
  FreeAndNil(FClient1);
  FreeAndNil(FServer);
end;


function TTestPropagatorTests.GetObjectByBoldIDString (const
aObjectIdString: String; aBoldSytems:TBoldSystem): TBoldObject;
var
  ObjectId: TBoldObjectID;
begin
  ObjectId := nil;
  try
    ObjectID := TBoldDefaultId.CreateWithClassID(0, false);
    TBoldDefaultId(ObjectID).AsInteger := StrToInt(aObjectIdString);
    Result := aBoldSytems.EnsuredLocatorByID
[ObjectID].EnsuredBoldObject;
  finally
    FreeAndNil(ObjectId);
  end;
end;


procedure TTestPropagatorTests.Locking;
var
  BoldObject:TBoldObject;
  aName:String;
begin
   if (FClient1.BoldListHandle1.CurrentBoldObject is TTestClass) then
   begin
     BoldObject := FClient1.BoldListHandle1.CurrentBoldObject;
     if not (BoldObject is TTestClass) then
        Fail('Not a good object');
      aName := TTestClass(BoldObject).Name;

     TTestClass(BoldObject).Name := aName + DEFAULT_NAME_STRING;
     BoldObject := GetObjectByBoldIDString(BoldObject.BoldObjectLocator.BoldObjectID.AsString,FClient2.BoldSystemHandle1.System);
     TTestClass(BoldObject).Name :=aName +  'Other';
   end
   else
     Fail('Invalid Object');
end;

procedure TTestPropagatorTests.TestNewClass;
var
  i : integer;
begin
  i := FClient1.BoldListHandle1.Count;
  TTestClass.Create(FClient1.BoldSystemHandle1.System);
  FClient1.BoldSystemHandle1.UpdateDatabase;
  Application.ProcessMessages;
  sleep(1000);
  Application.ProcessMessages;
  CheckEquals(i+1,FClient2.BoldListHandle1.Count,'Polling Failed');
end;

procedure TTestPropagatorTests.TestLocking;
begin
  Self.CheckException(Locking,EBoldGetLocksFailed,'No Locks');
end;

initialization
  RegisterTest('Propagator', TTestPropagatorTests.Suite);

end.
