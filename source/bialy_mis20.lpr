program bialy_mis20;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, abbrevia, datetimectrls, printer4lazarus, mwindow, bmhelpers,
  { you can add units after this }
   SysUtils;

{$R *.res}
{$R res_string.rc}
{
ABOUT1_HTML RCDATA "res_string-about1.html"
ABOUT2_HTML RCDATA "res_string-about2.html"
VERIF1_HTML RCDATA "res_string-verification1.html"
CONFIG1_HTML RCDATA "res_string-config1.html"
BLANK1_HTML RCDATA "res_string-blank1.html"
}

//TODO: move all images/icons to resource file
{$R res_image.rc}
{
RES_IMAGE1 RCDATA "res_image_bialymis1.png"
}


// icons from
//https://fonts.google.com/icons?icon.query=setti&icon.size=32&icon.color=%231f1f1f

begin
  DefaultFormatSettings.DecimalSeparator := ',';
  DefaultFormatSettings.ThousandSeparator := ' ';
  DefaultFormatSettings.DateSeparator := '-';
  DefaultFormatSettings.ShortDateFormat := 'yyyy-MM-dd';
  DefaultFormatSettings.TimeSeparator := ':';
  DefaultFormatSettings.ShortTimeFormat := 'hh:nn';
  DefaultFormatSettings.LongTimeFormat := 'hh:nn:ss';

  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;


  {$IFDEF WINDOWS}
  {$WARN SYMBOL_PLATFORM OFF}
  Application.UpdateFormatSettings := false;
  {$WARN SYMBOL_PLATFORM ON}
  {$ENDIF}


  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

