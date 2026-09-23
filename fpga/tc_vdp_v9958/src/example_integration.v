// Example: Integrating tc_vdp_v9958 into a Tang Console 60K/138K project
//
// This shows the instantiation pattern. Your parent top module provides
// clocks and connects the VDP to your CPU bus.
//
// Clock requirements:
//   clk_21m  = 21.477 MHz (generate from PLL)
//   clk_135m = 135 MHz    (generate from PLL, ideally 5x 27MHz)
//
// PLL example for Tang Console 138K (GW5AST, 50 MHz input):
//   50 MHz -> PLL -> 21.477 MHz (CLKOUT0) + 135 MHz (CLKOUT1)
//
// Memory map example (matching TMS9918A/V9958 style):
//   Base + 0: VDP data port    (mode = 2'b00)
//   Base + 1: VDP register/status port (mode = 2'b01)

module example_top (
    input  wire       sys_clk,      // 50 MHz
    input  wire       rst_n,

    // HDMI
    output wire       tmds_clk_p,
    output wire       tmds_clk_n,
    output wire [2:0] tmds_d_p,
    output wire [2:0] tmds_d_n
);

    // =========================================================================
    // Clock generation - you need a PLL for these
    // =========================================================================
    wire clk_21m;    // 21.477 MHz
    wire clk_135m;   // 135 MHz
    wire pll_lock;

    // Replace with your Gowin PLL instantiation:
    // pll_v9958 pll_inst (
    //     .clkin(sys_clk),
    //     .clkout0(clk_21m),    // 21.477 MHz
    //     .clkout1(clk_135m),   // 135 MHz
    //     .lock(pll_lock)
    // );

    wire reset = ~rst_n | ~pll_lock;

    // =========================================================================
    // VDP instantiation
    // =========================================================================
    wire [7:0] vdp_data_out;
    wire       vdp_int_n;

    // Connect these to your CPU bus:
    wire       vdp_cs   = 1'b0;    // your address decoder output
    wire       vdp_we   = 1'b0;    // your CPU write enable
    wire [1:0] vdp_mode = 2'b00;   // your address bits [1:0]
    wire [7:0] vdp_din  = 8'h00;   // your CPU data bus

    tc_vdp_v9958 vdp_inst (
        .clk_21m    (clk_21m),
        .clk_135m   (clk_135m),
        .reset      (reset),

        .cs         (vdp_cs),
        .we         (vdp_we),
        .mode       (vdp_mode),
        .data_in    (vdp_din),
        .data_out   (vdp_data_out),

        .int_n      (vdp_int_n),

        .tmds_clk_p  (tmds_clk_p),
        .tmds_clk_n  (tmds_clk_n),
        .tmds_data_p (tmds_d_p),
        .tmds_data_n (tmds_d_n),

        .scanlines  (1'b0),
        .spr_max    (1'b0),
        .vdp_speed  (1'b0)
    );

endmodule
