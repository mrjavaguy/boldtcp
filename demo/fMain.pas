unit fMain;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  Menus,
  BoldSystemDebuggerForm, StdCtrls, ExtCtrls, BoldNavigatorDefs,
  BoldNavigator, Grids, BoldGrid, BoldSubscription, BoldHandles,
  BoldRootedHandles, BoldAbstractListHandle, BoldCursorHandle,
  BoldListHandle;

type
  TfrmMain = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Debug1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    SystemDebugger1: TMenuItem;
    N2: TMenuItem;
    Updatedatabase1: TMenuItem;
    About1: TMenuItem;
    BoldListHandle1: TBoldListHandle;
    BoldGrid1: TBoldGrid;
    BoldNavigator1: TBoldNavigator;
    procedure Exit1Click(Sender: TObject);
    procedure SystemDebugger1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    procedure UpdateGenerator(var Message:TMessage); message WM_USER +1000;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  BoldSystem,
  dMain;

{$R *.DFM}

procedure TfrmMain.Exit1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.SystemDebugger1Click(Sender: TObject);
begin
  TBoldSystemDebuggerFrm.CreateWithSystem(self, dmMain.bshMain.System).show;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := true;
  if dmMain.bshMain.Active and dmMain.bshMain.system.BoldDirty then
  begin
    if MessageDlg('You have dirty objects. Do you want to quit anyway?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      dmMain.bshMain.system.Discard
    else
      CanClose := false;
  end
end;

procedure TfrmMain.About1Click(Sender: TObject);
begin
  ShowMessage('Yet another project powered by Bold technology');
end;

procedure TfrmMain.UpdateGenerator(var Message: TMessage);
begin
  dmMain.bshMain.System.UpdateDatabaseWithList(TBOldObjectList(Message.LParam));
end;

end.
