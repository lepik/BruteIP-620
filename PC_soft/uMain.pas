unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Mask, ComCtrls, FileUtil, Registry, StrUtils,
  Menus, CPortCtl, CPort, CPortTypes;

const
  DefaultBaudrate: string = '9600';

type
  TByteList = array of Byte;

type
  TfrmMain = class(TForm)
    GroupBox1: TGroupBox;
    StatusBar: TStatusBar;
    cbComPort: TComboBox;
    btnPortOpen: TButton;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    meStartPassw: TMaskEdit;
    cbDownCount: TCheckBox;
    btnBruteStart: TButton;
    btnBruteStop: TButton;
    Label2: TLabel;
    manEdtPaswd: TMaskEdit;
    btnSendPassw: TButton;
    btnSendMENU: TButton;
    btnSendF: TButton;
    GroupBox3: TGroupBox;
    lvPasswd: TListView;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    PopupMenu: TPopupMenu;
    Save1: TMenuItem;
    Load1: TMenuItem;
    N1: TMenuItem;
    Sendpasswd1: TMenuItem;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnPortOpenClick(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure Load1Click(Sender: TObject);
    procedure btnSendPasswClick(Sender: TObject);
    procedure btnBruteStartClick(Sender: TObject);
    procedure btnBruteStopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Sendpasswd1Click(Sender: TObject);
  private
    //FSerialConn: TBlockSerial;
    ComPort: TComPort;
    ComDataPacket: TComDataPacket;

    FBackFile: string;
    FExeLogFileName: string;
    procedure SleepActive(Duration: integer);
    function GetComPortCount: integer;
    function GetComportFriendlyName(RegKey, Port: string): string;
    procedure GetComportNames(Ports: TStrings);
    procedure ComPortDisconnect;
    procedure ComPortConnect;
  public
    procedure AddListRec(CurPassw: string);
    procedure SavePaswList(fileName: string);
    procedure LoadPaswList(fileName: string);
    procedure SendManualPassw(passw: string);
    procedure StopBrute;

    function StrToByte(const Value: String): TByteList;
    function ByteToString(const Value: TByteList): String;
    procedure OnRxBuffer(Sender: TObject; const Buffer:TCPortBytes;Count: Integer);
    procedure AppendToLogExe(Str: string);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.AddListRec(CurPassw: string);
  var
  passwItem: TListItem;
begin
  passwItem:= lvPasswd.Items.Add;
  passwItem.Caption:=DateTimeToStr(Now());
  passwItem.SubItems.Add('N');
  passwItem.SubItems.Add(CurPassw);
  SavePaswList(FBackFile);
end;

procedure TfrmMain.AppendToLogExe(Str: string);
var
  fs: TextFile;
begin
  try
    AssignFile(fs, FExeLogFileName);
    if not FileExists(FExeLogFileName) then
      Rewrite(fs)
    else
      Append(fs);
      Writeln(fs, FormatDateTime('dd-mm-yyyy hh:nn:ss', Now()) + ' ' + Str);
      CloseFile(fs);
  except

  end;
end;

procedure TfrmMain.btnBruteStartClick(Sender: TObject);
var
  SendByte: TByteList;
begin
  try
    if cbDownCount.Checked then
      SendByte := StrToByte('D'+meStartPassw.Text+#13+#10)
      else
      SendByte := StrToByte('U'+meStartPassw.Text+#13+#10);
    Sleep(1000);
    SendByte := StrToByte('S'+meStartPassw.Text+#13+#10);
    ComPort.Write(PChar(SendByte),Length(SendByte));
  except
    on e: Exception do
     begin
        AppendToLogExe('btnBruteStartClick: '+e.Message);
     end;
  end;
end;

procedure TfrmMain.btnBruteStopClick(Sender: TObject);
var
  SendByte: TByteList;
begin
  try
    SendByte := StrToByte('E'+#13+#10);
    ComPort.Write(PChar(SendByte),Length(SendByte));
  except
    on e: Exception do
     begin
        AppendToLogExe('btnBruteStopClick: '+ e.Message);
     end;
  end;
end;

procedure TfrmMain.btnPortOpenClick(Sender: TObject);
begin
  try
    if (ComPort.Connected = False) then
      begin
        ComPortConnect;
        btnPortOpen.Caption:= 'Discon';
        if ComPort.Connected = True then
          begin
            btnBruteStart.Enabled:= True;
            btnBruteStop.Enabled:= True;
            btnSendPassw.Enabled:= True;
            btnSendMENU.Enabled:= True;
            btnSendF.Enabled:= True;
            AppendToLogExe('ComPort: Connect');
          end;
      end
      else
      begin
        ComPortDisconnect;
        btnPortOpen.Caption:= 'Connect';
        if ComPort.Connected = False then
          begin
            btnBruteStart.Enabled:= False;
            btnBruteStop.Enabled:= False;
            btnSendPassw.Enabled:= False;
            btnSendMENU.Enabled:= False;
            btnSendF.Enabled:= False;
            AppendToLogExe('ComPort: Disconnect');
          end;
      end;
    Application.ProcessMessages;  
  except
    on e: Exception do
     begin
        AppendToLogExe('btnPortOpenClick: '+ e.Message);
     end;
  end;
end;

procedure TfrmMain.btnSendPasswClick(Sender: TObject);
begin
  SendManualPassw(manEdtPaswd.Text);
end;

function TfrmMain.ByteToString(const Value: TByteList): String;
var
  i: integer;
  s : String;
  Letra: char;
begin
  S := '';
  for i := Length(Value)-1 downto 0 do
    begin
    letra := Chr(Value[I] + 48);
    S := letra + S;
    end;
    Result := S;
end;

procedure TfrmMain.ComPortConnect;
var
  comPortStr: string;
begin
  try
    comPortStr := LeftStr(cbComPort.Text, Pos(':', cbComPort.Text) - 1);
    ComPort.Port := comPortStr;
    ComPort.BaudRate := StrToBaudRate(DefaultBaudrate);
    ComPort.Open;
    if ComPort.Connected then
    begin
      StatusBar.Panels[0].Text:= 'Connect: '+BoolToStr(ComPort.Connected,True);
    end;
  except
    on e: Exception do
     begin
        AppendToLogExe('ComPortConnect: '+ e.Message);
     end;
  end;
end;

procedure TfrmMain.ComPortDisconnect;
begin
  try
    if ComPort.Connected = true then
    begin
      ComPort.Close;
      if not ComPort.Connected then
        begin
          StatusBar.Panels[0].Text:= 'Connect: '+BoolToStr(ComPort.Connected,True);
        end;
    end;
  except
    on e: Exception do
     begin
        AppendToLogExe('ComPortDisconnect: '+ e.Message);
     end;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ComPortDisconnect;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  try

  ComPort := TComPort.Create(Self);
  ComPort.Connected := False;
  ComPort.Buffer.InputSize := 2048;
  ComPort.Buffer.OutputSize := 2048;
  ComPort.DataBits := dbEight;
  ComPort.DiscardNull := False;
  ComPort.EventChar := #0;
  ComPort.Events := [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD, evRx80Full];
  ComPort.FlowControl.ControlDTR := dtrDisable;
  ComPort.FlowControl.ControlRTS := rtsDisable;
  ComPort.FlowControl.DSRSensitivity := False;
  ComPort.FlowControl.FlowControl := fcNone;
  ComPort.FlowControl.OutCTSFlow := False;
  ComPort.FlowControl.OutDSRFlow := False;
  ComPort.FlowControl.TxContinueOnXoff := False;
  ComPort.FlowControl.XoffChar := #19;
  ComPort.FlowControl.XonChar := #17;
  ComPort.FlowControl.XonXoffIn := False;
  ComPort.FlowControl.XonXoffOut := False;
  ComPort.Parity.Bits := prNone;
  ComPort.Parity.Check := False;
  ComPort.Parity.Replace := False;
  ComPort.Parity.ReplaceChar := #0;
  ComPort.StopBits := sbOneStopBit;
  ComPort.SyncMethod := smThreadSync;

  ComDataPacket := TComDataPacket.Create(Self);
  ComDataPacket.ComPort := ComPort;
  ComDataPacket.MaxBufferSize:= 2048;
  ComPort.OnRxBuf:= OnRxBuffer;

    FBackFile:= 'paswlist_back_'+FormatDateTime('ddmmyy',Now())+'.txt';
    FExeLogFileName:= ExtractFilePath(Application.ExeName)+'\log_app_'+FormatDateTime('ddmmyy',Now())+'.txt';
    btnBruteStart.Enabled:= false;
    btnBruteStop.Enabled:= false;
    btnSendPassw.Enabled:= false;
    btnSendMENU.Enabled:= false;
    btnSendF.Enabled:= false;
  except

  end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  PortsCount: integer;
begin
  try
    PortsCount:= GetComPortCount;
    if PortsCount <= 0 then
      begin
        ShowMessage('В системе не обнаружены COM порты');
      end;
    GetComportNames(cbComPort.Items);
    cbComPort.ItemIndex := 0;
  except
    on e: Exception do
     begin
        AppendToLogExe('FormShow: '+ e.Message);
     end;
  end;
end;

function TfrmMain.GetComPortCount: integer;
var
  Registry: TRegistry;
  KeyInfo: TRegKeyInfo;
begin
  try
    Registry := TRegistry.Create;
    Result := -1;
    try
      Registry.RootKey := HKEY_LOCAL_MACHINE;
      if Registry.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM') then
      begin
        Registry.GetKeyInfo(KeyInfo);
        Result := KeyInfo.NumValues;
      end;
    finally
      Registry.CloseKey;
      Registry.Free;
    end;
  except
    on e: Exception do
     begin
        AppendToLogExe('GetComPortCount: '+ e.Message);
     end;
  end;
end;

function TfrmMain.GetComportFriendlyName(RegKey, Port: string): string;
var
  Registry: TRegistry;
  KeyNames: TStringList;
  Count: integer;
  CurrentKey: string;
  FriendlyName: string;
  FoundKeyIn: string;
begin
  try
    Registry := TRegistry.Create;
    KeyNames := TStringList.Create;
    Result := EmptyStr;
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    Registry.OpenKeyReadOnly(RegKey);
    Registry.GetKeyNames(KeyNames);
    Registry.CloseKey;
    try
      for Count := 0 to KeyNames.Count - 1 do
      begin
        CurrentKey := RegKey + KeyNames[Count] + '\';
        if Registry.OpenKeyReadOnly(CurrentKey + 'Device Parameters') then
        begin
          if Registry.ReadString('PortName') = port then
          begin
            Registry.CloseKey;
            Registry.OpenKeyReadOnly(CurrentKey);
            FriendlyName := Registry.ReadString('FriendlyName');
            Registry.CloseKey;
            FoundKeyIn := Copy(CurrentKey, 32, length(CurrentKey) - 32);
            FoundKeyIn := Copy(FoundKeyIn, 0, pos('\', FoundKeyIn) - 1);
            FriendlyName := FriendlyName + ' - (' + FoundKeyIn + ')';
            Break;
          end;
        end
        else
        begin
          if Registry.OpenKeyReadOnly(CurrentKey) and Registry.HasSubKeys then
          begin
            FriendlyName := GetComportFriendlyName(CurrentKey, Port);
            Registry.CloseKey;
            if FriendlyName <> EmptyStr then
              Break;
          end;
        end;
      end;
      Result := FriendlyName;
    finally
      Registry.CloseKey;
      Registry.Free;
      KeyNames.Free;
    end;
  except
    on e: Exception do
     begin
        AppendToLogExe('GetComportFriendlyName: '+ e.Message);
     end;
  end;
end;


procedure TfrmMain.GetComportNames(Ports: TStrings);
var
  Registry: TRegistry;
  PortNames: TStringList;
  PortList: TStringList;
  Count: integer;
  Port: string;
  FriendlyName: string;
begin
  try
    Registry := TRegistry.Create;
    PortNames := TStringList.Create;
    PortList := TStringList.Create;
    PortNames.Clear;
    PortList.Clear;
    Ports.BeginUpdate;
    try
      Ports.Clear;
      Registry.RootKey := HKEY_LOCAL_MACHINE;
      if Registry.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM') then
      begin
        Registry.GetValueNames(PortList);
        for Count := 0 to PortList.Count - 1 do
        begin
          Port := Registry.ReadString(PortList[Count]);
          FriendlyName := GetComportFriendlyName('\SYSTEM\CurrentControlSet\Enum\', Port);
          if FriendlyName <> '' then
            PortNames.Add(Port + ': ' + FriendlyName)
          else
            PortNames.Add(Port);
        end;
        PortNames.Sort;
        Ports.Assign(PortNames);
      end;
    finally
      Registry.CloseKey;
      Registry.Free;
      PortNames.Free;
      PortList.Free;
      Ports.EndUpdate;
    end;
  except
    on e: Exception do
     begin
        AppendToLogExe('GetComportNames: '+e.Message);
     end;
  end;
end;

procedure TfrmMain.Load1Click(Sender: TObject);
begin
  OpenDialog.InitialDir:= ExtractFilePath(Application.ExeName);
  if OpenDialog.Execute then
    begin
      lvPasswd.Items.Clear;
      LoadPaswList(OpenDialog.FileName);
    end;
end;

procedure TfrmMain.LoadPaswList(fileName: string);
const Delimiter = '|';
var ff: TextFile;
    S: String;
begin
 AssignFile(ff, fileName);
 Reset(ff);
 try
  while not Eof(ff) do
   begin
    ReadLn(ff,S);
    with lvPasswd.Items.Add do
     begin
      Caption:=Copy(S,1,Pos(Delimiter,S)-1);
      System.Delete(S,1,Pos(Delimiter,S));
      S:=StringReplace(S,Delimiter,#13#10,[rfReplaceAll]);
      SubItems.Text:=S;
     end; {With}
   end; {While}
 finally
  CloseFile(ff);
 end;
end;

procedure TfrmMain.OnRxBuffer(Sender: TObject; const Buffer: TCPortBytes;
  Count: Integer);
begin
  if Pos('N',PChar(Buffer)) = 1 then
    AddListRec(Copy(PChar(Buffer),1,StrLen(PChar(Buffer))-2));
  ComPort.ClearBuffer(True,True);
end;

procedure TfrmMain.Save1Click(Sender: TObject);
begin
  SaveDialog.InitialDir:= ExtractFilePath(Application.ExeName);
  if lvPasswd.Items.Count > 0 then
  begin
    SaveDialog.FileName:= 'paswlist_'+FormatDateTime('ddmmyy-hhnnss',Now())+'.txt';
    if SaveDialog.Execute then
      begin
        SavePaswList(SaveDialog.FileName);
      end;
  end;
end;

procedure TfrmMain.SavePaswList(fileName: string);
const Delimiter = '|';
var ff: TextFile;
    t: Integer;
begin
 AssignFile(ff, fileName);
 ReWrite(ff);
 try
  with lvPasswd do
  for t:=0 to Items.Count - 1 do
   WriteLn(ff,StringReplace(Items[t].Caption + Delimiter + Items.Item[t].SubItems.Text,#13#10,Delimiter,[rfReplaceAll]));
 finally
  CloseFile(ff);
 end;
end;

procedure TfrmMain.SendManualPassw(passw: string);
var
  SendByte: TByteList;
begin
  try
    SendByte := StrToByte('M'+passw+#13+#10);
    ComPort.Write(PChar(SendByte),Length(SendByte));
  except
    on e: Exception do
     begin
        AppendToLogExe('SendManualPassw: '+e.Message);
     end;
  end;
end;

procedure TfrmMain.Sendpasswd1Click(Sender: TObject);
begin
  btnBruteStop.Click;
  Sleep(1000);
  SendManualPassw(Copy(lvPasswd.ItemFocused.SubItems[1],2,StrLen(PChar(lvPasswd.ItemFocused.SubItems[1]))));
end;

procedure TfrmMain.SleepActive(Duration: integer);
var
  i: integer;
begin
  try
    if Duration <= 0 then
      Exit;
    for i := 0 to Round(Duration / 100) do
    begin
       Sleep(100);
       Application.ProcessMessages;
    end;
  except
    on e: Exception do
     begin
        AppendToLogExe('SleepActive: '+e.Message);
     end;
  end;
end;

procedure TfrmMain.StopBrute;
begin
  try

  except

  end;
end;

function TfrmMain.StrToByte(const Value: String): TByteList;
var
  i: integer;
begin
  SetLength(Result, Length(Value));
  for i:= 0 to Length(Value) - 1 do
  begin
    Result[i]:= Ord(Value[i+1]);
  end;
end;

end.
