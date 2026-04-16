program OpenEnvEd;

{$mode objfpc}{$H+}
{$J-}
{$WARN 5024 on}
{$WARN 4031 on}

uses
  Interfaces,
  Forms,
  ufrmmain;

var
  frmMain: TMainForm;

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, frmMain);
  Application.Run;
end.
