#
# Examples are sequenced according to complexity
# 
# First digit =
#    '0' = basic examples
#    >0  = more complex/exotic examples
#
# Second digit = major hardware
#    '0' = compiler
#    '1' = CPU/basic I/O - including interrupts, joypad controllers & backup memory
#    '2' = HuC6270 = Tile/Sprite video processor (same as PC Engine)
#    '3' = HuC6230 = Soundbox (PSG & ADPCM)
#    '4' = HuC6272 = King video processor, DMA engine, SCSI controller (CD)
#    '5' = HuC6261 = palette control
#    '6' = HuC6271 (Rainbow - MJPEG)
#
# Third digit = sequence 
#
#
.PHONY: all 000_hello_newlib 001_hello_plusplus 002_hello_no_libc 010_hello_interrupt\
     fxbmp fxpad cellophane psg bg7up spr7up scsi scsi_dma cd clean

all: 000_hello_newlib 001_hello_plusplus 002_hello_no_libc 010_hello_interrupt\
     fxbmp fxpad cellophane psg bg7up spr7up scsi scsi_dma 

000_hello_newlib:
	make -C $@
001_hello_plusplus:
	make -C $@
002_hello_no_libc:
	make -C $@
010_hello_interrupt:
	make -C $@

fxbmp:
	make -C $@
fxpad:
	make -C $@
cellophane:
	make -C $@
psg:
	make -C $@
bg7up:
	make -C $@
spr7up:
	make -C $@
scsi:
	make -C $@

cd:
	make -C 000_hello_newlib cd
	make -C 001_hello_plusplus cd
	make -C 002_hello_no_libc cd
	make -C 010_hello_interrupt cd
	make -C fxpad cd
	make -C bg7up cd
	make -C spr7up cd
	make -C fxbmp cd
	make -C psg cd
	make -C cellophane cd
	make -C scsi cd
	make -C scsi_dma cd

clean:
	make -C 000_hello_newlib clean
	make -C 001_hello_plusplus clean
	make -C 002_hello_no_libc clean
	make -C 010_hello_interrupt clean
	make -C fxpad clean
	make -C bg7up clean
	make -C spr7up clean
	make -C fxbmp clean
	make -C psg clean
	make -C cellophane clean
	make -C scsi clean
	make -C scsi_dma clean
