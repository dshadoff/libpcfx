/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff  <GitHub ID: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*****************************************************************************
 *  Backup memory (internal and external) support                            *
 *                                                                           *
 * NOTE:                                                                     *
 * -----                                                                     *
 * These functions only provide direct access to the backup memory on        *
 * the machine, and do not implement any measure for accessing the           *
 * files themselves (which are in FAT format).                               *
 *                                                                           *
 * Furthermore, the PC-FXGA does NOT implement backup memory through         *
 * the same means, so these functions will have no effect on a               *
 * PC-FXGA.                                                                  *
 *                                                                           *
 * As such, these functions are NOT RECOMMENDED for general use.             *
 *                                                                           *
 * The FX BIOS implements correct file management measures which             *
 * will work across both machines, and work at a filesystem level.           *
 *                                                                           *
 * A 'C' language interface to these functions will be implemented           *
 * as part of libpcfx in the near future, as "filesys.h". As this            *
 * interface has some complexities, there will be several examples           *
 * in order to demonstrate how to use the functions                          *
 *****************************************************************************/

	.global	_bkupmem_set_access
	.global	_bkupmem_read
	.global	_bkupmem_write

/*-------------------------------------------------------*
 * void bkupmem_set_access(int internal, int external)   *
 *                                                       *
 * inputs:                                               *
 *  r6 = internal: Allow write to internal backup memory *
 *  r7 = external: Allow write to external backup memory *
 *-------------------------------------------------------*/
_bkupmem_set_access:
	shl	1, r7
	or	r7, r6
	out.h	r6, 0xC80[r0]
	jmp	[lp]

/*---------------------------------------------------------*
 * void bkupmem_read(int ext, u8 *buf, u32 addr, u32 len)  *
 *                                                         *
 * inputs:                                                 *
 *  r6 = ext:  1 = read external mem. 0 = internal mem.    *
 *  r7 = buf:  Buffer to store the data.                   *
 *  r8 = addr: Address to start reading from               *
 *  r9 = len:  Bytes to read                               *
 *---------------------------------------------------------*/
_bkupmem_read:
	shl	27, r6
	movhi	0xE000, r6, r6
	shl	1, r8
	shl	1, r9
	add	r6, r8
	add	r8, r9
	mov	-2, r10
	and	r10, r9
	and	r10, r8
1:	ld.h	0[r8], r10
	st.b	r10, 0[r7]
	add	2, r8
	add	1, r7
	cmp	r8, r9
	bne	1b
	jmp	[lp]

/*---------------------------------------------------------*
 * void bkupmem_write(int ext, u8 *buf, u32 addr, u32 len) *
 *                                                         *
 * inputs:                                                 *
 *  r6 = ext:  1 = write external mem. 0 = internal mem.   *
 *  r7 = buf:  Buffer holding the data.                    *
 *  r8 = addr: Address to start writing to                 *
 *  r9 = len:  Bytes to write                              *
 *---------------------------------------------------------*/
_bkupmem_write:
	shl	27, r6
	movea	0xFF, r0, r11
	movhi	0xE000, r6, r6
	shl	1, r8
	shl	1, r9
	add	r6, r8
	add	r8, r9
	mov	-2, r10
	and	r10, r9
	and	r10, r8
1:	ld.b	0[r7], r10
	and	r11, r10
	st.h	r10, 0[r8]
	add	2, r8
	add	1, r7
	cmp	r8, r9
	bne	1b
	jmp	[lp]


