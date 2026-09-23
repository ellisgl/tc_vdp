module ram64k (
    input         clk,
    input         we,
    input         re,
    input  [15:0] addr,
    input  [7:0]  din,
    output [7:0]  dout
);

    reg [7:0] mem_r [0:65535];
    reg [7:0] dout_r;

    always @(posedge clk) begin
        if (re)
            dout_r <= mem_r[addr];
        if (we)
            mem_r[addr] <= din;
    end

    assign dout = dout_r;

endmodule
