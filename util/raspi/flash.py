import sys
import os
from spidev import SpiDev

class SPIFlash(object):
    READ_ID = 0x9f
    READ_RS = 0x05
    CHIP_ERASE = 0x60

    PAGE_READ = 0x3
    PAGE_WRITE = 0x2

    WRITE_ENABLE = 0x6
    WRITE_DISABLE = 0x4

    # Flash attribute
    W25Q80_MID = 0xEF
    W25Q80_DID = 0x4015
    FLASH_PAGE_SIZE = 256
    FLASH_TOTAL_SIZE = 0

    def __init__(self, bus, dev, speed):
        """Init a spi flash
        :param bus: spi bus number
        :param dev: spi device number
        :param speed: spi speed unit khz
        """
        try:
            self.__spi = SpiDev()
            self.__spi.open(bus, dev)
            self.__spi.max_speed_hz = speed * 1000
            print("Device:/dev/spidev{}.{}, speed:{}".format(bus, dev, speed))

        except IOError:
            raise("Do not found spi device:/dev/spidev{}.{}".format(bus, dev))

    def __del__(self):
        self.__spi.close()

    def probe(self):
        try:

            data = self.__spi.xfer([self.READ_ID, 0, 0, 0])
            return data[1], data[2] << 8 | data[3]

        except IndexError:
            return 0, 0

    def erase(self):
        # First enable write
        self.__spi.xfer([self.WRITE_ENABLE])

        # Second erase chip
        self.__spi.xfer([self.CHIP_ERASE])

        # Final wait chip erase done
        while self.get_rs() & 0x1:
            pass

    def get_rs(self):
        return self.__spi.xfer([self.READ_RS, 0])[1]

    def read_page(self, page):
        address = page * self.FLASH_PAGE_SIZE
        # Msb first
        cmd = [self.PAGE_READ, (address >> 16) & 0xff, (address >> 8) & 0xff, address & 0xff]
        return bytearray(self.__spi.xfer(cmd + [0] * self.FLASH_PAGE_SIZE)[4:])

    def read_chip(self):
        data = bytearray()
        max_page = int(self.FLASH_TOTAL_SIZE / self.FLASH_PAGE_SIZE)
        for page in range(max_page):
            data += self.read_page(page)

        return data

    def write_page(self, page, data):
        address = page * self.FLASH_PAGE_SIZE
        cmd = [self.PAGE_WRITE, (address >> 16) & 0xff, (address >> 8) & 0xff, address & 0xff]
        # First enable write
        self.__spi.xfer([self.WRITE_ENABLE])

        # Second write page data
        self.__spi.xfer(cmd + data)

        # Wait done
        while self.get_rs() & 0x1:
            pass

    def write_chip(self, data, verify=False):
        """Write chip
        :param data: data will write to chip
        :param verify: verify data
        :return:success return true else false
        """
        # Check data len
        if len(data) != self.FLASH_TOTAL_SIZE:
            print("Data size error!")
            return False

        # First erase chip
        self.erase()

        # Convert data to list
        data = list(data)

        # Write data to page
        max_page = int(self.FLASH_TOTAL_SIZE / self.FLASH_PAGE_SIZE)
        for page in range(max_page):
            start = page * self.FLASH_PAGE_SIZE
            end = start + self.FLASH_PAGE_SIZE

            write_buffer = data[start:end]
            self.write_page(page, write_buffer)
            if verify and bytearray(write_buffer) != self.read_page(page):
                print("Verify error, page:{}".format(page))
                return False

        return True


if __name__ == "__main__":

    if len(sys.argv) < 3:
       print ("Usage flash <operation> <flash.bin>")
       print ("Where operation is read | write")
       sys.exit()

    operation = sys.argv[1]
    filename = sys.argv[2]

    if operation == 'write':
        file_stats = os.stat(filename)
        size = file_stats.st_size
    elif operation == "read":
        if len(sys.argv) < 4:
            print ("read requires size argument after filename")
            sys.exit()
        else:
            size = int(sys.argv[3])
    else:
        print ("unknown operation")
        sys.exit()

    # SPI0  GPIO10 PIN19 MOSI
    #       GPIO9  PIN21 MISO
    #       GPIO11 PIN23 CLK
    #       GPIO8  PIN24 CS
    #              PIN20 GND
    #              PIN25 RST

    print ("bistream file is ", size," bytes")

    if size % 256 != 0:
       print ("Size must be multiple of 256")
       sys.exit()

    if size == 0:
       print ("Size must be > 0")
       sys.exit()

    flash = SPIFlash(0, 0, 8000)

    flash.FLASH_TOTAL_SIZE = size

    # Get device manufacturer id and device id
    mid, device_id = flash.probe()
    print("Manufacturer ID:0x{0:X}, Device ID:0x{1:X}".format(mid, device_id))

    if mid != SPIFlash.W25Q80_MID or device_id != SPIFlash.W25Q80_DID:
        print("SPI Flash is not Winbond W25Q80")
        sys.exit()

    if operation == 'write':
        # Write from filename to flash
        with open(filename, "rb") as fp:
            flash.write_chip(fp.read())

        # Read data to read_back.bit
        with open("read_back.bit", "wb") as fp:
            fp.write(flash.read_chip())

        # Do a verification check
        with open(filename, "rb") as f1, open("read_back.bit", "rb") as f2:
            file1_contents = f1.read()
            file2_contents = f2.read()
            if file1_contents == file2_contents:
                print("Verification OK.")
            else:
                print("Verificatoin failed.")

    elif operation == 'read':
        # Read data to filename
        with open(filename, "wb") as fp:
            fp.write(flash.read_chip())
    else:
        print ("unknown operation")

