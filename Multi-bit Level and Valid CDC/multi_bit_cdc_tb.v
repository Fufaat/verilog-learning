// File: tb_multi_bit_cdc.v

`timescale 1ns/1ps

module tb_multi_bit_cdc;

    // aclk domain
    reg        aclk, arst_n;
    reg [7:0]  data_aclk;
    reg        valid_aclk;
    wire       ready_aclk;

    // bclk domain
    reg        bclk, brst_n;
    wire [7:0] data_bclk;
    wire       valid_bclk;
    reg        ready_bclk;

    // Clock generators
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk; // 100 MHz
    end

    initial begin
        bclk = 0;
        forever #13 bclk = ~bclk; // ~38.5 MHz
    end

    // Reset
    initial begin
        arst_n = 0;
        brst_n = 0;
        #30;
        arst_n = 1;
        brst_n = 1;
    end

    // DUT instantiation (to be created)
    multi_bit_cdc dut (
        .aclk(aclk),
        .arst_n(arst_n),
        .data_aclk(data_aclk),
        .valid_aclk(valid_aclk),
        .ready_aclk(ready_aclk),

        .bclk(bclk),
        .brst_n(brst_n),
        .data_bclk(data_bclk),
        .valid_bclk(valid_bclk),
        .ready_bclk(ready_bclk)
    );

    // Stimulus
    initial begin
        valid_aclk = 0;
        data_aclk  = 8'h00;
        ready_bclk = 1;

        #100;

        repeat (5) begin
            @(posedge aclk);
            data_aclk  <= $random;
            valid_aclk <= 1;
            @(posedge aclk);
            valid_aclk <= 0;
        end

        #500;
        $finish;
    end

    // Dump waveform
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_multi_bit_cdc);
    end

endmodule


module multi_bit_cdc (
    input wire        aclk,       // Clock for the input data
    input wire        arst_n,     // Active low reset for the input data
    input wire [7:0]  data_aclk,  // Input data signal
    input wire        valid_aclk,  // Input valid signal
    output reg       ready_aclk,  // Output ready signal for the aclk domain

    input wire        bclk,       // Clock for the output data
    input wire        brst_n,     // Active low reset for the output data
    output reg [7:0]  data_bclk,  // Output data signal
    output reg        valid_bclk,  // Output valid signal
    input wire        ready_bclk   // Input ready signal for the bclk domain
);

reg [7:0]data_reg ;
wire response_bclk;

always @(posedge aclk or negedge arst_n)begin
  if(!arst_n)begin
    ready_aclk <= 1'b1;
  end else if (valid_aclk && ready_aclk) begin
    ready_aclk <= 1'b0; // Set the ready signal when valid is high
  end else if (response_bclk)begin
    ready_aclk <= 1'b1; // Clear the ready signal when valid is low
  end
end

always @(posedge aclk or negedge arst_n) begin
    if (!arst_n) begin
        data_reg <= 8'b0;
    end else if (valid_aclk && ready_aclk) begin
        data_reg <= data_aclk; // Capture the input data on valid signal
    end else data_reg <= data_reg; // Hold the previous value when valid is low
end


reg toggle_ff_aclk;

always @(posedge aclk or negedge arst_n) begin
    if (!arst_n) begin
        toggle_ff_aclk <= 1'b0;
    end else if (valid_aclk && ready_aclk) begin
        toggle_ff_aclk <= ~toggle_ff_aclk; // Toggle the flip-flop on the valid signal
    end
end
reg [2:0] sync_ack_aclk; // 3-stage synchronizer for the output response signal

always @(posedge aclk or negedge arst_n) begin
    if (!arst_n)
        sync_ack_aclk <= 3'b000;
    else
        sync_ack_aclk <= {sync_ack_aclk[1:0], toggle_ff_bclk};
end

///shadow

reg[7:0] data_shadow; // Shadow register for the bclk domain
always @(posedge aclk or negedge arst_n) begin
    if (!arst_n)
        data_shadow <= 8'd0;
    else if (valid_aclk && ready_aclk)
        data_shadow <= data_aclk;
end


//// bclk domain


reg [2:0] sync_ff_bclk; // 3-stage synchronizer for the output data
wire load_pulse_bclk;

always @(posedge bclk or negedge brst_n) begin
    if (!brst_n) begin
        sync_ff_bclk <= 3'b000;
    end else begin
        sync_ff_bclk <= {sync_ff_bclk[1:0], toggle_ff_aclk}; // Shift the toggle FF into the synchronizer
    end
end

assign load_pulse_bclk = sync_ff_bclk[2] ^ sync_ff_bclk[1]; // Generate the load pulse on the rising edge of the last stage of the synchronizer

reg[7:0] data_buffer_bclk; // Shadow register for the bclk domain

always @(posedge bclk or negedge brst_n) begin
    if (!brst_n)
        data_buffer_bclk <= 8'd0;
    else if (load_pulse_bclk && ready_bclk)
        data_buffer_bclk <= data_shadow;  // unsafe 但此處同步點為 pulse，尚可接受
end


always@(posedge bclk or negedge brst_n) begin
    if (!brst_n) begin
        data_bclk <= 8'b0;
        valid_bclk <= 1'b0;
    end else if (load_pulse_bclk && ready_bclk) begin
        data_bclk <= data_buffer_bclk; // Capture the input data on load pulse
        valid_bclk <= 1'b1; // Set the valid signal when load pulse is high
    end else if (ready_bclk) begin
        valid_bclk <= 1'b0; // Clear the valid signal when ready is high
    end
end

reg toggle_ff_bclk;

always @(posedge bclk or negedge brst_n) begin
    if (!brst_n) begin
        toggle_ff_bclk <= 1'b0;
    end else if (valid_bclk && ready_bclk) begin
        toggle_ff_bclk <= ~toggle_ff_bclk; // Toggle the flip-flop on the valid signal
    end
end


assign response_bclk = sync_ack_aclk[2] ^ sync_ack_aclk[1]; // Generate the response signal on the rising edge of the last stage of the synchronizer

endmodule