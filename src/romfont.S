/*
        libpcfx -- A set of libraries for controlling the NEC PC-FX
                   Based on liberis by Alex Marshall

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>
      and (C) 2024              Dave Shadoff <GitHub user: dshadoff>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*****************************************************************************
 *  ROM Font handling                                                    []  *
 *****************************************************************************/
	.global	_romfont_get

/* TODO: Maybe ABI needs conversion? */
_romfont_get:
	mov	0xC, r10
	movhi	0xFFF0, r10, r10
	jmp	[r10]
