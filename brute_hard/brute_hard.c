/*
 * brute_hard.c
 *
 * Created: 08.03.2015 18:02:58
 *  Author: Alexey
 */ 


#include <avr/io.h>
#include <avr/iom16.h>
#include <avr/cpufunc.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#define F_CPU 8000000UL

/* 9600 baud UART*/
#define UART_BAUD_RATE		(9600)
#include <util/delay.h>
#include <stdlib.h>
#include <stdio.h>

#include "uart.h"

#define ENC_DELAY				110
#define ENC_END_DELAY			190

//пин "MENU"
#define MENU_BIT				(PA0)
#define MENU_PIN				(PINA)
#define MENU_DDR				(DDRA)
#define MENU_PORT				(PORTA)
#define MENU_DOWN				(MENU_PORT&=~(1<<MENU_BIT))
#define MENU_UP					(MENU_PORT|=(1<<MENU_BIT))
#define MENU_IS_BIT_DOWN		(!(MENU_PIN & _BV(MENU_BIT)))

//пин "F"
#define F_BIT				(PA3)
#define F_PIN				(PINA)
#define F_DDR				(DDRA)
#define F_PORT				(PORTA)
#define F_DOWN				(F_PORT&=~(1<<F_BIT))
#define F_UP				(F_PORT|=(1<<F_BIT))
#define F_IS_BIT_DOWN		(!(F_PIN & _BV(F_BIT)))

//LCD PINS
//пин DATA
#define DATA_BIT			(PB0)
#define DATA_PIN			(PINB)
#define DATA_DDR			(DDRB)
#define DATA_PORT			(PORTB)
#define DATA_DOWN			(DATA_PORT&=~(1<<DATA_BIT))
#define DATA_UP				(DATA_PORT|=(1<<DATA_BIT))
#define DATA_IS_BIT_DOWN	(!(DATA_PIN & _BV(DATA_BIT)))

//INT0
//пин CS
#define CS_BIT				(PD2)
#define CS_PIN				(PIND)
#define CS_DDR				(DDRD)
#define CS_PORT				(PORTD)
#define CS_DOWN				(CS_PORT&=~(1<<CS_BIT))
#define CS_UP				(CS_PORT|=(1<<CS_BIT))
#define CS_IS_BIT_DOWN		(!(CS_PIN & _BV(CS_BIT)))

//INT1
//пин WR
#define WR_BIT				(PD3)
#define WR_PIN				(PIND)
#define WR_DDR				(DDRD)
#define WR_PORT				(PORTD)
#define WR_DOWN				(WR_PORT&=~(1<<WR_BIT))
#define WR_UP				(WR_PORT|=(1<<WR_BIT))
#define WR_IS_BIT_DOWN		(!(WR_PIN & _BV(WR_BIT)))

//#define nop() {asm("nop");}

//const uint32_t  pow6Table32[]=
//{
	//100000ul,
	//10000ul,
	//1000ul,
	//100ul,
	//10ul,
	//1ul
//};

//текущий буффер строки
char curr_lcd_set[15]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
//строка "SET"		    FA   F0   FF  FF   FF   FF   FF   DF   F7   B7   8F   B5   E7   FF   FF
const char compare_set[15] PROGMEM = {0xFA,0xF0,0xFF,0xFF,0xFF,0xFF,0xFF,0xDF,0xF7,0xB7,0x8F,0xB5,0xE7,0xFF,0xFF};
//текущий пароль
char curr_pass_set[6]={0x30,0x30,0x30,0x30,0x30,0x30};
	
//счетчик пароля
uint32_t currPasswd=999999ul;

volatile uint16_t curr_time_msec = 0;
char isBrute=0;
char isCouDown=1;
char buf_in_uart[7];

volatile uint8_t isWaitCS = 0; //флаг ожидания CS
volatile uint8_t isCSDown = 0; //флаг состояния CS
volatile uint8_t currByte = 0; //текущий байт LCD
volatile uint8_t currCouBit = 0; //текущий бит LCD
volatile uint8_t currCou = 0; //счетчик байт LCD
volatile uint8_t viewUART = 0;

//char *utoa_cycle_sub(uint32_t value, char *buffer)
//{
	//if(value == 0)
	//{
		//buffer[0] = '0';
		//buffer[1] = 0;
		//return buffer;
	//}
	//char *ptr = buffer;
	//uint8_t i = 0;
	//do
	//{
		//uint32_t pow6 = pow6Table32[i++];
		//uint8_t count = 0;
		//while(value >= pow6)
		//{
			//count ++;
			//value -= pow6;
		//}
		//*ptr++ = count + '0';
	//}while(i < 6);
	//*ptr = 0;
	//while(buffer[0] == '0') ++buffer;
	//return buffer;
//}

void init(void){//инициализация портов
	DDRA |= (1<<DDA0)|(1<<DDA1)|(1<<DDA2)|(1<<DDA3)|(1<<DDA4)|(1<<DDA5)|(1<<DDA6)|(1<<DDA7);
	PORTA |= (0<<PA0)|(1<<PA1)|(0<<PA2)|(0<<PA3)|(0<<PA4)|(0<<PA5)|(0<<PA6)|(0<<PA7);	
	
	DDRB |= (0<<DDB0)|(1<<DDB1)|(0<<DDB2)|(1<<DDB3)|(1<<DDB4)|(1<<DDB5)|(1<<DDB6)|(1<<DDB7);
	PORTB |= (1<<PB0)|(1<<PB1)|(1<<PB2)|(0<<PB3)|(0<<PB4)|(0<<PB5)|(0<<PB6)|(0<<PB7);
	
	DDRC = 255;
	PORTC = 0;
	
	DDRD |= (1<<DDD0)|(1<<DDD1)|(0<<DDD2)|(0<<DDD3)|(1<<DDD4)|(1<<DDD5)|(1<<DDD6)|(1<<DDD7);
	PORTD |= (0<<PD0)|(1<<PD1)|(1<<PD2)|(1<<PD3)|(0<<PD4)|(0<<PD5)|(0<<PD6)|(0<<PD7);
	
	uart_init( UART_BAUD_SELECT(UART_BAUD_RATE,F_CPU) );	
}

void Timer0_Init(void)
{
	// Timer0 settings: ~ 8000 ticks (1000 us / 1 ms / 0,001 sec)
	TCCR0 = (1<<CS01) | (1<<CS00); // CLK/64
	TIMSK |= (1 << TOIE0); // Timer/Counter0 Overflow Interrupt Enable
	TCNT0 = 131;
}

ISR(TIMER0_OVF_vect) // Timer/Counter0 Overflow
{
	TCNT0 = 131;
	if (curr_time_msec < 999){
		curr_time_msec++;
	}else{
		curr_time_msec=0;
		if (viewUART == 0)
			viewUART=1;
	}	
}

void init_int_on(void){ //инициализация прерываний
	//cli();
	isWaitCS=0;	
	MCUCR |= (1<<ISC11)|(1<<ISC10)|(1<<ISC01)|(0<<ISC00); //INT1 INT0
	//GICR |= (1<<INT1)|(1<<INT0); //разрешаем прерывания	INT1 INT0
}

void enable_int(void){
	GICR |= (1<<INT1)|(1<<INT0); //разрешаем прерывания	INT1 INT0
}

void disable_int(void){
	GICR |= (0<<INT1)|(0<<INT0); //разрешаем прерывания	INT1 INT0
}

ISR(INT0_vect)//обработка прерываний INT0 (CS)
{
	cli();
	if (isWaitCS == 1){ //ожидаем CS
		isCSDown = CS_IS_BIT_DOWN;		
	}
	GIFR |=(0<<INTF0);
	sei();	
}


ISR(INT1_vect)//обработка прерываний INT2 (WR)
{
	cli();
	if ((isCSDown == 1 )&&(isWaitCS == 1)){ //CS прижата и мы ее ждем
			if (currCouBit <= 7 ){
				curr_lcd_set[currCou]|=(DATA_IS_BIT_DOWN<<currCouBit);
				currCouBit++;				
			}else{
				if (currCouBit == 8 ){
					currCouBit=0;
					currCou++;
				}				
			}
			if (currCou > 14){
				currCou=0;
				isWaitCS=0;
				isCSDown=0;
			}					
	}
	GIFR |=(0<<INTF1);
	sei();
}

void encoder_up(void){ //эмулятор энкодера
	
	PORTA|=(1<<PA1);
	_delay_ms(6);
	PORTA|=(1<<PA2);	
	_delay_ms(6);
			
	PORTA&=~(1<<PA1);
	_delay_ms(6);
	PORTA&=~(1<<PA2);
	_delay_ms(6);
	PORTA|=(1<<PA1);	
}

void encoder_down(void){ //эмулятор энкодера
	
	PORTA|=(1<<PA2);
	_delay_ms(6);
	PORTA|=(1<<PA1);
	_delay_ms(6);
	
	PORTA&=~(1<<PA2);
	_delay_ms(6);
	PORTA&=~(1<<PA1);
	_delay_ms(6);
	PORTA|=(1<<PA2);
}

void press_menu(uint8_t cs){ //нажимаем кнопку "MENU"
	if ((isWaitCS == 1)&&(cs == 0)){ //если ждем CS и пин CS высокий
		disable_int();
		isWaitCS=0;
	}	
	MENU_UP;
	if (cs == 1){
		enable_int();
		isWaitCS=1;
	}
	_delay_ms(100);
	MENU_DOWN;
}

void press_f(void){ //нажимаем кнопку "F"
	PORTA |=(1<<PA3);
	_delay_ms(100);
	PORTA &=~(1<<PA3);
}

uint8_t compare_buff(void){ //сравниваем буффер с "эталоном"
	uint8_t res=1;
	disable_int();
	for(uint8_t i=0; i<15; i++){
		if (pgm_read_byte(&compare_set[i]) != curr_lcd_set[i]){
			res=0;
		}
	}		
	return res;
}

void increm(void){ //заносим счетчик в значения буффера для пароля
	//utoa_cycle_sub(currPasswd, curr_pass_set);	
	ultoa(currPasswd, curr_pass_set, 10);
}


void encod_num_up(uint8_t e_num){ //установка цифры
		
	switch(e_num)
	{
		case 0:		
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();			
			_delay_ms(ENC_END_DELAY);			
		break;		
		case 1:
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_END_DELAY);
		break;
		case 2:
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_END_DELAY);			
		break;
		case 3:
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();			
			_delay_ms(ENC_END_DELAY);
		break;
		case 4:
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();			
			_delay_ms(ENC_END_DELAY);
		break;
		case 5:
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();			
			_delay_ms(ENC_END_DELAY);
		break;
		case 6:
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();			
			_delay_ms(ENC_END_DELAY);
		break;
		case 7:
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();			
			_delay_ms(ENC_END_DELAY);
		break;
		case 8:
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();
			_delay_ms(ENC_DELAY);
			encoder_up();			
			_delay_ms(ENC_END_DELAY);
		break;
		case 9:
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();
			_delay_ms(105);
			encoder_up();					
			_delay_ms(ENC_END_DELAY);
		break;
		default:
		
		break;																				
	}
}

void send_radio_pass(void){// процедура установки текущего пароля на устройстве
	
	press_menu(0);
	_delay_ms(70);

	encod_num_up(curr_pass_set[0]-0x30);
	_delay_ms(70);
	press_menu(0);
	_delay_ms(70);
	
	encod_num_up(curr_pass_set[1]-0x30);
	_delay_ms(70);
	press_menu(0);
	_delay_ms(70);
			
	encod_num_up(curr_pass_set[2]-0x30);	
	_delay_ms(70);
	press_menu(0);
	_delay_ms(70);
			
	encod_num_up(curr_pass_set[3]-0x30);	
	_delay_ms(70);
	press_menu(0);
	_delay_ms(70);
			
	encod_num_up(curr_pass_set[4]-0x30);	
	_delay_ms(70);
	press_menu(0);
	_delay_ms(70);
			
	encod_num_up(curr_pass_set[5]-0x30);	
	_delay_ms(60);
	press_menu(1);
	_delay_ms(70);
	
}

void delay_6s(void){ //задержка ~6 секунд
	for(uint8_t i=0; i<60; i++){
		_delay_ms(100);
	} 
}

void uart_cmd(char cmd){
	switch(cmd){
		case 0x4D://"M" 
			isBrute =0;
			curr_pass_set[0]= buf_in_uart[1];
			curr_pass_set[1]= buf_in_uart[2];
			curr_pass_set[2]= buf_in_uart[3];
			curr_pass_set[3]= buf_in_uart[4];
			curr_pass_set[4]= buf_in_uart[5];
			curr_pass_set[5]= buf_in_uart[6];		
			send_radio_pass();
		break;
		case 0x53://"S"
			curr_pass_set[0]= buf_in_uart[1];
			curr_pass_set[1]= buf_in_uart[2];
			curr_pass_set[2]= buf_in_uart[3];
			curr_pass_set[3]= buf_in_uart[4];
			curr_pass_set[4]= buf_in_uart[5];
			curr_pass_set[5]= buf_in_uart[6];
			currPasswd = atol(curr_pass_set);
			isBrute =1;			
		break;
		case 0x45://"E"
			isBrute=0;
		break;
		case 0x44://"D"
			isCouDown=1;
		break;
		case 0x55://"U"
			isCouDown=0;
		break;				
	}
}

void poll_rx_uart(){
	unsigned int c;
	int Count;
	
	Count = 0;
	c = uart_getc();
	if( c != UART_NO_DATA )
	{
	while( c != UART_NO_DATA )
	{
		buf_in_uart[Count++] = c;
		c = uart_getc();
	}	
		uart_cmd(buf_in_uart[0]);
		uart_puts(buf_in_uart);
		buf_in_uart[0]=0x00;
	}		
}


int main(void)
{
	init();
	Timer0_Init();
	sei(); // enable interrupts		
	press_f();
	increm();
	_delay_ms(150);
	init_int_on();
	disable_int();
    while(1)
    {	
		/* опрос UART */
		if (viewUART == 1){
			poll_rx_uart();
			viewUART=0;
		}				
		if (isBrute == 1){
			poll_rx_uart();
			send_radio_pass(); //устанавливаем данные
			_delay_ms(70);			
			if (compare_buff() == 0){//сравниваем буффер
				delay_6s();
				press_f();
				_delay_ms(70);
				press_f();
				_delay_ms(70);
				uart_puts(" ");
				uart_puts("N");
				uart_puts(curr_pass_set);
			}
		
			for(uint8_t i=0; i<15; i++){//чистим буффер
				curr_lcd_set[i]=0x00;
			}
			if (isCouDown == 1){
				currPasswd--;
			}else{
				currPasswd++;
			}			
			increm();			
		}		
	
    }
}