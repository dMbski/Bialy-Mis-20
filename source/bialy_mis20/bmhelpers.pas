unit bmhelpers;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, fpjson, jsonparser;

const
  cColorWarning = $00C8C8FF;
  cColorResError = $008888FF;
  cColorResOK = $00C8FFC8;
  cColorResWarning = $00C8FFFF;

type
  THTTPResponseRecord = record
    Code: integer;
    DataStr: string;
  end;

function OnlyNumbers(const S: string): string;
function QuoteString(const S: string; Q: string = '"'): string;
function DialogSelectFolder(DName: string; StartDir: string): string;
function DialogSaveFile(DName: string; FExt: string): string;
function TerminatePath(path: string): string;
function SaveStringTo(FileName, Data: string): boolean;
function EscapeHtml(const S: string): string;
function SubjectToHtml(const SubData: string): string;
function ResponseToHtml(const ResponseJson: string): string;
function RespErrToHtml(const ResponseJson: string): string;

implementation

function OnlyNumbers(const S: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    if S[i] in ['0'..'9'] then
      Result := Result + S[i];
  end;
end;

function QuoteString(const S: string; Q: string): string;
begin
  Result := Q + S + Q;
end;

function DialogSelectFolder(DName: string; StartDir: string): string;
var
  Dlg: TOpenDialog;
begin
  Result := '';
  Dlg := TOpenDialog.Create(nil);
  if (StartDir <> '') then
  begin
    Dlg.InitialDir := StartDir;
  end;
  if (DName = '') then DName := 'Wybierz folder';
  //Dlg.FileName := Dlg.InitialDir;

  Dlg.Title := DName;
  Dlg.Options := [ofPathMustExist, ofEnableSizing];
  Dlg.OptionsEx := [ofForceFileSystem, ofPickFolders];
  Dlg.Execute;
  Result := Dlg.FileName;
  Dlg.Free;
end;

function DialogSaveFile(DName: string; FExt: string): string;
var
  Dlg: TOpenDialog;
begin
  Result := '';
  Dlg := TOpenDialog.Create(nil);
  if (DName = '') then DName := 'Wskaż plik';
  FExt := StringReplace(FExt, '.', '', [rfReplaceAll]);
  Dlg.Title := DName;
  Dlg.DefaultExt := FExt;
  Dlg.Filter := FExt + '|*.' + FExt + '|Wszystkie pliki (*.*)|*.*';
  Dlg.Options := DefaultOpenDialogOptions;
  //Dlg.OptionsEx := [ofForceFileSystem];
  Dlg.Execute;
  Result := Dlg.FileName;
  Dlg.Free;
end;

function TerminatePath(path: string): string;
begin
  Result := '';
  if Path = '' then Exit;
  Result := IncludeTrailingPathDelimiter(path);
end;

function SaveStringTo(FileName, Data: string): boolean;
var
  Lines: TStringList;
begin
  Result := False;
  if (FileName = '') then Exit;
  Lines := TStringList.Create;
  try
    Lines.Text := Data;
    Lines.SaveToFile(FileName);
  finally
    Lines.Free;
  end;
  if (FileExists(FileName)) then Result := True;
end;

function EscapeHtml(const S: string): string;
begin
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&#39;', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #10, '<br>', [rfReplaceAll]);
end;


function SubjectToHtml(const SubData: string): string;
const
  BasicKeys: array[0..7] of string = (
    'name', 'statusVat', 'nip', 'regon', 'pesel', 'krs',
    'residenceAddress', 'workingAddress'
    );
  TableStart =
    '<table style="border-collapse:collapse;width:100%;">';
var
  Root, Value: TJSONData;
  Subject: TJSONObject;
  I: integer;
  Key, Rows, ExtraRows, Cell, Color: string;

  function FieldLabel(const AKey: string): string;
  begin
    case AKey of
      'name': Result := 'Nazwa podmiotu';
      'statusVat': Result := 'Status VAT';
      'nip': Result := 'NIP';
      'regon': Result := 'REGON';
      'pesel': Result := 'PESEL';
      'krs': Result := 'KRS';
      'residenceAddress': Result := 'Adres zamieszkania';
      'workingAddress': Result := 'Adres prowadzenia działalności';
      'representatives': Result := 'Osoby reprezentujące podmiot';
      'authorizedClerks': Result := 'Prokurenci';
      'partners': Result := 'Wspólnicy';
      'registrationLegalDate': Result := 'Data rejestracji jako podatnika VAT';
      'registrationDenialDate': Result := 'Data odmowy rejestracji';
      'registrationDenialBasis': Result := 'Podstawa prawna odmowy rejestracji';
      'restorationDate': Result := 'Data przywrócenia rejestracji';
      'restorationBasis': Result := 'Podstawa prawna przywrócenia rejestracji';
      'removalDate': Result := 'Data wykreślenia';
      'removalBasis': Result := 'Podstawa prawna wykreślenia';
      'exemptionSmeDate': Result := 'Data zwolnienia SME';
      'accountNumbers': Result := 'Numery rachunków bankowych';
      'hasVirtualAccounts': Result := 'Posiada rachunki wirtualne';
      'companyName': Result := 'Nazwa firmy';
      'firstName': Result := 'Imię';
      'lastName': Result := 'Nazwisko';
      else
        Result := AKey;
    end;
  end;

  function IsBasicKey(const AKey: string): boolean;
  var
    N: integer;
  begin
    Result := True;
    for N := Low(BasicKeys) to High(BasicKeys) do
      if AKey = BasicKeys[N] then
        Exit;
    Result := False;
  end;

  // AHtml jest już bezpiecznym fragmentem HTML.
  function TableRow(const AKey, AHtml: string): string;
  begin
    Result :=
      '<tr>' + '<td style="padding:5px 8px;border-bottom:1px solid #dddddd;' +
      'vertical-align:middle;width:40%;">' + EscapeHtml(FieldLabel(AKey)) +
      '</td>' + '<td style="padding:5px 8px;border-bottom:1px solid #dddddd;' +
      'vertical-align:middle;">' + AHtml + '</td>' + '</tr>';
  end;

  function RenderValue(Data: TJSONData): string;
  var
    N: integer;
    Part, Content: string;
    Obj: TJSONObject;
  begin
    Result := '';
    if Data = nil then
      Exit;

    case Data.JSONType of
      jtNull:
        Exit;

      jtString:
      begin
        if Trim(Data.AsString) <> '' then
          Result := EscapeHtml(Data.AsString);
      end;

      jtBoolean:
      begin
        if Data.AsBoolean then
          Result := 'Tak'
        else
          Result := 'Nie';
      end;

      jtObject:
      begin
        Obj := TJSONObject(Data);
        Content := '';

        for N := 0 to Obj.Count - 1 do
        begin
          Part := RenderValue(Obj.Items[N]);
          if Part <> '' then
            Content := Content + TableRow(Obj.Names[N], Part);
        end;

        if Content <> '' then
          Result := TableStart + Content + '</table>';
      end;

      jtArray:
      begin
        Content := '';

        for N := 0 to Data.Count - 1 do
        begin
          Part := RenderValue(Data.Items[N]);
          if Part = '' then
            Continue;

          if Content <> '' then
            Content := Content + '<div style="height:6px;"></div>';

          Content := Content + '<div>' + Part + '</div>';
        end;

        Result := Content;
      end;

      else
        Result := EscapeHtml(Data.AsString);
    end;
  end;

  procedure AddBasicField(const AKey: string);
  begin
    Value := Subject.Find(AKey);
    Cell := RenderValue(Value);
    if Cell = '' then
      Exit;

    if AKey = 'name' then
      Cell := '<strong>' + Cell + '</strong>'
    else if AKey = 'statusVat' then
    begin
      Color := '#c00000';
      if Value.AsString = 'Czynny' then
        Color := '#008000';

      Cell := '<span style="color:' + Color + ';font-weight:bold;">' +
        Cell + '</span>';
    end;

    Rows := Rows + TableRow(AKey, Cell);
  end;

begin
  Result := '';
  Root := GetJSON(SubData);
  try
    if Root.JSONType <> jtObject then
      raise Exception.Create(
        'SubjectToHtml: oczekiwano obiektu JSON pojedynczego podmiotu.');

    Subject := TJSONObject(Root);
    Rows := '';

    // Pola podstawowe: odczyt indywidualny, ustalona kolejność.
    AddBasicField('name');
    AddBasicField('statusVat');
    AddBasicField('nip');
    AddBasicField('regon');
    AddBasicField('pesel');
    AddBasicField('krs');
    AddBasicField('residenceAddress');
    AddBasicField('workingAddress');

    // Wszystkie pozostałe pola: generycznie i rekurencyjnie.
    ExtraRows := '';
    for I := 0 to Subject.Count - 1 do
    begin
      Key := Subject.Names[I];
      if IsBasicKey(Key) then
        Continue;

      Cell := RenderValue(Subject.Items[I]);
      if Cell <> '' then
        ExtraRows := ExtraRows + TableRow(Key, Cell);
    end;

    Result :=
      '<div style="margin-bottom:16px;padding:10px;' +
      'border:1px solid #cccccc;">' + TableStart + Rows + '</table>';

    if ExtraRows <> '' then
      Result := Result + '<details style="margin-top:8px;">' +
        '<summary style="font-size: 75%; font-weight: bold;">Dodatkowe informacje</summary>'
        + TableStart + ExtraRows + '</table>' + '</details>';

    Result := Result + '</div>';
  finally
    Root.Free;
  end;
end;

function ResponseToHtml(const ResponseJson: string): string;
const
  NoSubjectHtml =
    '<p class="txt-info">Nie znaleziono podmiotu dla podanych danych.</p>';
var
  Root, ResData, Data: TJSONData;
  ResObj: TJSONObject;
  RequestIdData: TJSONData;
  I: integer;

  function InvalidResponseHtml: string;
  var
    S: string;
  begin
    S := EscapeHtml(ResponseJson);
    Result :=
      '<p class="txt-title">' + 'Odpowiedź z serwisu jest nieprawidłowa' +
      '</p>' + '<p class="txt-info">' + S + '</p>';
  end;

begin
  Result := '';
  Root := nil;
  try
    try
      Root := GetJSON(ResponseJson);

      if Root = nil then
      begin
        Result := InvalidResponseHtml;
        Exit;
      end;

      if Root.JSONType <> jtObject then
      begin
        Result := InvalidResponseHtml;
        Exit;
      end;

      ResData := TJSONObject(Root).Find('result');
      if ResData = nil then
      begin
        Result := InvalidResponseHtml;
        Exit;
      end;

      if ResData.JSONType <> jtObject then
      begin
        Result := InvalidResponseHtml;
        Exit;
      end;

      ResObj := TJSONObject(ResData);
      //requestid
      RequestIdData := ResObj.Find('requestId');

      //check result for check method
      Data := ResObj.Find('accountAssigned');
      if Data <> nil then
      begin
        Result := '<p class="txt-title">Informacja, że rachunek jest przypisany do podmiotu';
        if (UpperCase(Data.AsString) = 'TAK') then
        begin
          Result := Result + '</p><h1 style="text-align: center; color: #006400;">TAK</h1>';
        end
        else
        begin
          Result := Result + '<h1 class="txt-info">' + Data.AsString + '</h1></p>';
        end;
        //Dodaj resuetsid
        if ((RequestIdData <> nil) and (RequestIdData.JSONType = jtString)) then
        begin
          Result := Result + '<p class="txt-code">Identyfikator wyszukania: ' +
            EscapeHtml(RequestIdData.AsString) + '</p>';
        end;
        Exit;
      end;


      // Pojedynczy podmiot.
      Data := ResObj.Find('subject');
      if Data <> nil then
      begin
        case Data.JSONType of
          jtNull:
            Result := NoSubjectHtml;

          jtObject:
            Result := SubjectToHtml(Data.AsJSON);
          else
            Result := InvalidResponseHtml;
        end;

        //Dodaj resuetsid
        if ((RequestIdData <> nil) and (RequestIdData.JSONType = jtString)) then
        begin
          Result := Result + '<p class="txt-code">Identyfikator wyszukania: ' +
            EscapeHtml(RequestIdData.AsString) + '</p>';
        end;
        Exit;
      end;

      // Tablica podmiotów.
      Data := ResObj.Find('subjects');
      if Data <> nil then
      begin
        case Data.JSONType of
          jtNull:
            Result := NoSubjectHtml;

          jtArray:
          begin
            for I := 0 to Data.Count - 1 do
            begin
              if Data.Items[I].JSONType = jtNull then
                Continue;

              if Data.Items[I].JSONType <> jtObject then
              begin
                Result := InvalidResponseHtml;
                Exit;
              end;

              Result := Result + SubjectToHtml(Data.Items[I].AsJSON);
            end;

            if Result = '' then
              Result := NoSubjectHtml;
          end;
          else
            Result := InvalidResponseHtml;
        end;

        //Dodaj resuetsid
        if ((RequestIdData <> nil) and (RequestIdData.JSONType = jtString)) then
        begin
          Result := Result + '<p class="txt-code">Identyfikator wyszukania: ' +
            EscapeHtml(RequestIdData.AsString) + '</p>';
        end;
        Exit;
      end;

      Result := InvalidResponseHtml;
    except
      on E: Exception do
        Result := InvalidResponseHtml;
    end;
  finally
    Root.Free;
  end;
end;

function RespErrToHtml(const ResponseJson: string): string;
var
  Root: TJSONData;
  J: TJSONObject;

  function InvalidResponseHtml: string;
  var
    S: string;
  begin
    S := EscapeHtml(ResponseJson);

    Result :=
      '<p class="txt-title">' + 'Odpowiedź z serwisu jest nieprawidłowa' +
      '</p>' + '<p class="txt-info">' + S + '</p>';
  end;

begin
  Root := GetJSON(ResponseJson);
  try
    if Root.JSONType <> jtObject then
    begin
      Result := InvalidResponseHtml;
    end;

    J := TJSONObject(Root);
    Result :=
      '<p class="txt-title">Wystąpił błąd: ' + EscapeHtml(J.Get('code', '')) +
      '</p><p class="txt-info">' + EscapeHtml(J.Get('message', '')) + '</p>';
  finally
    Root.Free;
  end;
end;

end.
