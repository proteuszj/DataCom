program DataCom;

uses
  Forms,
  Windows,
  UMain in 'UMain.pas' {frmMain},
  UThreadProcess in 'UThreadProcess.pas',
  UDBProcess in 'UDBProcess.pas' {DM: TDataModule},
  UPublic in 'UPublic.pas',
  TmriOutAccess in 'TmriOutAccess.pas';

{$R *.res}
var
  vlHandle: hWnd;

begin
  //防止二次启动——检测窗口句柄是否已经存在
  vlHandle := FindWindow(APPNAME, NIL);
  if vlHandle > 0 then
  begin
    PostMessage(vlHandle, CM_RESTORE, 0, 0);
    Exit;
  end;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
