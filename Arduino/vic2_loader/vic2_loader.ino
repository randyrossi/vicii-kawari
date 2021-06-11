#include <TFT.h>

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

char scratch_buf[32];

#define SERIAL_BUFFER_SIZE 128
#define SERIAL_STOP 100

int tx_busy = 0;
RingBuffer_t serialBuffer;
uint8_t serialBufferData[SERIAL_BUFFER_SIZE];

// TODO : Use common file from config util for all defaults
// Default luma/phase/amplitude
#define DEFAULT_BLANKING_LEVEL 12
#define DEFAULT_BURST_AMPLITUDE 12
#define DEFAULT_DISPLAY_FLAGS 0
// Default colors - community
int colors[] = {0,0,0,0,
                63,63,63,0,
                43,10,10,0,
                24,54,51,0,
                44,15,45,0,
                18,49,18,0,
                13,14,49,0,
                57,59,19,0,
                45,22,7,0,
                26,14,2,0,
                58,29,27,0,
                19,19,19,0,
                33,33,33,0,
                41,62,39,0,
                28,31,57,0,
                45,45,45,0 };

int luma[] = {
   12,0,0,
   58,0,0,
   19,80,10,
   36,208,10,
   22,32,12,
   30,160,12,
   14,0,10,
   43,128,14,
   22,96,14,
   14,112,10,
   30,80,10,
   19,0,0,
   28,0,0,
   43,160,10,
   28,0,10,
   36,0,0,
};

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
// PB4-5 data lines.
int chip_model = 0;

#define BLANKING_LEVEL 0x80
#define BURST_AMPLITUDE 0x81
#define CHIP_MODEL_ADDR 0x82
#define DISPLAY_FLAGS_ADDR 0x84

#define CHIP_MODEL_BIT_0 4
#define CHIP_MODEL_BIT_1 5

// P46 CHIP_MODEL_BIT_0
// P61 CHIP_MODEL_BIT_1

#define DISPLAY_SHOW_RASTER_LINES_BIT 1
#define DISPLAY_NATIVE_Y_BIT 2
#define DISPLAY_NATIVE_X_BIT 4
#define DISPLAY_ENABLE_CSYNC_BIT 8
#define DISPLAY_VPOLARITY_BIT 16
#define DISPLAY_HPOLARITY_BIT 32

// Last known saved settings. Used to compare
// against what the FPGA is telling us it
// thinks the settings ought to be.
unsigned char last_regs[256];
unsigned char magic_1;
unsigned char magic_2;
unsigned char magic_3;
unsigned char magic_4;

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

void setMagic() {
  magic_1 = 'V';
  magic_2 = 'I';
  magic_3 = 'C';
  magic_4 = '2';
  EEPROM.write(0xfc, magic_1);
  EEPROM.write(0xfd, magic_2);
  EEPROM.write(0xfe, magic_3);
  EEPROM.write(0xff, magic_4);
  last_regs[0xfc] = magic_1;
  last_regs[0xfd] = magic_2;
  last_regs[0xfe] = magic_3;
  last_regs[0xff] = magic_4;
}

int haveMagic() {
  return magic_1 == 'V' && magic_2 == 'I' && magic_3 == 'C' && magic_4 == '2';
}

void restoreSettings() {
 // Only restore config if we have the magic bytes
  if (haveMagic()) {
     // Restore the palette
     for (int r = 0; r < 64; r++) {
        // Don't bother with 4th byte in RGBX
        if (r % 4 == 3) continue;
        Serial_SendByte(r);
        Serial_SendByte(last_regs[r]);
     }

     // Restore luma/phase/amp
     for (int r = 0xa0; r < 0xd0; r++) {
        Serial_SendByte(r);
        Serial_SendByte(last_regs[r]);
     }
     Serial_SendByte(BLANKING_LEVEL);
     Serial_SendByte(last_regs[BLANKING_LEVEL]);
     Serial_SendByte(BURST_AMPLITUDE);
     Serial_SendByte(last_regs[BURST_AMPLITUDE]);

     // Restore some select registers
     Serial_SendByte(DISPLAY_FLAGS_ADDR);
     Serial_SendByte(last_regs[DISPLAY_FLAGS_ADDR]);

     // Put magic
     Serial_SendByte(0xfc);
     Serial_SendByte(magic_1);
     Serial_SendByte(0xfd);
     Serial_SendByte(magic_2);
     Serial_SendByte(0xfe);
     Serial_SendByte(magic_3);
     Serial_SendByte(0xff);
     Serial_SendByte(magic_4);
  }
}

/* Here you can do some setup before entering the userLoop loop */
void initPostLoad() {
  //Serial.flush();

  RingBuffer_InitBuffer(&serialBuffer, serialBufferData, SERIAL_BUFFER_SIZE);

  // Restore all registers (not all are used)
  for (int r=0;r<256;r++) {
     last_regs[r] = EEPROM.read(r);
  }
  chip_model = last_regs[CHIP_MODEL_ADDR] & 0b11;

  // Read magic bytes
  magic_1 = EEPROM.read(0xfc);
  magic_2 = EEPROM.read(0xfd);
  magic_3 = EEPROM.read(0xfe);
  magic_4 = EEPROM.read(0xff);

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
      // 01 - 6569R9
      ADC_BUS_PORT |= (1 << CHIP_MODEL_BIT_0);
      ADC_BUS_PORT &= ~(1 << CHIP_MODEL_BIT_1);
      break;
    case 2:
      // 10 - 6567 R56A
      ADC_BUS_PORT &= ~(1 << CHIP_MODEL_BIT_0);
      ADC_BUS_PORT |= (1 << CHIP_MODEL_BIT_1);
      break;
    case 3:
      // 11 - 6569R3
      ADC_BUS_PORT |= (1 << CHIP_MODEL_BIT_0);
      ADC_BUS_PORT |= (1 << CHIP_MODEL_BIT_1);
      break;
  }

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

  // Send over last known config to FPGA
  delay(250);
  restoreSettings();
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

#define CMD_BUFFER_SIZE 32
char cmd_buf[CMD_BUFFER_SIZE];
byte cmd_buf_ptr = 0;

unsigned char cfg_reg_num;
unsigned char cfg_byte_ff = 0;

// Store the change and tell FPGA the new value
void SaveAndSend(const unsigned int reg, const unsigned char value)
{
    EEPROM.write(reg, value);
    Serial_SendByte(reg);
    Serial_SendByte(value);
}

void uartTask() {
  // We listen to the fpga for its current settings and if they
  // don't match our last saved value, then we save the change back to
  // EEPROM for the next boot to pick it up.

  // Something to read?
  uint16_t ct;
  do {
    ct = RingBuffer_GetCount(&serialBuffer);
    if (ct > 0) {
       // FPGA sents register followed by value.
       uint8_t cfg_byte = RingBuffer_Remove(&serialBuffer);
       if (cfg_byte_ff == 0) {
           cfg_reg_num = cfg_byte;
           cfg_byte_ff = 1;
       } else {
           if (last_regs[cfg_reg_num] != cfg_byte) {
              EEPROM.write(cfg_reg_num, cfg_byte);
              last_regs[cfg_reg_num] = cfg_byte;
           }
           if (cfg_reg_num == 0xfc)
              magic_1 = cfg_byte;
           if (cfg_reg_num == 0xfd)
              magic_2 = cfg_byte;
           if (cfg_reg_num == 0xfe)
              magic_3 = cfg_byte;
           if (cfg_reg_num == 0xff)
              magic_4 = cfg_byte;
           cfg_byte_ff = 0;
       }

       // Print what we get to see if it's what we expect
       sprintf (scratch_buf, "(%02x) \n", cfg_byte);
       Serial.write(scratch_buf);

       if (ct < SERIAL_STOP) {
          if (tx_busy) {
            tx_busy = 0;
            SET(TX_BUSY, LOW);
          }
       }
    }
  } while (ct > 0);

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
         int ok = 1;
         // Reset only takes effect next boot so don't send to FPGA
         if (strcmp(cmd_buf, "re") == 0) {
             // chip
             last_regs[CHIP_MODEL_ADDR] = 0;
             EEPROM.write(CHIP_MODEL_ADDR, last_regs[CHIP_MODEL_ADDR]);
             // display flags (all off, no native x, no native y, no raster lines)
             last_regs[DISPLAY_FLAGS_ADDR] = DEFAULT_DISPLAY_FLAGS;
             EEPROM.write(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             // color registers - only 1st palette
             for (int r = 0; r < 64; r++) {
                if (r % 4 == 3) continue;
                last_regs[r] = colors[r];
                last_regs[r+64] = colors[r];
                EEPROM.write(r, last_regs[r]);
                EEPROM.write(r+64, last_regs[r+64]);
             }
             // luma,phase,amplitude registers
             for (int ci = 0; ci < 16; ci++) {
                last_regs[ci+0xa0] = luma[ci*3];  // luma
                last_regs[ci+0xb0] = luma[ci*3+1]; // phase
                last_regs[ci+0xc0] = luma[ci*3+2]; // amplitude
                EEPROM.write(ci+0xa0, last_regs[ci+0xa0]);
                EEPROM.write(ci+0xb0, last_regs[ci+0xb0]);
                EEPROM.write(ci+0xc0, last_regs[ci+0xc0]);
             }
             last_regs[BLANKING_LEVEL] = DEFAULT_BLANKING_LEVEL;
             last_regs[BURST_AMPLITUDE] = DEFAULT_BURST_AMPLITUDE;
             EEPROM.write(BLANKING_LEVEL, last_regs[BLANKING_LEVEL]);
             EEPROM.write(BURST_AMPLITUDE, last_regs[BURST_AMPLITUDE]);
             if (!haveMagic()) {
                setMagic();
             }
         }
         // Takes effect immediately
         else if (strcmp(cmd_buf, "nx") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_NATIVE_X_BIT) != DISPLAY_NATIVE_X_BIT) {
                last_regs[DISPLAY_FLAGS_ADDR] |= DISPLAY_NATIVE_X_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         else if (strcmp(cmd_buf, "dx") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_NATIVE_X_BIT) != 0) {
                last_regs[DISPLAY_FLAGS_ADDR] &= ~DISPLAY_NATIVE_X_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         else if (strcmp(cmd_buf, "15") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_NATIVE_Y_BIT) != DISPLAY_NATIVE_Y_BIT) {
                last_regs[DISPLAY_FLAGS_ADDR] |= DISPLAY_NATIVE_Y_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         // Takes effect immediately
         else if (strcmp(cmd_buf, "31") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_NATIVE_Y_BIT) != 0) {
                last_regs[DISPLAY_FLAGS_ADDR] &= ~DISPLAY_NATIVE_Y_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         // Takes effect immediately
         else if (strcmp(cmd_buf, "r0") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_SHOW_RASTER_LINES_BIT) != 0) {
                last_regs[DISPLAY_FLAGS_ADDR] &= ~DISPLAY_SHOW_RASTER_LINES_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         // Takes effect immediately
         else if (strcmp(cmd_buf, "r1") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_SHOW_RASTER_LINES_BIT) != DISPLAY_SHOW_RASTER_LINES_BIT) {
                last_regs[DISPLAY_FLAGS_ADDR] |= DISPLAY_SHOW_RASTER_LINES_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         // Takes effect immediately
         else if (strcmp(cmd_buf, "s0") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_ENABLE_CSYNC_BIT) != 0) {
                last_regs[DISPLAY_FLAGS_ADDR] &= ~DISPLAY_ENABLE_CSYNC_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         // Takes effect immediately
         else if (strcmp(cmd_buf, "s1") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_ENABLE_CSYNC_BIT) != DISPLAY_ENABLE_CSYNC_BIT) {
                last_regs[DISPLAY_FLAGS_ADDR] |= DISPLAY_ENABLE_CSYNC_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         else if (strcmp(cmd_buf, "v0") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_VPOLARITY_BIT) != 0) {
                last_regs[DISPLAY_FLAGS_ADDR] &= ~DISPLAY_VPOLARITY_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         // Takes effect immediately
         else if (strcmp(cmd_buf, "v1") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_VPOLARITY_BIT) != DISPLAY_VPOLARITY_BIT) {
                last_regs[DISPLAY_FLAGS_ADDR] |= DISPLAY_VPOLARITY_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         else if (strcmp(cmd_buf, "h0") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_HPOLARITY_BIT) != 0) {
                last_regs[DISPLAY_FLAGS_ADDR] &= ~DISPLAY_HPOLARITY_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         // Takes effect immediately
         else if (strcmp(cmd_buf, "h1") == 0) {
             if ((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_HPOLARITY_BIT) != DISPLAY_HPOLARITY_BIT) {
                last_regs[DISPLAY_FLAGS_ADDR] |= DISPLAY_HPOLARITY_BIT;
                SaveAndSend(DISPLAY_FLAGS_ADDR, last_regs[DISPLAY_FLAGS_ADDR]);
             }
         }
         // Chip changes next boot
         else if (strcmp(cmd_buf, "0") == 0 ||
                  strcmp(cmd_buf, "1") == 0 ||
                  strcmp(cmd_buf, "2") == 0 ||
                  strcmp(cmd_buf, "3") == 0) {
             int m = atoi(cmd_buf);
             if ((last_regs[CHIP_MODEL_ADDR] & 3) != m) {
                last_regs[CHIP_MODEL_ADDR] = (last_regs[CHIP_MODEL_ADDR] & ~3) | m;
                EEPROM.write(CHIP_MODEL_ADDR, last_regs[CHIP_MODEL_ADDR]);
                // No register to write to.  Takes effect on next boot.
             }
         }
         else if (strcmp(cmd_buf, "l") == 0) {
            restoreSettings();
         }
         // Show current settings
         else if (strcmp(cmd_buf, "?") == 0) {
             Serial.write('C'); Serial.write('0'+(last_regs[CHIP_MODEL_ADDR] & 3));
             Serial.write('R'); Serial.write((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_SHOW_RASTER_LINES_BIT) ? '1' : '0');
             Serial.write('X'); Serial.write((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_NATIVE_X_BIT) ? '1' : '0');
             Serial.write('Y'); Serial.write((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_NATIVE_Y_BIT) ? '1' : '0');
             Serial.write('S'); Serial.write((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_ENABLE_CSYNC_BIT) ? '1' : '0');
             Serial.write('H'); Serial.write((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_HPOLARITY_BIT) ? '1' : '0');
             Serial.write('V'); Serial.write((last_regs[DISPLAY_FLAGS_ADDR] & DISPLAY_VPOLARITY_BIT) ? '1' : '0');

             for (int r = 0; r < 256; r++) {
                if (r % 16 == 0)
                   Serial.write("\n");
                sprintf (scratch_buf, "%02x=%02x  ", r, last_regs[r]);
                Serial.write(scratch_buf);
             }
             Serial.write("\n");
         }
         else {
             // Unknown command
             ok = 0;
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

// This is inbound serial data from the FPGA -> MCU
ISR(USART1_RX_vect) { // new serial data!
  *(serialBuffer.In) = UDR1;

  if (++serialBuffer.In == serialBuffer.End)
    serialBuffer.In = serialBuffer.Start;

  serialBuffer.Count++;

  if (serialBuffer.Count >= SERIAL_STOP && !tx_busy) { // are we almost out of space?
     tx_busy = 1;
     SET(TX_BUSY, HIGH); 
  }
}
