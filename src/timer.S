/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff <GitHub user: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*****************************************************************************
 *  Timer handling                                                           *
 *****************************************************************************/
	.global	_timer_init
	.global	_timer_set_period
	.global	_timer_read_counter
	.global	_timer_ack_irq
	.global	_timer_read_control
	.global	_timer_write_control
	.global	_timer_start
	.global	_timer_stop

/*----------------------------------*
 * void timer_init(void)            *
 *                                  *
 * inputs: none                     *
 *----------------------------------*/
_timer_init:
	out.h	r0, 0xF00[r0]
	out.h	r0, 0xF80[r0]
	jmp	[lp]

/*-------------------------------------*
 * void timer_set_period(int period)   *
 *                                     *
 * input: r6 = period (1-65535)        *
 *-------------------------------------*/
_timer_set_period:
	out.h	r6, 0xF80[r0]
	jmp	[lp]

/*----------------------------------*
 * int timer_read_counter(void)     *
 *                                  *
 * inputs:  none                    *
 * outputs: r10 = (value)           *
 *----------------------------------*/
_timer_read_counter:
	in.h	0xFC0[r0], r10
	jmp	[lp]

/*----------------------------------*
 * void timer_ack_irq(void)         *
 *   Acknowledge IRQ                *
 *                                  *
 * inputs: none                     *
 *----------------------------------*/
_timer_ack_irq:
	in.h	0xF00[r0], r10
	andi	~4, r10, r10
	out.h	r10, 0xF00[r0]
	jmp	[lp]

/*----------------------------------*
 * u16 timer_read_control(void)     *
 *   Read Control register          *
 *                                  *
 * inputs: none                     *
 *----------------------------------*/
_timer_read_control:
	in.h	0xF00[r0], r10
	jmp	[lp]

/*----------------------------------*
 * void timer_write_control(int cr) *
 *                                  *
 * inputs: r6 = cr = new value      *
 *----------------------------------*/
_timer_write_control:
	out.h	r6, 0xF00[r0]
	jmp	[lp]

/*----------------------------------*
 * void timer_start(int irq)        *
 *                                  *
 * inputs: r6 = irq                 *
 *  (if 1, fire IRQ at completion)  *
 *----------------------------------*/
_timer_start:
	in.h	0xF00[r0], r10
	andi	~3, r10, r10
	ori	2, r6, r6
	or	r6, r10
	out.h	r10, 0xF00[r0]
	jmp	[lp]

/*----------------------------------*
 * void timer_stop(void)            *
 *                                  *
 * inputs: none                     *
 *----------------------------------*/
_timer_stop:
	in.h	0xF00[r0], r10
	andi	~1, r10, r10
	out.h	r10, 0xF00[r0]
	jmp	[lp]
