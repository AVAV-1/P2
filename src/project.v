/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_iir_biquad (
    input  wire [7:0] ui_in,    // 8-bit filter input
    output wire [7:0] uo_out,   // 8-bit filter output
    input  wire [7:0] uio_in,   // Unused IO input
    output wire [7:0] uio_out,  // Unused IO output
    output wire [7:0] uio_oe,   // IO output enable
    input  wire       ena,      // Enable
    input  wire       clk,      // Clock
    input  wire       rst_n     // Active-low reset
);

  // ============================================================
  // IIR Biquad Coefficients
  // Q1.7 fixed-point format
  // ============================================================

  localparam signed [7:0] B0 = 8'sd37;
  localparam signed [7:0] B1 = 8'sd75;
  localparam signed [7:0] B2 = 8'sd37;

  localparam signed [7:0] A1 = 8'sd0;
  localparam signed [7:0] A2 = 8'sd22;


  // ============================================================
  // Delay registers
  // ============================================================

  reg signed [7:0] x1;
  reg signed [7:0] x2;

  reg signed [7:0] y1;
  reg signed [7:0] y2;

  reg signed [7:0] y;


  // ============================================================
  // Intermediate calculation
  // ============================================================

  reg signed [31:0] acc;


  // ============================================================
  // IIR Biquad Filter
  // ============================================================

  always @(posedge clk) begin

    if (!rst_n) begin

      x1  <= 8'sd0;
      x2  <= 8'sd0;

      y1  <= 8'sd0;
      y2  <= 8'sd0;

      y   <= 8'sd0;

      acc <= 32'sd0;

    end
    else if (ena) begin

      // Biquad difference equation
      acc = (B0 * $signed(ui_in))
          + (B1 * x1)
          + (B2 * x2)
          - (A1 * y1)
          - (A2 * y2);

      // Convert from Q1.7 fixed-point
      y <= acc >>> 7;

      // Delay input samples
      x2 <= x1;
      x1 <= $signed(ui_in);

      // Delay output samples
      y2 <= y1;
      y1 <= acc >>> 7;

    end

  end


  // ============================================================
  // Outputs
  // ============================================================

  assign uo_out  = ena ? y : 8'b0;

  assign uio_out = 8'b0;

  assign uio_oe  = 8'b0;


  // ============================================================
  // Unused input
  // ============================================================

  wire _unused = &{uio_in, 1'b0};

endmodule

`default_nettype wire
