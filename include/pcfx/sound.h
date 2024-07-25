/*
        liberis -- A set of libraries for controlling the NEC PC-FX

Copyright (C) 2011              Alex Marshall "trap15" <trap15@raidenii.net>

# This code is licensed to you under the terms of the MIT license;
# see file LICENSE or http://www.opensource.org/licenses/mit-license.php
*/

/*! \file
 * \brief Low-level access to the SoundBox.
 */

#ifndef _LIBPCFX_SOUNDBOX_H_
#define _LIBPCFX_SOUNDBOX_H_

/*! \brief ADPCM sample rate.
 */
typedef enum {
	ADPCM_RATE_32000 = 0, /*!< 32kHz sample rate */
	ADPCM_RATE_16000 = 1, /*!< 16kHz sample rate */
	ADPCM_RATE_8000  = 2, /*!< 8kHz sample rate */
	ADPCM_RATE_4000  = 3, /*!< 4kHz sample rate */
} adpcm_rate;

/* Set main volume.
 *
 * left:  Left speaker output volume. (0 ~ 15)
 * right: Right speaker output volume. (0 ~ 15)
 */
void psg_set_main_volume(u8 left, u8 right);

/* Set the active channel to operate on.
 *
 * This affects which channel is changed for the functions
 * eris_psg_set_freq(), eris_psg_set_volume(),
 * eris_psg_set_balance(), eris_psg_waveform_data(),
 * and eris_psg_set_noise().
 *
 * chan: The channel to become active. (0 ~ 5)
 */
void psg_set_channel(u8 chan);

/* Set the frequency of the active channel.
 *
 * freq: The frequency of the channel. 12bit. Calculated as 
 *             n = (3580000 / 32) / freq
 */
void psg_set_freq(u16 freq);

/* Set the volume (and some controls) of the active channel.
 *
 * vol: Volume of the channel. (0 ~ 31)
 * on:  Controls whether the channel is on or off.
 * dda: Direct DAC access control. When enabled, waveform data is
 *            streamed through eris_psg_waveform_data().
 */
void psg_set_volume(u8 vol, u8 on, u8 dda);

/*  Set the balance on the active channel.
 * 
 * left:  Left speaker output volume. (0 ~ 15)
 * right: Right speaker output volume. (0 ~ 15)
 */
void psg_set_balance(u8 left, u8 right);

/* Write waveform data for the active channel.
 *
 * If DDA is off, writes to the waveform buffer and increases the index.
 * If it's on, it changes the current sample being played.
 *
 * sample: A 5bit unsigned sample. (0 ~ 31)
 */
void psg_waveform_data(u8 sample);

/* Set noise control data for the active channel.
 *
 * Only works on the last 2 channels (4 and 5).
 * freq:    Frequency of the noise. 5bit. Calculated as 
 *             n = (3580000 / 32) / freq
 * enabled: Whether the channel should or should not output noise.
 */
void psg_set_noise(u8 freq, u8 enabled);

/* Set LFO frequency.
 *
 * freq: The LFO's new frequency value. Influence is not simple; see
 *             hardware documentation.
 */
void psg_set_lfo_freq(u8 freq);

/* Set LFO controls.
 *
 * on:   Whether the LFO is enabled or not.
 * ctrl: LFO control. Influence is not simple; see hardware
 *             documentation.
 */
void psg_set_lfo_control(int on, int ctrl);

/* Set ADPCM controls.
 *
 * rate Sample rate for the ADPCM.
 * ch0_interp: Whether Channel 0 has linear interpolation enabled.
 * ch1_interp: Whether Channel 1 has linear interpolation enabled.
 * ch0_reset:  If set, reset Channel 0.
 * ch1_reset:  If set, reset Channel 1.
 */
void adpcm_set_control(adpcm_rate rate, u8 ch0_interp, u8 ch1_interp,
			u8 ch0_reset, u8 ch1_reset);

/* Set ADPCM channel volume.
 *
 * chan:  Which channel to set the volume of.
 * left:  Left speaker volume. (0 ~ 63)
 * right: Right speaker volume. (0 ~ 63)
 */
void adpcm_set_volume(u8 chan, u8 left, u8 right);

/* Set CDDA volume.
 *
 * left:  Left speaker volume. (0 ~ 63)
 * right: Right speaker volume. (0 ~ 63)
 */
void cdda_set_volume(u8 left, u8 right);

#endif

