# tc_vdp_v9958 - Required Source Files

## Module wrapper (new)
- `tc_vdp_v9958/src/tc_vdp_v9958.v` - Top-level module wrapper
- `tc_vdp_v9958/src/ram64k.v` - BSRAM-based 64KB VRAM (x2 instances = 128KB)

## VDP core (from tn_vdp_v3_v9958)
- `tn_vdp_v3_v9958/src/vdp/vdp.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_package.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_colordec.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_command.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_doublebuf.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_graphic123m.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_graphic4567.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_hvcounter.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_interrupt.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_linebuf.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_ntsc_pal.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_register.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_spinforam.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_sprite.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_ssg.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_text12.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_vga.vhd`
- `tn_vdp_v3_v9958/src/vdp/vdp_wait_control.vhd`
- `tn_vdp_v3_v9958/src/vdp/vencode.vhd`
- `tn_vdp_v3_v9958/src/ram.vhd` (internal RAM for VDP core)

## HDMI encoder (from tn_vdp_v3_v9958 - V9958 variant with external serializer)
- `tn_vdp_v3_v9958/src/hdmi/hdmi.sv`
- `tn_vdp_v3_v9958/src/hdmi/serializer.sv`
- `tn_vdp_v3_v9958/src/hdmi/tmds_channel.sv`
- `tn_vdp_v3_v9958/src/hdmi/packet_assembler.sv`
- `tn_vdp_v3_v9958/src/hdmi/packet_picker.sv`
- `tn_vdp_v3_v9958/src/hdmi/audio_clock_regeneration_packet.sv`
- `tn_vdp_v3_v9958/src/hdmi/audio_info_frame.sv`
- `tn_vdp_v3_v9958/src/hdmi/audio_sample_packet.sv`
- `tn_vdp_v3_v9958/src/hdmi/auxiliary_video_information_info_frame.sv`
- `tn_vdp_v3_v9958/src/hdmi/source_product_description_info_frame.sv`

## Utility (from tn_vdp_v3_v9958)
- `tn_vdp_v3_v9958/src/clockdiv.v` (CLOCK_DIV - differential clock divider)

## NOT needed (removed from standalone design)
- SDRAM controller (memory_controller.v, sdram.v) - replaced by BSRAM
- Pin filter (pinfilter.v) - not needed for internal bus
- SPI ADC (SPI_MCP3202.v) - no external ADC
- LPF (lpf.vhd) - audio filter for external ADC
- Gowin PLL IPs (clk_108p, clk_135, etc.) - parent provides clocks

## Clock requirements
- `clk_21m`: 21.477 MHz (VDP core clock, also used as HDMI pixel clock)
- `clk_135m`: 135 MHz (5x 27MHz, used for HDMI TMDS serialization)

## BSRAM usage
- 2x 64KB = 128KB total VRAM (uses ~1024 Kbit of BSRAM)
- GW5AST-138K has 6,120 Kbit BSRAM - plenty of headroom
- GW5A-60K has 2,124 Kbit BSRAM - still fits comfortably
