unit RecieverTestForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,   BoldTCPGlobals;

type
  TThreadReceive = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FEvents:TStrings;
    procedure PollingEvent(var Message:TMessage); message TM_POLL_EVENT;
  public
    { Public declarations }
    property Events:TStrings read FEvents;
  end;

var
  ThreadReceive: TThreadReceive;

implementation

{$R *.dfm}

procedure TThreadReceive.FormCreate(Sender: TObject);
begin
  FEvents := TStringList.Create;
end;

procedure TThreadReceive.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FreeAndNil(FEvents);
end;

procedure TThreadReceive.PollingEvent(var Message: TMessage);
begin
  FEvents.Add(TClientEvent(Message.lParam).Event)
end;

end.
