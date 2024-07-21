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
#    '9' = filesys (Backup memory filesystem)
#
# Third digit = sequence 
#
#
.PHONY: all 000_hello_newlib 001_hello_plusplus 002_hello_no_libc\
     010_hello_interrupt 011_controller 019_bkupmem\
     020_vdc_simple_background 021_vdc_simple_sprite 022_vdc_raster 023_vdc_multi_sprite\
     cellophane psg scsi scsi_dma cd clean

all: 000_hello_newlib 001_hello_plusplus 002_hello_no_libc\
     010_hello_interrupt 011_controller 019_bkupmem\
     020_vdc_simple_background 021_vdc_simple_sprite 022_vdc_raster 023_vdc_multi_sprite\
     cellophane psg scsi scsi_dma 

000_hello_newlib:
	make -C $@
001_hello_plusplus:
	make -C $@
002_hello_no_libc:
	make -C $@
010_hello_interrupt:
	make -C $@
011_controller:
	make -C $@
019_bkupmem:
	make -C $@
020_vdc_simple_background:
	make -C $@
021_vdc_simple_sprite:
	make -C $@
022_vdc_raster:
	make -C $@
023_vdc_multi_sprite:
	make -C $@

cellophane:
	make -C $@
psg:
	make -C $@
scsi:
	make -C $@

cd:
	make -C 000_hello_newlib cd
	make -C 001_hello_plusplus cd
	make -C 002_hello_no_libc cd
	make -C 010_hello_interrupt cd
	make -C 011_controller cd
	make -C 019_bkupmem cd
	make -C 020_vdc_simple_background cd
	make -C 021_vdc_simple_sprite cd
	make -C 022_vdc_raster cd
	make -C 023_vdc_multi_sprite cd
	make -C psg cd
	make -C cellophane cd
	make -C scsi cd
	make -C scsi_dma cd

clean:
	make -C 000_hello_newlib clean
	make -C 001_hello_plusplus clean
	make -C 002_hello_no_libc clean
	make -C 010_hello_interrupt clean
	make -C 011_controller clean
	make -C 019_bkupmem clean
	make -C 020_vdc_simple_background clean
	make -C 021_vdc_simple_sprite clean
	make -C 022_vdc_raster clean
	make -C 023_vdc_multi_sprite clean
	make -C psg clean
	make -C cellophane clean
	make -C scsi clean
	make -C scsi_dma clean
