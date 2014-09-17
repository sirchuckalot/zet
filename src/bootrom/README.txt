New 8086 boot process

Disable interrupts

Init hpdmc

Call bootrom_copy

Call bootrom_init

Jump post


Low level pragma


Call Init memory devices
	Init hpdmc controller

Call init text mode video

	
Call check bypass mode enabled
	Check to see if bypass mode enabled
	If not enabled set carry flag and jump to end of check bypass mode
	Display bypass mode enabled
	Display waiting on serial com port
	Copy serial com port to ram
	Check if valid bios rom loaded
		Look for correct checksum
		Look for valid bios rom signatures
	If valid bios did not pass set carry flag and jump to end bypass mode
	Display valid bios from received
	Display erasing spi serial eeprom address
	Write valid bios rom to spi serial memory	
	
	end bypass mode:
		return status

Call load bios spi eeprom
	Check to see if valid boot rom exists
		Look for correct checksum
		Look for valid bios rom signatures
	If not valid boot rom set carry flag and jump to end of load bios spi rom
	Display found boot rom on spi eeprom
	Copy valid boot rom from spi eeprom
	
	end load bios spi rom:
		return status
	
If successful pass control over to post
	
Call load bios sd card
	Check to see if valid boot rom exists
		Display found boot rom on sd card
	Load valid boot rom from sd card
	
If successful pass control over to post
	
Call load bios serial com port
	Check to see if valid boot rom exists
		Display found boot rom on serial com port
	Load valid boot rom from serial com port
	
If successful pass control over to post startup

	
	
Execute post from loaded bios rom

Assembly routines
	Disable interrupts
	Call init memory devices
		Init hpdmc controller
	Call load bios from spi eeprom
	
	
Pass control over to

Relocated bootstrap code to ram memory 1000
Jump to ram memory 1000

Call init sd controller
Load first sector to Segment 
Retrieve BIOS BOO
bpb
Load sd card boot sector to 
Call load file Load zetbios.rom to f000 segment
Load vgabios.rom to e000 segment

Execute

Check if write bios to sd card button has been pressed
	Fall back mode has been enabled if button has been pressed
		If button has not been pressed, then jump to load bios from flash memory
	Display "Erasing flash memory..."
	Erase flash memory
	Display "Now send bios image, waiting on RS232... 115200bps"
	Wait until first byte received
	Display "Receiving new bios image..."
	While bytes to receive
		Write byte to flash
		Calculate next flash address
		Receive next byte


+++++++++++++++++++++++++
New 8086 boot process

Disable interrupts

Init hpdmc controller

Check if write bios to sd card button has been pressed
	Fall back mode has been enabled if button has been pressed
		If button has not been pressed, then jump to load bios from flash memory
	Display "Erasing flash memory..."
	Erase flash memory
	Display "Now send bios image, waiting on RS232... 115200bps"
	Wait until first byte received
	Display "Receiving new bios image..."
	While bytes to receive
		Write byte to flash
		Calculate next flash address
		Receive next byte

Try loading bios from flash memory port
	Copy byte from flash
	Store byte into sdram
	Loop until all bytes have been received

	Check for a valid flash memory bios magic string
		Compare first two bytes at offset 0 for magic string "eN"
		If magic string is not equal, then jump to Init sd card controller
		Compare last two bytes at offset 2 for magic string "tx"
		If magic string is equal, then jump to BIOSOK
	
Try loading bios from sd card
	Init sd card controller
		Init PIC
		Call sdinit
		If returned size in ax is 0, then jump to RS232 port

	Calculate starting sector of bios
		Total BIOS bytes = Total BIOS Sectors * 512 bytes
		Store DX:AX starting sector
		Store DS:BX buffer to read into
		Store CX number of sectors to read	

	Nextsector:
		Call SDREAD
			Parameters DX:AX sector, DS:BX buffer, returns CX = # of sectors read
		If cx is not 1, then jump RS232 port
		Calculate next sector to read
		Calculate next offset to load sector
		Loop Nextsector until last sector
	
	Check for a valid sd card loaded bios magic string
		Compare first two bytes at offset 0 for magic string "eN"
		If magic string is not equal, then jump to RS232 port
		Compare last two bytes at offset 2 for magic string "tx"
		If magic string is equal, then jump to BIOSOK

Load code from serial port
RS232:
	Display "BIOS not present on SDCard last 8KB, waiting on RS232 (115200bps, f000:100) ..."
	Set offset si to load into 0100h
	Put total bytes to read into bx
		Receive first byte
		Store into bh
		Receive second byte
		Store into bl
	SREC:
		Call receive serial byte
		Store byte ah at location si
		Increase si
		Decrease bx
		If bx is not zero, then jump to SREC
	Set stack pointer to 0
	Set stack segment to 0
	Execute loaded program
	
BIOSOK:
	Execute copied BIOS code
	
SRECB:
	Receive one byte from serial port
	
SDREAD:
	Read one sector
	
----------------------
Current boot process

Disable interrupts
Init hpdmc controller
Init PIC

Init sd card controller
	Call sdinit
	If returned size in ax is 0, then jump to RS232 port

Calculate starting sector of bios
	Total BIOS bytes = Total BIOS Sectors * 512 bytes
	Store DX:AX starting sector
	Store DS:BX buffer to read into
	Store CX number of sectors to read	

Nextsector:
	Call SDREAD
		Parameters DX:AX sector, DS:BX buffer, returns CX = # of sectors read
	If cx is not 1, then jump RS232 port
	Calculate next sector to read
	Calculate next offset to load sector
	Loop Nextsector until last sector
	
Check for a valid sd card loaded bios magic string
	Compare first two bytes at offset 0 for magic string "eN"
	If magic string is not equal, then jump to RS232 port
	Compare last two bytes at offset 2 for magic string "tx"
	If magic string is equal, then jump to BIOSOK

RS232:
	Display "BIOS not present on SDCard last 8KB, waiting on RS232 (115200bps, f000:100) ..."
	Set offset si to load into 0100h
	Put total bytes to read into bx
		Receive first byte
		Store into bh
		Receive second byte
		Store into bl
	SREC:
		Call receive serial byte
		Store byte ah at location si
		Increase si
		Decrease bx
		If bx is not zero, then jump to SREC
	Set stack pointer to 0
	Set stack segment to 0
	Execute loaded program
	
BIOSOK:
	Execute copied BIOS code
	
SRECB:
	Receive one byte from serial port
	
SDREAD:
	Read one sector




Jump to bootstrap loader


Bootstrap protocol:
Magic string "boot"
Segment memory location - 16 bit
Offset memory location - 16 bit
Total bytes to copy - 16 bit
Payload



; Start of assembly code file for payload loader:

; This is the magic string the bootstrap loader is looking for
BOOTSTRAP_HEADER_STRING equ "boot"

; This is the segment and offset that the boot code will be loaded into
BOOTSEGMENT             equ 0f000h
BOOTOFFSET              equ 00000h

STARTOFBOOTHEADER:      org    00000h

; This the assembled bootstrap header for the code file
BOOTSTRAP_STRING:       db     BOOTSTRAP_HEADER_STRING
                        dw     BOOTSEGMENT, BOOTOFFSET
                        dw     ENDOFBOOTCODE
                        db     0,0,0,0,0
                        
; Assembly code can start at this offset
STARTOFBOOTCODE:        org    STARTOFBOOTCODE    ;; Absolute offset location 00010h
                        nop                       ;; Do nothing as this is only a template
                        jmp    STARTOFBOOTCODE
ENDOFBOOTCODE:

payloadheader:
		db		0eah
		dw		BOOTOFFSET, 0f000h
		db		0,0,0,0,0,0,0,0,0,0,0
0000 Magic string "

BIOS_BUILD_DATE         equ     "09/09/10\n"
MSG2:                   db      BIOS_BUILD_DATE

----------------------------------------------------------------------------
   README FILE FOR BOOTSTRAP ROM FOR ZET BUILD MAKE  08-16-2014
----------------------------------------------------------------------------
This readme file explains the steps needed to build and install the bootstrap
ROM for Zet SoC.

Supported bootstrap modes:
         - Load code into ram from serial port when boot fails
         - Boot from onboard spi serial 

Pre-requisites:
         - Openwatcom compiler and assembler installed on your PC
         - a fpga board with serial port
         - the bootstrap distro for Zet



Step 1.  Make a sub-directory and load the DE0 bios package into that folder.
         Open a console window and type wmake. This should make the bios for you.
         There will be a number of warning messages, this is normal, you can
         ignore those. If an error occurs the make will break.

Step 2.  There should be a file "bootrom.dat" this is the shadow bios boot
         ROM. You are going to need to copy that file into the rtl folder of
         Zet and build zet in Quartus. This file will be included into a ROM
         instantiated in the FPGA. Rename the file to whatever the file name
         is that you are using in the bootrom.v module (the default is
         "biosrom.dat" but you can make it what ever you want). This is the
         little section of code that sits up at the top end of memory that
         will copy the main BIOS into SDRAM.

Step 3.  Find the DE0_ControlPanel.exe program that was loaded from the
         CDROM that came with your DE0 board.

Step 4.  Plug in and power on your board to the USB port on your computer
         and run the program. It should load up OK. If not, you will need
         to debug that with Terasic.

Step 5.  Find the file "bios_de0.hex" this is the HEX version of the Main BIOS
         that will be loaded into the flash ram on the DE0 board. Go to the
         "Memory" tab, and select FLASH (10000h) from the drop down
         menu. Then Click on Memory Erase. It will take a minute to erase
         the flash.

Step 6.  Now click on the check box that says "File Length", then click on the
         button that says "Write a file to memory". In the file selection
         dialog, select the file "bios_de0.hex". It will take a minute or so
         to load the file into Flash.

Step 7.  Your board should now have it's bios loaded into flash. Now you will
         need to start Quartus. If all went well, it should boot up. It should
         first jump to that little 256 byte bootstrap loader that is in
         "bootrom.dat". That code will then copy the main BIOS from Flash
         into SDRAM in the right location and then jump to it.

         If all goes well at this point, the BIOS is running in SDRAM all
         except for the top 256 bytes which is running in FGPA ROM.


Note:    For the Floppy Disk, you just need to take the floppy image file you
         have and run it through the hexer.exe program to make the hex version
         of it and then go into the DE0_ControlPanel.exe and load it starting
         at 0x010000.


----------------------------------------------------------------------------
   README FILE FOR ZET SHADOW BIOS FOR DE0 BUILD MAKE  09-14-2010
----------------------------------------------------------------------------
This readme file explains the steps needed to build and install the Shadow
BIOS for the Terasic DE0 board.

Pre-requisites:
         - Openwatcom compiler and assembler installed on your PC
         - a working Terasic DE0 board
         - the DE0 distro for Zet

Step 1.  Make a sub-directory and load the DE0 bios package into that folder.
         Open a console window and type wmake. This should make the bios for you.
         There will be a number of warning messages, this is normal, you can
         ignore those. If an error occurs the make will break.

Step 2.  There should be a file "bootrom.dat" this is the shadow bios boot
         ROM. You are going to need to copy that file into the rtl folder of
         Zet and build zet in Quartus. This file will be included into a ROM
         instantiated in the FPGA. Rename the file to whatever the file name
         is that you are using in the bootrom.v module (the default is
         "biosrom.dat" but you can make it what ever you want). This is the
         little section of code that sits up at the top end of memory that
         will copy the main BIOS into SDRAM.

Step 3.  Find the DE0_ControlPanel.exe program that was loaded from the
         CDROM that came with your DE0 board.

Step 4.  Plug in and power on your board to the USB port on your computer
         and run the program. It should load up OK. If not, you will need
         to debug that with Terasic.

Step 5.  Find the file "bios_de0.hex" this is the HEX version of the Main BIOS
         that will be loaded into the flash ram on the DE0 board. Go to the
         "Memory" tab, and select FLASH (10000h) from the drop down
         menu. Then Click on Memory Erase. It will take a minute to erase
         the flash.

Step 6.  Now click on the check box that says "File Length", then click on the
         button that says "Write a file to memory". In the file selection
         dialog, select the file "bios_de0.hex". It will take a minute or so
         to load the file into Flash.

Step 7.  Your board should now have it's bios loaded into flash. Now you will
         need to start Quartus. If all went well, it should boot up. It should
         first jump to that little 256 byte bootstrap loader that is in
         "bootrom.dat". That code will then copy the main BIOS from Flash
         into SDRAM in the right location and then jump to it.

         If all goes well at this point, the BIOS is running in SDRAM all
         except for the top 256 bytes which is running in FGPA ROM.


Note:    For the Floppy Disk, you just need to take the floppy image file you
         have and run it through the hexer.exe program to make the hex version
         of it and then go into the DE0_ControlPanel.exe and load it starting
         at 0x010000.
