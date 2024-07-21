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


/*****************************************************************************
 *  High-level VDC control                                                   *
 *****************************************************************************/
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


vdc_last_vdcnum:
	.hword	0
vdc_last_spr:
	.hword	0

vdc_curr_vdcport:   /* hardware port of current sprite-related operation */
	.word	0
vdc_curr_spr_addr:  /* Address in VRAM of the current sprite entry in SATB */
	.hword	0

satb_base:
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
        /*      "Never setup the timing on VDC-B" (MWR/HSR/HDR/VPR/VDR/VCR)             */

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


	/* setup sprite basics - vdcnum, vdcport, last_spr */

	mov	r19, r6
	movw	vdc_last_vdcnum, r10   /* address of storage  */
	st.h	r6, 0[r10]             /* place VDC num there */

	shl     8, r6                  /* pre-calc I/O port addr */
        movea   VDC_0_PORT, r6, r7
	movw    vdc_curr_vdcport, r8   /* address of storage */
	st.w	r7, 0[r8]              /* place port # there */


        /* Setup SATB */

        mov     r19, r6
        shl     8, r6                        /* r6 = vdc number */
        set_vreg_num    VDC_REG_DVSSR, r6, r10, r11   /* set VDC_REG_DVSSR to 0xFF00   */
        movw    0xFF00, r11 
        out.h   r11, 4[r10]

        movw    satb_base, r10     /* place value in satb_base array */
        mov     r19, r6
	shl	1, r6
        add     r6, r10
        st.h    r11, 0[r10]

	/* finish  sprite basics - vdcnum, vdcport, last_spr */

	movw	vdc_last_spr, r10      /* store 0 at vdc_last_spr */
	st.h	r0, 0[r10]

	movw	vdc_curr_spr_addr, r10
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
	movw	vdc_last_vdcnum, r10   /* address of storage  */
	st.h	r6, 0[r10]             /* place VDC num there */

	shl     8, r6                  /* pre-calc I/O port addr */
        movea   VDC_0_PORT, r6, r7
	movw    vdc_curr_vdcport, r8   /* address of storage */
	st.w	r7, 0[r8]              /* place port # there */

	jmp	[lp]


/*------------------------------------------*
 * void vdc_spr_set(int spr)                *
 *                                          *
 * inputs:                                  *
 *  r6 = spr                                *
 *------------------------------------------*/
_vdc_spr_set:
	andi	63, r6, r6
	movw	vdc_last_spr, r7       /* store at vdc_last_spr */
	st.h	r6, 0[r7]

	movw	vdc_last_vdcnum, r7
	ld.h    0[r7], r8              /* r8 = curr vdc */

	movw    satb_base, r7
	add     r8, r7                 /* get SATB addr for curr VDC */
	ld.h    0[r7], r8

	movw	vdc_curr_spr_addr, r7
	shl     2, r6                  /* each sprite entry is 4 16-bit words */
	add     r6, r8
	st.h    r8, 0[r7]

	jmp	[lp]


/*------------------------------------------*
 * void vdc_spr_x(u16 x)                    *
 *                                          *
 * inputs:                                  *
 *  r6 = x                                  *
 *------------------------------------------*/
_vdc_spr_x:
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	addi    1, r12, r12               /* X is second 16-bit word in sprite entry */

	out.h   r0, 0[r11]                /* set VDC_REG_MAWR */
	out.h   r12, 4[r11]               /* set addr to write */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	out.h   r6, 4[r11]                /* x addr is first */

	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_y(u16 y)                    *
 *                                          *
 * inputs:                                  *
 *  r6 = y                                  *
 *------------------------------------------*/
_vdc_spr_y:
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	out.h   r0, 0[r11]                /* set VDC_REG_MAWR */
	out.h   r12, 4[r11]               /* set addr to write */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	out.h   r6, 4[r11]                /* y addr is first */

	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_xy(u16 x, u16 y)            *
 *                                          *
 * inputs:                                  *
 *  r6 = x                                  *
 *  r7 = y                                  *
 *------------------------------------------*/
_vdc_spr_xy:
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	out.h   r0, 0[r11]                /* set VDC_REG_MAWR */
	out.h   r12, 4[r11]               /* set addr to write */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	out.h   r7, 4[r11]                /* y addr is first */

	addi    1, r12, r12               /* Add 1 to VRAM addr. This is necessary */
	out.h   r0, 0[r11]                /* only because we don't know whether it */
	out.h   r12, 4[r11]               /* is set to auto-increment by 1 */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	out.h   r6, 4[r11]                /* now, x addr */

	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_pattern(u16 pat)            *
 *                                          *
 * inputs:                                  *
 *  r6 = pat                                *
 *------------------------------------------*/
_vdc_spr_pattern:
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	addi    2, r12, r12               /* pattern is third 16-bit word in sprite entry */

	out.h   r0, 0[r11]                /* set VDC_REG_MAWR */
	out.h   r12, 4[r11]               /* set addr to write */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	out.h   r6, 4[r11]                /* pattern */

	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_ctrl(u16 val)               *
 *                                          *
 * inputs:                                  *
 *  r6 = val                                *
 *------------------------------------------*/
_vdc_spr_ctrl:
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	addi    3, r12, r12               /* control is fourth 16-bit word in sprite entry */

	out.h   r0, 0[r11]                /* set VDC_REG_MAWR */
	out.h   r12, 4[r11]               /* set addr to write */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	out.h   r6, 4[r11]                /* control */

	jmp	[lp]

/*------------------------------------------*
 * void vdc_spr_pal(int pal)                *
 *                                          *
 * inputs:                                  *
 *  r6 = pal                                *
 *------------------------------------------*/
_vdc_spr_pal:
	andi	0x000F, r6, r6            /* palette portion only */

	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	addi    3, r12, r12               /* control is fourth 16-bit word in sprite entry */

	movea   VDC_REG_MARR, r0, r13
	out.h   r13, 0[r11]               /* set VDC_REG_MARR */
	out.h   r12, 4[r11]               /* set addr to read */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	in.h    4[r11], r10               /* control data */

	andi	0xFFF0, r10, r10          /* remove palette portion */
	or	r6, r10                   /* new palette portion */

	out.h   r0, 0[r11]                /* set VDC_REG_MAWR */
	out.h   r12, 4[r11]               /* set addr to write */

	out.h   r13, 0[r11]               /* r13 still holds VDC_REG_DATA */
	out.h   r10, 4[r11]               /* output value */

	jmp	[lp]

/*------------------------------------------------------*
 * void vdc_spr_create(u16 x, u16 y, u16 pat, u16 ctrl) *
 *                                                      *
 * inputs:                                              *
 *  r6 = x                                              *
 *  r7 = y                                              *
 *  r8 = pat                                            *
 *  r9 = ctrl                                           *
 *------------------------------------------------------*/
_vdc_spr_create:
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	out.h   r0, 0[r11]                /* set VDC_REG_MAWR */
	out.h   r12, 4[r11]               /* set addr to write */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	out.h   r7, 4[r11]                /* y addr is first */

	addi    1, r12, r12               /* Add 1 to VRAM addr. This is necessary */
	out.h   r0, 0[r11]                /* only because we don't know whether it */
	out.h   r12, 4[r11]               /* is set to auto-increment by 1 */

	out.h   r13, 0[r11]               /* r13 is still VDC_REG_DATA */
	out.h   r6, 4[r11]                /* now, x addr */

	addi    1, r12, r12               /* Add 1 to VRAM addr. again */
	out.h   r0, 0[r11]                /* Set MAWR again */
	out.h   r12, 4[r11]

	out.h   r13, 0[r11]               /* r13 is still VDC_REG_DATA */
	out.h   r8, 4[r11]                /* now, pattern */

	addi    1, r12, r12               /* Add 1 to VRAM addr. again */
	out.h   r0, 0[r11]                /* Set MAWR again */
	out.h   r12, 4[r11]

	out.h   r13, 0[r11]               /* r13 is still VDC_REG_DATA */
	out.h   r9, 4[r11]                /* now, control */

	jmp	[lp]

/*------------------------------------------*
 * u16 vdc_spr_get_x(void)                  *
 *                                          *
 * inputs:                                  *
 *  None                                    *
 *                                          *
 * outputs:                                 *
 *  r10 = x                                 *
 *------------------------------------------*/
_vdc_spr_get_x:
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	addi    1, r12, r12               /* X is second 16-bit word in sprite entry */

	movea   VDC_REG_MARR, r0, r13
	out.h   r13, 0[r11]               /* set VDC_REG_MARR */
	out.h   r12, 4[r11]               /* set addr to read */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	in.h    4[r11], r10                /* x addr */

	jmp	[lp]


/*------------------------------------------*
 * u16 vdc_spr_get_y(void)                  *
 *                                          *
 * inputs:                                  *
 *  None                                    *
 *                                          *
 * outputs:                                 *
 *  r10 = y                                 *
 *------------------------------------------*/
_vdc_spr_get_y:
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	movea   VDC_REG_MARR, r0, r13
	out.h   r13, 0[r11]               /* set VDC_REG_MARR */
	out.h   r12, 4[r11]               /* set addr to read (and Y is first word) */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	in.h    4[r11], r10               /* y addr */

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
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	addi    2, r12, r12               /* pattern is third 16-bit word in sprite entry */

	movea   VDC_REG_MARR, r0, r13
	out.h   r13, 0[r11]               /* set VDC_REG_MARR */
	out.h   r12, 4[r11]               /* set addr to read */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	in.h    4[r11], r10               /* patttern */

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
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	addi    3, r12, r12               /* control is fourth 16-bit word in sprite entry */

	movea   VDC_REG_MARR, r0, r13
	out.h   r13, 0[r11]               /* set VDC_REG_MARR */
	out.h   r12, 4[r11]               /* set addr to read */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	in.h    4[r11], r10               /* control data */

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
	movw    vdc_curr_vdcport, r10
	ld.w    0[r10], r11               /* port address */

        movw    vdc_curr_spr_addr, r10
        ld.h    0[r10], r12               /* r12 = vid arr of sprite entry */

	addi    3, r12, r12               /* control is fourth 16-bit word in sprite entry */

	movea   VDC_REG_MARR, r0, r13
	out.h   r13, 0[r11]               /* set VDC_REG_MARR */
	out.h   r12, 4[r11]               /* set addr to read */

	movea   VDC_REG_DATA, r0, r13
	out.h   r13, 0[r11]
	in.h    4[r11], r10               /* control data */

	andi	0xF, r10, r10             /* palette portion */

	jmp	[lp]


/*****************************************************************************
 *  Low-level VDC functions                                                  *
 *****************************************************************************/
        .global _vdc_status
        .global _vdc_setreg
        .global _vdc_get_last_regnum
        .global _vdc_set_vram_write
        .global _vdc_vram_write
        .global _vdc_set_vram_read
        .global _vdc_vram_read
        .global _vdc_set_raster
        .global _vdc_set_scroll
        .global _vdc_do_dma
        .global _vdc_set_satb_address


/*-----------------------------------------------------------*
 * u16 vdc_status(int chip)                                  *
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

/*-----------------------------------------------------------*
 * void vdc_set_raster(int chip, int raster)                 *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip:    which VDC chip to act on (0 - 1)           *
 *  r7 = raster:  Raster to generate interrupt on            *
 *                (This should be raster line + 64)          *
 *-----------------------------------------------------------*/
_vdc_set_raster:
        shl     8, r6
        set_vreg_num    VDC_REG_RCR, r6, r10, r11
        out.h   r7, 4[r10]
        jmp     [lp]

/*-----------------------------------------------------------*
 * void vdc_set_scroll(int chip, u16 x, u16 y)               *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip: which VDC chip to act on (0 - 1)              *
 *  r7 = x:    Top-left X coordinate of background           *
 *  r7 = y:    Top-left Y coordinate of background           *
 *-----------------------------------------------------------*/
_vdc_set_scroll:
        shl     8, r6
        set_vreg_num    VDC_REG_BXR, r6, r10, r11
        out.h   r7, 4[r10]
        set_vreg_num    VDC_REG_BYR, r6, r10, r11
        out.h   r8, 4[r10]
        jmp     [lp]

/*-----------------------------------------------------------*
 * void vdc_do_dma(int chip, u16 src, u16 dst, u16 len)      *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip: which VDC chip to act on (0 - 1)              *
 *  r7 = src:  Source address of the DMA                     *
 *  r8 = dst:  Destination address of the DMA                *
 *  r9 = len:  Number of 16-bit words to transfer            *
 *-----------------------------------------------------------*/
_vdc_do_dma:
        shl     8, r6
        set_vreg_num    VDC_REG_SOUR, r6, r10, r11
        out.h   r7, 4[r10]
        set_vreg_num    VDC_REG_DESR, r6, r10, r11
        out.h   r8, 4[r10]
        set_vreg_num    VDC_REG_LENR, r6, r10, r11
        out.h   r9, 4[r10]
        jmp     [lp]

/*-----------------------------------------------------------*
 * void vdc_set_satb_address(int chip, u16 addr)             *
 *                                                           *
 * inputs:                                                   *
 *  r6 = chip:  which VDC chip to act on (0 - 1)             *
 *  r7 = addr:  VRAM address for the start of the SATB.      *
 *    Note: This also sets a new base address for the        *
 *          sprite functions to use                          *
 *-----------------------------------------------------------*/
_vdc_set_satb_address:
        mov     r6, r12
        shl     8, r6
        set_vreg_num    VDC_REG_DVSSR, r6, r10, r11
        out.h   r7, 4[r10]

        movw    satb_base, r10         /* array for SATB locations */
	shl	1, r12                  /* array index * 2 (size)   */
        add     r12, r10
        st.h    r7, 0[r10]              /* save new SATB address for sprite function use */

        jmp     [lp]


