unit NotificationUnit;

interface

uses Classes,
     ExtCtrls,
     SyncObjs,
     DispatcherUnit;

type INotificationQueue = interface;

     TNotification = class
     public
      constructor Create (const aNotificationQueue : INotificationQueue); virtual;
     end;

     TNotificationClass = class of TNotification;

     INotificationQueue = interface
      function  ThisQueue : INotificationQueue;
      procedure AddNotification (const aNotification : TNotification);
      procedure Send;
     end;

     INotificationManager = interface
      function  NewQueue : INotificationQueue;
      procedure SendNotification (aNotification : TNotification);
     end;

     TNotificationManager = class (TComponent, INotificationManager)
     private
      FDispatcher : TDispatcher;
      FList       : TThreadList;
      FTimer      : TTimer;

      procedure DoTimer (aSender : TObject);
     protected
      function  NewQueue : INotificationQueue;
      procedure SendNotification (aNotification : TNotification);
     public
      procedure AfterConstruction; override;
      procedure BeforeDestruction; override;

      procedure AddDispatch (const aNotificationClass : TNotificationClass;
                             const aMethodAddress     : Pointer;
                             const aObject            : TObject);
     end;

implementation

uses Windows;

{ TNotification }

constructor TNotification.Create (const aNotificationQueue : INotificationQueue);
begin
 inherited Create;

 if   Assigned (aNotificationQueue)
 then aNotificationQueue.AddNotification (Self);
end;

type TNotificationQueue = class (TInterfacedObject, INotificationQueue)
     private
      FNotificationManager : INotificationManager;
      FList                : TList;
     protected
      function  ThisQueue : INotificationQueue;
      procedure AddNotification (const aNotification : TNotification);
      procedure Send;
     public
      constructor Create (const aNotificationManager : INotificationManager);
      destructor  Destroy; override;
     end;

{ TNotificationQueue }

constructor TNotificationQueue.Create (const aNotificationManager : INotificationManager);
begin
 inherited Create;

 FNotificationManager := aNotificationManager;
 FList                := TList.Create;
end;

destructor TNotificationQueue.Destroy;
 var aIndex : Integer;
begin
 if FList.Count > 0 then
 begin
  for aIndex := 0 to Pred (FList.Count) do
  try
   TObject (FList [aIndex]).Free;
  except
  end;
 end;

 FList.Free;

 inherited;
end;

function TNotificationQueue.ThisQueue : INotificationQueue;
begin
 Result := Self;
end;

procedure TNotificationQueue.AddNotification (const aNotification : TNotification);
begin
 FList.Add (aNotification);
end;

procedure TNotificationQueue.Send;
 var aIndex : Integer;
begin
 try
  try
   for aIndex := 0 to Pred (FList.Count) do
   try
    FNotificationManager.SendNotification (TNotification (FList [aIndex]))
   except
   end;
  finally
   FList.Clear;
  end;
 except
 end;
end;

{ TNotificationManager }
     
procedure TNotificationManager.AfterConstruction;
begin
 inherited;

 FDispatcher := TDispatcher.Create (Nil);
 FList       := TThreadList.Create;
 FTimer      := TTimer     .Create (Nil);

 with FTimer do
 begin
  Enabled  := False;
  Interval := 1;
  OnTimer  := DoTimer;
 end;
end;

procedure TNotificationManager.BeforeDestruction;
 var aIndex : Integer;
begin
 with FList, LockList do
 try
  FTimer.Enabled := False;

  for aIndex := 0 to Pred (Count) do
  try
   TObject (Items [aIndex]).Free;
  except
  end;

  Clear;
 finally
  UnlockList;
 end;

 FTimer     .Free;
 FList      .Free;
 FDispatcher.Free;

 inherited;
end;
     
procedure TNotificationManager.AddDispatch (const aNotificationClass : TNotificationClass;
                                            const aMethodAddress     : Pointer;
                                            const aObject            : TObject);
begin
 FDispatcher.AddDispatch (aNotificationClass, aMethodAddress, aObject);
end;

function TNotificationManager.NewQueue : INotificationQueue;
begin
 Result := TNotificationQueue.Create (Self);
end;

procedure TNotificationManager.SendNotification (aNotification : TNotification);
begin
 try
  try
   with FList, LockList do
   try
    Add (aNotification);

    aNotification  := Nil;

    FTimer.Enabled := True;
   finally
    UnlockList;
   end;
  except
   aNotification.Free;
  end; 
 except
 end;
end;

procedure TNotificationManager.DoTimer (aSender : TObject);
 var aObject : TObject;
begin
 try
  aObject := Nil;
  try
   with FList, LockList do
   try
    try
     if   Count <= 0
     then Exit;

     aObject := First;

     Delete (0);
    finally
     FTimer.Enabled := Count > 0;
    end;
   finally
    UnlockList;
   end;

   FDispatcher.Execute (aObject);
  finally
   aObject.Free;
  end;
 except
 end; 
end;

end.
