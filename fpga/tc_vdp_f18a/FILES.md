# tc_vdp_f18a - Required Source Files

## Module wrapper (new)
- `tc_vdp_f18a/src/tc_vdp_f18a.v` - Top-level module wrapper

## F18A core (from tn_vdp_v1)
- `tn_vdp_v1/src/f18a/f18a_core.vhd`
- `tn_vdp_v1/src/f18a/f18a_color.vhd`
- `tn_vdp_v1/src/f18a/f18a_counters.vhd`
- `tn_vdp_v1/src/f18a/f18a_cpu.vhd`
- `tn_vdp_v1/src/f18a/f18a_div32x16.vhd`
- `tn_vdp_v1/src/f18a/f18a_gpu.vhd`
- `tn_vdp_v1/src/f18a/f18a_single_port_ram.vhd`
- `tn_vdp_v1/src/f18a/f18a_sprites.vhd`
- `tn_vdp_v1/src/f18a/f18a_tile_linebuf.vhd`
- `tn_vdp_v1/src/f18a/f18a_tiles.vhd`
- `tn_vdp_v1/src/f18a/f18a_top.vhd`
- `tn_vdp_v1/src/f18a/f18a_version.vhd`
- `tn_vdp_v1/src/f18a/f18a_vga_cont_640_60.vhd`
- `tn_vdp_v1/src/f18a/f18a_vram.vhd`

## HDMI encoder (from tn_vdp_v1 - F18A variant with built-in serializer)
**IMPORTANT**: Use the v1 hdmi.sv, NOT the v3 version. They have different port lists.

- `tn_vdp_v1/src/hdmi/hdmi.sv`
- `tn_vdp_v1/src/hdmi/serializer.sv`
- `tn_vdp_v1/src/hdmi/tmds_channel.sv`
- `tn_vdp_v1/src/hdmi/packet_assembler.sv`
- `tn_vdp_v1/src/hdmi/packet_picker.sv`
- `tn_vdp_v1/src/hdmi/audio_clock_regeneration_packet.sv`
- `tn_vdp_v1/src/hdmi/audio_info_frame.sv`
- `tn_vdp_v1/src/hdmi/audio_sample_packet.sv`
- `tn_vdp_v1/src/hdmi/auxiliary_video_information_info_frame.sv`
- `tn_vdp_v1/src/hdmi/source_product_description_info_frame.sv`

## NOT needed (removed from standalone design)
- Gowin PLL/CLKDIV IPs - parent provides clocks
- Pin filter - not needed for internal bus
- 16K RAM (ram16k.v) - VRAM is internal to F18A core

## Clock requirements
- `clk_50m`: 50 MHz (F18A core clock - despite port name clk_100m0_i, it runs at 50 MHz)
- `clk_25m`: 25 MHz pixel clock (VGA 640x480)
- `clk_125m`: 125 MHz (5x pixel clock for HDMI serialization)

## BSRAM usage
- F18A includes its own 16KB VRAM internally (f18a_vram.vhd)
- Minimal BSRAM footprint compared to V9958
