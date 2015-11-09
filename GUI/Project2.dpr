program Project2;

uses
  Forms,
  Unit2 in 'Unit2.pas' {Form2},
  LibUSB in '..\Delphi LibUSB\PowerSwitch_DelphiSource\Delphi-libUSB\LibUSB.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Kendali Motor';
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
