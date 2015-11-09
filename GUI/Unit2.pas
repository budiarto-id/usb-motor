unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, LibUSB, ComCtrls, AdvSmoothGauge, AdvSmoothRotaryMenu,
  AdvSmoothJogWheel, AdvAppStyler, AdvSmoothSlider, DBAdvSmoothSlider,
  AdvSmoothButton, AdvSmoothDock, AdvSmoothMenu, AdvSmoothTabPager,
  AdvSmoothLabel, AdvSmoothListBox, AdvSmoothComboBox, ExtCtrls;

type
  TForm2 = class(TForm)
    AdvSmoothButton1: TAdvSmoothButton;
    AdvSmoothTabPager1: TAdvSmoothTabPager;
    AdvSmoothTabPager11: TAdvSmoothTabPage;
    AdvSmoothTabPager12: TAdvSmoothTabPage;
    AdvSmoothGauge1: TAdvSmoothGauge;
    AdvSmoothLabel1: TAdvSmoothLabel;
    AdvSmoothLabel2: TAdvSmoothLabel;
    AdvSmoothButton2: TAdvSmoothButton;
    TrackBar1: TTrackBar;
    AdvSmoothLabel3: TAdvSmoothLabel;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    UpDown1: TUpDown;
    RadioGroup1: TRadioGroup;
    AdvSmoothButton3: TAdvSmoothButton;
    StatusBar1: TStatusBar;
    AdvSmoothTabPage1: TAdvSmoothTabPage;
    Edit2: TEdit;
    Button1: TButton;
    procedure Button3Click(Sender: TObject);
    procedure Buttonx1Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure AdvSmoothGauge1Change(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure AdvSmoothButton3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  USB_Motor: pusb_device;
  LED_Handle: pusb_dev_handle;
  buffer: array[0..100] of byte;
const
  _SET = 0;
  _SET_SPEED = 1;

implementation
        
uses wbemScripting_TLB, activex;
{$R *.dfm}
procedure TForm2.Button3Click(Sender: TObject);
var foundVendor,foundProduct:boolean;
    bus: pusb_bus;
    dev: pusb_device;
    ret: integer;
    S : array [0..255] of char;
    manufacturer,product:string;
begin
foundVendor:=false;
foundProduct:=false;
usb_init; // Initialize libusb
//form1.Caption:=usb_strerror;
if(usb_find_busses<1) then
  showmessage(usb_strerror);
if (usb_find_devices<1) then
  showmessage(usb_strerror); // Find all devices on all USB devices }
bus := usb_get_busses; // Return the list of USB busses found
if  bus=nil then showmessage(usb_strerror);
while Assigned(bus) do
begin
dev := bus^.devices;
while Assigned(dev) do
      begin
      if dev^.descriptor.idVendor=5824  then
        foundVendor:=true;
      if dev^.descriptor.idProduct=1503 then
        foundProduct:=true;
      if (foundVendor and foundProduct) then
      begin
         try
            USB_Motor:= usb_open(dev);
              if dev^.descriptor.iManufacturer > 0 then
                begin
                  ret := usb_get_string_simple(USB_Motor, dev^.descriptor.iManufacturer, S, sizeof(S));
                  if (ret > 0) then
                    begin
                      manufacturer := S;
                    end
                    else
                    begin
                      manufacturer := 'error';
                    end;
                end;

              if (dev^.descriptor.iProduct > 0) then
                begin
                  ret := usb_get_string_simple(USB_Motor, dev^.descriptor.iProduct, S, sizeof(S));
                  if (ret > 0) then
                    begin
                      product := S;
                    end
                    else
                    begin
                      product := 'error';
                    end;
                end;
         finally
            ShowMessage('Koneksi Sukses'+#10+#13+
                        'VID----------- : 0x16c0'+#10+#13+
                        'PID----------- : 0x05dc'+#10+#13+
                        'Manufacturer : '+manufacturer+#10+#13+
                        'Product------ : '+product+#10+#13+
                        'by semarme.com');  
            StatusBar1.Panels.Items[0].Text := 'Jalur USB terbuka';
         end;
         break;
      end else
      begin
        foundVendor:=false;
        foundProduct:=false;
      end;
      dev := dev^.next;
      end;
      if  (foundVendor and foundProduct) then break;
      bus := bus^.next;
 end;
//statusbar1.Panels[0].Text:=usb_strerror;
if not (foundVendor and foundProduct) then showmessage('USBStepper or USBMotorDC (VID=0x16C0  PID=0x05DC)'+chr(10)+chr(13)+'Not Found');

end;

procedure TForm2.Buttonx1Click(Sender: TObject);
begin            
  if (Assigned(USB_Motor)) then
  begin
  usb_control_msg(USB_Motor,USB_TYPE_VENDOR or USB_RECIP_DEVICE or USB_ENDPOINT_IN,_SET,UpDown1.Position,ComboBox1.ItemIndex,buffer,sizeof(buffer),5000);
  end
  else
  begin
    ShowMessage('Jalur USB masih tertutup. Klik tombol [Open USB Device] untuk membukanya.');
  end;
end;

procedure TForm2.TrackBar1Change(Sender: TObject);
begin
  if (Assigned(USB_Motor)) then
  begin
  usb_control_msg(USB_Motor,
                  USB_TYPE_VENDOR or USB_RECIP_DEVICE or USB_ENDPOINT_IN,
                  _SET_SPEED,
                  TrackBar1.Position,
                  1,buffer,
                  sizeof(buffer),
                  5000);
  end;
  AdvSmoothLabel3.Caption.Text := 'Kecepatan = '+FloatToStr(TrackBar1.Position/1000)+'ms/step';
end;

procedure TForm2.AdvSmoothGauge1Change(Sender: TObject);
var
  nilai : integer;
begin
  if (Assigned(USB_Motor)) then
  begin
    nilai := round(AdvSmoothGauge1.Value);
    usb_control_msg(USB_Motor,USB_TYPE_VENDOR or USB_RECIP_DEVICE or USB_ENDPOINT_IN,_SET_SPEED,nilai,1,buffer,sizeof(buffer),5000);
    end;
  end;

procedure TForm2.RadioGroup1Click(Sender: TObject);
begin
  if (Assigned(USB_Motor)) then
  begin
    usb_control_msg(USB_Motor,USB_TYPE_VENDOR or USB_RECIP_DEVICE or USB_ENDPOINT_IN,_SET,RadioGroup1.ItemIndex,1,buffer,sizeof(buffer),5000);
  end;
end;

procedure TForm2.AdvSmoothButton3Click(Sender: TObject);
begin
  if (Assigned(USB_Motor)) then
  begin
    usb_close(USB_Motor);
    StatusBar1.Panels.Items[0].Text := 'Jalur USB tertutup';
  end;
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
  if (Assigned(USB_Motor)) then
  begin
    usb_control_msg(USB_Motor,
                    USB_TYPE_VENDOR or USB_RECIP_DEVICE or USB_ENDPOINT_IN,
                    4,
                    strtoint(edit2.text),
                    1,
                    buffer,
                    sizeof(buffer),
                    5000
    );
  end;
end;

end.
