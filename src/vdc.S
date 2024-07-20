/*
        libp cfx -- A set of libraries for controlling the NEC PC-FX

                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff  <GitHub ID: dshadoff>


# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*****************************************************************************
 *  Named values (no 'magic numbers' please)                                 *
 *****************************************************************************/
.equiv VDC_0_PORT,    0x0400
.equiv VDC_0_LAST_AR, 0x0C00
.equiv VDC_1_PORT,    0x0500
.equiv VDC_1_LAST_AR, 0x0C40

.equiv VDC_REG_MAWR,  0x00      /* Memory Address Write register */
.equiv VDC_REG_MARR,  0x01      /* Memory Address Read register */
.equiv VDC_REG_DATA,  0x02      /* Data (write or read) */
.equiv VDC_REG_CR,    0x05      /* Control register */
.equiv VDC_REG_RCR,   0x06      /* Raster Counter register */
.equiv VDC_REG_BXR,   0x07      /* BGX Scroll register */
.equiv VDC_REG_BYR,   0x08      /* BGY Scroll register */
.equiv VDC_REG_MWR,   0x09      /* Memory Access Width register */
.equiv VDC_REG_HSR,   0x0A      /* Horizontal Sync register */
.equiv VDC_REG_HDR,   0x0B      /* Horizontal Display register */
.equiv VDC_REG_VPR,   0x0C      /* Vertical Sync register */
.equiv VDC_REG_VDR,   0x0D      /* Vertical Display register */
.equiv VDC_REG_VCR,   0x0E      /* Vertical Display End Position register */
.equiv VDC_REG_DCR,   0x0F      /* Block Transfer Control register */
.equiv VDC_REG_SOUR,  0x10      /* Block Transfer Source Address register */
.equiv VDC_REG_DESR,  0x11      /* Block Transfer Destination Address register */
.equiv VDC_REG_LENR,  0x12      /* Block Transfer Length register */
.equiv VDC_REG_DVSSR, 0x13      /* VRAM-SATB Block Transfer Source Address register */

.equiv VDC_MWR_SCREEN_64x32, 0x0010  /* Bitfield for virtual screen map of  64 wide, 32 tall */

.equiv VDC_DCR_SATB_AUTO,    0x0010  /* Automatically trigger SATB each VBlank */


/*****************************************************************************
 *  Macros                                                                   *
 *****************************************************************************/
/* movw moves a data value into a register
 */
.macro  movw data, reg1
        movhi   hi(\data),r0,\reg1
        movea   lo(\data),\reg1,\reg1
.endm

/* set_vreg_reg a, b, c
 *
 *  outputs value 'a' to port at 0x400 + 'b' ('c' is scratch register)
 */
.macro  set_vreg_reg    reg, ch, tmp
        movea   VDC_0_PORT, \ch, \tmp
        out.h   \reg, 0[\tmp]
.endm

/* set_vreg_num a, b, c, d
 *
 *  outputs value 'a' to port at 0x400 + 'b' ('c' and 'd' are scratch registers)
 *  In this version, value 'a' is a non-register value
 */
.macro  set_vreg_num    reg, ch, tmp1, tmp2
        movea   \reg, r0, \tmp2
        set_vreg_reg    \tmp2, \ch, \tmp1
.endm



.macro get_vdc vdcreg
	movhi	hi(vdc_last_sup), r0, \vdcreg
	ld.w	lo(vdc_last_sup)[\vdcreg], \vdcreg
.endm

.macro setup_addr sprreg, vdcreg, calcreg, off
	movhi	hi(vdc_last_sup), r0, \vdcreg
	movea	lo(vdc_last_spr), r0, \sprreg
	ld.w	lo(vdc_last_sup)[\vdcreg], \vdcreg
	movhi	hi(vdc_last_spr), \sprreg, \sprreg
	add	\vdcreg, \sprreg
	ld.w	0[\sprreg], \sprreg

	shl	2, \sprreg
	ori	0xFF00|\off, \sprreg, \calcreg
.endm

/*****************************************************************************
 *  High-level VDC control                                                   *
 *****************************************************************************/
	.global	_satb_base
	.global	_vdc_init_5MHz
	.global	_vdc_init_7MHz
	.global	_vdc_set

	.global	_vdc_spr_set
	.global	_vdc_spr_x
	.global	_vdc_spr_y
	.global	_vdc_spr_xy
	.global	_vdc_spr_pattern
	.global	_vdc_spr_pri
	.global	_vdc_spr_pal
	.global	_vdc_spr_ctrl
	.global	_vdc_spr_create
	.global	_vdc_spr_get_x
	.global	_vdc_spr_get_y
	.global	_vdc_spr_get_pattern


vdc_last_sup:
	.word	0
vdc_last_spr:
	.word	0, 0

_satb_base:
	.hword  0   /* SATB location on VDC 0 */
	.hword  0   /* SATB location on VDC 1 */


regtable_5MHz:
	.hword VDC_REG_CR, 0                      /* no IRQ, sprite & BG invisible, auto-inc=1 */
	.hword VDC_REG_RCR, 0
	.hword VDC_REG_BXR, 0
	.hword VDC_REG_BYR, 0
	.hword VDC_REG_MWR, VDC_MWR_SCREEN_64x32
	.hword VDC_REG_HSR, 0x0202                /* 256 x 239 */
	.hword VDC_REG_HDR, 0x041F
	.hword VDC_REG_VPR, 0x1102
	.hword VDC_REG_VDR, 0x00EF
	.hword VDC_REG_VCR, 0x0002
	.hword VDC_REG_DCR, VDC_DCR_SATB_AUTO

regtable_7MHz:
	.hword VDC_REG_CR, 0                      /* no IRQ, sprite & BG invisible, auto-inc=1 */
	.hword VDC_REG_RCR, 0
	.hword VDC_REG_BXR, 0
	.hword VDC_REG_BYR, 0
	.hword VDC_REG_MWR, VDC_MWR_SCREEN_64x32
	.hword VDC_REG_HSR, 0x0303                /* 352 x 239 */
	.hword VDC_REG_HDR, 0x062B
	.hword VDC_REG_VPR, 0x1102
	.hword VDC_REG_VDR, 0x00EF
	.hword VDC_REG_VCR, 0x0002
	.hword VDC_REG_DCR, VDC_DCR_SATB_AUTO

/*------------------------------------------*
 * void vdc_init_5MHz(int chip)             *
 * void vdc_init_7MHz(int chip)             *
 *                                          *
 * inputs:                                  *
 *  r6 = chip                               *
 *------------------------------------------*/
_vdc_init_5MHz:
        movw    regtable_5MHz, r12
        jr      vdc_init

_vdc_init_7MHz:
        movw    regtable_7MHz, r12

vdc_init:
	andi	1, r6, r19        /* enforce only 0 or 1 values */
	mov	r19, r6

        /* Clear VRAM (0x10000 16-bit words, starting at address 0x0000) */
        /* Start by setting Write register to 0x0000 and Auto-inc to 1   */

        shl     8, r6                        /* r6 = vdc number */
        set_vreg_num    VDC_REG_CR, r6, r10, r11    /* set VDC_REG_CR to 0 */
        out.h   r0, 4[r10]                          /* = no IRQ, auto-inc = 1, don't display BG/SP */

        set_vreg_num    VDC_REG_MAWR, r6, r10, r11  /* set VDC_REG_MAWR to 0 */
        out.h   r0, 4[r10]

        set_vreg_num    VDC_REG_DATA, r6, r10, r11  /* prepare to write to VRAM (at 0x0000) */

        movhi   1, r0, r8                    /* set r8 to 0x10000 */
1:
        out.h   r0, 4[r10]                   /* write 4 16-bit '0' values to VRAM */
        out.h   r0, 4[r10]
        out.h   r0, 4[r10]
        out.h   r0, 4[r10]
        add     -4, r8                       /* count down by 4 */
        bne     1b


        /* Setup the remaining registers according to the table referenced at the start */

        /* Note that old code said (and I don't know why):                              */
        /*      "Never setup the timing on 7up-B" (MWR/HSR/HDR/VPR/VDR/VCR)             */

	mov	r19, r6
        shl     8, r6                        /* r6 = vdc number */

        movea   VDC_0_PORT, r6, r10          /* setup base I/O port for VDC */
        mov     11, r8                       /* 11 registers to set */
2:
        ld.h    0[r12], r11                  /* register number */
        out.h   r11, 0[r10]
        ld.h    2[r12], r11                  /* register value  */
        out.h   r11, 4[r10]

        add     4, r12                       /* loop to next entry */
        add     -1, r8
        bne     2b


        /********/
        /* Not sure what this "sprite stuff" does yet */

	mov	r19, r6
	# sprite stuff
	movhi	hi(vdc_last_sup), r0, r10
	movea	lo(vdc_last_spr), r0, r11
	movhi	hi(vdc_last_spr), r11, r11

	st.w	r19, lo(vdc_last_sup)[r10]
	shl	2, r6
	add	r6, r11
	st.w	r0, 0[r11]
        /********/


        /* Setup SATB */

        mov     r19, r6
        shl     8, r6                        /* r6 = vdc number */
        set_vreg_num    VDC_REG_DVSSR, r6, r10, r11   /* set VDC_REG_DVSSR to 0xFF00   */
        movw    0xFF00, r11 
        out.h   r11, 4[r10]

        movw    _satb_base, r10     /* place value in _satb_base array */
        mov     r19, r6
	shl	1, r6
        add     r6, r10
        st.h    r11, 0[r10]

	jmp	[lp]

/*------------------------------------------*
 * void vdc_set(int chip)                   *
 *                                          *
 * inputs:                                  *
 *  r6 = chip                               *
 *------------------------------------------*/
_vdc_set:
	andi	1, r6, r6
	movhi	hi(vdc_last_sup), r0, r10
	st.w	r6, lo(vdc_last_sup)[r10]
	jmp	[lp]


/*------------------------------------------*
 * void vdc_spr_set(int spr)                *
 *                                          *
 * inputs:                                  *
 *  r6 = spr                                *
 *------------------------------------------*/
_vdc_spr_set:
	andi	63, r6, r6
	movhi	hi(vdc_last_sup), r0, r10
	movea	lo(vdc_last_spr), r0, r11
	ld.w	lo(vdc_last_sup)[r10], r10
	movhi	hi(vdc_last_spr), r11, r11
	add	r10, r11
	st.w	r6, 0[r11]
	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_x(s16 x)                    *
 *                                          *
 * inputs:                                  *
 *  r6 = x                                  *
 *------------------------------------------*/
_vdc_spr_x:
	mov	lp, r17
	setup_addr	r20, r19, r18, 1
	mov	r6, r16

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_write

	mov	r19, r6
	mov	r16, r7
	jal	_vdc_vram_write

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_y(s16 y)                    *
 *                                          *
 * inputs:                                  *
 *  r6 = y                                  *
 *------------------------------------------*/
_vdc_spr_y:
	mov	lp, r17
	setup_addr	r20, r19, r18, 0
	mov	r6, r16

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_write

	mov	r19, r6
	mov	r16, r7
	jal	_vdc_vram_write

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_xy(s16 x, s16 y)            *
 *                                          *
 * inputs:                                  *
 *  r6 = x                                  *
 *  r7 = y                                  *
 *------------------------------------------*/
_vdc_spr_xy:
	mov	lp, r17
	setup_addr	r20, r19, r18, 0
	mov	r6, r16
	mov	r7, r15

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_write

	mov	r19, r6
	mov	r15, r7
	jal	_vdc_vram_write

	mov	r19, r6
	mov	r16, r7
	jal	_vdc_vram_write

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_pattern(u16 pat)            *
 *                                          *
 * inputs:                                  *
 *  r6 = pat                                *
 *------------------------------------------*/
_vdc_spr_pattern:
	mov	lp, r17
	setup_addr	r20, r19, r18, 2
	mov	r6, r16

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_write

	mov	r19, r6
	mov	r16, r7
	jal	_vdc_vram_write

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_pri(int pri)                *
 *                                          *
 * inputs:                                  *
 *  r6 = pri                                *
 *------------------------------------------*/
_vdc_spr_pri:
	mov	lp, r17
	setup_addr	r20, r19, r18, 3
	mov	r6, r16

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_write

	shl	7, r16

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_read

	mov	r19, r6
	jal	_vdc_vram_read

	andi	0x80, r10, r7
	or	r16, r7
	mov	r19, r6
	jal	_vdc_vram_write

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_pal(int pal)                *
 *                                          *
 * inputs:                                  *
 *  r6 = pal                                *
 *------------------------------------------*/
_vdc_spr_pal:
	mov	lp, r17
	setup_addr	r20, r19, r18, 3
	andi	0xF, r6, r16

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_write

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_read

	mov	r19, r6
	jal	_vdc_vram_read

	andi	0xFFF0, r10, r7
	or	r16, r7
	mov	r19, r6
	jal	_vdc_vram_write

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_ctrl(u16 mask, u16 val)     *
 *                                          *
 * inputs:                                  *
 *  r6 = mask                               *
 *  r7 = val                                *
 *------------------------------------------*/
_vdc_spr_ctrl:
	mov	lp, r17
	setup_addr	r20, r19, r18, 3
	mov	r6, r16
	mov	r7, r15

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_write

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_read

	mov	r19, r6
	jal	_vdc_vram_read
	mov	r10, r7

	and	r16, r7
	or	r15, r7
	mov	r19, r6
	jal	_vdc_vram_write

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------------------*
 * void vdc_spr_create(s16 x, s16 y, u16 pat, u16 ctrl) *
 *                                                      *
 * inputs:                                              *
 *  r6 = x                                              *
 *  r7 = y                                              *
 *  r8 = pat                                            *
 *  r9 = ctrl                                           *
 *------------------------------------------------------*/
_vdc_spr_create:
	mov	lp, r17
	setup_addr	r20, r19, r18, 0
	mov	r6, r16
	mov	r7, r15

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_write

	mov	r19, r6
	mov	r15, r7
	jal	_vdc_vram_write

	mov	r19, r6
	mov	r16, r7
	jal	_vdc_vram_write

	mov	r19, r6
	mov	r8, r7
	jal	_vdc_vram_write

	mov	r19, r6
	mov	r9, r7
	jal	_vdc_vram_write

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * s16 vdc_spr_get_x(void)                  *
 *                                          *
 * inputs:                                  *
 *  None                                    *
 *                                          *
 * outputs:                                 *
 *  r10 = x                                 *
 *------------------------------------------*/
_vdc_spr_get_x:
	mov	lp, r17
	setup_addr	r20, r19, r18, 1

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_read

	mov	r19, r6
	jal	_vdc_vram_read

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * s16 vdc_spr_get_y(void)                  *
 *                                          *
 * inputs:                                  *
 *  None                                    *
 *                                          *
 * outputs:                                 *
 *  r10 = y                                 *
 *------------------------------------------*/
_vdc_spr_get_y:
	mov	lp, r17
	setup_addr	r20, r19, r18, 0

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_read

	mov	r19, r6
	jal	_vdc_vram_read

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * u16 vdc_spr_get_pattern(void)            *
 *                                          *
 * inputs:                                  *
 *  None                                    *
 *                                          *
 * outputs:                                 *
 *  r10 = pattern                           *
 *------------------------------------------*/
_vdc_spr_get_pattern:
	mov	lp, r17
	setup_addr	r20, r19, r18, 2

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_read

	mov	r19, r6
	jal	_vdc_vram_read

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * u16 vdc_spr_get_ctrl(void)               *
 *                                          *
 * inputs:                                  *
 *  None                                    *
 *                                          *
 * outputs:                                 *
 *  r10 = control bit pattern               *
 *------------------------------------------*/
_vdc_spr_get_ctrl:
	mov	lp, r17
	setup_addr	r20, r19, r18, 3

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_read

	mov	r19, r6
	jal	_vdc_vram_read

	mov	r17, lp
	jmp	[lp]

/*------------------------------------------*
 * int vdc_spr_get_pal(void)                *
 *                                          *
 * inputs:                                  *
 *  None                                    *
 *                                          *
 * outputs:                                 *
 *  r10 = palette                           *
 *------------------------------------------*/
_vdc_spr_get_pal:
	mov	lp, r17
	setup_addr	r20, r19, r18, 1

	mov	r19, r6
	mov	r18, r7
	jal	_vdc_set_vram_read

	mov	r19, r6
	jal	_vdc_vram_read

	andi	0xF, r10, r10

	mov	r17, lp
	jmp	[lp]



/*****************************************************************************
 *  Low-level 7up functions                                                  *
 *****************************************************************************/
        .global _vdc_status
        .global _vdc_setreg
        .global _vdc_get_last_regnum
        .global _vdc_set_vram_write
        .global _vdc_vram_write
        .global _vdc_set_vram_read
        .global _vdc_vram_read
        .global _vdc_set_interrupt_raster
        .global _vdc_set_scroll
        .global _vdc_do_dma
        .global _vdc_setup_dma
        .global _vdc_set_satb_address


/*-----------------------------------------------------------*
 * s16 vdc_status(int chip)                                  *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip:  which VDC chip to act on (0 - 1)             *
 *                                                           *
 * output:                                                   *
 *  r10 = status of VDC chip                                 *
 *-----------------------------------------------------------*/
_vdc_status:
        shl     8, r6                        /* r6 = vdc number */
        movea   VDC_0_PORT, r6, r7           /* r7 set to VDC base port number */
        in.h    0[r7], r10
        jmp     [lp]

/*-----------------------------------------------------------*
 * void vdc_setreg(int chip, int reg, int value)             *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip:  which VDC chip to act on (0 - 1)             *
 *  r7 = reg:   Which VDC register to initialize. (0 ~ 0x13) *
 *  r8 = value: The value to set it to (0 ~ 0xFFFF)          *
 *-----------------------------------------------------------*/
_vdc_setreg:
        shl     8, r6
        set_vreg_reg    r7, r6, r10
        out.h   r8, 4[r10]
        jmp     [lp]

/*-----------------------------------------------------------*
 * void vdc_get_last_regnum(int chip)                        *
 *   Needed during interrupt service, if VDC registers       *
 *   are updated: fetch this, do updates, and then set       *
 *   the register back to what it was (fetched from here)    *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip: which VDC chip to act on (0 - 1)              *
 *                                                           *
 * output:                                                   *
 *  r10= reg:  Last register number (address register) set   *
 *             on that VDC                                   *
 *                                                           *
 *  Note: 0x13 (DVSSR) would return as 0x03                  *
 *        0x10, 0x11, 0x12 (DMA-related) are not saved       *
 *        so DMA should not be run while IRQs are possible   *
 *-----------------------------------------------------------*/
_vdc_get_last_regnum:
        shl     6, r6
        movea   VDC_0_LAST_AR, r6, r7
        in.h    0[r7], r10
        jmp     [lp]


/*-----------------------------------------------------------*
 * void vdc_set_vram_write(int chip, u16 addr)               *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip:  which VDC chip to act on (0 - 1)             *
 *  r7 = addr:  Address to write to (0 ~ 0xFFFF)             *
 *-----------------------------------------------------------*/
_vdc_set_vram_write:
        shl     8, r6
        set_vreg_reg    r0, r6, r10
        out.h   r7, 4[r10]
        jmp     [lp]

/*-----------------------------------------------------------*
 * void vdc_vram_write(int chip, u16 data)                   *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip:  which VDC chip to act on (0 - 1)             *
 *  r7 = data:  Data to write                                *
 *-----------------------------------------------------------*/
_vdc_vram_write:
        shl     8, r6
        set_vreg_num    VDC_REG_DATA, r6, r10, r11
        out.h   r7, 4[r10]
        jmp     [lp]

/*-----------------------------------------------------------*
 * void vdc_set_vram_read(int chip, u16 addr)                *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip:  which VDC chip to act on (0 - 1)             *
 *  r7 = addr:  Address to write to (0 ~ 0xFFFF)             *
 *-----------------------------------------------------------*/
_vdc_set_vram_read:
        shl     8, r6
        set_vreg_num    VDC_REG_MARR, r6, r10, r11
        out.h   r7, 4[r10]
        jmp     [lp]

/*-----------------------------------------------------------*
 * u16 vdc_vram_read(int chip)                               *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip:  which VDC chip to act on (0 - 1)             *
 *                                                           *
 * returns:                                                  *
 *  r10 = data: Data Read                                    *
 *-----------------------------------------------------------*/
_vdc_vram_read:
        shl     8, r6
        set_vreg_num    VDC_REG_DATA, r6, r10, r11
        in.h    4[r10], r10
        jmp     [lp]

/* Note - 64 = first line */
_vdc_set_interrupt_raster:
        shl     8, r6
        set_vreg_num    VDC_REG_RCR, r6, r10, r11
        out.h   r7, 4[r10]
        jmp     [lp]

_vdc_set_scroll:
        shl     8, r6
        set_vreg_num    VDC_REG_BXR, r6, r10, r11
        out.h   r7, 4[r10]
        set_vreg_num    VDC_REG_BYR, r6, r10, r11
        out.h   r8, 4[r10]
        jmp     [lp]

_vdc_do_dma:
        shl     8, r6
        set_vreg_num    VDC_REG_SOUR, r6, r10, r11
        out.h   r7, 4[r10]
        set_vreg_num    VDC_REG_DESR, r6, r10, r11
        out.h   r8, 4[r10]
        set_vreg_num    VDC_REG_LENR, r6, r10, r11
        out.h   r9, 4[r10]
        jmp     [lp]

_vdc_setup_dma:
        ld.w    0[sp], r10
        ld.w    4[sp], r11
        shl     8, r6
        shl     4, r7
        shl     3, r8
        shl     2, r9
        shl     1, r10
        or      r8, r7
        or      r9, r7
        or      r10, r7
        or      r11, r7
        set_vreg_num    VDC_REG_DCR, r6, r10, r11
        out.h   r7, 4[r10]
        jmp     [lp]

/* 
*/
_vdc_set_satb_address:
        mov     r6, r12
        shl     8, r6
        set_vreg_num    VDC_REG_DVSSR, r6, r10, r11
        out.h   r7, 4[r10]

        movw    _satb_base, r10
	shl	1, r12
        add     r12, r10
        st.h    r7, 0[r10]

        jmp     [lp]


