module tbtop;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // Instantiate interface
    uart_if uart_if0 (.*); // clk connection
    
    // Instantiate DUT
    uart_dut dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx(uart_if0.tx),
        .rx(uart_if0.rx),
        .cs(uart_if0.cs),
        .addr(uart_if0.addr),
        .wdata(uart_if0.wdata),
        .rdata(uart_if0.rdata),
        .we(uart_if0.we)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Reset generation
    initial begin
        rst_n = 0;
        #100 rst_n = 1;
    end
    
    // UVM test setup
    initial begin
        // Set the virtual interface in config DB
        uvm_config_db#(virtual uart_if)::set(null, "*.tx_agent.*", "vif", uart_if0);
        uvm_config_db#(virtual uart_if)::set(null, "*.rx_agent.*", "vif", uart_if0);
        
        // Start the test
        run_test("uart_base_test");
    end
    
    // Simulation timeout
    initial begin
        #1000000; // 1ms timeout
        $display("Error: Simulation timeout!");
        $finish;
    end
endmodule
