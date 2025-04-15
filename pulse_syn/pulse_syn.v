module pulse_sync (
    input wire aclk,       // Clock for the input pulse
    input wire arst_n,     // Active low reset for the input pulse
    input wire a_pulse,    // Input pulse signal
    input wire bclk,       // Clock for the output pulse
    input wire brst_n,     // Active low reset for the output pulse
    output reg b_pulse     // Output pulse signal
);

  reg toggle_ff;

  always @(posedge aclk or negedge arst_n) begin
    if (!arst_n) begin
      toggle_ff <= 1'b0;
    end else if (a_pulse) begin
      toggle_ff <= ~toggle_ff; // Toggle the flip-flop on the input pulse
    end
  end

  reg [2:0] sync_ff; // 3-stage synchronizer for the output pulse

  always @(posedge bclk or negedge brst_n) begin
    if (!brst_n) begin
      sync_ff <= 3'b000;
    end else begin
      sync_ff <= {sync_ff[1:0], toggle_ff}; // Shift the toggle FF into the synchronizer
    end
  end

  always @(posedge bclk or negedge brst_n) begin
    if (!brst_n) begin
      b_pulse <= 1'b0;
    end else begin
      b_pulse <= sync_ff[2] ^ sync_ff[1]; // Generate the output pulse on the rising edge of the last stage of the synchronizer
    end
  end






endmodule