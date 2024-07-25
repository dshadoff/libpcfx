/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff  <GitHub ID: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/* 
 * Controls the NEW Iron Guanyin (Tetsu kannon) chip (Video Controller)
 */

#ifndef _LIBPCFX_TETSU_H_
#define _LIBPCFX_TETSU_H_

#include <pcfx/types.h>

/* Number of vertical lines to display.
 */
typedef enum {
	TETSU_LINES_263        = 0, /* 263 lines. A little flickery, but less cross-talk. */
	TETSU_LINES_262        = 1, /* 262 lines. No flicker, but lots of cross-talk. */
	TETSU_LINES_INTERLACED = 2, /* Interlaced. Very flickery. */
	TETSU_LINES_UNKNOWN    = 3, /* Interlaced + 1/2dot shift?. Flickery^2 */
} tetsu_lines;

/* Dot clock. Determines screen width.
 */
typedef enum {
	TETSU_DOTCLOCK_5MHz = 0, /* ~5MHz dot clock. 256px wide. */
	TETSU_DOTCLOCK_7MHz = 1, /* ~7MHz dot clock. 320px wide. */
} tetsu_dotclock;

/* Amount of colors (to display?).
 */
typedef enum {
	TETSU_COLORS_16  = 0, /* 16 colors */
	TETSU_COLORS_256 = 1, /* 256 colors */
} tetsu_colordepth;

/* Which coefficient to use for cellophane.
 */
typedef enum {
	TETSU_NO_COEFF = 0, /* No coefficient (no cellophane). */
	TETSU_COEFF_1  = 1, /* Coefficient 1 */
	TETSU_COEFF_2  = 2, /* Coefficient 2 */
	TETSU_COEFF_3  = 3, /* Coefficient 3 */
} tetsu_coeff;

/* Initialize the NEW Iron Guanyin.
 */
void tetsu_init();

/* Setup the video mode.
 *
 * lines:        Vertical line mode.
 * ext_sync:     Whether to use external sync.
 * dotclock:     The dotclock to run at.
 * bg_depth:     Color depth of VDC backgrounds.
 * spr_depth:    Color depth of VDC sprites.
 * vdcbg:        Whether VDC backgrounds are displayed.
 * vdcspr:       Whether VDC sprites are displayed.
 * bg0_disp:     Whether KING BG0 is displayed.
 * bg1_disp:     Whether KING BG1 is displayed.
 * bg2_disp:     Whether KING BG2 is displayed.
 * bg3_disp:     Whether KING BG3 is displayed.
 * rainbow_disp: Whether the RAINBOW output is displayed.
 */
void tetsu_set_video_mode(tetsu_lines lines, int ext_sync,
			tetsu_dotclock dotclock, tetsu_colordepth bg_depth,
			tetsu_colordepth spr_depth, int vdcbg_show,
			int vdcspr_show, int bg0_disp, int bg1_disp,
			int bg2_disp, int bg3_disp, int rainbow_disp);

/* Set a palette entry.
 *
 * pal_entry: Which palette entry to set the color of.
 * color:     The color to set. In Y8U4V4 format.
 */
void tetsu_set_palette(u16 pal_entry, u16 color);

/* Which palette to use for the VDC chips.
 *
 * Palettes are actually indexes into the palette which is the first color
 * to the chip. For example, if vdcbg was 4, then the 4th palette entry would
 * be color 0, 5th would be 1, etc.
 *
 * vdcbg:  Which palette to use for VDC backgrounds.
 * vdcspr: Which palette to use for VDC sprites.
 */
void tetsu_set_vdc_palette(u16 vdcbg, u16 vdcspr);

/* Which palette to use for the KING backgrounds.
 *
 * Palettes are actually indexes into the palette which is the first color
 * to the chip. For example, if bg0 was 4, then the 4th palette entry would
 * be color 0, 5th would be 1, etc.
 *
 * bg0: Which palette to use for KING background 0.
 * bg1: Which palette to use for KING background 1.
 * bg2: Which palette to use for KING background 2.
 * bg3: Which palette to use for KING background 3.
 */
void tetsu_set_king_palette(u16 bg0, u16 bg1, u16 bg2, u16 bg3);

/* Which palette to use for RAIBOW.
 *
 * Palettes are actually indexes into the palette which is the first color
 * to the chip. For example, if raibow was 4, then the 4th palette entry would
 * be color 0, 5th would be 1, etc.
 *
 * rainbow: Which palette to use for RAIBOW.
 */
void tetsu_set_rainbow_palette(u16 rainbow);

/* Set layer priorities.
 *
 * vdcbg:   Priority for the VDC backgrounds. (0 ~ 7)
 * vdcspr:  Priority for the VDC sprites. (0 ~ 7)
 * bg0:     Priority for KING BG0. (0 ~ 7)
 * bg1:     Priority for KING BG1. (0 ~ 7)
 * bg2:     Priority for KING BG2. (0 ~ 7)
 * bg3:     Priority for KING BG3. (0 ~ 7)
 * rainbow: Priority for RAINBOW. (0 ~ 7)
 */
void tetsu_set_priorities(u8 vdcbg, u8 vdcspr, u8 bg0, u8 bg1, u8 bg2,
				u8 bg3, u8 rainbow);

/* Set chroma color key values.
 *
 * Disable each colorkey by setting the minimum higher than the maximum.
 * maxy: Maximum Y.
 * miny: Minimum Y.
 * maxu: Maximum U.
 * minu: Minimum U.
 * maxv: Maximum V.
 * minv: Minimum V.
 */
void tetsu_set_chroma_key(u8 maxy, u8 miny, u8 maxu, u8 minu,
				u8 maxv, u8 minv);

/* Get the current raster.
 *
 * return: Current raster.
 */
int tetsu_get_raster(void);

/* Check which field is being displayed for interlaced mode.
 *
 * return: 1 if displaying odd field, 0 for even field.
 */
int tetsu_get_field(void);

/* Checks if we are currently displaying (not in H or V blank)
 *
 * return: 1 if we are displaying, 0 for in blank.
 */
int tetsu_is_displaying(void);

/* Sets the constant color for the cellophane.
 *
 * This color is either the color of the cellophane (in the case of it being
 * in front) or the color of the background (in the case of it being in back).
 *
 * color: Color in Y8U4V4 format.
 */
void tetsu_set_cellophane_color(u16 color);

/* Sets cellophane activity on sprites.
 *
 * banks: A 16-element array of 1s or 0s that contains whether that color
 *        palette bank receives cellophane treatment.
 */
void tetsu_set_cellophane_sprites(int* banks); /* 16 element array */

/* Set cellophane control.
 *
 * enable:   Whether the cellophane is being used or not.
 * in_front: Whether the cellophane is the constant color, or the active
 *           surfaces. If 1, it is the constant color.
 * vdcbg:    Which coefficient to use for VDC backgrounds.
 * vdcspr:   Which coefficient to use for VDC sprites.
 * bg0:      Which coefficient to use for KING BG0.
 * bg1:      Which coefficient to use for KING BG1.
 * bg2:      Which coefficient to use for KING BG2.
 * bg3:      Which coefficient to use for KING BG3.
 * rainbow:  Which coefficient to use for RAINBOW output.
 */
void tetsu_set_cellophane_control(int enable, int in_front,
				tetsu_coeff vdcbg, tetsu_coeff vdcspr,
				tetsu_coeff bg0, tetsu_coeff bg1,
				tetsu_coeff bg2, tetsu_coeff bg3,
				tetsu_coeff rainbow);

/* Set a cellophane coefficient.
 *
 * For coefficient information, see hardware documentation.
 *
 * coeff: Which coefficient to set the information for. (1 ~ 3)
 * ay:    Y component of the A coefficient.
 * au:    U component of the A coefficient.
 * av:    V component of the A coefficient.
 * by:    Y component of the B coefficient.
 * bu:    U component of the B coefficient.
 * bv:    V component of the B coefficient.
 */
void tetsu_set_cellophane_coeffs(int coeff, u8 ay, u8 au, u8 av,
				u8 by, u8 bu, u8 bv);

#endif

