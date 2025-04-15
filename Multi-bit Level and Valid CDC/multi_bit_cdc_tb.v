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
