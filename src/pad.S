/*
        liberis -- A set of libraries for controlling the NEC PC-FX

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
and       (C) 2024              Dave Shadoff  <GitHub ID: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*****************************************************************************
 *  High-level pad control                                               []  *
 *****************************************************************************/
	.global	_eris_pad_init
	.global	_eris_pad_read

	.global	_eris_pad_values

_eris_pad_values:
	.word	0  /* port 0, pad 0 */
/*	.word	0  *//* port 0, pad 1  - For FUTURE USE*/
/*	.word	0  *//* port 0, pad 2 */
/*	.word	0  *//* port 0, pad 3 */
/*	.word	0  *//* port 0, pad 4 */
/*	.word	0  *//* port 0, pad 5 (unused) */
/*	.word	0  *//* port 0, pad 6 (unused) */
/*	.word	0  *//* port 0, pad 7 (unused) */
	.word	0  /* port 1, pad 0 */
/*	.word	0  *//* port 1, pad 1  - For FUTURE USE*/
/*	.word	0  *//* port 1, pad 2 */
/*	.word	0  *//* port 1, pad 3 */
/*	.word	0  *//* port 1, pad 4 */
/*	.word	0  *//* port 1, pad 5 (unused) */
/*	.word	0  *//* port 1, pad 6 (unused) */
/*	.word	0  *//* port 1, pad 7 (unused) */

/*-------------------------------*
 * void eris_pad_init (int port) *
 *                               *
 * inputs: r6 = port             *
 *-------------------------------*/
_eris_pad_init:
	andi	1, r6, r6                       /* port 0 or 1 only          */
	mov	r6, r10
	shl	2, r10                          /* offset into table (words) */
/*	shl	5, r10       */                   /* offset into 8-pad per port table - FUTURE */
	movhi	hi(_eris_pad_values), r0, r11
	movea	lo(_eris_pad_values), r11, r11  /* r11 is table address      */
	add	r10, r11                        /* port within table         */
	st.w	r0, 0[r11]                      /* clear 'current value'     */

/*	st.w	r0, 4[r11]   */                   /* clear pad 1 - FUTURE      */
/*	st.w	r0, 8[r11]   */                   /* clear pad 2 - FUTURE      */
/*	st.w	r0, 12[r11]  */                   /* clear pad 3 - FUTURE      */
/*	st.w	r0, 16[r11]  */                   /* clear pad 4 - FUTURE      */
/*	st.w	r0, 20[r11]  */                   /* clear pad 5 - FUTURE      */
/*	st.w	r0, 24[r11]  */                   /* clear pad 6 - FUTURE      */
/*	st.w	r0, 28[r11]  */                   /* clear pad 7 - FUTURE      */

	jr	_eris_port_init                 /* Now, init the port itself */

/*-------------------------------*
 * u32  eris_pad_read (int port) *
 *                               *
 * input:  r6  = port            *
 * output: r10 = (value)         *
 *-------------------------------*/
/* NOTE: this won't perform 4-pad multitap reads */

_eris_pad_read:
	andi	1, r6, r6
	mov	r6, r17                           /* store port # temporarily */
	mov	r6, r16
	shl	2, r16
/*	shl	5, r16       */                   /* offset into 8-pad per port table - FUTURE */
	movhi	hi(_eris_pad_values), r0, r15
	movea	lo(_eris_pad_values), r15, r15
	add	r16, r15                          /* address of current value */

/* Here, we do a blocking read - request, wait, and read: */

        shl     7, r6
        mov     7, r10                            /* reset multitap and request data from port */
        out.h   r10, 0[r6]

wait_for_input_ready:
        in.h    0[r6], r10                        /* r10 is now the status register value */
        andi    9, r10, r10
        cmp     1, r10
        bz      wait_for_input_ready

        in.w    0x40[r6], r10                     /* and now r10 is the pad data value */

	st.w	r10, 0[r15]                       /* store return data in pad_values table */

	jmp	[lp]


/*****************************************************************************
 *  Low-level port access                                                    *
 *****************************************************************************/
        .global _eris_port_init
        .global _eris_port_read_status
        .global _eris_port_read_data
        .global _eris_port_write_control
        .global _eris_port_write_data

/*-----------------------------------*
 * void eris_port_init (int port)    *
 *                                   *
 * inputs: r6 = port                 *
 *-----------------------------------*/
_eris_port_init:
        shl     7, r6           /* r6 will be either 0x00 or 0x80 = control port address */
        out.h   r0, 0[r6]
        out.w   r0, 0x40[r6]    /* put zero value in data port value (why ?) */
        in.h    0[r6], r10      /* get status .... ?  */
        jmp     [lp]


/*-------------------------------------*
 * u16 eris_port_read_status(int port) *
 *                                     *
 * inputs: r6  = port # (0 or 1)       *
 * output: r10 = status                *
 *-------------------------------------*/
_eris_port_read_status:
        shl     7, r6
        in.h    0[r6], r10
        jmp     [lp]

/*-------------------------------------*
 * u32 eris_port_read_data(int port)   *
 *                                     *
 * inputs: r6  = port # (0 or 1)       *
 * output: r10 = data                  *
 *-------------------------------------*/
_eris_port_read_data:
        shl     7, r6
        in.h    0x40[r6], r10
        jmp     [lp]

/*-------------------------------------------------*
 * void eris_port_write_control(int port, u16 ctl) *
 *                                                 *
 * inputs: r6  = port # (0 or 1)                   *
 *         r7  = control value to write to port    *
 * output: (none)                                  *
 *-------------------------------------------------*/
_eris_port_write_control:
        shl     7, r6
        out.h   r7, 0[r6]
        jmp     [lp]

/*-------------------------------------------------*
 * void eris_port_write_data(int port, u32 data)   *
 *                                                 *
 * inputs: r6  = port # (0 or 1)                   *
 *         r7  = data value to write to port       *
 * output: (none)                                  *
 *-------------------------------------------------*/
_eris_port_write_data:
        shl     7, r6
        out.w   r7, 0x40[r6]
        jmp     [lp]

