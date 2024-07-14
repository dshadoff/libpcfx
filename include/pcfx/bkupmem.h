/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff  <GitHub ID: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*
 *  Backup memory control.
 */

#ifndef _LIBPCFX_BKUPMEM_H_
#define _LIBPCFX_BKUPMEM_H_

#include <pcfx/types.h>

// NOTE:
// -----
// These functions only provide direct access to the backup memory on
// the machine, and do not implement any measure for accessing the
// files themselves (which are in FAT format).
//
// Furthermore, the PC-FXGA does NOT implement backup memory through
// the same means, so these functions will have no effect on a
// PC-FXGA.
//
// As such, these functions are NOT RECOMMENDED for general use.
//
// The FX BIOS implements correct file management measures which
// will work across both machines, and work at a filesystem level.
//
// A 'C' language interface to these functions will be implemented
// as part of libpcfx in the near future, as "filesys.h". As this
// interface has some complexities, there will be several examples
// in order to demonstrate how to use the functions
//

/* Set access bits.
 * These bits control access to external and internal backup memory.
 *
 * internal = Allow writing of internal backup memory.
 * external = Allow writing of external backup memory.
 */
void bkupmem_set_access(int internal, int external);


/* Directly read backup memory.
 *
 * ext = If 1, read from external memory. 0 is internal memory.
 * buf = Buffer to store the data.
 * addr=  Address to start reading from.
 * len = Bytes to read.
 */
void bkupmem_read(int ext, u8 *buf, u32 addr, u32 len);


/* Directly write backup memory.
 *
 * ext = If 1, write to external memory. 0 is internal memory.
 * buf = Buffer holding the data to write.
 * addr=  Address to start writing to.
 * len = Bytes to write.
 */
void bkupmem_write(int ext, u8 *buf, u32 addr, u32 len);

#endif

