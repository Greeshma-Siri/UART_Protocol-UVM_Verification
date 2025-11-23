interface uart_if (input clk);
    logic rst_n;
    logic tx; // Transmitter output
    logic rx; // Receiver input

    // Register Interface (e.g., APB-like)
    logic        cs;
    logic [ 7:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        we;

    // Clocking blocks for driver and monitor synchronization
    clocking drv_cb @(posedge clk);
        output rst_n, rx, cs, addr, wdata, we;
        input  tx, rdata;
    endclocking

    clocking mon_cb @(posedge clk);
        input rst_n, tx, rx, cs, addr, wdata, we, rdata;
    endclocking

    modport drv_mp (clocking drv_cb);
    modport mon_mp (clocking mon_cb);
endinterface
