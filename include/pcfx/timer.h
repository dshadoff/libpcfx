/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff <GitHub user: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*
 * Utilize the built-in timer.
 */

#ifndef _LIBPCFX_TIMER_H_
#define _LIBPCFX_TIMER_H_


#include <pcfx/types.h>


// Normal sequence of operation:
//
// Choice (b) - IRQ (normal):
// --------------------------
// 1) Set irq handler
//      irq_set_mask(x);   -- see example code
//      irq_set_raw_handler(0x9, my_timer_irq);
//
// 2) Initialize timer 
//      timer_init();
//
// 3) Set timer
//      timer_set_period(n);
//
// 4) Enable IRQs:
//      irq_set_level(x);  -- see example code
//      irq_enable();
//
// 5) Start Timer
//      timer_start(0);
//
// 6) Within IRQ handler, acknowledge interrupt
//      timer_ack_irq();
//
//
// Choice (a) - non-IRQ:
// ---------------------
// 1) Initialize timer 
//      timer_init();
//
// 2) Set timer
//      timer_set_period(n);
//
// 3) Start Timer
//      timer_start(0);
//
// 4) Read counter at various intervals
//      timer_read_counter();
//


/* Initialize the timer.
 */
void timer_init(void);


/* Set the period of the timer.
 *
 * Period is in ticks of CPUclk/15. New period will not load until either the
 * timer is restarted, or expires.
 *
 * period: The period of the timer. (1 ~ 65535)
 */
void timer_set_period(int period);


/* Read the current value of the timer.
 *
 * return value: The current value of the timer.
 */
int timer_read_counter(void);


/* Acknowledge a timer IRQ.
 */
void timer_ack_irq(void);


/* Read the timer's control register.
 *
 * return value: The control register.
 */
u16 timer_read_control(void);


/* Write the timer's control register.
 *
 * cr: The new control register.
 */
void timer_write_control(int cr);


/* Start the timer.
 *
 * irq: If 1, fire an IRQ at timer expiration.
 */
void timer_start(int irq);


/* Stop the timer.
 */
void timer_stop(void);

#endif

