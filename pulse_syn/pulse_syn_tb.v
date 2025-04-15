`timescale 1ns/1ps

module tb_pulse_sync;

    reg aclk, arst_n, a_pulse;
    reg bclk, brst_n;
    wire b_pulse;

    // Instantiate the DUT
    pulse_sync dut (
        .aclk(aclk),
        .arst_n(arst_n),
        .a_pulse(a_pulse),
        .bclk(bclk),
        .brst_n(brst_n),
        .b_pulse(b_pulse)
    );

    // Clock generation
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;  // 100 MHz
    end

    initial begin
        bclk = 0;
        forever #12 bclk = ~bclk; // ~41.67 MHz
    end

    // Reset
    initial begin
        arst_n = 0;
        brst_n = 0;
        #20;
        arst_n = 1;
        brst_n = 1;
    end

    // Stimulus
    initial begin
        a_pulse = 0;
        #50;
        
        // generate a few pulse events
        @(posedge aclk); a_pulse = 1;
        @(posedge aclk); a_pulse = 0;

        #100;

        @(posedge aclk); a_pulse = 1;
        @(posedge aclk); a_pulse = 0;

        #200;

        @(posedge aclk); a_pulse = 1;
        @(posedge aclk); a_pulse = 0;

        #100;
        $finish;
    end

endmodule
