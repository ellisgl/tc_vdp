`define GW_IDE

module tc_vdp_f18a (
    input         clk_50m,        // 50 MHz F18A core clock
    input         clk_25m,        // 25 MHz pixel clock
    input         clk_125m,       // 125 MHz HDMI serializer clock (5x pixel)
    input         reset,          // Active-high synchronous reset

    // CPU bus interface
    input         cs,             // Chip select
    input         we,             // Write enable (active-high)
    input         mode,           // Register select (address bit 0)
    input  [7:0]  data_in,        // Data from CPU
    output [7:0]  data_out,       // Data to CPU

    // Interrupt
    output        int_n,          // Active-low interrupt

    // HDMI TMDS output
    output        tmds_clk_p,
    output        tmds_clk_n,
    output [2:0]  tmds_data_p,
    output [2:0]  tmds_data_n,

    // Configuration inputs
    input         scanlines,      // Enable scanline effect
    input         spr_max         // Sprite max: 0=32, 1=4 (classic TMS9918A)
);

    wire reset_n = ~reset;

    // =========================================================================
    // F18A VDP core
    // =========================================================================
    wire [3:0] vdp_r, vdp_g, vdp_b;
    wire       vdp_hs, vdp_vs, vdp_blank;
    wire [7:0] vdp_cd_out;

    wire csw_n = ~(cs & we);
    wire csr_n = ~(cs & ~we);

    assign data_out = cs ? vdp_cd_out : 8'h00;

    f18a_core f18a_inst (
        .clk_100m0_i  (clk_50m),
        .clk_25m0_i   (clk_25m),
        .reset_n_i    (reset_n),
        .mode_i       (mode),
        .csw_n_i      (csw_n),
        .csr_n_i      (csr_n),
        .int_n_o      (int_n),
        .cd_i         (data_in),
        .cd_o         (vdp_cd_out),
        .red_o        (vdp_r),
        .grn_o        (vdp_g),
        .blu_o        (vdp_b),
        .blank_o      (vdp_blank),
        .hsync_o      (vdp_hs),
        .vsync_o      (vdp_vs),
        .sprite_max_i (spr_max),
        .scanlines_i  (scanlines),
        .spi_clk_o    (),
        .spi_cs_o     (),
        .spi_mosi_o   (),
        .spi_miso_i   (1'b1)
    );

    // =========================================================================
    // HDMI output
    // =========================================================================
    wire [7:0] rgb_r = {vdp_r, 4'b0};
    wire [7:0] rgb_g = {vdp_g, 4'b0};
    wire [7:0] rgb_b = {vdp_b, 4'b0};

    localparam AUDIO_RATE      = 44100;
    localparam AUDIO_BIT_WIDTH = 16;
    localparam CLKFRQ          = 25200;
    localparam AUDIO_CLK_DELAY = CLKFRQ * 1000 / AUDIO_RATE / 2;

    reg [$clog2(AUDIO_CLK_DELAY)-1:0] audio_divider;
    reg clk_audio;

    always @(posedge clk_25m) begin
        if (audio_divider != AUDIO_CLK_DELAY - 1)
            audio_divider <= audio_divider + 1;
        else begin
            clk_audio     <= ~clk_audio;
            audio_divider <= 0;
        end
    end

    reg [15:0] audio_sample_word [1:0];
    always @(posedge clk_25m) begin
        audio_sample_word[0] <= 16'd0;
        audio_sample_word[1] <= 16'd0;
    end

    logic [2:0] tmds;

    hdmi #(
        .VIDEO_ID_CODE(1),
        .DVI_OUTPUT(0),
        .VIDEO_REFRESH_RATE(59.94),
        .IT_CONTENT(1),
        .AUDIO_RATE(AUDIO_RATE),
        .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
        .VENDOR_NAME({"Unknown", 8'd0}),
        .PRODUCT_DESCRIPTION({"FPGA", 96'd0}),
        .SOURCE_DEVICE_INFORMATION(8'h00),
        .START_X(0),
        .START_Y(0)
    ) hdmi_inst (
        .clk_pixel_x5  (clk_125m),
        .clk_pixel     (clk_25m),
        .clk_audio     (clk_audio),
        .rgb           ({rgb_r, rgb_g, rgb_b}),
        .reset         (reset),
        .audio_sample_word(audio_sample_word),
        .tmds          (tmds),
        .tmds_clock    (),
        .cx            (),
        .cy            (),
        .frame_width   (),
        .frame_height  ()
    );

    // Gowin LVDS output buffers
    ELVDS_OBUF tmds_bufds [3:0] (
        .I  ({clk_25m, tmds}),
        .O  ({tmds_clk_p, tmds_data_p}),
        .OB ({tmds_clk_n, tmds_data_n})
    );

endmodule
