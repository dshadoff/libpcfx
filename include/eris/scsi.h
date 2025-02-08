/*
        liberis -- A set of libraries for controlling the NEC PC-FX

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff  <GitHub ID: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*! \file
 * \brief Low-level control of the KING processor's SCSI controller.
 */

#ifndef _LIBPCFX_SCSI_H_
#define _LIBPCFX_SCSI_H_

#include <pcfx/types.h>


#define	SCSI_CDROM			2		/* SCSI LUN of CDROM unit */

#define	SCSI_ERR_TIMEOUT		0xFFFE
#define	SCSI_ERR_BUS_BUSY		0xFFFF

// #define	SCSI_CMD_TEST_UNIT_READY	0x00
#define	SCSI_CMD_AUDIO_TRK_SEARCH	0xD8
 

typedef struct scsiphasecounts {
        u32 dataout_sz;
        u32 datain_sz;
        u32 command_sz;
        u32 status_sz;
        u32 unused1_sz;
        u32 unused2_sz;
        u32 msgout_sz;
        u32 msgin_sz;
} scsiphscnt;

typedef struct scsibuffers {
        u8 * data_out;
        u8 * data_in;
        u8 * cmd;
        u8 * stat;
        u8 * unused1;
        u8 * unused2;
        u8 * msg_out;
        u8 * msg_in;
} scsibuf;

/* Reset the SCSI drive.
 */
void scsi_reset(void);

/* Perform a full SCSI command from start to end (CPU-managed, not DMA)
 *
 * devicenum: LUN of SCSI device (0-6, CDROM = 2)
 * buf:       Pointer to set of counters which track data in/out by phase
 * buf2:      Pointer to set of buffer pointers with data in/out by phase
 *
 * return code = first byte of status phase, or SCSI_ERR_xxx from above
 */
int scsi_command(u8 devicenum, scsiphscnt *buf, scsibuf * buf2);

// --------------------------------------------------------------------------------------
typedef enum
{
	SCSI_PHASE_BUS_FREE    = 0,
	SCSI_PHASE_SELECT      = 1,
	SCSI_PHASE_DATA_OUT    = 2,
	SCSI_PHASE_DATA_IN     = 3,
	SCSI_PHASE_COMMAND     = 4,
	SCSI_PHASE_STATUS      = 5,
	SCSI_PHASE_MESSAGE_OUT = 6,
	SCSI_PHASE_MESSAGE_IN  = 7,
	SCSI_PHASE_ILLEGAL     = 8
} scsi_phase;
typedef enum
{
	// Our special statuses, indicating that the command is still in-progress.
	SCSI_STATUS_MISC            = -5,
	SCSI_STATUS_NEED_MESSAGE    = -4,
	SCSI_STATUS_NEED_DATA       = -3,
	SCSI_STATUS_HAVE_DATA       = -2,
	SCSI_STATUS_IN_PROGRESS     = -1,

	SCSI_STATUS_GOOD            = 0x0,
	SCSI_STATUS_CHECK_CONDITION = 0x2,
	SCSI_STATUS_CONDITION_MET   = 0x4,
	SCSI_STATUS_BUSY            = 0x6,
	SCSI_STATUS_INTERMEDIATE    = 0x10
} scsi_status;
typedef enum {
	SCSI_CMD_TEST_UNIT_READY  = 0x00,
	SCSI_CMD_REQ_SENSE        = 0x03,
	SCSI_CMD_READ10           = 0x28,
	SCSI_CMD_SEEK10           = 0x2B,
	SCSI_CMD_PREFETCH10       = 0x34,
	SCSI_CMD_READ_SUBQ        = 0x42,
	SCSI_CMD_READ_TOC         = 0x43,
	SCSI_CMD_READ_HEADER      = 0x44,
	SCSI_CMD_PLAY_AUDIO_INDEX = 0x48,
	SCSI_CMD_PAUSE            = 0x4B,
} scsi_cmd;

/*! \brief Get SCSI phase.
 * \return Returns the current phase of the SCSI drive.
 */
scsi_phase eris_scsi_get_phase(void);
/*! \brief Get SCSI status.
 *
 * \return Returns the current state of the SCSI drive.
 */
scsi_status eris_scsi_status(void);
/* Reset the SCSI drive.
 */
void eris_scsi_reset(void);
/*! \brief Read data from the SCSI drive.
 *
 * \param buf Buffer to read into.
 * \param maxlen Maximum length to read from.
 * \return Bytes read.
 */
u32 eris_scsi_data_in(u8 *buf, u32 maxlen);
/*! \brief Write data to the SCSI drive.
 *
 * \param buf Buffer to write from.
 * \param len Length of the buffer.
 */
u32 eris_scsi_data_out(u8 *buf, u32 len);
/*! \brief Begin a DMA from the SCSI drive.
 *
 * \param kram_addr Address in KRAM to DMA to.
 * \param size How many bytes to transfer (must be a multiple of 2).
 */
void eris_scsi_begin_dma(u32 kram_addr, u32 size);
/*! \brief Check if a DMA is in progress.
 *
 * \return 1 if a DMA is in progress, 0 if not.
 */
int eris_scsi_check_dma(void);
/*! \brief Finish a DMA from the SCSI drive.
 */
void eris_scsi_finish_dma(void);
/*! \brief Abort the current SCSI operation.
 */
void eris_scsi_abort(void);
/*! \brief Send a command to the SCSI drive.
 *
 * \param cdb Command bytes.
 * \param len Length of the command data.
 */
int eris_scsi_command(u8 *cdb, u32 len);
// Get Error?

#endif

