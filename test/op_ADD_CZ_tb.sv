`timescale 1ns/1ps
import test_utils_pkg::*;
import arch_defs_pkg::*; 

module computer_tb;
  
  localparam string HEX_FILE = "../fixture/ADD_CZ.hex";

  reg clk;
  reg reset;
  wire flag_zero, flag_carry, flag_negative;
  wire [DATA_WIDTH-1:0] out_val; // Output value from the DUT
  
  // Instantiate the DUT (assumed to be named 'computer')
  computer uut (
        .clk(clk),
        .reset(reset),
        .out_val(out_val),
        .flag_zero_o(flag_zero),
        .flag_carry_o(flag_carry),
        .flag_negative_o(flag_negative)
    );

  // Clock generation: 10ns period (5ns high, 5ns low)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Testbench stimulus
  initial begin
    
    $dumpfile("waveform.vcd");
    $dumpvars(0, computer_tb);

    $display("--- Loading hex file: %s ---", HEX_FILE);
    $readmemh(HEX_FILE, uut.u_ram.mem);
    uut.u_ram.dump();
    
    reset_and_wait(0);
    
    inspect_register(uut.u_register_A.latched_data, 8'h00, "A", DATA_WIDTH);
    
    // LDA: (5 + 4) + 1 = 10
    repeat (10) @(posedge clk); 
    inspect_register(uut.u_register_A.latched_data, 8'h00, "A", DATA_WIDTH);

    // + 1 for latching A register
    repeat (1) @(posedge clk); // LDA: 5 + 4 + 1 + 1 = 11 
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'hFF, "A", DATA_WIDTH);

    // ADD: -1 + (5 + 6) + 1 = 11
    repeat (10) @(posedge clk); 
    inspect_register(uut.u_register_A.latched_data, 8'hFF, "A", DATA_WIDTH);
    inspect_register(uut.u_register_B.latched_data, 8'h01, "B", DATA_WIDTH);
    
    repeat (1) @(posedge clk); 
    inspect_register(uut.u_register_A.latched_data, 8'hFF, "A", DATA_WIDTH);
    inspect_register(uut.u_register_flags.latched_data, 3'b011, "Flags", 3); // N = 0, C = 1, Z = 1

    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h00, "A", DATA_WIDTH);

    // OUTA: -1 + (5 + 2) + 1 = 7 
    repeat (7) @(posedge clk); 
    inspect_register(uut.u_register_o.latched_data, 8'h00, "O", DATA_WIDTH);
    #0.1;
    inspect_register(uut.u_register_A.latched_data, 8'h00, "A", DATA_WIDTH);
    inspect_register(uut.u_register_o.latched_data, 8'h00, "O", DATA_WIDTH);

    run_until_halt(50);

    $display("\033[0;32mADD instruction test completed successfully.\033[0m");
    $finish;
  end

endmodule