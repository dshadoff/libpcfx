/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX

                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2025              Dave Shadoff  <GitHub ID: dshadoff>


# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*****************************************************************************
 *  Named values (no 'magic numbers' please)                                 *
 *****************************************************************************/
.equiv KING_reg,		0x600	/* KING address register (write) */
.equiv KING_stat,		0x600	/* KING status register (read) */
.equiv KING_stat_l,		0x600	/* status (low halfword) */
.equiv KING_stat_h,		0x602	/* status (high halfword) */
.equiv KING_data,		0x604	/* KING data register (read/write) */
.equiv KING_data_l,		0x604	/* data (low halfword) */
.equiv KING_data_h,		0x606	/* data (high halfword) */

.equiv SCSIREG_DATA,		0x0	/* SCSI Data Register number */
.equiv SCSIREG_INITCMD,		0x1	/* SCSI Initiator Command Register number */
.equiv SCSIREG_TARGCMD,		0x3	/* SCSI Target Commmand Register number */

/* Bitfields associated with SCSI Status (HIGH WORD) */
.equiv SCSISTAT_SEL,		0x2	/* Bit associated with SEL (select) line */
.equiv SCSISTAT_IO,		0x4	/* Bit associated with I/O line */
.equiv SCSISTAT_CD,		0x8	/* Bit associated with CMD (command) line */
.equiv SCSISTAT_MSG,		0x10	/* Bit associated with MSG (message) line */
.equiv SCSISTAT_REQ,		0x20	/* Bit associated with REQ (request) line */
.equiv SCSISTAT_BSY,		0x40	/* Bit associated with BSY (busy) line */
.equiv SCSISTAT_RESET,		0x80	/* Bit associated with RST (reset) line */

/* Bitfields associated with SCSI Register 1 (Initiator Command) */
.equiv INITCMD_DEASSERT,	 0x0	/* No bits asserted */
.equiv INITCMD_ASSERT_DATA,	 0x1	/* Bit to assert value in DATA register onto SCSI bus */
.equiv INITCMD_ASSERT_ATN,	 0x2	/* Bit to assert ATN (attention) signal onto SCSI bus */
.equiv INITCMD_ASSERT_SEL,	 0x4	/* Bit to assert SEL (select) signal onto SCSI bus */
.equiv INITCMD_ASSERT_ACK,	 0x10	/* Bit to assert ACK (acknowledge) signal onto SCSI bus */
.equiv INITCMD_ASSERT_RESET,	 0x80	/* Bit to assert RST (reset) signal onto SCSI bus */

/* Bitfields associated with SCSI Register 3 (Target Command) */
.equiv TARGCMD_DEASSERT,	 0x0	/* No bits asserted */
.equiv TARGCMD_IO,		 0x1	/* Bit associated with I/O line */
.equiv TARGCMD_CD,		 0x2	/* Bit associated with CMD (command) line */
.equiv TARGCMD_MSG,		 0x4	/* Bit associated with MSG (message) line */

/* Special constants  */
.equiv TIMEOUT_LOOP,		 0x40000 /* Timeout (loop iterations) during attempt to initiate SCSI command */

/* Special return codes  */
.equiv ERR_TIMEOUT,		 0xFFFE	/* Error - Timeout during attempt to initiate SCSI command */
.equiv ERR_BUS_BUSY,		 0xFFFF	/* Error - Attempt to initiate SCSI command when the bus is already busy */


/*****************************************************************************
 *  Macros                                                                   *
 *****************************************************************************/
/* movw moves a data value into a register
 */
.macro  movw data, reg1
        movhi   hi(\data),r0,\reg1
        movea   lo(\data),\reg1,\reg1
.endm

/* movscsireg_v moves an immediate value into a SCSI register
 */
.macro	movscsireg_v data, scsireg, scratch
	mov	\scsireg, \scratch
	out.h	\scratch, KING_reg[r0]
	movw	\data, \scratch
	out.h	\scratch, KING_data[r0]
.endm

/* movscsireg_r moves a register value into a SCSI register
 */
.macro	movscsireg_r reg, scsireg, scratch
	mov	\scsireg, \scratch
	out.h	\scratch, KING_reg[r0]
	out.h	\reg, KING_data[r0]
.endm

/* getscsireg gets a SCSI register value into a register
 */
.macro	getscsireg scsireg, reg, scratch
	mov	\scsireg, \scratch
	out.h	\scratch, KING_reg[r0]
	in.h	KING_data_l[r0], \reg
.endm

/* getscsistat gets the current status of SCSI into a register
 */
.macro	getscsistat reg
	in.h	KING_stat_h[r0], \reg
.endm

/* delay_2800ns creates a delay of roughly 2.8 microseconds
 */
.macro	delay_2800ns
	mov	8, r10
9:
	add	-1,r10
	bne	9b
.endm

/* scsi_delay is OBSOLETE and creates a massive multi-millisecond delay
 */
.macro scsi_delay
	movhi	4, r0, r10
9:
.rept 8
	mov	r0, r0
.endr
	add	-1, r10
	bne	9b
.endm


/*****************************************************************************
 * HuC6272 (KING) SCSI functions                                             *
 *****************************************************************************/
	.global _scsi_command
	.global _scsi_reset

/* ------ Original Functions - some will need replacement; others, removal ------- */
	.global _eris_scsi_get_phase
	.global _eris_scsi_status
	.global _eris_scsi_reset
	.global _eris_scsi_data_in
	.global _eris_scsi_data_out
	.global _eris_scsi_begin_dma
	.global _eris_scsi_check_dma
	.global _eris_scsi_finish_dma
	.global _eris_scsi_abort
	.global _eris_scsi_command
	.global _eris_scsi_test_unit_ready

	.global	eris_scsi_eat_data_in

/* ------ END Original Function Globals ------- */

.align 4
scsiptrs:		/* a set of pointers to the current location within ieach phase-specific data buffer */
	.word	0	/* dataout */
	.word	0	/* datain */
	.word	0	/* command */
	.word	0	/* status */
	.word	0	/* unused */
	.word	0	/* unused */
	.word	0	/* msgout */
	.word	0	/* msgin */


/*------------------------------------------*
 * void scsi_reset(void)                    *
 *------------------------------------------*/

_scsi_reset:
_eris_scsi_reset:
/*	movea	0x1000, r0, r10  */
	movea	0x0400, r0, r10
	mov	1, r11
/*	mov	SCSIREG_INITCMD, r11 */
	movea	0x80, r0, r12
/*	movea	INITCMD_ASSERT_RESET, r0, r12 */

1:
	out.h	r11, 0x600[r0]			/* select KING reg 1 */
	out.h	r12, 0x604[r0]			/* assert RESET */
/*	out.h	r11, KING_reg_l[r0]	*/		/* select KING reg 1 */
/*	out.h	r12, KING_data_l[r0]	*/		/* assert RESET */
	add	-1, r10				/* 4096 times -> 1024 times */
	bne	1b

	out.h	r11, 0x600[r0]			/* select KING reg 1 */
	out.h	r0, 0x604[r0]			/* deassert lines */
/*	movscsireg_v    INITCMD_DEASSERT, SCSIREG_INITCMD, r16 */
	jmp	[lp]


/*------------------------------------------------------------------------*
 * int scsi_command(int LUN, * phase_counters, * phase_buffers)           *
 *                                                                        *
 *  Sends a command to the SCSI drive                                     *
 *                                                                        *
 * inputs:                                                                *
 *  r6 = LUN (SCSI device number)                                         *
 *  r7 = pointer to array of integers tracking size of the phase buffers  *
 *  r8 = pointer to array of buffer pointers to hold phase data           *
 *                                                                        *
 *  Sequence of phases (as n 'scsiptrs' above):                           *
 *    0:  DATA OUT                                                        *
 *    1:  DATA IN                                                         *
 *    2:  COMMAND                                                         *
 *    3:  STATUS                                                          *
 *    4:  (unused)                                                        *
 *    5:  (unused)                                                        *
 *    6:  MESSAGE OUT                                                     *
 *    7:  MESSAGE IN                                                      *
 *                                                                        *
 * outputs:                                                               *
 *  r10 = status                                                          *
 *------------------------------------------------------------------------*/


_scsi_command:
	mov	r0, r10

/* Initialize size array and array of buffer pointers */
	
	st.w	r0, 0x00[r7]
	st.w	r0, 0x04[r7]
	st.w	r0, 0x08[r7]
	st.w	r0, 0x0C[r7]
	st.w	r0, 0x10[r7]
	st.w	r0, 0x14[r7]
	st.w	r0, 0x18[r7]
	st.w	r0, 0x1C[r7]

	movw	scsiptrs, r18
	ld.w	0x00[r8], r16
	st.w	r16, 0x00[r18]
	ld.w	0x04[r8], r16
	st.w	r16, 0x04[r18]
	ld.w	0x08[r8], r16
	st.w	r16, 0x08[r18]
	ld.w	0x0C[r8], r16
	st.w	r16, 0x0c[r18]
	ld.w	0x10[r8], r16
	st.w	r16, 0x10[r18]
	ld.w	0x14[r8], r16
	st.w	r16, 0x14[r18]
	ld.w	0x18[r8], r16
	st.w	r16, 0x18[r18]
	ld.w	0x1C[r8], r16
	st.w	r16, 0x1C[r18]

/* ----- Negotiate connection to CDROM (bus arbitration) ----- */

	movw	ERR_BUS_BUSY, r10
	getscsistat	r11
	andi	SCSISTAT_BSY, r11, r11
	bne	scsicmd_exit						/* return with error if already engaged */

	/* de-assert MSG + CD + IO in TARGET COMMAND register (put '0' in reg 3) */
	movscsireg_v	TARGCMD_DEASSERT, SCSIREG_TARGCMD, r16

	/* Select target device by asserting on databus as part of SELECT signal */
	movw	1, r12
	shl	r6, r12							/* shift bit by LUN # in r6      */
	ori	0x80, r12, r12						/* Ex: r12 will contain  0x84 for LUN 2 */
	movscsireg_r	r12, SCSIREG_DATA, r16				/* Place this value on the data bus */
	movscsireg_v	INITCMD_ASSERT_DATA, SCSIREG_INITCMD, r16	/* assert databus */

	delay_2800ns

	movscsireg_v	(INITCMD_ASSERT_DATA | INITCMD_ASSERT_SEL), SCSIREG_INITCMD, r16	/* now select */


/* TODO: There should be a TIMEOUT limit to this loop */
	movw	TIMEOUT_LOOP, r10
1:	getscsistat	r11
	andi	SCSISTAT_BSY, r11, r11					/* wait for BSY  as repsonse to SEL */
	bne	2f
	add	-1,r10
	bne	1b

	movw	ERR_TIMEOUT, r10
	br	scsicmd_exit						/* return with error if timed out */

2:									/* Connection is formed, so */
	movscsireg_v	INITCMD_DEASSERT, SCSIREG_INITCMD, r16		/* de-assert databus etc. */

/* ----- SCSI Connection is made ----- */

/* Wait for REQ from target device; decide which phase it is accordingly */
/* COMMAND phase will always be the first phase */

waitreq_1:
	getscsistat	r17
	andi	SCSISTAT_BSY, r17, r15		/* r15 is just temp */
	be	bus_closed

/* TODO: check for reset */

	andi	SCSISTAT_REQ, r17, r15		/* r15 is just temp */
	be	waitreq_1			/* loop until request */

	andi	(SCSISTAT_MSG | SCSISTAT_CD | SCSISTAT_IO), r17, r17	/* get SCSI phase */
	mov	r17, r15
	shr	2, r15
	movscsireg_r	r15, SCSIREG_TARGCMD, r16			/* put phase into SCSITARG_REG */

/* calculate phase-based pointers */
	mov	r7, r14
	add	r17, r14			/* phase-based pointer to size of data */

	mov	r18, r13
	add	r17, r13			/* phase-based pointer to data */

	andi	SCSISTAT_IO, r17, r15		/* check the direction of data */
	be	bytetodevice

bytefromdevice:

/* get byte of data */

	delay_2800ns
/* 	getscsireg     SCSIREG_DATA, r11, r16 */
	out.h	r0, 0x600[r0]			/* KING reg 0 (data) */
	in.h	0x604[r0], r11			/* read data */

	ld.w	0[r14], r12			/* get current size and increment */
	add	1, r12
	st.w	r12, 0[r14]

	ld.w	0[r13], r12			/* get data pointer */
	st.b	r11, 0[r12]			/* save data at current data pointer */
	add	1, r12				/* increment data pointer */
	st.w	r12, 0[r13]

	movscsireg_v	INITCMD_ASSERT_ACK, SCSIREG_INITCMD, r16	/* now assert ACK */

3:	getscsistat	r11	
	andi	SCSISTAT_REQ, r11, r11					/* wait for REQ to de-assert */
	bne	3b

	movscsireg_v	INITCMD_DEASSERT, SCSIREG_INITCMD, r16		/* de-assert ACK */

	br	waitreq_1
/* END  bytefromdevice */

bytetodevice:
	ld.w	0[r14], r12			/* get current size and increment */
	add	1, r12
	st.w	r12, 0[r14]

	ld.w	0[r13], r12			/* get data pointer */
	ld.b	0[r12], r11			/* get data byte at data pointer */
	add	1, r12				/* increment data pointer */
	st.w	r12, 0[r13]

	/* data to be sent is in r11 */

	movscsireg_r	r11, SCSIREG_DATA, r16				/* apply byte of (command) data to data bus */
	movscsireg_v	INITCMD_ASSERT_DATA, SCSIREG_INITCMD, r16	/* assert databus */

	delay_2800ns
	movscsireg_v	(INITCMD_ASSERT_DATA | INITCMD_ASSERT_ACK), SCSIREG_INITCMD, r16	/* now assert ACK */

3:	getscsistat	r11	
	andi	SCSISTAT_REQ, r11, r11					/* wait for REQ to de-assert */
	bne	3b


	movscsireg_v	INITCMD_ASSERT_DATA, SCSIREG_INITCMD, r16 	/* assert databus (de-assert ACK) */
	delay_2800ns
	movscsireg_v	INITCMD_DEASSERT, SCSIREG_INITCMD, r16		/* then, e-assert databus (and ACK) */

	br	waitreq_1
/* END  bytetodevice */

bus_closed:
	movscsireg_v	INITCMD_DEASSERT, SCSIREG_INITCMD, r16	/* De-assert initiator control signals */
	movscsireg_v	TARGCMD_DEASSERT, SCSIREG_TARGCMD, r16	/* De-assert target control signals */

	ld.w	0x0C[r8], r16		/* Obtain first byte of STATUS and put in R10 as return code */
	ld.b	0x00[r16], r10

scsicmd_exit:
	jmp	[lp]



/*------------------ OLD CODE BELOW ------------------------*/



/*
 * scsi_phase eris_scsi_get_phase(void);
 * 
 * Returns the current phase of the SCSI drive.
 */
_eris_scsi_get_phase:
	in.h	0x602[r0], r11
/*	getscsistat     r11     */

	mov	0, r10         # Bus Free
	andi	0x40, r11, r12   # BSY
	be	1f
	mov	1, r10         # Select
	andi	0x2, r11, r12    # SEL
	bne	1f
	andi	0x1C, r11, r12   # (MSG + CD + IO -> positive sense)
	mov	2, r10         # Data Out
	cmp	0, r12           # none asserted
	be	1f
	mov	3, r10         # Data In
	cmp	4, r12           # IO, but not MSG or CD
	be	1f
	mov	4, r10         # Command
	cmp	8, r12		 # CD, but not MSG or IO
	be	1f
	mov	5, r10         # Status
	cmp	0xC, r12	 # CD + IO (not MSG)
	be	1f
	movea	0x18, r0, r11	 # MSG + CD (not IO)
	mov	6, r10         # Message Out
	cmp	r11, r12
	be	1f
	add	4, r11		 # MSG + CD + IO all asserted
	mov	7, r10         # Message In
	cmp	r11, r12
	be	1f
	mov	8, r10         # Illegal
1:
	jmp	[lp]

scsi_phase_status_tbl:
	.word	0 # Bus free
	.word	-1 # Select
	.word	-3 # Data Out
	.word	-2 # Data In
	.word	-1 # Command
	.word	1 # Status
	.word	-4 # Message Out
	.word	0 # Message In
	.word	0 # Illegal

/*
 * scsi_status eris_scsi_status(void);
 * 
 * Returns the current state of the SCSI drive.
 */
_eris_scsi_status:
	mov	lp, r15
	jal	_eris_scsi_get_phase
	shl	2, r10
	movea	lo(scsi_phase_status_tbl), r0, r12
	movhi	hi(scsi_phase_status_tbl), r12, r12
	add	r10, r12
	ld.w	0[r12], r10
	cmp	0, r10
	be	1f
	blt	2f

	mov	1, r13
	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r0, 0x604[r0]			/* deassert all lines */
/*	movscsireg_v	INITCMD_DEASSERT, SCSIREG_INITCMD, r16 */

3:	in.h	0x602[r0], r11
/* 3:	getscsistat     r11     */
/*	andi	SCSISTAT_REQ, r11, r11	*/
	andi	0x20, r11, r11			/* wait for assertion of REQ */
	be	3b

	out.h	r0, 0x600[r0]
	in.h	0x604[r0], r10			/* read DATA lines */
/* 	getscsireg     SCSIREG_DATA, r10, r16     */
	andi	0xFFFE, r10, r10		/* WHY remove the lowest bit !??? */

	movea	0x10, r0, r14
	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r14, 0x604[r0]			/* assert ACK */
/*	movscsireg_v	INITCMD_ASSERT_ACK, SCSIREG_INITCMD, r16 */

3:	in.h	0x602[r0], r11
/* 3:	getscsistat     r11     */
/*	andi	SCSISTAT_REQ, r11, r11	*/
	andi	0x20, r11, r11			/* wait for de-assertion of REQ */
	bne	3b

	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r0, 0x604[r0]			/* de-assert ACK */
/*	movscsireg_v	INITCMD_DEASSERT, SCSIREG_INITCMD, r16 */

3:	in.h	0x602[r0], r11
/* 3:	getscsistat     r11     */
/*	andi	SCSISTAT_REQ, r11, r11	*/
	andi	0x20, r11, r11			/* wait for assertion of REQ */
	be	3b

	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r14, 0x604[r0]			/* assert ACK without grabbing data */
/*	movscsireg_v	INITCMD_ASSERT_ACK, SCSIREG_INITCMD, r16 */

3:	in.h	0x602[r0], r11
/* 3:	getscsistat     r11     */
/*	andi	SCSISTAT_REQ, r11, r11	*/
	andi	0x20, r11, r11			/* wait for de-assertion of REQ */
	bne	3b

	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r0, 0x604[r0]			/* deassert all lines */
/*	movscsireg_v	INITCMD_DEASSERT, SCSIREG_INITCMD, r16 */
2:
	mov	r15, lp
	jmp	[lp]

1:
	mov	-5, r10
	mov	r15, lp
	jmp	[lp]


/*
 * u32 eris_scsi_data_in(u8 *buf, u32 maxlen);
 *
 * Read Data from the SCSI drive
 *
 * buf     = Buffer to read into.
 * maxlen  = Maximum length to read from.
 *
 * return  = Bytes read.
 */
_eris_scsi_data_in:
	mov	0, r14
	mov	lp, r15
1:	in.h	0x602[r0], r10
	andi	0x20, r10, r10			/* wait for assertion of REQ */
	be	1b

	br	2f
1:
	mov	1, r10
	movea	0x10, r0, r12
	out.h	r0, 0x600[r0]			/* KING reg 0 (data) */
	in.h	0x604[r0], r11			/* read data */
	st.b	r11, 0[r6]			/* inc pointer */
	add	1, r14
	add	1, r6
	add	-1, r7				/* countdown bytes to read */

	out.h	r10, 0x600[r0]			/* KING reg 1 */
	out.h	r12, 0x604[r0]			/* assert ACK */

3:	in.h	0x602[r0], r11
	andi	0x20, r11, r11			/* wait for de-assertion of REQ */
	bne	3b

	out.h	r10, 0x600[r0]			/* KING reg 1 */
	out.h	r0, 0x604[r0]			/* de-assert ACK */

3:	in.h	0x602[r0], r11
	andi	0x20, r11, r11			/* wait for assertion of REQ */
	be	3b

2:	jal	_eris_scsi_get_phase
	cmp	3, r10				/*  data in */
	bne	1f
	cmp	0, r7				/* read all the bytes ? */
	bne	1b

1:
	mov	r14, r10
	mov	r15, lp
	jmp	[lp]

/*
 * u32 eris_scsi_data_out(u8 *buf, u32 len);
 *
 * Write data to the SCSI drive.
 *
 * buf = Buffer to write from.
 * len = Length of the buffer.
 */
_eris_scsi_data_out:
	mov	0, r14
	mov	lp, r15
	mov	3, r11			/* SCSIREG_TARGCMD */
1:	in.h	0x602[r0], r10
	andi	0x20, r10, r10
	be	1b

	out.h	r11, 0x600[r0]
	out.h	r0, 0x604[r0]
	br	2f
1:
	ld.b	0[r6], r11
	mov	1, r10
	movea	0x11, r0, r12
	out.h	r0, 0x600[r0]
	out.h	r11, 0x604[r0]
	add	1, r14

	out.h	r10, 0x600[r0]
	out.h	r12, 0x604[r0]

3:	in.h	0x602[r0], r11
	andi	0x20, r11, r11
	bne	3b

	out.h	r10, 0x600[r0]
	out.h	r0, 0x604[r0]

3:	in.h	0x602[r0], r11
	andi	0x20, r11, r11
	be	3b

2:	jal	_eris_scsi_get_phase
	cmp	2, r10 # data out
	bne	1f
	add	1, r6
	add	-1, r7
	bne	1b

1:
	mov	r14, r10
	mov	r15, lp
	jmp	[lp]

/*
 * void eris_scsi_begin_dma(u32 kram_addr, u32 size);
 *
 * Begin a DMA from the SCSI drive.
 *
 * kram_addr = Address in KRAM to DMA to.
 * size      = How many bytes to transfer (must be a multiple of 2).
 */
_eris_scsi_begin_dma:
	mov	3, r10		/* SCSIREG_TARGCMD */
	mov	2, r12
	mov	1, r11
	out.h	r10, 0x600[r0]
	add	6, r10
	out.h	r11, 0x604[r0]

	out.h	r10, 0x600[r0]
	add	1, r10
	out.w	r6, 0x604[r0]

	out.h	r10, 0x600[r0]
	add	-8, r10
	out.w	r7, 0x604[r0]

	out.h	r10, 0x600[r0]
	add	9, r10
	out.h	r12, 0x604[r0]

	out.h	r10, 0x600[r0]
	add	-4, r10
	out.h	r11, 0x604[r0]

	out.h	r10, 0x600[r0]
	out.h	r11, 0x604[r0]

	jmp	[lp]

/*
 * int eris_scsi_check_dma(void);
 *
 * Check if a DMA is in progress.
 *
 * Return = 1 if a DMA is in progress, 0 if not.
 */
_eris_scsi_check_dma:
	mov	11, r11
	out.h	r11, 0x600[r0]
	add	-1, r11
	in.h	0x604[r0], r10
	andi	1, r10, r10
	bne	1f

	out.h	r11, 0x600[r0]
	in.w	0x604[r0], r10
	cmp	0, r10
	setf	nz, r10
1:
	jmp	[lp]

/*
 * void eris_scsi_finish_dma(void);
 *
 * Finish a DMA from the SCSI drive.
 */
_eris_scsi_finish_dma:
	mov	2, r13
	out.h	r13, 0x600[r0]
	add	1, r13
	out.h	r0, 0x604[r0]
	out.h	r13, 0x600[r0]
	add	-2, r13
	out.h	r0, 0x604[r0]

	jr	eris_scsi_eat_data_in

/*
 * void eris_scsi_abort(void);
 *
 * Abort the current SCSI operation.
 */
_eris_scsi_abort:
	mov	1, r10
	out.h	r0, 0x600[r0]			/* KING register 0 (data) */
	out.h	r0, 0x604[r0]			/* send '0' data (does nothing without assert DATA BUS) */

	out.h	r0, 0x600[r0]			/* KING register 0 (data) */
	out.h	r10, 0x604[r0]			/* send '1' data (does nothing without assert DATA BUS) */
	add	1, r10

	out.h	r0, 0x600[r0]			/* KING register 0 (data) */
	out.h	r10, 0x604[r0]			/* send '2' data (does nothing without assert DATA BUS) */
	add	1, r10

	out.h	r0, 0x600[r0]			/* KING register 0 (data) */
	out.h	r10, 0x604[r0]			/* send '3' data (does nothing without assert DATA BUS) */
	add	3, r10

	out.h	r0, 0x600[r0]			/* KING register 0 (data) */
	out.h	r10, 0x604[r0]			/* send '6' data */
	add	-5, r10

	out.h	r10, 0x600[r0]			/* KING register 1 */
	out.h	r10, 0x604[r0]			/* assert DATA BUS */

	out.h	r10, 0x600[r0]			/* KING register 1 */
	add	2, r10
	out.h	r10, 0x604[r0]			/* assert data bus and ATN */
	jmp	[lp]





/*
 * int eris_scsi_command(u8 *cdb, u32 len);
 *
 * Send a command to the SCSI drive.
 *
 * cdb = Command bytes.
 * len = Length of the command data.
 */
_eris_scsi_command:
	mov	lp, r15				/* save return address for later */
	mov	0, r14				/* r14 = 0    */
	mov	1, r13				/* r13 = 1    */
	movea	0x84, r0, r12			/* r12 = 0x84 */
	mov	3, r11				/* r11 = 3    */
	mov	r0, r10				/* r10 = 0    */

/* First, negotiate connection to CDROM (bus arbitration) */

	out.h	r11, 0x600[r0]			/* select KING reg 3 (target command) */
	out.h	r0, 0x604[r0]			/* reg <- 0 (de-assert MSG + CD + IO) */

	out.h	r0, 0x600[r0]			/* select KING reg 0 (input/output data) */
	add	2, r11				/* r11 now = 5 */
	out.h	r12, 0x604[r0]			/* reg <- 0x84 (initiator = 7, target = 2) */


	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r13, 0x604[r0]			/* reg <- 1 (ASSERT DATA BUS) */

	delay_2800ns

	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r11, 0x604[r0]			/* reg <- 5 (set SEL and ASSERT DATA BUS) */


/*1:	jal	_eris_scsi_get_phase*/		/* wait as long as BUS FREE status */
/*	be	1b */

1:	in.h	0x602[r0], r11			/* read status */
	andi	0x40, r11, r11			/* wait for BSY */
	be	1b

/*	scsi_delay */

	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r0, 0x604[r0]			/* reg <- 0 (de-assert data bus and SEL) */

/*	scsi_delay */

1:	jal	_eris_scsi_get_phase
	cmp	4, r10 # command		/* wait until COMMAND phase */
	bne	1b

	mov	3, r11
	mov	2, r10
	out.h	r11, 0x600[r0]			/* select KING reg 3 */
	out.h	r10, 0x604[r0]			/* reg <- 2 (ASSERT CD) */

1:	in.h	0x602[r0], r11			/* read status */
	andi	0x20, r11, r11			/* wait for REQ */
	be	1b

	br	2f				/* jump ahead so you can jump back at command phase*/
1:
	mov	1, r10
	mov	r0, r11
	cmp	r14, r7				/* if passed-in SCSI command has reached its length */
	bnh	3f
	ld.b	0[r6], r11			/* get next byte in command */
	add	1, r6
3:
	add	1, r14
	movea	0x11, r0, r12
	out.h	r0, 0x600[r0]			/* select KING reg 0 */
	out.h	r11, 0x604[r0]			/* apply this byte of command to data bus */

	out.h	r10, 0x600[r0]			/* select KING reg 1 */
	out.h	r10, 0x604[r0]			/* reg <- 1 (ASSERT DATA BUS) */

	out.h	r10, 0x600[r0]			/* select KING reg 1 */
	out.h	r12, 0x604[r0]			/* reg <- 0x11 (ASSERT ACK + DATA BUS) */

3:	in.h	0x602[r0], r11
	andi	0x20, r11, r11			/* wait for REQ to finish */
	bne	3b

	out.h	r10, 0x600[r0]			/* select KING reg 1 */
	out.h	r10, 0x604[r0]			/* reg <- 1 (ASSERT DATA BUS (de-assert ACK)) */

3:	in.h	0x602[r0], r11
	andi	0x20, r11, r11			/* wait for REQ */
	be	3b

2:	jal	_eris_scsi_get_phase
	cmp	4, r10				/* command */
	be	1b

	/* NOOO ! There is still data (like STATUS) to fetch !!! */
	/* Don't collapse the connection yet !!! */

	mov	1, r11
	mov	3, r10
	out.h	r11, 0x600[r0]			/* select KING reg 1 */
	out.h	r0, 0x604[r0]			/* reg <- 0 (de-assert control signals) */

	out.h	r10, 0x600[r0]			/* select KING reg 3 */
	out.h	r0, 0x604[r0]			/* reg <- 0 (de-assert MSG + CD + IO) */

	mov	r14, r10
	mov	r15, lp
	jmp	[lp]

eris_scsi_eat_data_in:

	/* I assume that REQ has been detected as asserted before coming here */
	/* and also, why is the data not actually read at all ? */

	mov	lp, r20				/* preserve return address */
	mov	1, r13
	movea	0x10, r0, r14
	br	2f
1:
	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r14, 0x604[r0]			/* reg <- 0x10 (assert ACK) */
/*	movscsireg_v	INITCMD_ASSERT_ACK, SCSIREG_INITCMD, r16	*/	/* now assert ACK */

3:	in.h	0x602[r0], r11
/* 3:	getscsistat	r11	*/
	andi	0x20, r11, r11			/* wait for REQ to finish */
	bne	3b

	out.h	r13, 0x600[r0]			/* select KING reg 1 */
	out.h	r0, 0x604[r0]			/* reg <- 0 (de-assert ACK) */
/*	movscsireg_v	INITCMD_DEASSERT, SCSIREG_INITCMD, r16	*/	/* now assert ACK */

3:	in.h	0x602[r0], r11
/* 3:	getscsistat	r11	*/
	andi	0x20, r11, r11			/* wait for ACK */
	be	3b

2:	jal	_eris_scsi_get_phase
	cmp	3, r10				/* data in */
	be	1b

	mov	r20, lp
	jmp	[lp]

