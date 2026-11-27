unit mwindow;

{$mode objfpc}{$H+}
//{$codepage utf8}
interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls,
  ComCtrls, Buttons, ExtCtrls, Windows, LCLIntf, EditBtn, IniFiles,
  Pixie.HtmlView, Pixie.Element, Pixie.ElTextInput, Pixie.Document,
  Pixie.PdfExport, bmhelpers, httpsend, ssl_openssl3, Printers, AbZipper,
  AbArcTyp, DateUtils,
  PrintersDlgs, OSPrinters, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn1clean: TBitBtn;
    BitBtn2mode: TBitBtn;
    BitBtn3search: TBitBtn;
    BitBtn4info: TSpeedButton;
    BitBtn5conf: TSpeedButton;
    BitBtn5print: TSpeedButton;
    BitBtn6pdf: TSpeedButton;
    Edit4date: TDateEdit;
    Edit1nip: TEdit;
    Edit2regon: TEdit;
    Edit3bank: TEdit;
    GroupBox1: TPanel;
    GroupBox2: TPanel;
    ImageList1: TImageList;
    Label1nip: TLabel;
    Label2regon: TLabel;
    Label3bank: TLabel;
    Label4date: TLabel;
    MainMenu1: TMainMenu;
    mm5config: TMenuItem;
    mm4info: TMenuItem;
    mm1clean: TMenuItem;
    mm2mode: TMenuItem;
    mm3search: TMenuItem;
    mm6exit: TMenuItem;
    mmMenu: TMenuItem;
    PixieHtml1: TPixieHtmlView;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    Separator3: TMenuItem;
    procedure BitBtn2modeClick(Sender: TObject);
    procedure BitBtn3searchClick(Sender: TObject);
    procedure BitBtn4infoClick(Sender: TObject);
    procedure BitBtn5confClick(Sender: TObject);
    procedure BitBtn5printClick(Sender: TObject);
    procedure BitBtn6pdfClick(Sender: TObject);
    procedure Edit1nipKeyPress(Sender: TObject; var Key: char);
    procedure Edit2regonKeyPress(Sender: TObject; var Key: char);
    procedure Edit3bankKeyPress(Sender: TObject; var Key: char);
    procedure EditExit(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BitBtn1cleanClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mm3searchClick(Sender: TObject);
    procedure mm4infoClick(Sender: TObject);
    procedure mm5configClick(Sender: TObject);
    procedure PixieHtml1AnchorClick(Sender: TObject; const Url: string);
    function PixieHtml1ElementClick(Sender: TObject; El: TObject): boolean;
  private
    pathProgram: string;
    pathDataNew: string;
    pathDataOld: string;
    pathBackup: string;
    pathBackupInterval: integer;
    pathBackupLast: TDateTime;
    htmlStrings: TStrings;
    responseVat: string;
    mainIni: TIniFile;
    modeSearchIsOnline: boolean;
    modeIsConfiguration: boolean;
    modeIsResultView: boolean;
    function formValidate: boolean;
    function formIsEmpty: boolean;
    function LoadResourceStr(resname: string): string;
    function getElementAttr(elemId: string; AttrName: string;
      ARet: string = ''): string;
    function getElementInputVal(elemId: string; ARet: string = ''): string;
    function formToRequest(forceSearch: boolean = False): string;
    function sendRequest(ReqStr: string): THTTPResponseRecord;
    function htmlConvertResponse(Resp: THTTPResponseRecord): string;
    function prepareFileName: string;
    function packFilesList(const FileZip: string; FList: TStringList): boolean;

    procedure modeSearchToggle;
    procedure formClear;
    procedure formSetUp;
    procedure htmlConvertStrings(EOLstr: string = '');
    procedure showHtmlStrings;
    procedure showValidation;
    procedure showConfig;
    procedure saveConfig;
    procedure iniWriteCurrentCfg;
    procedure pixiePrint;
    procedure pixiePDF(filename: string);
    procedure pixieUnfoldAll;
    procedure backupData(force: boolean = False);
  public

  end;

  //https://wykazpodatnikowvat.mf.gov.pl/api#EntityCheckDto
  // all info https://www.gov.pl/web/kas/api-wykazu-podatnikow-vat
var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  pathProgram := ExtractFilePath(Application.ExeName);
  pathDataNew := pathProgram + 'Potwierdzenia\';
  pathDataOld := 'C:\Bialy_Mis\Potwierdzenia\';
  pathBackup := '';
  pathBackupInterval := 7;
  pathBackupLast := Date;
  mainIni := TIniFile.Create(pathProgram + 'config.ini');
  mainIni.Options := mainIni.Options + [ifoStripQuotes];
  if (mainIni.SectionExists('Paths') = False) then
  begin
    //blank ini or no ini
    iniWriteCurrentCfg;
  end;
  pathDataNew := TerminatePath(mainIni.ReadString('Paths', 'pathDataNew', ''));
  pathDataOld := TerminatePath(mainIni.ReadString('Paths', 'pathDataOld', ''));
  pathBackup := TerminatePath(mainIni.ReadString('Paths', 'pathBackup', ''));
  pathBackupInterval := mainIni.ReadInteger('Paths', 'pathBackupInterval', 0);
  pathBackupLast := mainIni.ReadDate('Paths', 'pathBackupLast', Date);
  if (not DirectoryExists(pathDataOld)) then pathDataOld := '';
  if (pathBackup <> '') and (not DirectoryExists(pathBackup)) then pathBackup := '';
  if (not DirectoryExists(pathDataNew)) then
  begin
    if not ForceDirectories(pathDataNew) then
    begin
      MessageDlg('Błąd', 'Nie mozna utworzyc folderu:' + LineEnding +
        pathDataNew + LineEnding + 'Potwierdzenia nie zostaną zapisane!',
        mtError, [mbOK], 0);
      pathDataNew := '';
    end;
  end;

  htmlStrings := TStringList.Create;
  formSetUp;
  formClear;
end;

procedure TForm1.mm3searchClick(Sender: TObject);
begin
  BitBtn3searchClick(Sender);
end;

procedure TForm1.mm4infoClick(Sender: TObject);
begin
  BitBtn4infoClick(Sender);
end;

procedure TForm1.mm5configClick(Sender: TObject);
begin
  BitBtn5confClick(Sender);
end;

procedure TForm1.PixieHtml1AnchorClick(Sender: TObject; const Url: string);
begin
  //reaction to href a click
  if (Pos('http://', LowerCase(Url)) = 1) or
    (Pos('https://', LowerCase(Url)) = 1) then
  begin
    OpenURL(Url);
  end
  else if Pos('app:', LowerCase(Url)) = 1 then
  begin
    // Obsługa poleceń aplikacji.
  end;
end;

function TForm1.PixieHtml1ElementClick(Sender: TObject; El: TObject): boolean;
var
  selPixEl: TPixieElement;
  Doc: TPixieDocument;
  selPixId: string;
  editValue: string;
  editId: string;
  editPixEl: TPixieElement;
  s: string;
begin
  Result := False;
  if not (El is TPixieElement) then
    Exit;
  Doc := PixieHtml1.Document;
  if (Doc = nil) then Exit;

  selPixEl := TPixieElement(El);
  selPixId := selPixEl.GetAttr('id');
  if selPixId = '' then Exit;
  if modeIsConfiguration then
  begin
    //buttons for edits
    editId := '';
    editValue := '';
    editPixEl := nil;
    case selPixId of
      'selectPathDataNew':
      begin
        editId := 'pathDataNew';
      end;
      'selectPathDataOld':
      begin
        editId := 'pathDataOld';
      end;
      'selectPathBackup':
      begin
        editId := 'pathBackup';
      end;
      else
      begin
        editId := '';
      end;
    end;
    if (editId <> '') then
    begin

      editPixEl := Doc.GetElementById(editId);
      if (editPixEl <> nil) then
      begin
        editValue := editPixEl.GetAttr('value');
        s := DialogSelectFolder('', editValue);
        if (s <> '') then editValue := s;
        Doc.BeginUpdate;
        editPixEl.SetAttr('value', editValue);
        Doc.EndUpdate;
        Doc.Changed;
      end;

    end;

    //other buttons
    case selPixId of
      'config_save':
      begin
        saveConfig;
      end;
      'config_backup':
      begin
        backupData(true);
      end;
      else
      begin
        //ShowMessage('Clicked: ' + selPixId);
      end;

    end;
  end;

end;

function TForm1.formValidate: boolean;
begin
  //strip numbers
  Result := True;
  Edit1nip.Text := OnlyNumbers(Edit1nip.Text);
  Edit2regon.Text := OnlyNumbers(Edit2regon.Text);
  Edit3bank.Text := OnlyNumbers(Edit3bank.Text);
  //set colors
  Edit1nip.Font.Color := clBlack;
  Edit2regon.Font.Color := clBlack;
  Edit3bank.Font.Color := clBlack;
  htmlStrings.Clear;
  if formIsEmpty then Exit;
  //verify lenghts
  if ((Length(Edit1nip.Text) <> 10) and (Length(Edit1nip.Text) > 0)) then
  begin
    Edit1nip.Font.Color := clRed;
    htmlStrings.Add('Nieprawidłowa długość numeru <b>NIP</b>');
    Result := False;
  end;
  if not ((Length(Edit2regon.Text) = 9) or (Length(Edit2regon.Text) = 14) or
    (Length(Edit2regon.Text) = 0)) then
  begin
    Edit2regon.Font.Color := clRed;
    htmlStrings.Add('Nieprawidłowa długość numeru <b>REGON</b>');
    Result := False;
  end;
  if ((Length(Edit3bank.Text) <> 26) and (Length(Edit3bank.Text) > 0)) then
  begin
    Edit3bank.Font.Color := clRed;
    htmlStrings.Add('Nieprawidłowa długość <b>numeru konta bankowego</b>');
    Result := False;
  end;

end;

function TForm1.formIsEmpty: boolean;
begin
  //strip numbers
  Result := True;
  if (Length(Edit1nip.Text) > 0) then Result := False;
  if (Length(Edit2regon.Text) > 0) then Result := False;
  if (Length(Edit3bank.Text) > 0) then Result := False;
end;

function TForm1.LoadResourceStr(resname: string): string;
var
  resstr: TResourceStream;
  ressize: SizeInt;
begin
  Result := '';
  if resname = '' then Exit;
  resstr := TResourceStream.Create(HInstance, resname, Windows.RT_RCDATA);
  try
    ressize := SizeInt(resstr.Size);
    SetLength(Result, ressize);
    if ressize > 0 then
      resstr.ReadBuffer(Result[1], ressize);
  finally
    resstr.Free;
  end;
end;

function TForm1.getElementAttr(elemId: string; AttrName: string; ARet: string): string;
var
  Doc: TPixieDocument;
  elemPix: TPixieElement;
  s: string;
begin
  //ShowMessage('getElementId=' + elemId + ' attrib=' + AttrName);
  Result := ARet;
  Doc := PixieHtml1.Document;
  if (Doc = nil) then Exit;
  elemPix := Doc.GetElementById(elemId);
  if (elemPix = nil) then Exit;
  s := elemPix.GetAttr(AttrName);
  if s = '' then
    Result := ARet
  else
    Result := s;
end;

function TForm1.getElementInputVal(elemId: string; ARet: string): string;
var
  Doc: TPixieDocument;
  elemPix: TPixieElement;
  elemTxt: TPixieElTextInput;
  s: string;
begin
  Result := ARet;
  Doc := PixieHtml1.Document;
  if (Doc = nil) then Exit;
  elemPix := Doc.GetElementById(elemId);
  if (elemPix = nil) then Exit;
  if (elemPix.ClassName <> 'TPixieElTextInput') then Exit;
  elemTxt := TPixieElTextInput(elemPix);
  s := elemTxt.Value;
  if (s <> '') then Result := s;
end;

function TForm1.formToRequest(forceSearch: boolean): string;
var
  isnip: boolean;
  isreg: boolean;
  isban: boolean;
  strmethod: string;
begin
  Result := '';
  isban := False;
  isreg := False;
  isnip := False;
  //must be validated before!!!
  if (Length(Edit1nip.Text) = 10) then
  begin
    isnip := True;
  end;
  if ((Length(Edit2regon.Text) = 9) or (Length(Edit2regon.Text) = 14)) then
  begin
    isreg := True;
  end;
  if (Length(Edit3bank.Text) = 26) then
  begin
    isban := True;
  end;

  if ((not forceSearch) and isban and (isnip or isreg)) then
  begin
    //method /check/
    strmethod := '/check/';
    if isnip then
    begin
      strmethod := strmethod + 'nip/' + Edit1nip.Text;
    end
    else
    begin
      strmethod := strmethod + 'regon/' + Edit2regon.Text;
    end;
    strmethod := strmethod + '/bank-account/' + Edit3bank.Text;
  end
  else
  begin
    //method /search/
    strmethod := '';
    if isnip then
    begin
      strmethod := strmethod + 'nip/' + Edit1nip.Text;
    end
    else if isreg then
    begin
      strmethod := strmethod + 'regon/' + Edit2regon.Text;
    end
    else if isban then
    begin
      strmethod := strmethod + 'bank-account/' + Edit3bank.Text;
    end;
    if (strmethod <> '') then
    begin
      strmethod := '/search/' + strmethod;
    end;
  end;
  if (strmethod <> '') then
  begin
    Result := strmethod + '?date=' + Edit4date.Text;
  end;
end;

function TForm1.sendRequest(ReqStr: string): THTTPResponseRecord;
var
  httpclient: THTTPSend;
  s: string;
begin
  Result.Code := 0;
  Result.DataStr := '';
  if (ReqStr = '') then Exit;
  s := '';
  httpclient := THTTPSend.Create();
  try
    httpclient.Timeout := 8000;
    httpclient.UserAgent :=
      'BialyMis/2.0 (Win64; x64) Mozilla/4.0 (compatible; Synapse)';
    httpclient.Protocol := '1.1'; //to wazne dla tego servera
    httpclient.Headers.Add('Accept: application/json');
    httpclient.Headers.Add('Accept-Encoding: identity');
    httpclient.Headers.Add('Accept-Language: pl-PL,pl;q=0.9,en-US;q=0.8,en;q=0.7');
    httpclient.Headers.Add('Cache-Control: no-cache');

    if not httpclient.HTTPMethod('GET', ReqStr) then
      raise Exception.CreateFmt('Błąd połączenia: %d — %s',
        [httpclient.Sock.LastError, httpclient.Sock.LastErrorDesc]);

    SetLength(s, httpclient.Document.Size);
    if Length(s) > 0 then
    begin
      httpclient.Document.Position := 0;
      httpclient.Document.ReadBuffer(s[1], Length(s));
    end;
    Result.Code := httpclient.ResultCode;
    Result.DataStr := s;
  finally
    httpclient.Free;
  end;
end;

function TForm1.htmlConvertResponse(Resp: THTTPResponseRecord): string;
var
  s: string;
begin
  Result := '';
  if ((Resp.Code = 0) or (Resp.DataStr = '')) then Exit;
  if (Resp.Code = 200) then
  begin
    //alles gut
    s := responseToHtml(Resp.DataStr);
  end
  else
  begin
    //some error response
    s := responseErrToHtml(Resp.DataStr);
  end;
  Result := s;
end;

function TForm1.prepareFileName: string;
begin
  Result := FormatDateTime('yyyy-mm-dd_hh.nn.ss_zzz', Now);
end;

function TForm1.packFilesList(const FileZip: string; FList: TStringList): boolean;
var
  Z: TAbZipper;
  i: integer;
begin
  Result := False;
  if (FileZip = '') then Exit;
  if (FList = nil) then Exit;
  if (FList.Count = 0) then Exit;

  Z := TAbZipper.Create(nil);
  try
    Z.FileName := FileZip;
    Z.StoreOptions := [soStripPath];   // bez ścieżek, same pliki
    for i := 0 to FList.Count - 1 do
      Z.AddFiles(FList[i], faAnyFile);
    Z.Save;
    Z.CloseArchive;
    Result := True;
  finally
    Z.Free;
  end;
end;

procedure TForm1.modeSearchToggle;
begin
  //select mode and icons
  modeSearchIsOnline := not modeSearchIsOnline;
  if modeSearchIsOnline then
  begin
    BitBtn2mode.ImageIndex := 1;
    BitBtn2mode.Caption := 'On-line';
  end
  else
  begin
    BitBtn2mode.ImageIndex := 2;
    BitBtn2mode.Caption := 'Lokalnie';
  end;

  mm2mode.ImageIndex := BitBtn2mode.ImageIndex;
  mm2mode.Caption := 'Szukaj ' + BitBtn2mode.Caption;
end;

procedure TForm1.BitBtn1cleanClick(Sender: TObject);
begin
  formClear;
end;

procedure TForm1.EditExit(Sender: TObject);
begin
  if (formValidate = False) then
  begin
    showValidation;
  end
  else
  begin
    PixieHtml1.Zoom := 1;
    htmlStrings.Text := LoadResourceStr('ABOUT2_HTML');
    showHtmlStrings();
    modeIsConfiguration := False;
  end;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  backupData(false);

  htmlStrings.Free;
  mainIni.Free;
end;

procedure TForm1.BitBtn3searchClick(Sender: TObject);
var
  s: string;
  req: string;
  resp: THTTPResponseRecord;
  tsl: TStringList;
  i: integer;
begin
  modeIsConfiguration := False;

  if (not formValidate) then
  begin
    showValidation;
    Exit;
  end;

  if (modeSearchIsOnline) then
  begin
    s := formToRequest(False);
    if (s = '') then
    begin

      modeIsResultView := False;
      Exit;
    end;
    modeIsResultView := True;
    {  serwis testoqwy  API}
    //req := 'https://wykazpodatnikowvat-test.mf.gov.pl/api' + s;
    {  serwis produkcyjny  API}
    req := 'https://wykazpodatnikowvat.mf.gov.pl/api' + s;

    resp := sendRequest(req);
    //ShowMessage('Get Code: ' + IntToStr(resp.Code) + ' Data: ' + LineEnding + resp.DataStr);
    htmlStrings.Text := LoadResourceStr('BLANK1_HTML');
    s := htmlConvertResponse(resp);
    //testing
    s := s + '<br><p class="txt-code">' +
      EscapeHtml(SmartWrap(resp.DataStr, 120, LineEnding, ',:')) + '</p>';
    htmlStrings.Text := htmlStrings.Text.Replace('{field_html_data}', s);
    showHtmlStrings;
    if ((resp.Code = 200) and (resp.DataStr <> '')) then
    begin
      //TODO: write response to Potwierdzenia
      s := pathDataNew;
      if (s <> '') then
      begin
        s := s + prepareFileName + '.json';
        //zapisujemy req z powodu /check/ gdzie w resp nie ma danych kto co
        if (not SaveStringTo(s, resp.DataStr + LineEnding + req)) then
        begin
          MessageDlg('Błąd', 'Nie można zapisać pliku:' +
            LineEnding + s + LineEnding + 'Powierdzenie nie zostało zapisane!',
            mtError, [mbOK], 0);
        end;

      end;

    end;

  end//online end
  else
  begin
    //search for
    s := Edit1nip.Text;
    if (s = '') then s := Edit2regon.Text;
    if (s = '') then s := Edit3bank.Text;
    if (s = '') then Exit;
    tsl := TStringList.Create;
    try
      //fill files to search
      //TODO make functions for these 2
      if pathDataOld <> '' then
      begin
        ListFilesSorted(pathDataOld, tsl, '*.json', s);
      end;
      if pathDataNew <> '' then
      begin
        ListFilesSorted(pathDataNew, tsl, '*.json', s);
      end;
      //prepare result
      s := '<h3> Szukane dane: ' + s + '<br>Wyszukano w <b>' +
        IntToStr(tsl.Count) + '</b> plikach.</h3>';
      i := 0;
      while (i < tsl.Count) do
      begin
        req := tsl[i];
        s := s + '<p>' + EscapeHtml(req) + '</p>';
        s := s + responseToHtml(LoadStringFrom(tsl[i])) + '<hr>';
        Inc(i);
      end;

      htmlStrings.Text := LoadResourceStr('BLANK1_HTML');
      htmlStrings.Text := htmlStrings.Text.Replace('{field_html_data}', s);
      showHtmlStrings;

    finally
      tsl.Clear;
      tsl.Free;
    end;

  end;

end;

procedure TForm1.BitBtn4infoClick(Sender: TObject);
var
  d: double;
begin
  //shows information
  modeIsConfiguration := False;
  modeIsResultView := False;
  PixieHtml1.SetFocus;
  htmlStrings.Text := LoadResourceStr('ABOUT1_HTML');
  showHtmlStrings();
  d := 0.50;
  while (d < 0.90) do
  begin
    PixieHtml1.Zoom := d;
    d := d + 0.02;
    PixieHtml1.Refresh;
  end;
end;

procedure TForm1.BitBtn5confClick(Sender: TObject);
begin
  //shows config
  modeIsConfiguration := True;
  PixieHtml1.SetFocus;
  showConfig;
end;

procedure TForm1.BitBtn5printClick(Sender: TObject);
begin
  if (not modeIsResultView) then Exit;
  pixiePrint;
end;

procedure TForm1.BitBtn6pdfClick(Sender: TObject);
var
  s: string;
begin
  if (not modeIsResultView) then Exit;
  s := DialogSaveFile('Eksport do pliku pdf', 'pdf');
  if s <> '' then
  begin
    pixiePDF(s);
  end;

end;

procedure TForm1.Edit1nipKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    if (Length(Edit1nip.Text) >= 10) then BitBtn3searchClick(Sender);
  end;
end;

procedure TForm1.Edit2regonKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    if ((Length(Edit2regon.Text) = 9) or (Length(Edit2regon.Text) = 14)) then
      BitBtn3searchClick(Sender);
  end;
end;

procedure TForm1.Edit3bankKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    if (Length(Edit3bank.Text) = 26) then
      BitBtn3searchClick(Sender);
  end;
end;

procedure TForm1.BitBtn2modeClick(Sender: TObject);
begin
  modeSearchToggle;
end;

procedure TForm1.formClear;
begin
  modeSearchIsOnline := False;//invert in next steep
  modeSearchToggle;
  modeIsConfiguration := False;
  modeIsResultView := False;
  responseVat := '';
  Edit4date.Date := Date();
  Edit1nip.Clear;
  Edit2regon.Clear;
  Edit3bank.Clear;
  Edit1nip.Font.Color := clBlack;
  Edit2regon.Font.Color := clBlack;
  Edit3bank.Font.Color := clBlack;
  PixieHtml1.Zoom := 1;
  htmlStrings.Text := LoadResourceStr('ABOUT2_HTML');
  showHtmlStrings();
end;

procedure TForm1.formSetUp;
begin
  Form1.Caption := 'Biały Miś v2.0.1';
  Label1nip.Caption := 'NIP: ';
  Label2regon.Caption := 'REGON: ';
  Label3bank.Caption := 'Numer rachunku bankowego: ';
  Label4date.Caption := 'Stan na dzień: ';
  BitBtn1clean.Caption := 'Wyczyść';
  BitBtn2mode.Caption := 'On-line';
  BitBtn3search.Caption := 'Szukaj';
  BitBtn4info.Caption := '';
  BitBtn5conf.Caption := '';
  BitBtn6pdf.Caption := '';
  GroupBox1.Caption := '';
  GroupBox2.Caption := '';
  mmMenu.Caption := '&Menu';
  mm1clean.Caption := '&' + BitBtn1clean.Caption;
  mm2mode.Caption := BitBtn2mode.Caption;
  mm3search.Caption := '&' + BitBtn3search.Caption;
  mm4info.Caption := '&O programie...';
  mm5config.Caption := '&Ustawienia';
  mm6exit.Caption := '&Zamknij';
  BitBtn1clean.Hint := 'Czyści wszystkie pola formularza';
  BitBtn2mode.Hint := 'On-line - szukanie na serwerz M.F.' + LineEnding +
    'Lokalnie - szukanie w zapisanych wynikach';
  BitBtn3search.Hint := 'Rozpocznij wyszukiwanie danych';
  BitBtn4info.Hint := 'Aktualna wersja i licencja';
  BitBtn5conf.Hint := 'Ustawienia programu' + LineEnding + 'Kopia danych';
  BitBtn5conf.Hint := 'Wydrukuj potwierdzenie';
  BitBtn6pdf.Hint := 'Zapisz potwierdzenie do pdf';
end;

procedure TForm1.htmlConvertStrings(EOLstr: string);
var
  i: integer;
begin
  for i := 0 to (htmlStrings.Count - 1) do
  begin
    htmlStrings[i] := htmlStrings[i] + EOLstr;
  end;

end;

procedure TForm1.showHtmlStrings;
begin
  PixieHtml1.LoadFromString(htmlStrings.Text);
end;

procedure TForm1.showValidation;
var
  s: string;
begin
  s := LoadResourceStr('VERIF1_HTML');
  htmlConvertStrings('<br>');
  htmlStrings.Text := s.Replace('{field_verification_result}', htmlStrings.Text);
  showHtmlStrings;
  modeIsResultView := False;
end;

procedure TForm1.showConfig;
var
  s: string;
begin
  s := LoadResourceStr('CONFIG1_HTML');
  s := s.Replace('{field_pathDataNew_value}', pathDataNew);
  s := s.Replace('{field_pathDataOld_value}', pathDataOld);
  s := s.Replace('{field_pathBackup_value}', pathBackup);
  s := s.Replace('{field_pathBackupInterval_value}', IntToStr(pathBackupInterval));
  htmlStrings.Text := s;
  showHtmlStrings;
  modeIsConfiguration := True;
  modeIsResultView := False;
end;

procedure TForm1.saveConfig;
var
  s: string;
begin
  if (not modeIsConfiguration) then Exit;
  pathDataNew := TerminatePath(getElementInputVal('pathDataNew', pathDataNew));
  pathDataOld := TerminatePath(getElementInputVal('pathDataOld', pathDataOld));
  pathBackup := TerminatePath(getElementInputVal('pathBackup', pathBackup));
  s := getElementInputVal('pathBackupInterval', '0');
  pathBackupInterval := StrToIntDef(OnlyNumbers(s), pathBackupInterval);
  iniWriteCurrentCfg;
  formClear;
end;

procedure TForm1.iniWriteCurrentCfg;
begin
  mainIni.WriteString('Paths', 'pathDataNew', QuoteString(pathDataNew));
  mainIni.WriteString('Paths', 'pathDataOld', QuoteString(pathDataOld));
  mainIni.WriteString('Paths', 'pathBackup', QuoteString(pathBackup));
  mainIni.WriteInteger('Paths', 'pathBackupInterval', pathBackupInterval);
  mainIni.WriteDate('Paths', 'pathBackupLast', pathBackupLast);
  mainIni.UpdateFile;
end;

procedure TForm1.pixiePrint;
var
  Dlg: TPrintDialog;
  Stream: TMemoryStream;
  Pic: TPicture;
  MarginX, MarginY: integer;
  AvailableW, AvailableH: integer;
  DestW, DestH: integer;
  Scale: double;
  R: Types.TRect;
begin
  Dlg := TPrintDialog.Create(nil);
  try
    if not Dlg.Execute then
      Exit;
  finally
    Dlg.Free;
  end;

  pixieUnfoldAll;

  Stream := TMemoryStream.Create;
  Pic := TPicture.Create;
  try
    // Szerokość układu HTML w pikselach.
    // Wysokość 0 oznacza całą zawartość dokumentu.
    PixieHtml1.SaveAsBmp(Stream, 1000, 0);
    Stream.Position := 0;
    Pic.LoadFromStream(Stream);

    if (Pic.Width <= 0) or (Pic.Height <= 0) then
      raise Exception.Create('Dokument nie zawiera obrazu do wydruku.');
    //Pic.SaveToFile(pathDataNew+'tmp_img.bmp');

    Printer.BeginDoc;
    try
      // Dodatkowe marginesy 10 mm wewnątrz obszaru drukowalnego.
      MarginX := Round(Printer.XDPI * 10 / 25.4);
      MarginY := Round(Printer.YDPI * 10 / 25.4);

      AvailableW := Printer.PageWidth - 2 * MarginX;
      AvailableH := Printer.PageHeight - 2 * MarginY;

      if (AvailableW <= 0) or (AvailableH <= 0) then
        raise Exception.Create('Zbyt mały obszar wydruku.');

      // Zachowanie proporcji fizycznych także przy różnym XDPI/YDPI.
      Scale := AvailableW / (Pic.Width * Printer.XDPI);
      if AvailableH / (Pic.Height * Printer.YDPI) < Scale then
        Scale := AvailableH / (Pic.Height * Printer.YDPI);

      DestW := Round(Pic.Width * Printer.XDPI * Scale);
      DestH := Round(Pic.Height * Printer.YDPI * Scale);
      R.Left := MarginX;
      R.Top := MarginY;
      R.Right := MarginX + DestW;
      R.Bottom := MarginY + DestH;
      Printer.Canvas.StretchDraw(R, Pic.Graphic);

      Printer.EndDoc;
    except
      Printer.Abort;
      raise;
    end;
  finally
    Pic.Free;
    Stream.Free;
  end;
end;

procedure TForm1.pixiePDF(filename: string);
var
  pdf: TPixiePdfExport;
begin
  if filename = '' then Exit;
  if Length(PixieHtml1.Lines.Text) = 0 then Exit;
  pixieUnfoldAll;

  pdf := TPixiePdfExport.Create;
  try
    pdf.Title := 'Raport weryfikacji podmiotu ' + DateTimeToStr(Now);
    pdf.Author := 'Biały Miś 2.0';
    pdf.PageSize := ppsA4;
    pdf.Margins := TPixiePdfMargins.Create(72, 36, 36, 36);
    pdf.SaveToFile(PixieHtml1.Lines.Text, filename);
  finally
    pdf.Free;
  end;
end;

procedure TForm1.pixieUnfoldAll;
var
  s: string;
begin
  s := PixieHtml1.Lines.Text;
  s := StringReplace(s, '<details style', '<details open style',
    [rfReplaceAll, rfIgnoreCase]);
  PixieHtml1.LoadFromString(s);
end;

procedure TForm1.backupData(force: boolean);
var
  doit: boolean;
  fs: string;
  tsl: TStringList;
  i: integer;
begin
  if pathBackup = '' then Exit;

  if (pathBackupInterval > 0) then
  begin
    i:= DaysBetween(Now, pathBackupLast);
    doit := (pathBackupInterval <= i);
  end;
  if force then doit := True;

  if (not doit) then Exit;

  fs := pathBackup + 'backup_data-' + prepareFileName + '.zip';
  tsl := TStringList.Create;
  try
    htmlStrings.Text := '<h1>Trwa archiwizacja danych</h1><br>' +
      '<h3>Plik archiwum:<br>' + fs + '</h3>';
    showHtmlStrings;
    if pathDataOld <> '' then
    begin
      ListFilesInPath(pathDataOld, tsl, '*.json');
    end;
    if pathDatanew <> '' then
    begin
      ListFilesInPath(pathDataNew, tsl, '*.json');
    end;
    htmlStrings.Text := htmlStrings.Text + '<h3>Znaleziono ' +
      IntToStr(tsl.Count) + ' plików.<br></h3>' + '<h3>Trwa zapis...</h3>';
    showHtmlStrings;
    packFilesList(fs, tsl);
    pathBackupLast:= Now;
    mainIni.WriteDate('Paths', 'pathBackupLast', pathBackupLast);
    mainIni.UpdateFile;
  finally
    tsl.Free;
  end;
  formClear;
end;


end.
