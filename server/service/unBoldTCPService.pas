unit unBoldTCPService;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs;

type
  TBoldTCPService = class(TService)
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceShutdown(Sender: TService);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  BoldTCPService: TBoldTCPService;

implementation

uses unPropagatorServer;

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  BoldTCPService.Controller(CtrlCode);
end;

function TBoldTCPService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TBoldTCPService.ServiceStart(Sender: TService;
  var Started: Boolean);
begin
    TPropagatorServer.Instance;
end;

procedure TBoldTCPService.ServiceShutdown(Sender: TService);
begin
    TPropagatorServer.Instance.Free;
end;

end.
