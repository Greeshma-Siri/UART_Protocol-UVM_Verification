class uart_item extends uvm_sequence_item;
    rand bit [7:0] data;        // Data to be transmitted/received
    rand int       baud_rate;   // Baud rate for this transaction
    rand bit       parity_en;   // Parity enable
    rand parity_e  parity_type; // EVEN or ODD
    rand int       data_bits;   // Number of data bits (5-9)
    rand int       stop_bits;   // Number of stop bits (1 or 2)

    bit            error;       // Indicates if a parity/framing error occurred

    `uvm_object_utils_begin(uart_item)
        `uvm_field_int(data, UVM_DEFAULT)
        `uvm_field_int(baud_rate, UVM_DEFAULT)
        `uvm_field_int(parity_en, UVM_DEFAULT)
        `uvm_field_enum(parity_e, parity_type, UVM_DEFAULT)
        `uvm_field_int(data_bits, UVM_DEFAULT)
        `uvm_field_int(stop_bits, UVM_DEFAULT)
        `uvm_field_int(error, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "uart_item");
        super.new(name);
    endfunction

    // Constraints for valid configuration
    constraint c_valid_cfg {
        data_bits inside {[5:9]};
        stop_bits inside {1, 2};
        baud_rate inside {9600, 19200, 38400, 57600, 115200};
    }
endclass
