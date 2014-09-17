/*---------------------------------------------------------------------------/
/  ZET SoC MMCv3/SDv1/SDv2 (in SPI mode) control module
/  Copyright  (C)  2014 Charley Picker <charleypicker@yahoo.com>
/----------------------------------------------------------------------------/
/
/  Copyright (C) 2013, ChaN, all right reserved.
/
/ * This software is a free software and there is NO WARRANTY.
/ * No restriction on use. You can use, modify and redistribute it for
/   personal, non-profit or commercial products UNDER YOUR RESPONSIBILITY.
/ * Redistributions of source code must retain the above copyright notice.
/
/-------------------------------------------------------------------------/

  Features and Limitations:

  * Re-written for ZET SoC and Intel 8086 processor
  	Simple interface to access the ZET SoC MMC/SD card controller

  * No Media Change Detection
    Application program needs to perform f_mount() after media change.

/-------------------------------------------------------------------------*/

#ifndef _ZETMMC_H
#define _ZETMMC_H

#ifdef __cplusplus
extern "C" {
#endif


/*---------------------------------------------------------*/
/* Prototypes for SoC MMCv3/SDv1/SDv2 Controller functions */


/*-----------------------------------------------------------------------*/
/* Get Disk Status                                                       */
/*-----------------------------------------------------------------------*/
DSTATUS MMC_disk_status (BYTE drv);			/* Drive number (always 0) */

/*-----------------------------------------------------------------------*/
/* Initialize Disk Drive                                                 */
/*-----------------------------------------------------------------------*/
DSTATUS MMC_disk_initialize (BYTE drv);		/* Physical drive nmuber (0) */

/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */
/*-----------------------------------------------------------------------*/
DRESULT MMC_disk_read (
	BYTE drv,			/* Physical drive nmuber (0) */
	BYTE *buff,			/* Pointer to the data buffer to store read data */
	DWORD sector,		/* Start sector number (LBA) */
	UINT count			/* Sector count (1..128) */
);


/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */
/*-----------------------------------------------------------------------*/

DRESULT MMC_disk_write (
	BYTE drv,			/* Physical drive nmuber (0) */
	const BYTE *buff,	/* Pointer to the data to be written */
	DWORD sector,		/* Start sector number (LBA) */
	UINT count			/* Sector count (1..128) */
);


/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */
/*-----------------------------------------------------------------------*/

DRESULT MMC_disk_ioctl (
	BYTE drv,		/* Physical drive nmuber (0) */
	BYTE ctrl,		/* Control code */
	void *buff		/* Buffer to send/receive control data */
);


#ifdef __cplusplus
}
#endif

#endif

