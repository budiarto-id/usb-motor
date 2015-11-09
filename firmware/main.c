/*----------------------------------------------------
Program kendali motor DC, Motor Stepper, dan motor
Servo dilengkapi + GUI dengan komunikasi USB
----------------------------------------------------*/
#include <avr/io.h>
#include <avr/wdt.h>
#include <avr/interrupt.h>  /* for sei() */
#include <util/delay.h>     /* for _delay_ms() */
#include <avr/pgmspace.h>   /* required by usbdrv.h */
#include "usbdrv.h"
#include <math.h>

//Definisikan nilai bRequest agar mudah dibaca
#define DC_ARAH			 0
#define DC_SPEED 		 1
#define STEPPER_SPEED 	 2
#define STEPPER_EKSEKUSI 3
#define SERVO			 4

#define KIRI    0
#define STOP    1
#define KANAN   2

//Deklarasi global variable
int step[4] = {9,5,6,10};
//0111; 1011; 1101; 1110
uint16_t stepSpeed=100;
uint16_t loop, nilai;

void jeda(uint16_t value)
{
 uint16_t n;
 for(n=0;n<value;n++)
 {
  _delay_us(1);
   wdt_reset();
 }
}

//Setiap data yang masuk dari PC, eksekusi fungsi berikut
//Fungsi sesuai Allocation List
USB_PUBLIC uchar usbFunctionSetup(uchar data[8])
{
 /*----------------------------------------
 Data yang dikirim oleh PC disimpan dalam 
 variabel bRequest, wValue, dan wIndex yang 
 disimpan dalam tipe data usbRequest_t.
 ----------------------------------------*/
 usbRequest_t *rq = (void *)data;
 static uint16_t x;
 x = 0;
 PORTA = rq->bRequest;
  
 /*------------------------------------------------
 Jika nilai bRequest=0 (DC_ARAH), berarti perintah
 tersebut akan mengubah arah putaran motor DC.
 Arah putaran motor DC dikirimkan dalam wValue byte 0
 -------------------------------------------------*/
 if (rq->bRequest==DC_ARAH)
 {
  switch(rq->wValue.bytes[0])
  {
   /*------------------------------------------
   Jika isi wValue=0 (KIRI), perintahkan mikro
   untuk menjalankan motor DC putar kiri. PORTB.0=0,
   PORTB.2=1
   ------------------------------------------*/
   case KIRI:
	PORTD &= ~(1<<4);
	PORTD |= (1<<6);
	return 0;
   /*------------------------------------------
   Jika isi wValue=1 (STOP), perintahkan mikro
   untuk menghentikan putaran motor DC. PORTB.0=0,
   PORTB.2=0
   ------------------------------------------*/
   case STOP:
	PORTD &= ~(1<<4);
	PORTD &= ~(1<<6);
	return 0;
   /*------------------------------------------
   Jika isi wValue=2 (KANAN), perintahkan mikro
   untuk menjalankan motor DC putar kanan. PORTB.0=1,
   PORTB.2=0
   ------------------------------------------*/
   case KANAN:
	PORTD |= 1<<4;
	PORTD &= ~(1<<6);
	return 0;
  }
  return 0;
 }
 /*------------------------------------------------
 Jika nilai bRequest=1 (DC_SPEED), berarti perintah
 tersebut akan mengubah kecepatan putar motor DC.
 Nilai PWM untuk mengatur kecepatan putar motor DC 
 dikirimkan dalam wValue byte 0
 -------------------------------------------------*/
 if (rq->bRequest==DC_SPEED)
 {
  //Update nilai PWM (OCR1A) sesuai data pada wValue
  OCR1A = rq->wValue.bytes[0];
  return 0;
 }
 /*------------------------------------------------
 Jika nilai bRequest=2 (STEPPER_SPEED), berarti perintah
 tersebut akan mengubah kecepatan putar motor stepper.
 Masukkan wValue ke dalam variabel stepSpeed
 -------------------------------------------------*/
 if (rq->bRequest==STEPPER_SPEED)
 {
  stepSpeed = rq->wValue.word;
  return 0;
 }
 /*------------------------------------------------
 Jika nilai bRequest=3 (STEPPER_EKSEKUSI), berarti 
 perintah menjalankan motor stepper dengan step 
 sejumlah wValue
 -------------------------------------------------*/
 if (rq->bRequest==STEPPER_EKSEKUSI)
 {
  PORTC = 0x0F;
  while(x<rq->wValue.word)
  {
   if(rq->wIndex.bytes[0]==KANAN) PORTC = step[x%4];
   if(rq->wIndex.bytes[0]==KIRI)  PORTC = step[3-(x%4)];
   jeda(stepSpeed);
   //PORTC = 0x0F;
   wdt_reset();
   x++;
  }
  return 0;
 }
 /*------------------------------------------------
 Jika nilai bRequest=4 (SERVO), berarti perintah
 tersebut akan mengubah arah motor servo ke arah
 sudut sesuai isi wValue
 -------------------------------------------------*/
 if (rq->bRequest==SERVO)
 {  
   nilai = 700 + floor(rq->wValue.bytes[0] * 12.77777778f);
   for(loop = 0; loop < 30; loop++){   
    PORTA |= (1<<7);
    jeda(nilai);   
    PORTA &= ~(1<<7); 
    jeda(20000-nilai);
    wdt_reset();              
   } 
  return 0;
 }
 return 0;
}

//Program Utama
int __attribute__((noreturn)) main()
{
 uchar i;
 
 DDRA = 0xFF;
 PORTA = 0x00;
 DDRB = 0xFF;
 DDRC = 0xFF;
 PORTC = 0x0F;
 DDRD |= 0xF3;
 
 //Aktifkan Timer1
 //Prescaler 1
 //Mode fast PWM top 0xFF
 //OCR1A sebagai keluaran PWM
 TCCR1A=0x81;
 TCCR1B=0x0A;
 //Aktifkan watchdog timer
 wdt_enable(WDTO_1S);
 //Inisialisasi perangkat USB
 usbInit();
 usbDeviceDisconnect();
 for (i=0; i<250; i++)
 {
  wdt_reset();
  _delay_ms(2);
 }
 usbDeviceConnect();
 //Aktifkan mode interrupt
 sei();
 
 while(1)
 {
  //Reset watchdog timer
  wdt_reset();
  usbPoll();
 }
}