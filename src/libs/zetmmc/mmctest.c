/*
 *  This is to test the functionality of the low level zetmmc.c library
 *  Copyright (C) 2014  Charley Picker <charleypicker@yahoo.com>
 *
 *  This file is part of the Zet processor. This processor is free
 *  hardware; you can redistribute it and/or modify it under the terms of
 *  the GNU General Public License as published by the Free Software
 *  Foundation; either version 3, or (at your option) any later version.
 *
 *  Zet is distrubuted in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
 *  License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Zet; see the file COPYING. If not, see
 *  <http://www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdlib.h>

#include "diskio.h"
#include "zetmmc.h"

DSTATUS dstatus;
DRESULT dresult;

BYTE *buff[512];

int main(int argc, char* argv[])
{
  // Initialize mmc disk drive for read/write access
  printf("Attempting to initialize the MMC card interface...\n");
  
  dstatus = MMC_disk_initialize(0);
  
  if (dstatus == 0)
  	printf("MMC Card Successfully initialized");
  if (dstatus == 1)
   printf("MMC Drive not initialized");
  if (dstatus == 3)
  	printf("MMC Write protected");
  	
  printf("\n"); // new line
  
  // Attempt to read one sector from MMC card
  
  printf("Attempting to reading drive 0, store into buff, sector 0, sector count 1... \n");
  
  // Read drive 0, store into buff, sector 0, sector count 1
  dresult = MMC_disk_read(0, buff, 0, 1);
  
  if (dresult == RES_OK)
	printf("Successful!\n");
  if (dresult == RES_ERROR)
	printf("R/W Error\n");
  if (dresult == RES_WRPRT)
  	printf("Write Protected\n");
  if (dresult == RES_NOTRDY)
  	printf("Not Ready\n");
  if (dresult == RES_PARERR)
  	printf("Invalid Parameter\n");
  	
  return 0;
  	
}
