program SetConfig;

uses
  Forms,
  USetConfig in 'USetConfig.pas' {frmSetConfig};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmSetConfig, frmSetConfig);
  Application.Run;
end.
