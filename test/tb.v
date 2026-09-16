```verilog
`default_nettype none
`timescale 1ns / 1ps

/*
 * Tiny Tapeout 2nd Order IIR Biquad Filter
 *
 * Difference equation:
 *
 * y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2]
 *        - a1*y[n-1] - a2*y[n-2]
 *
 * 8-bit input
 * 8-bit output
 *
 * ui_in[7:0]  : Input sample
 * uo_out[7:0] : Filter output
 *
 * uio_in/out/oe are unused.
 */

module tt_um_iir_biquad (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,

    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,

    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ============================================================
    // Coefficients
    // Q1.7 fixed-point format
    // ============================================================

    // Example low-pass biquad coefficients
    //
    // b0 = 0.2929
    // b1 = 0.5858
    // b2 = 0.2929
    // a1 = -0.0000
    // a2 = 0.1716
    //
    // Scaled by 128.

    localparam signed [7:0] B0 = 8'sd37;
    localparam signed [7:0] B1 = 8'sd75;
    localparam signed [7:0] B2 = 8'sd37;

    localparam signed [7:0] A1 = 8'sd0;
    localparam signed [7:0] A2 = 8'sd22;


    // ============================================================
    // Input and output samples
    // ============================================================

    reg signed [7:0] x0;
    reg signed [7:0] x1;
    reg signed [7:0] x2;

    reg signed [7:0] y1;
    reg signed [7:0] y2;

    reg signed [15:0] accumulator;
    reg signed [7:0]  y0;


    // ============================================================
    // Unused bidirectional pins
    // ============================================================

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;


    // ============================================================
    // Output
    // ============================================================

    assign uo_out = ena ? y0 : 8'b0;


    // ============================================================
    // IIR Biquad
    // ============================================================

    always @(posedge clk) begin

        if (!rst_n) begin

            x0 <= 8'sd0;
            x1 <= 8'sd0;
            x2 <= 8'sd0;

            y1 <= 8'sd0;
            y2 <= 8'sd0;

            accumulator <= 16'sd0;
            y0 <= 8'sd0;

        end

        else if (ena) begin

            // ----------------------------------------------------
            // Shift input samples
            // ----------------------------------------------------

            x2 <= x1;
            x1 <= x0;
            x0 <= $signed(ui_in);


            // ----------------------------------------------------
            // Biquad difference equation
            //
            // Products are Q1.7 × integer
            // Therefore divide accumulator by 128.
            // ----------------------------------------------------

            accumulator <=
                    B0 * $signed(ui_in)
                  + B1 * x1
                  + B2 * x2
                  - A1 * y1
                  - A2 * y2;


            // ----------------------------------------------------
            // Convert from Q1.7 back to 8-bit sample
            // ----------------------------------------------------

            y0 <= accumulator >>> 7;


            // ----------------------------------------------------
            // Shift previous outputs
            // ----------------------------------------------------

            y2 <= y1;
            y1 <= accumulator >>> 7;

        end

    end

endmodule
