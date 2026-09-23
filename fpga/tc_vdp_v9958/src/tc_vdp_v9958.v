`define GW_IDE

module tc_vdp_v9958 (
    input         clk_21m,        // 21.477 MHz VDP clock
    input         clk_135m,       // 135 MHz (5x pixel clock for HDMI serializer)
    input         reset,          // Active-high synchronous reset

    // CPU bus interface (active-high accent, accent accent)
    input         cs,             // Chip select
    input         we,             // Write enable (active-high)
    input  [1:0]  mode,           // Register select (directly from address bits)
    input  [7:0]  data_in,        // Data from CPU
    output [7:0]  data_out,       // Data to CPU

    // Interrupt
    output        int_n,          // Active-low interrupt (directly active-driven)

    // HDMI TMDS output
    output        tmds_clk_p,
    output        tmds_clk_n,
    output [2:0]  tmds_data_p,
    output [2:0]  tmds_data_n,

    // Configuration inputs
    input         scanlines,      // Enable scanline effect
    input         spr_max,        // Max sprites per line enable
    input         vdp_speed       // Speed mode (0=normal, 1=fast)
);

    // =========================================================================
    // VDP core signals
    // =========================================================================
    wire           VdpReq;
    wire  [7:0]    VdpDbi;
    wire           WeVdp_n;
    wire           ReVdp_n;
    wire  [16:0]   VdpAdr;
    wire  [7:0]    VrmDbo;
    wire  [15:0]   VrmDbi;
    wire           pVdpInt_n;
    wire           VideoDHClk;
    wire           VideoDLClk;
    wire           blank_o;

    wire  [5:0]    VideoR;
    wire  [5:0]    VideoG;
    wire  [5:0]    VideoB;
    wire           VideoHS_n;
    wire           VideoVS_n;
    wire           VideoCS_n;

    wire           pal_mode;
    wire           vdp_hdmi_reset;
    wire  [10:0]   vdp_cx;
    wire  [10:0]   vdp_cy;

    wire           reset_n = ~reset;

    // =========================================================================
    // CPU interface - synchronous bus (no pin filtering needed)
    // =========================================================================
    reg            CpuReq;
    reg            CpuWrt;
    reg   [15:0]   CpuAdr;
    reg   [7:0]    CpuDbo;
    wire  [7:0]    CpuDbi;

    reg            io_state_r;
    reg   [1:0]    cs_latch;

    always @(posedge clk_21m or posedge reset) begin
        if (reset) begin
            io_state_r <= 1'b0;
            CpuDbo     <= 8'b0;
            CpuAdr     <= 16'b0;
            CpuWrt     <= 1'b0;
            CpuReq     <= 1'b0;
        end else begin
            if (!io_state_r) begin
                CpuAdr     <= {14'b0, mode};
                CpuDbo     <= data_in;
                CpuReq     <= cs;
                CpuWrt     <= cs & we;
                cs_latch   <= {cs, we};
                io_state_r <= 1'b1;
            end else begin
                CpuWrt     <= 1'b0;
                CpuReq     <= 1'b0;
                if (cs_latch != {cs, we})
                    io_state_r <= 1'b0;
            end
        end
    end

    assign data_out = CpuDbi;
    assign int_n    = pVdpInt_n;

    // =========================================================================
    // VRAM - 128KB using BSRAM (two 64KB banks for 16-bit access)
    // =========================================================================
    wire [7:0] vram_dout_lo;
    wire [7:0] vram_dout_hi;

    ram64k vram_lo (
        .clk  (clk_21m),
        .we   (~WeVdp_n & VideoDLClk & ~VdpAdr[16]),
        .re   (1'b1),
        .addr (VdpAdr[15:0]),
        .din  (VrmDbo),
        .dout (vram_dout_lo)
    );

    ram64k vram_hi (
        .clk  (clk_21m),
        .we   (~WeVdp_n & VideoDLClk & VdpAdr[16]),
        .re   (1'b1),
        .addr (VdpAdr[15:0]),
        .din  (VrmDbo),
        .dout (vram_dout_hi)
    );

    assign VrmDbi = {vram_dout_hi, vram_dout_lo};

    // =========================================================================
    // V9958 VDP core
    // =========================================================================
    VDP u_v9958 (
        .CLK21M           (clk_21m),
        .RESET            (reset),
        .REQ              (CpuReq),
        .ACK              (),
        .WRT              (CpuWrt),
        .ADR              (CpuAdr),
        .DBI              (CpuDbi),
        .DBO              (CpuDbo),
        .INT_N            (pVdpInt_n),
        .PRAMOE_N         (ReVdp_n),
        .PRAMWE_N         (WeVdp_n),
        .PRAMADR          (VdpAdr),
        .PRAMDBI          (VrmDbi),
        .PRAMDBO          (VrmDbo),
        .VDPSPEEDMODE     (vdp_speed),
        .RATIOMODE        (3'b000),
        .CENTERYJK_R25_N  (1'b0),
        .PVIDEOR          (VideoR),
        .PVIDEOG          (VideoG),
        .PVIDEOB          (VideoB),
        .PVIDEOHS_N       (VideoHS_n),
        .PVIDEOVS_N       (VideoVS_n),
        .PVIDEOCS_N       (VideoCS_n),
        .PVIDEODHCLK      (VideoDHClk),
        .PVIDEODLCLK      (VideoDLClk),
        .BLANK_o          (blank_o),
        .DISPRESO         (1'b1),           // VGA 31kHz
        .NTSC_PAL_TYPE    (1'b1),
        .FORCED_V_MODE    (1'b0),
        .LEGACY_VGA       (1'b0),
        .VDP_ID           (5'b00010),       // V9958
        .OFFSET_Y         (7'd16),
        .HDMI_RESET       (vdp_hdmi_reset),
        .PAL_MODE         (pal_mode),
        .SPMAXSPR         (spr_max),
        .CX               (vdp_cx),
        .CY               (vdp_cy)
    );

    // =========================================================================
    // Video output with optional scanlines
    // =========================================================================
    logic [9:0] cx;
    logic [9:0] cy;

    wire [7:0] dvi_r = (scanlines && cy[0]) ? {1'b0, VideoR, 1'b0} : {VideoR, 2'b0};
    wire [7:0] dvi_g = (scanlines && cy[0]) ? {1'b0, VideoG, 1'b0} : {VideoG, 2'b0};
    wire [7:0] dvi_b = (scanlines && cy[0]) ? {1'b0, VideoB, 1'b0} : {VideoB, 2'b0};

    // =========================================================================
    // HDMI output (dual NTSC/PAL encoder + serializer)
    // =========================================================================
    localparam AUDIO_RATE      = 44100;
    localparam AUDIO_BIT_WIDTH = 16;
    localparam NUM_CHANNELS    = 3;

    localparam NTSC_Y = 525 - 45;
    localparam PAL_Y  = 625 - 60;

    // Audio clock divider (~44.1kHz from 27MHz)
    wire clk_audio;
    CLOCK_DIV #(
        .CLK_SRC(27),
        .CLK_DIV(0.044100),
        .PRECISION_BITS(16)
    ) audioclkd (
        .clk_src(clk_21m),
        .clk_div(clk_audio)
    );

    wire clk_audio_w;
    BUFG clk_audio_bufg_inst (
        .O(clk_audio_w),
        .I(clk_audio)
    );

    // Silent audio
    reg [15:0] audio_sample_word [1:0];
    always @(posedge clk_21m) begin
        audio_sample_word[0] <= 16'd0;
        audio_sample_word[1] <= 16'd0;
    end

    // Video reset logic
    reg ff_video_reset;
    logic [9:0] cy_ntsc, cx_ntsc;
    logic [9:0] cy_pal, cx_pal;

    always_ff @(posedge clk_21m) begin
        ff_video_reset <= vdp_hdmi_reset;
        if (vdp_cx == 11'd0 && vdp_cy == 11'd0) begin
            if ((pal_mode == 1'b0 && (cx_ntsc != 10'd0 || cy_ntsc != NTSC_Y)) ||
                (pal_mode == 1'b1 && (cx_pal  != 10'd0 || cy_pal  != PAL_Y)))
                ff_video_reset <= 1'b1;
        end
    end

    wire hdmi_reset = ff_video_reset | reset;

    // NTSC HDMI encoder
    logic [9:0] tmds_ntsc [NUM_CHANNELS-1:0];
    hdmi #(
        .VIDEO_ID_CODE(2),
        .DVI_OUTPUT(0),
        .VIDEO_REFRESH_RATE(59.94),
        .IT_CONTENT(1),
        .AUDIO_RATE(AUDIO_RATE),
        .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
        .VENDOR_NAME({"Unknown", 8'd0}),
        .PRODUCT_DESCRIPTION({"FPGA", 96'd0}),
        .SOURCE_DEVICE_INFORMATION(8'h00),
        .START_X(0),
        .START_Y(NTSC_Y),
        .NUM_CHANNELS(NUM_CHANNELS)
    ) hdmi_ntsc (
        .clk_pixel_x5       (clk_135m),
        .clk_pixel           (clk_21m),
        .clk_audio           (clk_audio_w),
        .rgb                 ({dvi_r, dvi_g, dvi_b}),
        .reset               (hdmi_reset),
        .audio_sample_word   (audio_sample_word),
        .cx                  (cx_ntsc),
        .cy                  (cy_ntsc),
        .tmds_internal       (tmds_ntsc)
    );

    // PAL HDMI encoder
    logic [9:0] tmds_pal [NUM_CHANNELS-1:0];
    hdmi #(
        .VIDEO_ID_CODE(17),
        .DVI_OUTPUT(0),
        .VIDEO_REFRESH_RATE(50),
        .IT_CONTENT(0),
        .AUDIO_RATE(AUDIO_RATE),
        .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
        .VENDOR_NAME({"Unknown", 8'd0}),
        .PRODUCT_DESCRIPTION({"FPGA", 96'd0}),
        .SOURCE_DEVICE_INFORMATION(8'h00),
        .START_X(0),
        .START_Y(PAL_Y),
        .NUM_CHANNELS(NUM_CHANNELS)
    ) hdmi_pal (
        .clk_pixel_x5       (clk_135m),
        .clk_pixel           (clk_21m),
        .clk_audio           (clk_audio_w),
        .rgb                 ({dvi_r, dvi_g, dvi_b}),
        .reset               (hdmi_reset),
        .audio_sample_word   (audio_sample_word),
        .cx                  (cx_pal),
        .cy                  (cy_pal),
        .tmds_internal       (tmds_pal)
    );

    assign cx = pal_mode ? cx_pal : cx_ntsc;
    assign cy = pal_mode ? cy_pal : cy_ntsc;

    // Mux and serialize
    logic [9:0] tmds_internal [NUM_CHANNELS-1:0];
    assign tmds_internal = pal_mode ? tmds_pal : tmds_ntsc;

    logic [2:0] tmds;
    serializer #(
        .NUM_CHANNELS(NUM_CHANNELS),
        .VIDEO_RATE(0)
    ) serializer_inst (
        .clk_pixel    (clk_21m),
        .clk_pixel_x5 (clk_135m),
        .reset        (reset),
        .tmds_internal(tmds_internal),
        .tmds         (tmds)
    );

    // Gowin LVDS output buffer
    ELVDS_OBUF tmds_bufds [3:0] (
        .I  ({clk_21m, tmds}),
        .O  ({tmds_clk_p, tmds_data_p}),
        .OB ({tmds_clk_n, tmds_data_n})
    );

endmodule
