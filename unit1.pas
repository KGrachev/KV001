unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynHighlighterVB, Forms,
  Controls, Graphics, Dialogs, StdCtrls, Menus, ActnList, ComCtrls, ExtCtrls,
  synaser, Math, IniFiles;

type

  { TForm1 }

  TForm1 = class(TForm)
    Edit1: TEdit;
    FlowControlComboBox: TComboBox;
    GroupBox2: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    TimeLabel: TLabel;
    ParityComboBox: TComboBox;
    Label3: TLabel;
    BaudRateComboBox: TComboBox;
 //   SdpoSerial1: TSdpoSerial;
    StatusBar1: TStatusBar;
    StopBitsComboBox: TComboBox;
    PortNumComboBox: TComboBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    DataBitsComboBox: TComboBox;
    RS485PortComboBox: TComboBox;
    Timer1: TTimer;
    Timer2: TTimer;
    procedure Edit1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Label3Click(Sender: TObject);
    procedure PortNumComboBoxChange(Sender: TObject);
    procedure TimeLabelClick(Sender: TObject);
//    procedure SdpoSerial1RxData(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);

  private
    { private declarations }
    IniFile: Tinifile;
    ser: synaser.TBlockSerial;
    buf_in: array of byte;
    buf_out: array of byte;
    s_out,s_last:string;
    comm_error:byte;                               //ошибки обмена, были если <>0
    FileOut:TextFile;                              // в файл записываются все полученные через порт данные
    FileOutVD:TextFile;                             // в файл записываются не повторяющиеся строки, каждые сутки формируется новый файл
    CurDate:TDateTime;
    function NumToFloat(dwNum: DWORD): String;  // перевод в строку float
    function CRC16(bdar,edar:byte;dar:array of byte):word; // Расчет CRC 16
    Procedure WriteIni;                        // запись информации в файл о настройках
    Procedure ReadIni;                         // чтение информации из файла о настройках
    //num_port:byte;  // номер устройства на шине RS-485
  public
    { public declarations }

  end;

var
  Form1: TForm1;


implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.WriteIni;
begin
  IniFile:=tinifile.create(ApplicationName+'.ini');
  Inifile.WriteString('Value','PortNum',PortNumComboBox.Text);
  Inifile.WriteString('Value','DataBits',DataBitsComboBox.Text);
  Inifile.WriteString('Value','Parity',ParityComboBox.Text);
  Inifile.WriteString('Value','StopBits',StopBitsComboBox.Text);
  Inifile.WriteString('Value','BaudRate',BaudRateComboBox.Text);
  Inifile.WriteString('Value','FlowControl',FlowControlComboBox.Text);
  Inifile.WriteString('Value','RS485Port',RS485PortComboBox.Text);
  Inifile.WriteString('Value','Period',Edit1.Text);
  Inifile.Free;
end;

Procedure Tform1.ReadIni;
begin
  IniFile:=tinifile.create(ApplicationName+'.ini');
  PortNumComboBox.Text:=IniFile.ReadString('Value','PortNum',PortNumComboBox.Items[PortNumComboBox.ItemIndex]);
  DataBitsComboBox.Text:=IniFile.ReadString('Value','DataBits',DataBitsComboBox.Items[DataBitsComboBox.ItemIndex]);
  ParityComboBox.Text:=IniFile.ReadString('Value','Parity',ParityComboBox.Items[ParityComboBox.ItemIndex]);
  StopBitsComboBox.Text:=IniFile.ReadString('Value','StopBits',StopBitsComboBox.Items[StopBitsComboBox.ItemIndex]);
  BaudRateComboBox.Text:=IniFile.ReadString('Value','BaudRate',BaudRateComboBox.Items[BaudRateComboBox.ItemIndex]);
  FlowControlComboBox.Text:=IniFile.ReadString('Value','FlowControl',FlowControlComboBox.Items[FlowControlComboBox.ItemIndex]);
  RS485PortComboBox.Text:=IniFile.ReadString('Value','RS485Port',RS485PortComboBox.Items[RS485PortComboBox.ItemIndex]);
  Edit1.Text:=IniFile.ReadString('Value','Period','10');
  Inifile.Free;
end;

procedure TForm1.Label3Click(Sender: TObject);
begin

end;

procedure TForm1.PortNumComboBoxChange(Sender: TObject);
begin
 // if ser<> nil then
  ser.Destroy;
  ser:=TblockSerial.Create;
  ser.Connect(PortNumComboBox.Text);
  ser.Config(strtoint(BaudRateComboBox.Text), strtoint(DataBitsComboBox.Text) , 'N', SB1, false, false);
  if ser.LastError <> 0 then
  begin
    ser.tag:=1;
    StatusBar1.Panels[1].Text:=PortNumComboBox.Text+' порт не доступен, измените настройки';

//    Dialogs.ShowMessage('не получилось поднять порт ' + PortNumComboBox.Text);
    exit;
  end
  else begin
   ser.Tag:=0;
//   Dialogs.ShowMessage('получилось поднять порт ' + PortNumComboBox.Text)
  end
end;

procedure TForm1.TimeLabelClick(Sender: TObject);
begin

end;

{procedure TForm1.SdpoSerial1RxData(Sender: TObject);
var s,s1:string;
  buf:array of byte;
  i:integer;




begin
  s:= sdposerial1.ReadData;
  setlength (buf, length(s));
  setlength (buf_in, length(s));
 for i:=0 to length(s) do begin
    s1:=s1+inttohex(ord(s[i]),1);
    buf[i]:=ord(s[i]);
    buf_in[i]:=ord(s[i]);
 end;
    memo1.Lines.Add(s1+' length-1----'+ inttostr(length(buf_in)));
end;}

function Tform1.CRC16(bdar,edar:byte;dar:array of byte):word;
var
  i,j : byte;
  bCRC : word;
begin
bCRC:=$FFFF;
for i:= bdar to edar do
  begin
   bCRC:=bCRC xor dar[i];
   for j:=1 to 8 do
     begin
     if bCRC mod 2 > 0 then begin
     bCRC:=bCRC shr 1;
     bCRC:=bCRC xor $A001;
     end else bCRC:=bCRC shr 1;
     end;
  end;
CRC16:=bCRC;
end;

function TForm1.NumToFloat(dwNum: DWORD): String;
const
  EXP_BIAS = 127;
var
  sFloat: String;
  dwFloat: Cardinal;
  snglFloat: Single; // 4 байта
  bySign, byExp: Byte;
  dwFractPart: Cardinal;
  snglFractPart: Single;
begin
  dwFloat:= dwNum;
  bySign:= (dwFloat shr 31) and $1;
  byExp:= Byte((dwFloat shr 23) and $FF);
  if byExp = $FF then
  begin
    // ShowMessage('Infinity or Nan');
    Result:= 'Infinity or Nan';
  end
  else
  if byExp = $00 then
  begin
    // ShowMessage('0 (Zero) or Denormal');
    Result:= '0 (Zero) or Denormal';
  end
  else
  begin
    dwFractPart:= Cardinal( (  Cardinal(dwFloat shl 9) shr 9  ) );
    // 0       131          5189916

    // 10 бит точность - тысячные доли - итоговая точность сотые доли
    snglFractPart:= 1.0 +
      ((dwFractPart shr 22) and $1) * 0.5 +
      ((dwFractPart shr 21) and $1) * 0.25 +
      ((dwFractPart shr 20) and $1) * 0.125 +
      ((dwFractPart shr 19) and $1) * 0.0625 +
      ((dwFractPart shr 18) and $1) * 0.03125 +
      ((dwFractPart shr 17) and $1) * 0.015625 +
      ((dwFractPart shr 16) and $1) * 0.0078125 +
      ((dwFractPart shr 15) and $1) * 0.00390625 +
      ((dwFractPart shr 14) and $1) * 0.001953125 +
      ((dwFractPart shr 13) and $1) * 0.0009765625 +
      // Максимальная точность
      ((dwFractPart shr 12) and $1) * 0.00048828125 +
      ((dwFractPart shr 11) and $1) * 0.000244140625 +
      ((dwFractPart shr 10) and $1) * 0.0001220703125 +
      ((dwFractPart shr 9) and  $1) * 0.00006103515625 +
      ((dwFractPart shr 8) and  $1) * 0.000030517578125 +
      ((dwFractPart shr 7) and  $1) * 0.0000152587890625 +
      ((dwFractPart shr 6) and  $1) * 0.00000762939453125 +
      ((dwFractPart shr 5) and  $1) * 0.000003814697265625 +
      ((dwFractPart shr 4) and  $1) * 0.0000019073486328125 +
      ((dwFractPart shr 3) and  $1) * 0.00000095367431640625 +
      ((dwFractPart shr 2) and  $1) * 0.000000476837158203125 +
      ((dwFractPart shr 1) and  $1) * 0.0000002384185791015625 +
      ( dwFractPart        and  $1) * 0.00000011920928955078125;

    snglFloat:= Power(-1, bySign) * Power(2.0, (byExp - EXP_BIAS)) * snglFractPart;
    sFloat:= FloatToStrF(snglFloat,ffFixed,5,2);
    // ShowMessage(sFloat);
  end;
  Result:= sFloat;
end;



procedure TForm1.Timer1Timer(Sender: TObject);
// считываем три счетчика
// 1. значение веса в счетчике отвесов, начальный адрес 125($7D), возвращает 4 байта тип float
// 2. значение кол-ва отвесов, начальный адрес 127 ($7F), возвращает 2 байта тип longint
// 3. значение веса в последнем отвесе, начальный адрес 128 (80$)

var
  i:integer;
  s,s_out1:string;
  AllVes1:Cardinal;
  CRCw,kol_otves: Word;
  //buf:array [1..8] of byte;
begin
// считываем общий вес в счетчике отвесов начальный адрес 125($7D), возвращает 4 байта тип float
//  s:=ser.GetSerialPortNames;
s_out:='';
comm_error:=0;                    // ошибки обмена;
if ser.Tag=0 then begin           // порт доступен
    setlength (buf_out,8);
    buf_out[0]:= StrToInt(RS485PortComboBox.items[RS485PortComboBox.ItemIndex]);
    buf_out[1]:= $03;
    buf_out[2]:= $00;
    buf_out[3]:= $7D;
    buf_out[4]:= $00;
    buf_out[5]:= $02;
    CRCw:=CRC16(0,5,buf_out);
    buf_out[6]:=Lo(CRCw);             //buf_out[6]:= $54;  //CRC
    buf_out[7]:=Lo(CRCw shr 8);       //buf_out[7]:= $13;  //CRC

    for i:=0 to length(buf_out)-1 do ser.SendByte(buf_out[i]);  // отправляем данные в порт
    sleep(100);                                                 // ждем ответа
    if ser.WaitingData>8 then begin                             // контроллер прислал данные не менее 8 байт
        setlength(buf_in,ser.WaitingData);
        for i:=0 to ser.WaitingData-1 do buf_in[i]:=ser.RecvByte(0); // принимаем данные
        //                      http://www.owen.ru/forum/showthread.php?t=10555&page=467
         AllVes1:= (byte(buf_in[6]) shl 24) + (byte(buf_in[5]) shl 16) + (byte(buf_in[4]) shl 8) + (byte(buf_in[3]));
         CRCw:=CRC16(0,length(buf_in)-3,buf_in);
         If (Lo(CRCw) <> buf_in[length(buf_in)-2]) or (Lo(CRCw shr 8)<>buf_in[length(buf_in)-1]) then  begin
          //Dialogs.ShowMessage('не сошлось CRC при приеме');
          s_out:=s_out+ 'не сошлось CRC при приеме общего веса;';
          inc(comm_error);
         end
         else begin
          for i:=0 to length(buf_in)-1 do begin
            s:=s+'['+inttohex(buf_in[i],2)+']';
          end;
          s_out:=s_out+numtofloat(AllVes1)+';';                   // прием нормальный
//          memo1.Lines.Add(numtofloat(AllVes1)+'!!!!'+s);
         end
     end
     else begin                                             // контроллер данные не прислал
         inc(comm_error);
         s_out:=s_out+ ';нет данных с общим весом';
     end;

  //  считываем значение кол-ва отвесов, начальный адрес 127 ($7F), возвращает 2 байта тип longint
     s:='';
     setlength (buf_out,8);
     buf_out[0]:= StrToInt(RS485PortComboBox.items[RS485PortComboBox.ItemIndex]);
     buf_out[1]:= $03;
     buf_out[2]:= $00;
     buf_out[3]:= $7F;
     buf_out[4]:= $00;
     buf_out[5]:= $01;
     CRCw:=CRC16(0,5,buf_out);
     buf_out[6]:=Lo(CRCw);             //buf_out[6]:= $B5;  //CRC
     buf_out[7]:=Lo(CRCw shr 8);       //buf_out[7]:= $D2;  //CRC

     for i:=0 to length(buf_out)-1 do ser.SendByte(buf_out[i]);  // отправляем данные в порт
     sleep(100);                                                   // ждем ответа
     if ser.WaitingData>6 then begin                               // контроллер прислал данные
         setlength(buf_in,ser.WaitingData);
         for i:=0 to ser.WaitingData-1 do buf_in[i]:=ser.RecvByte(0); // принимаем данные
         CRCw:=CRC16(0,length(buf_in)-3,buf_in);
         If (Lo(CRCw) <> buf_in[length(buf_in)-2]) or (Lo(CRCw shr 8)<>buf_in[length(buf_in)-1]) then begin
//          Dialogs.ShowMessage('не сошлось CRC при приеме');
          s_out:=s_out+ 'не сошлось CRC при приеме количества отвесов;';
          inc(comm_error);
         end
         else begin      // СRC сошлось
           kol_otves:=buf_in[3]+(byte(buf_in[4]) shl 8);
           s_out:=s_out+inttostr(kol_otves)+';';
           for i:=0 to length(buf_in)-1 do begin
            s:=s+'['+inttohex(buf_in[i],2)+']';
           end;
//           memo1.Lines.Add(inttostr(kol_otves)+'!!!!'+s);
         end
     end
     else begin                                                     // контроллер не прислал данные
         inc(comm_error);
         s_out:=s_out+ ';нет данных с кол-вом отвесов';
     end;





     // считываем последний вес начальный адрес 128($80), возвращает 4 байта тип float
     // пока считываем  с адреса $81 т.к есть рассхождения в документации
       s:='';
       setlength (buf_out,8);
       buf_out[0]:= StrToInt(RS485PortComboBox.items[RS485PortComboBox.ItemIndex]);
       buf_out[1]:= $03;
       buf_out[2]:= $00;
       buf_out[3]:= $81;
       buf_out[4]:= $00;
       buf_out[5]:= $02;
       CRCw:=CRC16(0,5,buf_out);
       buf_out[6]:=Lo(CRCw);             //buf_out[6]:= $C5;  //CRC
       buf_out[7]:=Lo(CRCw shr 8);       //buf_out[7]:= $E3;  //CRC

       for i:=0 to length(buf_out)-1 do ser.SendByte(buf_out[i]);  // отправляем данные в порт
       sleep(100);                                                 // ждем ответа
       if ser.WaitingData>8 then begin                             // контроллер прислал данные не менее 8 байт
           setlength(buf_in,ser.WaitingData);
           for i:=0 to ser.WaitingData-1 do buf_in[i]:=ser.RecvByte(0); // принимаем данные
           //                      http://www.owen.ru/forum/showthread.php?t=10555&page=467
            AllVes1:= (byte(buf_in[6]) shl 24) + (byte(buf_in[5]) shl 16) + (byte(buf_in[4]) shl 8) + (byte(buf_in[3]));
            CRCw:=CRC16(0,length(buf_in)-3,buf_in);
            If (Lo(CRCw) <> buf_in[length(buf_in)-2]) or (Lo(CRCw shr 8)<>buf_in[length(buf_in)-1]) then begin
//             Dialogs.ShowMessage('не сошлось CRC при приеме');
             s_out:=s_out+ 'не сошлось CRC при приеме последнего веса;';
             inc(comm_error);
            end
            else begin                                            //CRC сошлось
            s_out:=s_out+numtofloat(AllVes1)+';';
            for i:=0 to length(buf_in)-1 do begin
               s:=s+'['+inttohex(buf_in[i],2)+']';
            end;
//            memo1.Lines.Add(numtofloat(AllVes1)+'!!!!'+s);
            end;
       end
       else begin                                                 // контроллер данные не прислал
          inc(comm_error);
          s_out:=s_out+ ';нет данных с последним весом';
       end;

// проверяем были ли ошибки обмена и записываем данные в файл
       s_out1:=s_out;
       StatusBar1.Panels[1].Text:='';
       if comm_error>0 then begin                        // были ошибки обмена
          s_out:='#'+FormatDateTime('DD/MM/YYYY hh:nn',Now)+';'+s_out;
          StatusBar1.Panels[1].Text:=s_out;
       end
       else begin                                        // не было ошибок обмена
          s_out:=FormatDateTime('DD/MM/YYYY hh:nn',Now)+';'+s_out;
          StatusBar1.Panels[1].Text:=s_out;
       end;
       Writeln(FileOut,s_out);
       Flush(FileOut);
       If s_last<>s_out1 then begin          // текущая и предыдущая строки не совпадают
          Writeln(FileOutVD,s_out);
          Flush(FileOutVD);
       end;
       s_last:=s_out1;

 end
 else begin                                       // порт не доступен
    StatusBar1.Panels[1].Text:=PortNumComboBox.Text+' порт не доступен, измените настройки';
 end;
 TimeLabel.Caption:=inttostr(timer1.Interval div 1000);
 timelabel.Tag:=timer1.Interval div 1000;

end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
//  TimeLabel.Text=inttostr(timer1.Interval/1000);
  Timelabel.Tag:=Timelabel.Tag-1;
  TimeLabel.Caption:=inttostr(Timelabel.Tag);
  if Date > CurDate then begin             // произошла смена даты открываем новый файл
    CurDate:=Date;
    Closefile(FileOutVD);
    AssignFile(FileOutVD,GetCurrentDir+'\log\'+FormatDateTime('DDMMYYYY',Now)+'.log');
    Rewrite(FileOutVD);
    writeln(FileOutVD,'# Программа работает с контроллером КВ-001, версия 1.091');
    writeln(FileOutVD,'# С периодичностью заданной в программе (по умолчанию 10 секунд) опрашиваются регистры');
    writeln(FileOutVD,'#  1. значение веса в счетчике отвесов, начальный адрес 125($7D), возвращает 4 байта тип float');
    writeln(FileOutVD,'#  2. значение кол-ва отвесов, начальный адрес 127 ($7F), возвращает 2 байта тип longint');
    writeln(FileOutVD,'#  3. значение веса в последнем отвесе, начальный адрес 128 (80э$)? озвращает 4 байта тип float');
    writeln(FileOutVD,'# (пока считываем  с адреса $81  т.к есть рассхождения в документации, выясненно путем');
    writeln(FileOutVD,'# мониторинга COM порта при работающей программе Удаленный терминал КВ-001 (поставляемая с контроллером))');
    writeln(FileOutVD,'# Результаты записываются в этот файл, если данные не повторятся. Разделитель между считанными значениями ";"');
    writeln(FileOutVD,'# Если в результате обмена с портом(контроллером) обнаруживаются ошибки, то строка записывемая в файл начинается с "#"');
    writeln(FileOutVD,'#');
    writeln(FileOutVD,'# Настройки программы после выхода cохраняются в ini файл.');
    writeln(FileOutVD,'#');
    writeln(FileOutVD,'#');
    s_last:='#';
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  CurDate:=Date;
  ser:=TblockSerial.Create;
  ReadIni;
  TimeLabel.Caption:=inttostr(timer1.Interval div 1000);
  timelabel.Tag:=timer1.Interval div 1000;
  if FileExists(ApplicationName+'.log') then begin
//     FileOut:=FileOpen(ApplicationName+'.log',fmOpenWrite or fmShareDenyWrite);
       AssignFile(FileOut,ApplicationName+'.log');
       Append(FileOut);
  end
  else begin
       AssignFile(FileOut,ApplicationName+'.log');
       Rewrite(FileOut);
       writeln(FileOut,'# Программа работает с контроллером КВ-001, версия 1.091');
       writeln(FileOut,'# С периодичностью заданной в программе (по умолчанию 10 секунд) опрашиваются регистры');
       writeln(FileOut,'#  1. значение веса в счетчике отвесов, начальный адрес 125($7D), возвращает 4 байта тип float');
       writeln(FileOut,'#  2. значение кол-ва отвесов, начальный адрес 127 ($7F), возвращает 2 байта тип longint');
       writeln(FileOut,'#  3. значение веса в последнем отвесе, начальный адрес 128 (80э$)? озвращает 4 байта тип float');
       writeln(FileOut,'# (пока считываем  с адреса $81  т.к есть рассхождения в документации, выясненно путем');
       writeln(FileOut,'# мониторинга COM порта при работающей программе Удаленный терминал КВ-001 (поставляемая с контроллером))');
       writeln(FileOut,'# Результаты записываются в этот файл. Разделитель между считанными значениями ";"');
       writeln(FileOut,'# Если в результате обмена с портом(контроллером) обнаруживаются ошибки, то строка записывемая в файл начинается с "#"');
       writeln(FileOut,'#');
       writeln(FileOut,'# Настройки программы после выхода cохраняются в ini файл.');
       writeln(FileOut,'#');
       writeln(FileOut,'#');

//     FileOut:=FileCreate(ApplicationName+'.log',fmOpenWrite,fmShareDenyWrite);
  end;
  CreateDir(GetCurrentDir+'\log');               //создаем каталог и файл для записи не дублированных данных
  if FileExists(GetCurrentDir+'\log\'+FormatDateTime('DDMMYYYY',Now)+'.log') then begin
//     FileOut:=FileOpen(ApplicationName+'.log',fmOpenWrite or fmShareDenyWrite);
       AssignFile(FileOutVD,GetCurrentDir+'\log\'+FormatDateTime('DDMMYYYY',Now)+'.log');

       Reset(FileOutVD);
       While not(eof(FileOutVD)) do readln(FileOutVD,s_last);
       Closefile(FileOutVD);
       Append(FileOutVD);
       if pos(';',s_last)>0 then Delete(s_last,1,pos(';',s_last));    // удаляем первое поле (в нем дата и время) в s_last
  end
  else begin
       AssignFile(FileOutVD,GetCurrentDir+'\log\'+FormatDateTime('DDMMYYYY',Now)+'.log');
       Rewrite(FileOutVD);
       writeln(FileOutVD,'# Программа работает с контроллером КВ-001, версия 1.091');
       writeln(FileOutVD,'# С периодичностью заданной в программе (по умолчанию 10 секунд) опрашиваются регистры');
       writeln(FileOutVD,'#  1. значение веса в счетчике отвесов, начальный адрес 125($7D), возвращает 4 байта тип float');
       writeln(FileOutVD,'#  2. значение кол-ва отвесов, начальный адрес 127 ($7F), возвращает 2 байта тип longint');
       writeln(FileOutVD,'#  3. значение веса в последнем отвесе, начальный адрес 128 (80э$)? озвращает 4 байта тип float');
       writeln(FileOutVD,'# (пока считываем  с адреса $81  т.к есть рассхождения в документации, выясненно путем');
       writeln(FileOutVD,'# мониторинга COM порта при работающей программе Удаленный терминал КВ-001 (поставляемая с контроллером))');
       writeln(FileOutVD,'# Результаты записываются в этот файл, если данные не повторятся. Разделитель между считанными значениями ";"');
       writeln(FileOutVD,'# Если в результате обмена с портом(контроллером) обнаруживаются ошибки, то строка записывемая в файл начинается с "#"');
       writeln(FileOutVD,'#');
       writeln(FileOutVD,'# Настройки программы после выхода cохраняются в ini файл.');
       writeln(FileOutVD,'#');
       writeln(FileOutVD,'#');
       s_last:='#';
end;


//  Dialogs.ShowMessage(ApplicationName);
  ser.Connect(PortNumComboBox.Text);
  ser.Config(strtoint(BaudRateComboBox.Text), strtoint(DataBitsComboBox.Text) , 'N', SB1, false, false);
  if ser.LastError <> 0 then
  begin
    ser.Tag:=1;
    StatusBar1.Panels[1].Text:=PortNumComboBox.Text+' порт не доступен, измените настройки';
//    Dialogs.ShowMessage('не получилось поднять порт ' + PortNumComboBox.Text);
    exit;
  end
  else ser.Tag:=0;

end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseFile(FileOut);
  CloseFile(FileOutVD);
  WriteIni;
end;

procedure TForm1.Edit1Change(Sender: TObject);
var  i: integer;
begin
  // меняется период опроса
  i:=strtointdef(Edit1.Text,-1);
  if i<=0 then begin
     Timer1.Interval:=10000;
     Edit1.text:='10';
  end
  else begin
     Timer1.Interval:=i* 1000;
     TimeLabel.Caption:=inttostr(timer1.Interval div 1000);
     Timelabel.Tag:=timer1.Interval div 1000;
  end
end;



end.

