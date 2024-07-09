/*
        liberis -- A set of libraries for controlling the NEC PC-FX

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff  <GitHub ID: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*
 * Access to controller ports
 */

#ifndef _LIBPCFX_CONTRLR_H_
#define _LIBPCFX_CONTRLR_H_

#include <eris/types.h>


// These bits identify the various buttons on a joypad controller
//
#define JOY_I            0x01
#define JOY_II           0x02
#define JOY_III          0x04
#define JOY_IV           0x08
#define JOY_V            0x10
#define JOY_VI           0x20
#define JOY_SELECT       0x40
#define JOY_RUN          0x80
#define JOY_UP           0x100
#define JOY_RIGHT        0x200
#define JOY_DOWN         0x400
#define JOY_LEFT         0x800
#define JOY_MODE1        0x1000
#define JOY_MODE2        0x4000

// These bits are the buttons for mouse controller
// 
#define MOUSE_LEFT       0x10000
#define MOUSE_RIGHT      0x20000


#define CONTRLR_CTRL_XFER        1 /* write to initiate xfer/stays '1' until complete */
#define CONTRLR_CTRL_RESETMULTI  2 /* set to '1' for first controller of multitap set */
#define CONTRLR_CTRL_WRITEDATA   0 /* Set Bit 2 low for writing data to controller    */
#define CONTRLR_CTRL_READDATA    4 /* Set Bit 2 high for reading data from controller */
#define CONTRLR_CTRL_END         8 /* not writable; is set when scan complete (also raises interrupt) */


typedef enum {
	PAD_TYPE_NONE = 0,
	PAD_TYPE_MOUSE = 13,
	PAD_TYPE_MULTITAP = 14,
	PAD_TYPE_FXPAD = 15
} pad_type;

extern u32 contrlr_pad_values[];


/*----------------------------------------------------------*/
/* The idea is to read new data only when needed, and       */
/* consult existing data whenever possible                  */
/*----------------------------------------------------------*/
/* These MACROs act on data already read - USE CAREFULLY !! */
/*----------------------------------------------------------*/
#define contrlr_pad_data(x) (contrlr_pad_values[x])
#define contrlr_pad_type(x) (contrlr_pad_values[x] >> 28)
#define contrlr_pad_connected(x) (contrlr_pad_type(x) != PAD_TYPE_NONE)

#define mouse_x(x) ((contrlr_pad_values[x] >> 8) & 0xFF)
#define mouse_y(x) ((contrlr_pad_values[x]) & 0xFF)

// Normal sequence of operation:
//
// Choice (a):
// -----------
// 1) Initialize at start of program:
//      contrlr_pad_init(n);
//
// 2) Trigger write with control port:
//      contrlr_port_write_control(n, (CONTRLR_CTRL_XFER|CONTRLR_CTRL_RESETMULTI|CONTRLR_READDATA));
//
// 3) Check 100usec later to ensure that scan completed:
//      while((contrlr_port_status_read(n) & CONTRLR_CTRL_XFER) != 0);
//
// 4) Read data:
//      value = contrlr_port_read_data(n);
//
// Choice (b):
// -----------
// 1) Initialize at start of program:
//      contrlr_pad_init(n);
//
// 2) Do steps 2), 3) and 4) in one easy function:
//      value = contrlr_pad_read(n);
//
// Choice (a) has the advantage of flexibility in step 2's trigger parameters,
// as well as the ability to do some other processing for 100usec (which is
// roughly 1.5 scanlines)
//
//

/* Initialize a port.
 *
 * port = The port to initialize. (0 ~ 1)
 */
void contrlr_pad_init(int port);


/* Read the pad data (assuming no multitap)
 *
 * pad = The pad to read. (0 ~ 1)
 * return value:  Current state of the pad.
 */
u32 contrlr_pad_read(int pad);


// "port-level" functions:
//
/* Initialize a port.
 *
 * pad = The pad to initialize. (0 ~ 1)
 */
void contrlr_port_init(int port);


/* Read port status.
 *
 * port = The port to read the status of. (0 ~ 1)
 * return value = Pad's status.
 */
u16 contrlr_port_read_status(int port);


/* Read port data.
 *
 * port = The port to read data from. (0 ~ 1)
 * return value = Pad's data.
 */
u32 contrlr_port_read_data(int port);


/* Write port control.
 *
 * port = The port to write the control of. (0 ~ 1)
 * ctl = The control data to be written.
 */
void contrlr_port_write_control(int port, u16 ctl);


/* Write port data.
 *
 * port = The port to write data to. (0 ~ 1)
 * data = The data to be written.
 *
 * Note: When writing data to controller port, first
 *       check the status to ensure that scan isn't
 *       still active, then write data, then trigger
 *       scan by writing to control port
 */
void contrlr_port_write_data(int port, u32 data);


#endif

