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

#ifndef HARDWARE_H_
#define HARDWARE_H_

#include <avr/io.h>
#include <avr/wdt.h>
#include <avr/power.h>
#include <avr/interrupt.h>
#include <stdint.h>
#include <stdbool.h>

#include "Arduino.h"
#include <SPI.h>

#define FPGA_BUS_PORT PORTB
#define FPGA_BUS_DDR DDRB
#define FPGA_BUS_PIN PINB
#define FPGA_BUS_MASK 0xFF
#define FPGA_BUS_OFFSET 0

// Repurposing these for FPGA config
#define ADC_BUS_PORT PORTB
#define ADC_BUS_DDR DDRB
#define ADC_BUS_PIN PINB
#define ADC_BUS_MASK 0xF0
#define ADC_BUS_OFFSET 4   // doesn't mean anything for us

#define CCLK_N 3
#define CS_FLASH_N 2
#define INIT_N 30
#define TX_BUSY_N 30
#define DONE_N 5
#define PROGRAM_N 13

#define CCLK_PORT PORTD
#define CCLK_DDR DDRD
#define CCLK_BIT 0
#define CCLK_PIN PIND

#define CS_FLASH_PORT PORTD
#define CS_FLASH_DDR DDRD
#define CS_FLASH_BIT 1
#define CS_FLASH_PIN PIND

#define INIT_PORT PORTD
#define INIT_DDR DDRD
#define INIT_BIT 5
#define INIT_PIN PIND

#define TX_BUSY_PORT PORTD
#define TX_BUSY_DDR DDRD
#define TX_BUSY_BIT 5
#define TX_BUSY_PIN PIND

#define DONE_PORT PORTC
#define DONE_DDR DDRC
#define DONE_BIT 6
#define DONE_PIN PINC

#define PROGRAM_PORT PORTC
#define PROGRAM_DDR DDRC
#define PROGRAM_BIT 7
#define PROGRAM_PIN PINC

#define MISO_PORT PORTB
#define MISO_DDR DDRB
#define MISO_BIT 3
#define MISO_PIN PINB

#define SS_PORT PORTB
#define SS_DDR DDRB
#define SS_BIT 0
#define SS_PIN PINB

#define TOGGLE(p) p ## _PORT = (p ## _PORT ^ (1 << p ## _BIT))
#define SET(p, v) p ## _PORT = (p ## _PORT & ~(1 << p ## _BIT)) | (v << p ## _BIT)
#define VALUE(p) (p ## _PIN & (1 << p ## _BIT))
#define OUT(p) p ## _DDR |= (1 << p ## _BIT)
#define IN(p) p ## _DDR &= ~(1 << p ## _BIT)

#define LINESTATE_DTR  1

#endif /* HARDWARE_H_ */
