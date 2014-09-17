; This file is part of the Next186 SoC PC project
; http://opencores.org/project,next186

; Filename: bootstrap.asm
; Description: Part of the Next186 SoC PC project, bootstrap "ROM" code (RAM initialized with cache)
; Version 1.0
; Creation date: Jun2013

; Author: Nicolae Dumitrache 
; e-mail: ndumitrache@opencores.org

; -------------------------------------------------------------------------------------
 
; Copyright (C) 2013 Nicolae Dumitrache
 
; This source file may be used and distributed without 
; restriction provided that this copyright statement is not 
; removed from the file and that any derivative work contains 
; the original copyright notice and the associated disclaimer.
 
; This source file is free software; you can redistribute it 
; and/or modify it under the terms of the GNU Lesser General 
; Public License as published by the Free Software Foundation;
; either version 2.1 of the License, or (at your option) any 
; later version. 
 
; This source is distributed in the hope that it will be 
; useful, but WITHOUT ANY WARRANTY; without even the implied 
; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
; PURPOSE. See the GNU Lesser General Public License for more 
; details. 
 
; You should have received a copy of the GNU Lesser General 
; Public License along with this source; if not, download it 
; from http://www.opencores.org/lgpl.shtml 
 
; -----------------------------------------------------------------------

; Additional Comments: 
; Assembled with MASM v6.14.8444
; No hardware resources are required for the bootstrap ROM, I use only the initial value of the cache memory
; BIOS will be read from the last BIOSSIZE sectors of SD Card and placed in DRAM at F000:(-BIOSSIZE*512)
; SD HC card required

; Changelog:
;   16 Aug, 2014 - Charley:
;       Converted over to openwatcom v1.9
;       Added Shadow Boot Section

;;---------------------------------------------------------------------------
;; Flash RAM IO Definition
;;---------------------------------------------------------------------------
FLASH_PORT              equ     0x0238      ;; Flash RAM port

;;---------------------------------------------------------------------------
;; SD CARD IO Definition
;;--------------------------------------------------------------------------
IO_SDCARD               equ     0x0100      ;; SD Card IO port

;;--------------------------------------------------------------------------
;;--------------------------------------------------------------------------
                        .Model  Tiny    ;; this forces it to nears on code and data
                        .8086           ;; this forces it to use 80186 and lower
_BOOTSTRAPSEG           SEGMENT 'CODE'
                        assume  cs:_BOOTSTRAPSEG
bootrom:                org     0f800h           ;; start of ROM, get placed at 0E000h
                        
;;--------------------------------------------------------------------------
;;---------------------------------------------------------------------------
;;
;; S H A D O W      B O O T      S E C T I O N:
;;
;; This is the only section of the bios that will reside in the ROM. The rest
;; of the BIOS is loaded into DRAM by this section of code prior to POST.
;;--------------------------------------------------------------------------
;;---------------------------------------------------------------------------

;; BIOS Strings: These strings are not actually used for anything, they are
;; placed in the file so that the binary file can be identified later.
;                        org     0f800h          ; This is 2KB bootstrap rom

BIOS_COPYRIGHT_STRING   equ     "Zet Bios 1.1 (C) 2010 Zeus Gomez Marmolejo, Donna Polehn"
MSG1:                   db      BIOS_COPYRIGHT_STRING
                        db      0

;;--------------------------------------------------------------------------
;; First we have to prepare DRAM for use:
;;--------------------------------------------------------------------------
SDRAM_POST:             xor     ax, ax          ; Clear AX register
                        cli                     ; Disable interupt for startup

                        mov     dx, 0f200h      ; CSR_HPDMC_SYSTEM = HPDMC_SYSTEM_BYPASS|HPDMC_SYSTEM_RESET|HPDMC_SYSTEM_CKE;
                        mov     ax, 7           ; Bring CKE high
                        out     dx, ax          ; Initialize the SDRAM controller
                        mov     dx, 0f202h      ; Precharge All
                        mov     ax, 0400bh      ; CSR_HPDMC_BYPASS = 0x400B;
                        out     dx, ax          ; Output the word of data to the SDRAM Controller
                        mov     ax, 0000dh      ; CSR_HPDMC_BYPASS = 0xD;
                        out     dx, ax          ; Auto refresh
                        mov     ax, 0000dh      ; CSR_HPDMC_BYPASS = 0xD;
                        out     dx, ax          ; Auto refresh
                        mov     ax, 023fh       ; CSR_HPDMC_BYPASS = 0x23F;
                        out     dx, ax          ; Load Mode Register, Enable DLL
                        mov     cx, 50          ; Wait about 200 cycles
a_delay:                loop    a_delay         ; Loop until 50 goes to zero
                        mov     dx, 0f200h      ; CSR_HPDMC_SYSTEM = HPDMC_SYSTEM_CKE;
                        mov     ax, 4           ; Leave Bypass mode and bring up hardware controller
                        out     dx, ax          ; Output the word of data to the SDRAM Controller

                        mov     ax, 0fffeh      ; We are done with the controller, we can use the memory now
                        mov     sp, ax          ; set the stack pointer to fffe (top)
                        xor     ax, ax          ; clear ax register
                        mov     ds, ax          ; set data segment to 0
                        mov     ss, ax          ; set stack segment to 0

;;---------------------------------------------------------------------------
;; Copy Shadow BIOS from Flash into SDRAM after SDRAM has been initialized
;;---------------------------------------------------------------------------
VGABIOSSEGMENT          equ     0xC000                  ;; VGA BIOS Segment
VGABIOSLENGTH           equ     0x4000                  ;; Length of VGA Bios in Words
ROMBIOSSEGMENT          equ     0xF000                  ;; ROM BIOS Segment
ROMBIOSLENGTH           equ     0x7F80                  ;; Copy up to this ROM in Words

;;--------------------------------------------------------------------------
shadowcopy:             mov     ax, VGABIOSSEGMENT      ;; Load with the segment of the vga bios rom area
                        mov     es, ax                  ;; BIOS area segment
                        xor     bp, bp                  ;; Bios starts at offset address 0
                        mov     cx, VGABIOSLENGTH       ;; VGA Bios is <32K long
                        mov     dx, FLASH_PORT+2        ;; Set DX reg to FLASH IO port
                        mov     ax, 0x0000              ;; Load MSB address
                        out     dx, ax                  ;; Save MSB address word
                        mov     bx, 0x0000              ;; Bios starts at offset address 0
                        call    biosloop                ;; Call bios IO loop

;;--------------------------------------------------------------------------
                        mov     ax, ROMBIOSSEGMENT      ;; Load with the segment of the extra bios rom area
                        mov     es, ax                  ;; BIOS area segment
                        xor     bp, bp                  ;; Bios starts at offset address 0
                        mov     cx, ROMBIOSLENGTH       ;; Bios is 64K long - Showdow rom len
                        mov     dx, FLASH_PORT+2        ;; Set DX reg to FLASH IO port
                        mov     ax, 0x0000              ;; Load start address
                        out     dx, ax                  ;; Save MSB address word
                        mov     bx, 0x8000              ;; Bios starts at offset address 0x8000
                        call    biosloop                ;; Call bios IO loop
                        
;;---------------------------------------------------------------------------
;; Now bios has been copied to sdram, we should check for valid magic string
;;---------------------------------------------------------------------------

                        mov     ax, 0f000h              ;; Look for string in 0f000h segment
                        mov     ds, ax
                        cmp		word ptr ds:[0], 'eN'
		                jne		short BOOTSTRAP         ;; Magic string not recognized    
		                cmp		word ptr ds:[2], 'tx'
		                je		BIOSOK                  ;; We verified correct string to present

                        jmp     short BOOTSTRAP         ;; Magic string not recognized

;;--------------------------------------------------------------------------
biosloop:               mov     ax, bx                  ;; Put bx into ax
                        mov     dx, FLASH_PORT          ;; Set DX reg to FLASH IO port
                        out     dx, ax                  ;; Save LSB address word
                        mov     dx, FLASH_PORT          ;; Set DX reg to FLASH IO port
                        in      ax, dx                  ;; Get input word into ax register
                        mov     word ptr es:[bp], ax    ;; Save that word to next place in RAM
                        inc     bp                      ;; Increment to next address location
                        inc     bp                      ;; Increment to next address location
                        inc     bx                      ;; Increment to next flash address location
                        loop    biosloop                ;; Loop until bios is loaded up
                        ret                             ;; Return
;;--------------------------------------------------------------------------

;;---------------------------------------------------------------------------
;; Try loading bios from sd card
;;---------------------------------------------------------------------------
; Loads BIOS (128K = 256 sectors) from last sectors of SD card (if present)
; If no SD card detected, wait on RS232 115200bps and load program at F000:100h
; Also note the bootstrap code is write protected and it will not be overwritten!!
; ----------------- RS232 bootstrap ---------------

BIOSSIZE                EQU     256                     ; sectors
BOOTOFFSET              EQU     0f800h                  ; bootstrap code offset in segment 0f000h

BOOTSTRAP:		        cli
		                cld
		                mov		ax, cs        ; cs = 0f000h
		                mov		ds, ax
		                mov		es, ax
		                mov		ss, ax
		                mov		sp, BOOTOFFSET
		                xor		ax, ax        ; map seg0
		                out		80h, ax
		                mov		al, 0bh       ; map text segB
		                out		8bh, ax
		                mov		al, 0fh       ; map ROM segF
		                out		8fh, ax
		                mov		al, 34h
		                out		43h, al
		                xor		al, al
		                out		40h, al
		                out		40h, al       ; program PIT for RS232

		                call		sdinit_
		                test		ax, ax
		                jz		short RS232
		                mov		dx, ax
		                ; FIX ME shr		dx, 6
		                ; FIX ME shl		ax, 10
		                mov		cx, BIOSSIZE       ;  sectors
		                sub		ax, cx
		                sbb		dx, 0
		                xor		bx, bx       ; read BIOSSIZE/2 KB BIOS at 0f000h:0h
nextsect:      
		                push		ax
		                push		dx
		                push		cx
		                call		sdread_
		                dec		cx
		                pop		cx
		                pop		dx
		                pop		ax
		                jnz		short RS232  ; cx was not 1
		                add		ax, 1
		                adc		dx, 0
		                add		bx, 512    
		                loop		nextsect
		                cmp		word ptr ds:[0], 'eN'
		                jne		short RS232             
		                cmp		word ptr ds:[2], 'tx'
		                je		BIOSOK

RS232: 
		                mov		dx, 3c0h
		                mov		al, 10h
		                out		dx, al
		                mov		al, 8h
		                out		dx, al      ; set text mode
		                mov		dx, 3d4h
		                mov		al, 0ah
		                out		dx, al
		                inc		dx
		                mov		al, 1 shl 5 ; hide cursor
		                out		dx, al
		                dec		dx
		                mov		al, 0ch
		                out		dx, al
		                inc		dx
		                mov		al, 0
		                out		dx, al
		                dec		dx
		                mov		al, 0dh
		                out		dx, al
		                inc		dx
		                mov		al, 0
		                out		dx, al      ; reset video offset
      
		                ; FIX ME push		0b800h      ; clear screen
		                pop		es
		                xor		di, di
		                mov		cx, 25*80
		                xor		ax, ax
		                rep		stosw
		
		                mov		dx, 3c8h    ; set palette entry 1
		                mov		ax, 101h
		                out		dx, al
		                inc		dx
		                mov		al, 2ah
		                out		dx, al
		                out		dx, al
		                out		dx, al
		
		                xor		di, di      
		                mov		si, booterrmsg + BOOTOFFSET - begin
		                lodsb
nextchar:      
		                stosw
		                lodsb
		                test		al, al
		                jnz		short nextchar

		                mov		bh, 8
flush:        
		                mov		al, [bx]
		                dec		bh
		                jnz		flush
	
		                mov		si, 100h
		                call		srecb
		                mov		bh, ah
		                call		srecb
		                mov		bl, ah

sloop:	
		                call		srecb
		                mov		[si], ah
		                inc		si
		                dec		bx
		                jnz		sloop
		                xor		sp, sp
		                mov		ss, sp
		                db		0eah
		                dw		100h,0f000h ; execute loaded program
	
;; THIS NEEEDDDDDDDDDD TO BE FIXED
BIOSOK:
post:                   jmp far ptr post
;		                mov		si, reloc + BOOTOFFSET - begin
;		                mov		di, bx
;		                mov		cx, endreloc - reloc
;		                rep		movsb       ; relocate code from reloc to endreloc after loaded BIOS
;		                mov		di, -BIOSSIZE*512
;		                xor		si, si
;		                mov		cx, BIOSSIZE*512/2
;		                jmp		bx
;reloc:      
;		                rep		movsw
;		                db		0eah
;		                dw		0, -1       ; CPU reset, execute BIOS
;endreloc:
      

; ----------------  serial receive byte 115200 bps --------------
srecb:  
		                mov		ah, 80h
		                mov		dx, 3dah
		                mov		cx, -5aeh ; (half start bit)
srstb:  
		                in		al, dx
		                ; FIX ME shr		al, 2
		                jc		srstb

		                in		al, 40h ; lo counter
		                add		ch, al
		                in		al, 40h ; hi counter, ignore
l1:
		                call		dlybit
		                in		al, dx
		                ; FIX ME shr		al, 2
		                rcr		ah, 1
		                jnc		l1
dlybit:
		                sub		cx, 0a5bh  ;  (full bit)
dly1:
		                in		al, 40h
		                cmp		al, ch
		                in		al, 40h
		                jnz		dly1
		                ret

;---------------------  read/write byte ----------------------
sdrb:   
		                mov		al, 0ffh
sdsb:               ; in AL=byte, DX = IO_SDCARD, out AX=result
		                mov		ah, 1
sdsb1:
		                out		dx, al
		                add		ax, ax
		                jnc		sdsb1
		                in		ax, dx
		                ret

;---------------------  write block ----------------------
sdwblk:              ; in DS:SI=data ptr, DX=IO_SDCARD, CX=size
		                lodsb
		                call		sdsb
		                loop		sdwblk
		                ret

;---------------------  read block ----------------------
sdrblk:              ; in DS:DI=data ptr, DX=IO_SDCARD, CX=size
		                call		sdrb
		                mov		[di], ah
		                inc		di
		                loop		sdrblk
		                ret

;---------------------  write command ----------------------
sdcmd8T:
		                call	sdrb
sdcmd:              ; in DS:SI=6 bytes cmd buffer, DX=IO_SDCARD, out AH = 0ffh on error
		                mov		cx, 6
		                call		sdwblk
sdresp:
		                xor		si, si
sdresp1:
		                call		sdrb
		                inc		si
		                jz		sdcmd1
		                cmp		ah, 0ffh
		                je		sdresp1
sdcmd1: 
		                ret         

;---------------------  read one sector ----------------------
sdread_ proc near   ; DX:AX sector, DS:BX buffer, returns CX=read sectors
		                push		ax
		                mov		al, dl
		                push		ax
		                mov		dl, 51h     ; CMD17
		                push		dx
		                mov		si, sp

		                mov		dx, IO_SDCARD
		                mov		ah, 1
		                out		dx, ax      ; CS on
		                call		sdcmd
		                add		sp, 6
		                or		ah, ah
		                jnz		sdr1        ; error (cx=0)
		                call		sdresp      ; wait for 0feh token
		                cmp		ah, 0feh
		                jne		sdr1        ; read token error (cx=0)
		                mov		ch, 2       ; 512 bytes
		                mov		di, bx
		                call		sdrblk
		                call		sdrb        ; ignore CRC
		                call		sdrb        ; ignore CRC
		                inc		cx          ; 1 block
sdr1:       
		                xor		ax, ax
		                out		dx, ax
		                call		sdrb        ; 8T
		                ret     
sdread_ endp
        
;---------------------  init SD ----------------------
sdinit_ proc near       ; returns AX = num kilosectors
		                mov		dx, IO_SDCARD
		                mov		cx, 10
sdinit1:                   ; send 80T
		                call		sdrb
		                loop		sdinit1

		                mov		ah, 1
		                out		dx, ax       ; select SD

		                mov		si, SD_CMD0 + BOOTOFFSET - begin
		                call		sdcmd
		                dec		ah
		                jnz		sdexit      ; error
		
		                mov		si, SD_CMD8 + BOOTOFFSET - begin
		                call		sdcmd8T
		                dec		ah
		                jnz		sdexit      ; error
		                mov		cl, 4
		                sub		sp, cx
		                mov		di, sp
		                call		sdrblk
		                pop		ax
		                pop		ax
		                cmp		ah, 0aah
		                jne		sdexit      ; CMD8 error
repinit:        
		                mov		si, SD_CMD55 + BOOTOFFSET - begin
		                call		sdcmd8T
		                call		sdrb
		                mov		si, SD_CMD41 + BOOTOFFSET - begin
		                call		sdcmd
		                dec		ah
		                jz		repinit
		
		                mov		si, SD_CMD58 + BOOTOFFSET - begin
		                call		sdcmd8T
		                mov		cl, 4
		                sub		sp, cx
		                mov		di, sp
		                call		sdrblk
		                pop		ax
		                test		al, 40h     ; test OCR bit 30 (CCS)
		                pop		ax
		                jz		sdexit      ; no SDHC

		                mov		si, SD_CMD9 + BOOTOFFSET - begin ; get size info
		                call		sdcmd8T
		                or		ah, ah
		                jnz		sdexit
		                call		sdresp      ; wait for 0feh token
		                cmp		ah, 0feh
		                jne		sdexit
		                mov		cl, 18      ; 16bytes + 2bytes CRC
		                sub		sp, cx
		                mov		di, sp
		                call		sdrblk
		                mov		cx, [di-10]
		                xchg		cl, ch
		                inc		cx
		                mov		sp, di
sdexit: 
		                xor		ax, ax      ; raise CS
		                out		dx, ax
		                call	sdrb
		                mov		ax, cx       
		                ret
sdinit_ endp

    
booterrmsg              db      'BIOS not present on SDCard last 8KB, waiting on RS232 (115200bps, f000:100) ...', 0
SD_CMD0		            db		40h, 0, 0, 0, 0, 95h
SD_CMD8		            db		48h, 0, 0, 1, 0aah, 087h
SD_CMD9		            db		49h, 0, 0, 0, 0, 0ffh
SD_CMD41	            db		69h, 40h, 0, 0, 0, 0ffh
SD_CMD55	            db		77h, 0, 0, 0, 0, 0ffh
SD_CMD58	            db		7ah, 0, 0, 0, 0, 0ffh


;;---------------------------------------------------------------------------
;;--------------------------------------------------------------------------
;; MAIN BIOS Entry Point:  
;; on Reset - Processor starts at this location. This is the first instruction
;; that gets executed on start up. So we just immediately jump to the entry
;; Point for the Bios which is the POST (which stands for Power On Self Test).
                        org     0fff0h                  ;; Power-up Entry Point
                        jmp     far ptr SDRAM_POST      ;; Boot up bios

                        org     0fff5h                  ;; ASCII Date ROM was built - 8 characters in MM/DD/YY
BIOS_BUILD_DATE         equ     "09/09/10\n"
MSG2:                   db      BIOS_BUILD_DATE

                        org     0fffeh                  ;; Put the SYS_MODEL_ID
SYS_MODEL_ID            equ     0xFC
                        db      SYS_MODEL_ID            ;; here
                        db      0

_BOOTSTRAPSEG           ends                    ;; End of code segment
                        end             bootrom ;; End of this program