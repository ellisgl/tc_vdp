# TC VDP

VDP (Video Display Processor) modules for Tang Console 60K / 138K FPGA projects.

Forked from [lfantoniosi/tn_vdp](https://github.com/lfantoniosi/tn_vdp), which implements TMS9918A and V9958 VDP replacements as standalone devices on the Tang Nano 9K. This fork converts those cores into reusable modules that can be integrated into larger SoC designs targeting the Sipeed Tang Console 60K (GW5A) and 138K (GW5AST).

## Modules

### tc_vdp_v9958

V9958 VDP module (MSX2+ compatible) with 128KB VRAM and HDMI output.

- Based on the ESE-VDP V9958 core by Kunihiko Ohnaka
- 128KB VRAM using BSRAM (2x 64KB banks, no external SDRAM needed)
- Dual NTSC/PAL HDMI output with automatic mode switching
- Optional scanline effect and sprite-max configuration

**Clock requirements:**
| Clock | Frequency | Purpose |
|-------|-----------|---------|
| `clk_21m` | 21.477 MHz | VDP core clock and HDMI pixel clock |
| `clk_135m` | 135 MHz | HDMI TMDS serialization (5x pixel) |

**CPU bus interface:**
| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `cs` | in | 1 | Chip select (active-high) |
| `we` | in | 1 | Write enable (active-high) |
| `mode` | in | 2 | Register select from address bits |
| `data_in` | in | 8 | Data from CPU |
| `data_out` | out | 8 | Data to CPU |
| `int_n` | out | 1 | Interrupt (active-low) |

**BSRAM usage:** ~1,024 Kbit (fits easily on both 60K and 138K).

Source files: see [`fpga/tc_vdp_v9958/FILES.md`](fpga/tc_vdp_v9958/FILES.md)

### tc_vdp_f18a

F18A VDP module (TMS9918A compatible with enhancements) with HDMI output.

- Based on [Matthew Hagerty's F18A core](https://github.com/dnotq/f18a)
- 16KB VRAM internal to the F18A core
- 640x480 VGA over HDMI
- Enhanced sprite, tile, and color capabilities beyond the original TMS9918A

**Clock requirements:**
| Clock | Frequency | Purpose |
|-------|-----------|---------|
| `clk_50m` | 50 MHz | F18A core clock |
| `clk_25m` | 25 MHz | VGA pixel clock |
| `clk_125m` | 125 MHz | HDMI TMDS serialization (5x pixel) |

**CPU bus interface:**
| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `cs` | in | 1 | Chip select (active-high) |
| `we` | in | 1 | Write enable (active-high) |
| `mode` | in | 1 | Register select (address bit 0) |
| `data_in` | in | 8 | Data from CPU |
| `data_out` | out | 8 | Data to CPU |
| `int_n` | out | 1 | Interrupt (active-low) |

Source files: see [`fpga/tc_vdp_f18a/FILES.md`](fpga/tc_vdp_f18a/FILES.md)

## Integration Example

```verilog
// V9958 in a Tang Console 138K project
tc_vdp_v9958 vdp_inst (
    .clk_21m     (clk_21m),      // from your PLL
    .clk_135m    (clk_135m),     // from your PLL
    .reset       (reset),

    .cs          (vdp_cs),       // from address decoder
    .we          (cpu_we),
    .mode        (address[1:0]),
    .data_in     (cpu_do),
    .data_out    (vdp_do),

    .int_n       (vdp_irq_n),

    .tmds_clk_p  (tmds_clk_p),   // to HDMI connector pins
    .tmds_clk_n  (tmds_clk_n),
    .tmds_data_p (tmds_d_p),
    .tmds_data_n (tmds_d_n),

    .scanlines   (1'b0),
    .spr_max     (1'b0),
    .vdp_speed   (1'b0)
);
```

A full integration example is at [`fpga/tc_vdp_v9958/src/example_integration.v`](fpga/tc_vdp_v9958/src/example_integration.v).

## What Changed from tn_vdp

The original tn_vdp is a standalone device — it sits in a physical VDP socket and communicates with the host CPU over external bus pins. These modules are designed to live **inside** a larger FPGA design:

| Aspect | tn_vdp (standalone) | tc_vdp (module) |
|--------|---------------------|-----------------|
| CPU bus | External pins + pin filtering | Synchronous internal signals |
| VRAM | External SDRAM + controller | BSRAM (no extra clock domain) |
| Clocks | Internal PLLs from oscillators | Received from parent design |
| Audio input | External SPI ADC (MCP3202) | Removed (silent HDMI audio) |
| Configuration | DIP switches | Input ports / parameters |
| Video output | HDMI via TMDS | Same — self-contained HDMI |
| Target FPGA | Tang Nano 9K (GW2AR-18) | Tang Console 60K/138K (GW5A/GW5AST) |

The VDP cores themselves (the VHDL `VDP` entity and F18A) are unmodified.

## Original Standalone Designs

The original tn_vdp standalone board designs are preserved under `fpga/`:

| Directory | Description |
|-----------|-------------|
| `tn_vdp_v1` | F18A (TMS9918A), Tang Nano 9K, 16KB VRAM |
| `tn_vdp_v2_v9918` | F18A with audio, Tang Nano 9K |
| `tn_vdp_v2_v9958` | V9958, Tang Nano 9K, 32KB BRAM VRAM |
| `tn_vdp_v3_v9958` | V9958, Tang Nano 20K, 128KB SDRAM VRAM |

For standalone board assembly, programming, BOMs, and KiCad gerbers, see the [original project](https://github.com/lfantoniosi/tn_vdp).

## Building

Requires the Gowin EDA toolchain. The Education Edition (free, no license required) works.

1. Create a Gowin project targeting your FPGA (GW5AST-LV138PG484AC1/I0 for TC138K, or GW5A-LV60PG484AC1/I0 for TC60K)
2. Add the source files listed in the module's `FILES.md`
3. Add your constraint file (`.cst`) with pin mappings for your board
4. Add timing constraints (`.sdc`) for your clock frequencies
5. Synthesize, place & route, and program

## Credits

- **V9958 core**: [ESE-VDP](http://www.ohnaka.jp/ese-vdp/) by Kunihiko Ohnaka, with contributions from Kazuhiro Tsujikawa, Alex Wulms, and KdL
- **F18A core**: [F18A](https://github.com/dnotq/f18a) by Matthew Hagerty
- **HDMI encoder**: [hdmi](https://github.com/sameer/hdmi) by Sameer Puri
- **Original tn_vdp project**: [tn_vdp](https://github.com/lfantoniosi/tn_vdp) by Felipe Antoniosi
- **CLOCK_DIV**: Differential clock divider by Felipe Antoniosi

## License

See [LICENSE](LICENSE) for details. Individual cores retain their original licenses as noted in their source files.
