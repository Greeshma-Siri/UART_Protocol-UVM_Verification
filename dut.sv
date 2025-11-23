module uart_dut (
    input logic clk,
    input logic rst_n,
    
    // UART serial lines
    output logic tx,
    input logic rx,
    
    // Register interface
    input logic        cs,
    input logic [7:0]  addr,
    input logic [31:0] wdata,
    output logic [31:0] rdata,
    input logic        we
);
    
    // Internal registers
    logic [15:0] baud_divisor;
    logic [2:0]  data_bits;
    logic [0:0]  stop_bits;
    logic [1:0]  parity_config;
    logic        tx_enable;
    logic        rx_enable;
    
    logic [7:0]  tx_data;
    logic        tx_valid;
    logic        tx_ready;
    
    logic [7:0]  rx_data;
    logic        rx_valid;
    logic        rx_error;
    
    // Register map
    localparam REG_BAUD = 8'h00;
    localparam REG_CONFIG = 8'h04;
    localparam REG_TX_DATA = 8'h08;
    localparam REG_RX_DATA = 8'h0C;
    localparam REG_STATUS = 8'h10;
    
    // Register write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_divisor <= 16'd104; // 115200 baud for 12MHz clock
            data_bits <= 3'd7; // 8 data bits
            stop_bits <= 1'd0; // 1 stop bit
            parity_config <= 2'd0; // No parity
            tx_enable <= 1'b0;
            rx_enable <= 1'b0;
            tx_valid <= 1'b0;
        end else begin
            tx_valid <= 1'b0;
            
            if (cs && we) begin
                case (addr)
                    REG_BAUD: baud_divisor <= wdata[15:0];
                    REG_CONFIG: begin
                        data_bits <= wdata[2:0];
                        stop_bits <= wdata[3];
                        parity_config <= wdata[5:4];
                        tx_enable <= wdata[6];
                        rx_enable <= wdata[7];
                    end
                    REG_TX_DATA: begin
                        tx_data <= wdata[7:0];
                        tx_valid <= 1'b1;
                    end
                endcase
            end
        end
    end
    
    // Register read
    always_comb begin
        rdata = 32'h0;
        if (cs && !we) begin
            case (addr)
                REG_BAUD: rdata = {16'h0, baud_divisor};
                REG_CONFIG: rdata = {24'h0, rx_enable, tx_enable, parity_config, stop_bits, data_bits};
                REG_RX_DATA: rdata = {24'h0, rx_data};
                REG_STATUS: rdata = {30'h0, rx_error, tx_ready};
            endcase
        end
    end
    
    // UART transmitter
    uart_tx tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_divisor(baud_divisor),
        .data_bits(data_bits),
        .stop_bits(stop_bits),
        .parity_config(parity_config),
        .data_in(tx_data),
        .data_valid(tx_valid),
        .data_ready(tx_ready),
        .tx_out(tx)
    );
    
    // UART receiver
    uart_rx rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_divisor(baud_divisor),
        .data_bits(data_bits),
        .stop_bits(stop_bits),
        .parity_config(parity_config),
        .rx_in(rx),
        .data_out(rx_data),
        .data_valid(rx_valid),
        .error(rx_error)
    );
    
endmodule

// UART Transmitter sub-module
module uart_tx (
    input logic clk,
    input logic rst_n,
    input logic [15:0] baud_divisor,
    input logic [2:0] data_bits,
    input logic stop_bits,
    input logic [1:0] parity_config,
    input logic [7:0] data_in,
    input logic data_valid,
    output logic data_ready,
    output logic tx_out
);
    
    logic [15:0] baud_counter;
    logic [3:0] bit_counter;
    logic [8:0] shift_reg;
    logic parity_bit;
    logic transmitting;
    
    enum logic [2:0] {
        IDLE = 3'b000,
        START = 3'b001,
        DATA = 3'b010,
        PARITY = 3'b011,
        STOP = 3'b100
    } state;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_out <= 1'b1;
            data_ready <= 1'b1;
            baud_counter <= 16'h0;
            bit_counter <= 4'h0;
            shift_reg <= 9'h0;
            transmitting <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tx_out <= 1'b1;
                    data_ready <= 1'b1;
                    if (data_valid && data_ready) begin
                        state <= START;
                        data_ready <= 1'b0;
                        baud_counter <= 16'h0;
                        shift_reg <= {1'b0, data_in};
                        transmitting <= 1'b1;
                    end
                end
                
                START: begin
                    tx_out <= 1'b0;
                    if (baud_counter == baud_divisor) begin
                        state <= DATA;
                        baud_counter <= 16'h0;
                        bit_counter <= 4'h0;
                    end else begin
                        baud_counter <= baud_counter + 16'h1;
                    end
                end
                
                DATA: begin
                    tx_out <= shift_reg[0];
                    if (baud_counter == baud_divisor) begin
                        shift_reg <= {1'b0, shift_reg[8:1]};
                        bit_counter <= bit_counter + 4'h1;
                        baud_counter <= 16'h0;
                        
                        if (bit_counter == data_bits) begin
                            if (parity_config != 2'b00) begin
                                state <= PARITY;
                            end else begin
                                state <= STOP;
                            end
                        end
                    end else begin
                        baud_counter <= baud_counter + 16'h1;
                    end
                end
                
                PARITY: begin
                    // Calculate parity
                    parity_bit = ^data_in;
                    if (parity_config == 2'b01) parity_bit = ~parity_bit; // Odd parity
                    tx_out <= parity_bit;
                    
                    if (baud_counter == baud_divisor) begin
                        state <= STOP;
                        baud_counter <= 16'h0;
                    end else begin
                        baud_counter <= baud_counter + 16'h1;
                    end
                end
                
                STOP: begin
                    tx_out <= 1'b1;
                    if (baud_counter == baud_divisor) begin
                        if (bit_counter == (data_bits + stop_bits)) begin
                            state <= IDLE;
                            transmitting <= 1'b0;
                        end else begin
                            bit_counter <= bit_counter + 4'h1;
                            baud_counter <= 16'h0;
                        end
                    end else begin
                        baud_counter <= baud_counter + 16'h1;
                    end
                end
            endcase
        end
    end
    
endmodule

// UART Receiver sub-module (simplified)
module uart_rx (
    input logic clk,
    input logic rst_n,
    input logic [15:0] baud_divisor,
    input logic [2:0] data_bits,
    input logic stop_bits,
    input logic [1:0] parity_config,
    input logic rx_in,
    output logic [7:0] data_out,
    output logic data_valid,
    output logic error
);
    // Implementation similar to transmitter but for receiving
    
    // Simplified for example
    assign data_out = 8'h0;
    assign data_valid = 1'b0;
    assign error = 1'b0;
    
endmodule
