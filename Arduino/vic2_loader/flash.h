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

#ifndef FLASH_H_
#define FLASH_H_

#include "ring_buffer.h"
#include "hardware.h"

#define MICROCHIP_ID 0xBF
#define ADESTO_ID 0x1F

void SPI_Setup(void);

void getDevID();

/*
 * eraseFlash()
 * This will erase the entire flash
 * memory. This must be called before writing
 * to it to ensure it is in the erased state.
 */
void eraseFlash(void);

/*
 * writeByteFlash(address, byte)
 * This writes one byte to the address
 * specified.
 */
void writeByteFlash (uint32_t, uint8_t);

/*
 * writeFlash(address, data, length)
 * This will write a block of data of size length
 * to the flash starting at the address specified.
 *
 * The starting address MUST be an even number as
 * writes are performed in pairs. If an odd number
 * is given the actual start address will be the
 * address one earlier.
 */
void writeFlash(uint32_t, uint8_t*, uint16_t);

/*
 * readFlash(data, address, length)
 * This reads the flash memory and stores the
 * values into data. Data must be an array
 * of size length or more.
 */
void readFlash(volatile uint8_t*, uint32_t, uint16_t);

#endif /* FLASH_H_ */

