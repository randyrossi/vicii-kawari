/*
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "hardware.h"
#include "ring_buffer.h"
#include <SPI.h>
#include <EEPROM.h>
#include "flash.h"
#include "string.h"

typedef enum {
  IDLE,
  READ_SIZE,
  WRITE_TO_FLASH,
  WRITE_TO_FPGA,
  VERIFY_FLASH,
  LOAD_FROM_FLASH
}
loaderState_t;

typedef enum {
  WAIT, START_LOAD, LOAD, SERVICE
}
taskState_t;

#if defined(__AVR_ATmega32U4__)
#define BUFFER_SIZE 1024
#endif

uint8_t loadBuffer[BUFFER_SIZE + 128];

volatile taskState_t taskState = SERVICE;

// Current VIC2 settings we are holding on
// PB4-7 data lines (and maybe in the future
// what we are transmitting via Serial tx.)
int chip_model = 0;
int is_15khz = 0;
int is_hide_raster_lines = 0;

#define CHIP_MODEL_ADDR 0x00
#define IS_15KHZ_ADDR 0x01
#define IS_HIDE_RASTER_LINES_ADDR 0x02

#define CHIP_MODEL_BIT_0 4
#define CHIP_MODEL_BIT_1 5
#define IS_15KHZ_BIT 6
#define IS_HIDE_RASTER_LINES_BIT 7

// P46 CHIP_MODEL_BIT_0
// P61 CHIP_MODEL_BIT_1
// P62 IS_15KHZ
// P65 IS_HIDE_RASTER_LINES

// Last known saved settings. Used to compare
// against what the FPGA is telling us it
// thinks the settings ought to be.
int last_chip_model;
int last_is_15khz;
int last_is_hide_raster_lines;

void userLoop() {
  uartTask();
}

/* this is used to undo any setup you did in initPostLoad */
void disablePostLoad() {
  ADCSRA = 0; // disable ADC
  UCSR1B = 0; // disable serial port
  SPI.end();  // disable SPI
  SET(CCLK, LOW);
  OUT(PROGRAM);
  SET(PROGRAM, LOW); // reset the FPGA
  IN(INIT);
  SET(INIT, HIGH); // pullup on INIT
}

/* Here you can do some setup before entering the userLoop loop */
void initPostLoad() {
  //Serial.flush();

  // Restore VIC settings
  chip_model = EEPROM.read(CHIP_MODEL_ADDR);
  is_15khz = EEPROM.read(IS_15KHZ_ADDR);
  is_hide_raster_lines = EEPROM.read(IS_HIDE_RASTER_LINES_ADDR);

  last_chip_model = chip_model;
  last_is_15khz = is_15khz;
  last_is_hide_raster_lines = is_hide_raster_lines;

  // Set PB4-PB7 as outputs. These are our configuration pins.
  ADC_BUS_DDR |= ADC_BUS_MASK; // make outputs

  // Set two chip lines according to selected model
  switch (chip_model) {
    case 0:
      // 00 - 6567 R8
      ADC_BUS_PORT &= ~(1 << CHIP_MODEL_BIT_0); 
      ADC_BUS_PORT &= ~(1 << CHIP_MODEL_BIT_1); 
      break;
    case 1:
      // 01 - 6569
      ADC_BUS_PORT |= (1 << CHIP_MODEL_BIT_0);
      ADC_BUS_PORT &= ~(1 << CHIP_MODEL_BIT_1);
      break;
    case 2:
      // 10 - 6567 R56A
      ADC_BUS_PORT &= ~(1 << CHIP_MODEL_BIT_0); 
      ADC_BUS_PORT |= (1 << CHIP_MODEL_BIT_1);
      break;
    default:
      // 00 - 6569
      ADC_BUS_PORT |= (1 << CHIP_MODEL_BIT_0);
      ADC_BUS_PORT &= ~(1 << CHIP_MODEL_BIT_1);
      break;
  }

  if (is_15khz)
      ADC_BUS_PORT |= 1 << IS_15KHZ_BIT;
  else
      ADC_BUS_PORT &= ~(1 << IS_15KHZ_BIT); 

  if (is_hide_raster_lines)
      ADC_BUS_PORT |= 1 << IS_HIDE_RASTER_LINES_BIT;
  else
      ADC_BUS_PORT &= ~(1 << IS_HIDE_RASTER_LINES_BIT); 

  // Again, the Arduino libraries didn't offer the functionality we wanted
  // so we access the serial port directly. This sets up an interrupt
  // that is used with our own buffer to capture serial input from the FPGA
  UBRR1 = 1; 

  UCSR1C = (1 << UCSZ11) | (1 << UCSZ10);
  UCSR1A = (1 << U2X1);
  UCSR1B = (1 << TXEN1) | (1 << RXEN1) | (1 << RXCIE1);

  // Setup all the SPI pins
  SET(CS_FLASH, HIGH);
  OUT(SS);
  SET(SS, HIGH);
  SPI_Setup(); // enable the SPI Port

  // AVR_TX and AVR_RX pin config
  // REF DataDir 1 = OUTPUT, 0 = INPUT
  DDRD |= (1 << 3);  // Port D Pin 3 TX as OUTPUT
  DDRD &= ~(1 << 2); // Port D Pin 2 RX as INPUT
  PORTD |= (1 << 2); // ??

  // This pin is used to signal the serial buffer is almost full
  // I don't think we will ever use this since we are not
  // relaying data, we instantly consume anything coming in.
  serialRXEnable();
  OUT(TX_BUSY);
  SET(TX_BUSY, LOW);

  // set progam as an input so that it's possible to use a JTAG programmer
  IN(PROGRAM);

  // the FPGA looks for CCLK to be high to know the AVR is ready for data
  SET(CCLK, HIGH);

  IN(CCLK); // set as pull up so JTAG can work
}


void setup() {
  /* Disable clock division */
  clock_prescale_set(clock_div_1);

  OUT(CS_FLASH);
  SET(CS_FLASH, HIGH);
  OUT(CCLK);
  OUT(PROGRAM);

  /* Disable digital inputs on analog pins */
  DIDR0 = 0xF3;
  DIDR2 = 0x03;

  // Apparently, this baud rate means nothing.  The baud rate
  // is 9600.
  Serial.begin(115200);

  sei(); // enable interrupts

  getDevID();

  loadFromFlash(); // load on power up
  initPostLoad();
}

void loop() {
  static loaderState_t state = IDLE;
  static int8_t destination;
  static int8_t verify;
  static uint32_t byteCount;
  static uint32_t transferSize;

  int16_t w;
  uint8_t bt;
  uint8_t buffIdx;
  uint32_t addr;

  switch (taskState) {
    case WAIT:
      break;
    case START_LOAD: // command to enter loader mode
      disablePostLoad(); // setup peripherals
      taskState = LOAD; // enter loader mode
      state = IDLE; // in idle state
      break;
    case LOAD:
      w = Serial.read();
      bt = (uint8_t) w;
      if (w >= 0) { // if we have data
        switch (state) {
          case IDLE: // in IDLE we are waiting for a command from the PC
            byteCount = 0;
            transferSize = 0;
            if (bt == 'F') { // write to flash
              destination = 0; // flash
              verify = 0; // don't verify
              state = READ_SIZE;
              Serial.write('R'); // signal we are ready
            }
            if (bt == 'V') { // write to flash and verify
              destination = 0; // flash
              verify = 1; // verify
              state = READ_SIZE;
              Serial.write('R'); // signal we are ready
            }
            if (bt == 'R') { // write to RAM
              destination = 1; // ram
              state = READ_SIZE;
              Serial.write('R'); // signal we are ready
            }
            if (bt == 'E') { //erase
              eraseFlash();
              Serial.write('D'); // signal we are done
            }
            //Serial.flush();
            break;
          case READ_SIZE: // we need to read in how many bytes the config data is
            transferSize |= ((uint32_t) bt << (byteCount++ * 8));
            if (byteCount > 3) {
              byteCount = 0;
              
              if (destination) {
                state = WRITE_TO_FPGA;
                initLoad(); // get the FPGA read for a load
                startLoad(); // start the load
              }
              else {
                buffIdx = 0;
                state = WRITE_TO_FLASH;
                eraseFlash();
              }
              Serial.write('O'); // signal the size was read
              //Serial.flush();
            }
            break;
          case WRITE_TO_FLASH:
            if (byteCount < 256 - 5)
              buffIdx = byteCount % 256;
            else
              buffIdx = (byteCount+5) % 256;
            loadBuffer[buffIdx] = bt;
            addr = byteCount + 5;
            byteCount++;

            if (addr % 256 == 255 || byteCount == transferSize){
              writeFlash(addr - buffIdx, loadBuffer, buffIdx+1); // write blocks of 256 bytes at a time for speed
            }

            if (byteCount == transferSize) { // the last block to write
              delayMicroseconds(50); // these are necciary to get reliable writes
              uint32_t size = byteCount + 5;
              for (uint8_t k = 0; k < 4; k++) {
                writeByteFlash(k + 1, (size >> (k * 8)) & 0xFF); // write the size of the config data to the flash
                delayMicroseconds(50);
              }
              delayMicroseconds(50);
              writeByteFlash(0, 0xAA); // 0xAA is used to signal the flash has valid data
              Serial.write('D'); // signal we are done
              //Serial.flush(); // make sure it sends
              if (verify) {
                state = VERIFY_FLASH;
              }
              else {
                state = LOAD_FROM_FLASH;
              }
            }
            break;
          case WRITE_TO_FPGA:
            sendByte(bt); // just send the byte!
            if (++byteCount == transferSize) { // if we are done
              sendExtraClocks(); // send some extra clocks to make sure the FPGA is happy
              state = IDLE;
              taskState = SERVICE; // enter user mode
              initPostLoad();
              Serial.write('D'); // signal we are done
              //Serial.flush();
            }
            break;
          case VERIFY_FLASH:
            if (bt == 'S') {
              byteCount += 5;
              for (uint32_t k = 0; k < byteCount; k += 256) { // dump all the flash data
                uint16_t s;
                if (k + 256 <= byteCount) {
                  s = 256;
                }
                else {
                  s = byteCount - k;
                }
                readFlash(loadBuffer, k, s); // read blocks of 256
                uint16_t br = Serial.write((uint8_t*) loadBuffer, s); // dump them to the serial port
                k -= (256 - br); // if all the bytes weren't sent, resend them next round
                //Serial.flush();
                delay(10); // needed to prevent errors in some computers running Windows (give it time to process the data?)
              }
              state = LOAD_FROM_FLASH;
            }
            break;
          case LOAD_FROM_FLASH:
            if (bt == 'L') {
              loadFromFlash(); // load 'er up!
              Serial.write('D'); // loading done
              //Serial.flush();
              state = IDLE;
              taskState = SERVICE;
              initPostLoad();
            }
            break;
        }
      }

      break;
    case SERVICE:
      userLoop(); // loop the user code
      break;
  }
}

/* This is called when any control lines on the serial port are changed.
 It requires a modification to the Arduino core code to work.

 This looks for 5 pulses on the DTR line within 250ms. Checking for 5
 makes sure that false triggers won't happen when the serial port is opened. */
void lineStateEvent(unsigned char linestate)
{
  static unsigned long start = 0;
  static uint8_t falling = 0;
  if (!(linestate & LINESTATE_DTR)) {
    if ((millis() - start) < 250) {
      if (++falling >= 5)
        taskState = START_LOAD;
    }
    else {
      start = millis();
      falling = 1;
    }
  }
}

void serialRXEnable() {
  UCSR1B |= (1 << RXEN1);
}

void serialRXDisable() {
  UCSR1B &= ~(1 << RXEN1);
}

static inline void Serial_SendByte(const char DataByte)
{
  while (!(UCSR1A & (1 << UDRE1)));
  UDR1 = DataByte;
}

#define CONFIG_BUFFER_SIZE 10
#define CMD_BUFFER_SIZE 32

char config_buf[CONFIG_BUFFER_SIZE];
volatile byte config_buf_write_ptr = 0;
byte config_buf_read_ptr = 0;

char cmd_buf[CMD_BUFFER_SIZE];
byte cmd_buf_ptr = 0;

void uartTask() {
  // We listen to the fpga for its current settings and if they
  // don't match our last saved value, then we save the change back to
  // EEPROM for the next boot to pick it up.

  // Something to read?
  if (config_buf_read_ptr != config_buf_write_ptr) {
       // So far we have just 4 bits of config from the fpga
       // so this doesn't have to be complicated.  Just read
       // a byte and use the lower 4 bits to make the config
       // change if necessary.
       char bits = config_buf[config_buf_read_ptr];
       int fpga_chip_model = (bits & 3);
       int fpga_is_15khz = (bits & 4) ? 1 : 0;
       int fpga_is_hide_raster_lines = (bits & 8) ? 1 : 0;
       
       if (fpga_chip_model != last_chip_model) {
          EEPROM.write(CHIP_MODEL_ADDR, fpga_chip_model);
          last_chip_model = fpga_chip_model;
          Serial.write((fpga_chip_model & 1) ? 'P' : 'N');
          Serial.write('\n');
       }
       if (fpga_is_15khz != last_is_15khz) {
          EEPROM.write(IS_15KHZ_ADDR, fpga_is_15khz);
          last_is_15khz = fpga_is_15khz;
          Serial.write(fpga_is_15khz ? 'L' : 'H');
          Serial.write('\n');
       }
       if (fpga_is_hide_raster_lines != last_is_hide_raster_lines) {
          EEPROM.write(IS_HIDE_RASTER_LINES_ADDR, fpga_is_hide_raster_lines);
          last_is_hide_raster_lines = fpga_is_hide_raster_lines;
          Serial.write(fpga_is_hide_raster_lines ? 'X' : 'R');
          Serial.write('\n');
       }
     
       config_buf_read_ptr = (config_buf_read_ptr + 1) % CONFIG_BUFFER_SIZE;
  }
        

  // Process commands from the PC serial channel.
  // We expect 9600 baud.  Commands can end with \n alone
  // or \r\n.

  if (Serial) {
    int16_t w;
    while ((w = Serial.read()) >= 0) {
      cmd_buf[cmd_buf_ptr] = (char)w;
      if (cmd_buf[cmd_buf_ptr] == '\n') {
         
         if (cmd_buf_ptr > 0 && cmd_buf[cmd_buf_ptr-1] == '\r' && cmd_buf[cmd_buf_ptr] == '\n')
            cmd_buf[cmd_buf_ptr-1] = '\0';

         cmd_buf[cmd_buf_ptr] = '\0';
         cmd_buf_ptr = 0;
         int ok = 0;
         if (strcmp(cmd_buf, "re") == 0) {
             if (last_chip_model != 0) {
                last_chip_model = 0;
                EEPROM.write(CHIP_MODEL_ADDR, last_chip_model);
             }
             if (last_is_15khz != 0) {
                last_is_15khz = 0;
                EEPROM.write(IS_15KHZ_ADDR, last_is_15khz);
             }
             if (last_is_hide_raster_lines != 0) {
                last_is_hide_raster_lines = 0;
                EEPROM.write(IS_HIDE_RASTER_LINES_ADDR, last_is_hide_raster_lines);
             }
             ok = 1;
         }
         else if (strcmp(cmd_buf, "15") == 0) {
             if (last_is_15khz != 1) {
                last_is_15khz = 1;
                EEPROM.write(IS_15KHZ_ADDR, last_is_15khz);
             }
             ok = 1;
         }
         else if (strcmp(cmd_buf, "31") == 0) {
             if (last_is_15khz != 0) {
                last_is_15khz = 0;
                EEPROM.write(IS_15KHZ_ADDR, last_is_15khz);
             }
             ok = 1;
         }
         else if (strcmp(cmd_buf, "r0") == 0) {
             if (last_is_hide_raster_lines != 1) {
                last_is_hide_raster_lines = 1;
                EEPROM.write(IS_HIDE_RASTER_LINES_ADDR, last_is_hide_raster_lines);
             }
             ok = 1;
         }
         else if (strcmp(cmd_buf, "r1") == 0) {
             if (last_is_hide_raster_lines != 0) {
                last_is_hide_raster_lines = 0;
                EEPROM.write(IS_HIDE_RASTER_LINES_ADDR, last_is_hide_raster_lines);
             }
             ok = 1;
         }
         else if (strcmp(cmd_buf, "0") == 0 || strcmp(cmd_buf, "1") == 0 || strcmp(cmd_buf, "2") == 0) {
             int m = atoi(cmd_buf);
             if (last_chip_model != m) {
                last_chip_model = m;
                EEPROM.write(CHIP_MODEL_ADDR, last_chip_model);
             }
             ok = 1;
         }
         else if (strcmp(cmd_buf, "?") == 0) {
             Serial.write('R'); Serial.write(last_is_hide_raster_lines ? '0' : '1');
             Serial.write('C'); Serial.write('0'+last_chip_model);
             Serial.write('K'); Serial.write('0'+last_is_15khz);
             Serial.write('\n');
         }
         if (ok) {
             Serial.write('O'); Serial.write('K');
         } else {
             Serial.write('?');
         }
         Serial.write('\n');
       } else {
         cmd_buf_ptr++;
       }
    }
  }
}

ISR(USART1_RX_vect) { // new serial data!
  config_buf[config_buf_write_ptr] = UDR1;
  config_buf_write_ptr = (config_buf_write_ptr + 1) % CONFIG_BUFFER_SIZE;
}

