/*
	libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011		Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024		David Shadoff  GitHub userid: dshadoff

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

#define	min(a,b)	(a<b)?a:b

#include <string.h>

#include <pcfx/types.h>
#include <pcfx/v810.h>
#include <pcfx/romfont.h>
#include <pcfx/king.h>
#include <pcfx/tetsu.h>

#include <eris/cd.h>
#include <pcfx/contrlr.h>
#include <eris/scsi.h>




#define SCSI_CDROM	2

// Default SCSI buffers
//
u8 dataout[128];
u8 datain[4096];
u8 command[32];
u8 status[8];
u8 unused[128];
u8 msgout[32];
u8 msgin[32];

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

scsiphscnt scsi_counters;


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

scsibuf scsi_buf;


extern int scsi_command(u8 devicenum, scsiphscnt *buf, scsibuf * buf2);




int cmdnum = 0;
u32 retcode = 0;

u8 command_set[][12] = {
	/*
	{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Test Unit Ready
	{ 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Rezero Unit
//	{ 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Read - need more research
//	{ 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Seek - need more research
	{ 0x0D, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// No Operation
	{ 0x12, 0x40, 0x00, 0x00, 0x24, 0x00, 0, 0, 0, 0, 0, 0},	// Inquiry
//	{ 0x15, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Mode Select - need more research
//	{ 0x16, 0x40, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Reserve
//	{ 0x17, 0x40, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Release
//	{ 0x1A, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Mode Sense - need more research
//	{ 0x1B, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Start/Stop - need more research
	{ 0x1D, 0x04, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Send Diagnostic
	{ 0x1E, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// Allow Media Removal
	{ 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0},	// End set
	*/
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x47, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x01, 0x1C, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x04, 0x73, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x11, 0xCE, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x47, 0x3B, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x01, 0x1C, 0xE0, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x04, 0x73, 0xB0, 0x00, 0x00, 0x01, 0x00, 0, 0},	// Read
	{ 0x28, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x01, 0x00, 0, 0}	// Read
};


u32 temp;

void printch(u32 sjis, u32 kram, int tall);
void printstr(const char* str, int x, int y, int tall);
void printhex(void* data, int x, int y, int bytes, int addr, int tall);
char x1toa(int val);

u32 test_data_in(u8 *buf, u32 maxlen);


void clear_scsibufs(void)
{
//int i;

/*
	for (i=0; i < 4096; i++) {
		datain[i] = 0xff;
	}
	for (i=0; i < 32; i++) {
		msgin[i] = 0xff;
		command[i] = 0xff;
	}
	for (i=0; i < 8; i++) {
		status[i] = 0xff;
	}
*/
}

void request_sense(void)
{
	clear_scsibufs();

	command[0] = 0x03;		// Test Unit Ready
	command[1] = 0;
	command[2] = 0;
	command[3] = 0;
	command[4] = 0x18;
	command[5] = 0;
}

void data_init(void)
{
	clear_scsibufs();

	command[0] = command_set[cmdnum][0];
	command[1] = command_set[cmdnum][1];
	command[2] = command_set[cmdnum][2];
	command[3] = command_set[cmdnum][3];
	command[4] = command_set[cmdnum][4];
	command[5] = command_set[cmdnum][5];
	command[6] = command_set[cmdnum][6];
	command[7] = command_set[cmdnum][7];
	command[8] = command_set[cmdnum][8];
	command[9] = command_set[cmdnum][9];
	command[10] = command_set[cmdnum][10];
	command[11] = command_set[cmdnum][11];

	cmdnum = cmdnum + 1;
	if (cmdnum > 17) cmdnum = 0;
}

void val_display(u32 value, u32 x, u32 y)
{
char str[256];

	str[0] = x1toa(value>>12);
	str[1] = x1toa(value>>8);
	str[2] = x1toa(value>>4);
	str[3] = x1toa(value);
	str[4] = 0;

	printstr(str, x, y, 0);
}

void data_display(void)
{
int y_pos = 0x20;
int size;
int i;

	king_set_kram_write(0, 1);
	// Clear BG0's RAM
	for(i = 0x0; i < 0x1E00; i++) {
		king_kram_write(0);
	}
	king_set_kram_write(0, 1);

	printstr("retcode:", 0, 0x10, 0);
	val_display(retcode, 12, 0x10);

	temp = scsi_counters.command_sz;

	printstr("command_sz:", 0, y_pos, 0);
	val_display(temp, 12, y_pos);
	y_pos += 8;
	if (temp > 0) {
		y_pos += 2;
		printhex(command, 0, y_pos, temp, 0, 0);
		y_pos += ((temp/8)+1) * 8;
	}
	y_pos += 8;

	temp = scsi_counters.dataout_sz;

	printstr("dataout_sz:", 0, y_pos, 0);
	val_display(temp, 12, y_pos);
	y_pos += 8;
	if (temp > 0) {
		y_pos += 2;
		size = min(temp, 32);
		printhex(dataout, 0, y_pos, size, 0, 0);
		y_pos += ((size/8)+1) * 8;
	}
	y_pos += 8;

	temp = scsi_counters.datain_sz;

	printstr("datain_sz:", 0, y_pos, 0);
	val_display(temp, 12, y_pos);
	y_pos += 8;
	if (temp > 0) {
		y_pos += 2;
		size = min(temp, 32);
		printhex(datain, 0, y_pos, size, 0, 0);
		y_pos += ((size/8)+1) * 8;
	}
	y_pos += 8;

	temp = scsi_counters.status_sz;

	printstr("status_sz:", 0, y_pos, 0);
	val_display(temp, 12, y_pos);
	y_pos += 8;
	if (temp > 0) {
		y_pos += 2;
		printhex(status, 0, y_pos, temp, 0, 0);
		y_pos += ((temp/8)+1) * 8;
	}
	y_pos += 8;

//	printstr("unused1_sz:", 0, 0x70, 0);
//	val_display(unused1_sz, 12, 0x70);

//	printstr("unused2_sz:", 0, 0x80, 0);
//	val_display(unused2_sz, 12, 0x80);

	temp = scsi_counters.msgout_sz;

	printstr("msgout_sz:", 0, y_pos, 0);
	val_display(temp, 12, y_pos);
	y_pos += 8;
	if (temp > 0) {
		y_pos += 2;
		printhex(msgout, 0, y_pos, temp, 0, 0);
		y_pos += ((temp/8)+1) * 8;
	}
	y_pos += 8;

	temp = scsi_counters.msgin_sz;

	printstr("msgin_sz:", 0, y_pos, 0);
	val_display(temp, 12, y_pos);
	y_pos += 8;
	if (temp > 0) {
		y_pos += 2;
		printhex(msgin, 0, y_pos, temp, 0, 0);
		y_pos += ((temp/8)+1) * 8;
	}
	y_pos += 8;
}

int main(int argc, char *argv[])
{
	int i;
//	char str[256];
	u16 microprog[16];
	u32 paddata = 0;
	u32 lastpad = 0;
//	u8 scsimem[4096];
//	u32 seekaddr = 0;
//	u32 sector_read = 0;
//	u32 bytes;
//	int bytes;

	scsi_buf.data_out = dataout;
	scsi_buf.data_in  = datain;
	scsi_buf.cmd      = command;
	scsi_buf.stat     = status;
	scsi_buf.unused1  = unused;
	scsi_buf.unused2  = unused;
	scsi_buf.msg_out  = msgout;
	scsi_buf.msg_in   = msgin;

	king_init();
	tetsu_init();
	
	tetsu_set_priorities(0, 0, 1, 0, 0, 0, 0);
	tetsu_set_king_palette(0, 0, 0, 0);
	tetsu_set_rainbow_palette(0);

	king_set_bg_prio(KING_BGPRIO_3, KING_BGPRIO_HIDE, KING_BGPRIO_HIDE, KING_BGPRIO_HIDE, 0);
	king_set_bg_mode(KING_BGMODE_4_PAL, 0, 0, 0);
	king_set_kram_pages(0, 0, 0, 0);

	for(i = 0; i < 16; i++) {
		microprog[i] = KING_CODE_NOP;
	}

	microprog[0] = KING_CODE_BG0_CG_0;
	king_disable_microprogram();
	king_write_microprogram(microprog, 0, 16);
	king_enable_microprogram();

	tetsu_set_palette(0, 0x0088);
	tetsu_set_palette(1, 0xE088);
	tetsu_set_palette(2, 0xE0F0);
	tetsu_set_palette(3, 0x602C);
	tetsu_set_video_mode(TETSU_LINES_262, 0, TETSU_DOTCLOCK_5MHz, TETSU_COLORS_16,
				TETSU_COLORS_16, 0, 0, 1, 0, 0, 0, 0);
	king_set_bat_cg_addr(KING_BG0, 0, 0);
	king_set_bat_cg_addr(KING_BG0SUB, 0, 0);
	king_set_scroll(KING_BG0, 0, 0);
	king_set_bg_size(KING_BG0, KING_BGSIZE_256, KING_BGSIZE_256, KING_BGSIZE_256, KING_BGSIZE_256);

	king_set_kram_read(0, 1);
	king_set_kram_write(0, 1);
	// Clear BG0's RAM
	for(i = 0x0; i < 0x1E00; i++) {
		king_kram_write(0);
	}
	king_set_kram_write(0, 1);
	contrlr_pad_init(0);


	printstr("SCSI Command Test", 5, 0, 1);
	for(;;) {
		lastpad = paddata;
		paddata = contrlr_pad_read(0);
		/*
		if((paddata & JOY_SELECT) && !(lastpad & JOY_SELECT)) { // Select
			eris_scsi_abort();
		}
		*/
		/*
		if((paddata & JOY_RUN) && !(lastpad & JOY_RUN)) { // Run
			eris_scsi_reset();
		}
		*/
		if((paddata & JOY_I) && !(lastpad & JOY_I)) { // (I) Read next to Buffer
			data_init();
			retcode = scsi_command(SCSI_CDROM, &scsi_counters, &scsi_buf);
			data_display();
		}
		
		if((paddata & JOY_II) && !(lastpad & JOY_II)) { // (II) Read prev to Buffer
			request_sense();
			retcode = scsi_command(SCSI_CDROM, &scsi_counters, &scsi_buf);
			data_display();
		}
	}

	return 0;
}

char x1toa(int val)
{
	val &= 0xF;
	if(val >= 0xA)
		return (val - 0xA) + 'A';
	else
		return val + '0';
}

void printhex(void* data, int x, int y, int bytes, int addr, int tall)
{
	char tmpstr[256];
	int tmpptr = 0;
	int i, l;
	for(i = 0; i < bytes; i += 8) {
		tmpptr = 0;
		if(addr) {
			tmpstr[tmpptr++] = x1toa(i >> 12);
			tmpstr[tmpptr++] = x1toa(i >> 8);
			tmpstr[tmpptr++] = x1toa(i >> 4);
			tmpstr[tmpptr++] = x1toa(i);
			tmpstr[tmpptr++] = ' ';
			tmpstr[tmpptr++] = ' ';
		}
		for(l = 0; (l < 8) && ((l + i) < bytes); l++) {
			tmpstr[tmpptr++] = x1toa(((char*)data)[i + l] >> 4);
			tmpstr[tmpptr++] = x1toa(((char*)data)[i + l]);
			tmpstr[tmpptr++] = ' ';
		}
		tmpstr[tmpptr] = 0;
		printstr(tmpstr, x, y + i, tall);
	}
}

void printstr(const char* str, int x, int y, int tall)
{
	int i;
	u32 tempstr;

	u32 kram = x + (y << 5);
	int len = strlen(str);
	for(i = 0; i < len; i++) {
		tempstr = str[i];
		printch(tempstr, kram + i, tall);
	}
}

void printch(u32 sjis, u32 kram, int tall)
{
	u16 px;
	int x, y;
	u8* glyph = romfont_get(sjis, tall ? ROMFONT_ANK_8x16 : ROMFONT_ANK_8x8);
	for(y = 0; y < (tall ? 16 : 8); y++) {
		king_set_kram_write(kram + (y << 5), 1);
		px = 0;
		for(x = 0; x < 8; x++) {
			if((glyph[y] >> x) & 1) {
				px |= 1 << (x << 1);
			}
		}
		king_kram_write(px);
	}
}
