class uart_base_test extends uvm_test;
    `uvm_component_utils(uart_base_test)
    
    uart_env env;
    uart_virtual_sequencer virt_seqr;
    
    // Test configuration
    int test_timeout_ns = 1000000; // 1ms default timeout
    
    function new(string name = "uart_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_env::type_id::create("env", this);
        virt_seqr = uart_virtual_sequencer::type_id::create("virt_seqr", this);
        
        // Set test configuration
        uvm_config_db#(int)::set(this, "*", "test_timeout_ns", test_timeout_ns);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        virt_seqr.tx_seqr = env.tx_agent.sequencer;
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        // Set timeout
        phase.phase_done.set_drain_time(this, test_timeout_ns);
    endtask
    
    virtual function void report_phase(uvm_phase phase);
        uvm_report_server svr;
        svr = uvm_report_server::get_server();
        
        if (svr.get_severity_count(UVM_FATAL) + 
            svr.get_severity_count(UVM_ERROR) == 0) begin
            `uvm_info("TEST", "** TEST PASSED **", UVM_NONE)
        end else begin
            `uvm_info("TEST", "** TEST FAILED **", UVM_NONE)
        end
    endfunction
endclass

// Virtual Sequencer for coordinating multiple sequencers
class uart_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(uart_virtual_sequencer)
    
    uart_sequencer tx_seqr;
    
    function new(string name = "uart_virtual_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// Virtual sequence base class
class uart_virtual_sequence_base extends uvm_sequence;
    `uvm_object_utils(uart_virtual_sequence_base)
    `uvm_declare_p_sequencer(uart_virtual_sequencer)
    
    uart_simple_seq simple_seq;
    uart_baud_rate_seq baud_seq;
    uart_parity_seq parity_seq;
    
    function new(string name = "uart_virtual_sequence_base");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_info("VSEQ", "Starting virtual sequence", UVM_LOW)
    endtask
endclass

//----------------------------------------------------------------------------
// TEST 1: Basic Functionality Test
//----------------------------------------------------------------------------
class uart_basic_test extends uart_base_test;
    `uvm_component_utils(uart_basic_test)
    
    function new(string name = "uart_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uart_basic_vseq vseq;
        
        phase.raise_objection(this);
        
        vseq = uart_basic_vseq::type_id::create("vseq");
        vseq.start(virt_seqr);
        
        phase.drop_objection(this);
    endtask
endclass

class uart_basic_vseq extends uart_virtual_sequence_base;
    `uvm_object_utils(uart_basic_vseq)
    
    function new(string name = "uart_basic_vseq");
        super.new(name);
    endfunction
    
    task body();
        super.body();
        
        `uvm_info("VSEQ", "Running basic UART functionality test", UVM_LOW)
        
        // Test simple data transfer
        simple_seq = uart_simple_seq::type_id::create("simple_seq");
        simple_seq.num_transactions = 50;
        simple_seq.start(p_sequencer.tx_seqr);
        
        // Wait for all transactions to complete
        #10000;
    endtask
endclass

//----------------------------------------------------------------------------
// TEST 2: Baud Rate Test
//----------------------------------------------------------------------------
class uart_baud_test extends uart_base_test;
    `uvm_component_utils(uart_baud_test)
    
    function new(string name = "uart_baud_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uart_baud_vseq vseq;
        
        phase.raise_objection(this);
        
        vseq = uart_baud_vseq::type_id::create("vseq");
        vseq.start(virt_seqr);
        
        phase.drop_objection(this);
    endtask
endclass

class uart_baud_vseq extends uart_virtual_sequence_base;
    `uvm_object_utils(uart_baud_vseq)
    
    function new(string name = "uart_baud_vseq");
        super.new(name);
    endfunction
    
    task body();
        super.body();
        
        `uvm_info("VSEQ", "Running UART baud rate test", UVM_LOW)
        
        // Test all baud rates
        baud_seq = uart_baud_rate_seq::type_id::create("baud_seq");
        baud_seq.start(p_sequencer.tx_seqr);
        
        // Additional baud stress test
        repeat (10) begin
            simple_seq = uart_simple_seq::type_id::create("simple_seq");
            simple_seq.num_transactions = 5;
            simple_seq.start(p_sequencer.tx_seqr);
            #2000;
        end
    endtask
endclass

//----------------------------------------------------------------------------
// TEST 3: Parity Test
//----------------------------------------------------------------------------
class uart_parity_test extends uart_base_test;
    `uvm_component_utils(uart_parity_test)
    
    function new(string name = "uart_parity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uart_parity_vseq vseq;
        
        phase.raise_objection(this);
        
        vseq = uart_parity_vseq::type_id::create("vseq");
        vseq.start(virt_seqr);
        
        phase.drop_objection(this);
    endtask
endclass

class uart_parity_vseq extends uart_virtual_sequence_base;
    `uvm_object_utils(uart_parity_vseq)
    
    function new(string name = "uart_parity_vseq");
        super.new(name);
    endfunction
    
    task body();
        super.body();
        
        `uvm_info("VSEQ", "Running UART parity test", UVM_LOW)
        
        // Test parity functionality
        parity_seq = uart_parity_seq::type_id::create("parity_seq");
        parity_seq.num_transactions = 20;
        parity_seq.start(p_sequencer.tx_seqr);
        
        // Mix of parity and non-parity transactions
        repeat (5) begin
            simple_seq = uart_simple_seq::type_id::create("simple_seq");
            simple_seq.num_transactions = 4;
            if (!simple_seq.randomize() with {parity_en == 0;})
                `uvm_error("VSEQ", "Randomization failed")
            simple_seq.start(p_sequencer.tx_seqr);
            #500;
        end
    endtask
endclass

//----------------------------------------------------------------------------
// TEST 4: Data Frame Configuration Test
//----------------------------------------------------------------------------
class uart_frame_test extends uart_base_test;
    `uvm_component_utils(uart_frame_test)
    
    function new(string name = "uart_frame_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uart_frame_vseq vseq;
        
        phase.raise_objection(this);
        
        vseq = uart_frame_vseq::type_id::create("vseq");
        vseq.start(virt_seqr);
        
        phase.drop_objection(this);
    endtask
endclass

class uart_frame_vseq extends uart_virtual_sequence_base;
    `uvm_object_utils(uart_frame_vseq)
    
    uart_frame_config_seq frame_seq;
    
    function new(string name = "uart_frame_vseq");
        super.new(name);
    endfunction
    
    task body();
        super.body();
        
        `uvm_info("VSEQ", "Running UART frame configuration test", UVM_LOW)
        
        // Test different frame configurations
        frame_seq = uart_frame_config_seq::type_id::create("frame_seq");
        frame_seq.start(p_sequencer.tx_seqr);
    endtask
endclass

class uart_frame_config_seq extends uart_base_sequence;
    `uvm_object_utils(uart_frame_config_seq)
    
    function new(string name = "uart_frame_config_seq");
        super.new(name);
    endfunction
    
    task body();
        uart_item item;
        
        `uvm_info("SEQ", "Testing various frame configurations", UVM_LOW)
        
        // Test different data bits
        foreach ([5,6,7,8,9]) begin
            item = uart_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                data_bits == local::[i];
                stop_bits == 1;
                parity_en == 0;
            }) `uvm_error("SEQ", "Randomization failed")
            `uvm_info("SEQ", $sformatf("Testing %0d data bits", item.data_bits), UVM_MEDIUM)
            finish_item(item);
            #1000;
        end
        
        // Test different stop bits
        foreach ([1,2]) begin
            item = uart_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                data_bits == 8;
                stop_bits == local::[i];
                parity_en == 0;
            }) `uvm_error("SEQ", "Randomization failed")
            `uvm_info("SEQ", $sformatf("Testing %0d stop bits", item.stop_bits), UVM_MEDIUM)
            finish_item(item);
            #1000;
        end
    endtask
endclass

//----------------------------------------------------------------------------
// TEST 5: Error Injection Test
//----------------------------------------------------------------------------
class uart_error_test extends uart_base_test;
    `uvm_component_utils(uart_error_test)
    
    function new(string name = "uart_error_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uart_error_vseq vseq;
        
        phase.raise_objection(this);
        
        vseq = uart_error_vseq::type_id::create("vseq");
        vseq.start(virt_seqr);
        
        phase.drop_objection(this);
    endtask
endclass

class uart_error_vseq extends uart_virtual_sequence_base;
    `uvm_object_utils(uart_error_vseq)
    
    uart_error_seq err_seq;
    
    function new(string name = "uart_error_vseq");
        super.new(name);
    endfunction
    
    task body();
        super.body();
        
        `uvm_info("VSEQ", "Running UART error injection test", UVM_LOW)
        
        // Start with normal traffic
        simple_seq = uart_simple_seq::type_id::create("simple_seq");
        simple_seq.num_transactions = 10;
        simple_seq.start(p_sequencer.tx_seqr);
        
        // Inject errors
        err_seq = uart_error_seq::type_id::create("err_seq");
        err_seq.start(p_sequencer.tx_seqr);
        
        // More normal traffic
        simple_seq = uart_simple_seq::type_id::create("simple_seq");
        simple_seq.num_transactions = 10;
        simple_seq.start(p_sequencer.tx_seqr);
    endtask
endclass

//----------------------------------------------------------------------------
// TEST 6: Randomized Stress Test
//----------------------------------------------------------------------------
class uart_stress_test extends uart_base_test;
    `uvm_component_utils(uart_stress_test)
    
    function new(string name = "uart_stress_test", uvm_component parent = null);
        super.new(name, parent);
        test_timeout_ns = 2000000; // Longer timeout for stress test
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uart_stress_vseq vseq;
        
        phase.raise_objection(this);
        
        vseq = uart_stress_vseq::type_id::create("vseq");
        vseq.start(virt_seqr);
        
        phase.drop_objection(this);
    endtask
endclass

class uart_stress_vseq extends uart_virtual_sequence_base;
    `uvm_object_utils(uart_stress_vseq)
    
    uart_random_seq rand_seq;
    
    function new(string name = "uart_stress_vseq");
        super.new(name);
    endfunction
    
    task body();
        super.body();
        
        `uvm_info("VSEQ", "Running UART randomized stress test", UVM_LOW)
        
        // Run randomized sequences
        rand_seq = uart_random_seq::type_id::create("rand_seq");
        rand_seq.num_transactions = 100;
        rand_seq.start(p_sequencer.tx_seqr);
    endtask
endclass

class uart_random_seq extends uart_base_sequence;
    `uvm_object_utils(uart_random_seq)
    
    function new(string name = "uart_random_seq");
        super.new(name);
    endfunction
    
    task body();
        uart_item item;
        
        `uvm_info("SEQ", "Running randomized UART sequence", UVM_LOW)
        
        for (int i = 0; i < num_transactions; i++) begin
            item = uart_item::type_id::create("item");
            start_item(item);
            
            // Fully randomize with constraints
            if (!item.randomize()) 
                `uvm_error("SEQ", "Randomization failed")
            
            `uvm_info("SEQ", $sformatf("Random transaction %0d: data=0x%0h, baud=%0d, data_bits=%0d, parity_en=%0d", 
                      i, item.data, item.baud_rate, item.data_bits, item.parity_en), UVM_HIGH)
            
            finish_item(item);
            
            // Random delay between transactions
            #($urandom_range(10, 1000));
        end
    endtask
endclass

//----------------------------------------------------------------------------
// TEST 7: Regression Test
//----------------------------------------------------------------------------
class uart_regression_test extends uart_base_test;
    `uvm_component_utils(uart_regression_test)
    
    function new(string name = "uart_regression_test", uvm_component parent = null);
        super.new(name, parent);
        test_timeout_ns = 5000000; // Even longer timeout for regression
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        uart_regression_vseq vseq;
        
        phase.raise_objection(this);
        
        vseq = uart_regression_vseq::type_id::create("vseq");
        vseq.start(virt_seqr);
        
        phase.drop_objection(this);
    endtask
endclass

class uart_regression_vseq extends uart_virtual_sequence_base;
    `uvm_object_utils(uart_regression_vseq)
    
    function new(string name = "uart_regression_vseq");
        super.new(name);
    endfunction
    
    task body();
        super.body();
        
        `uvm_info("VSEQ", "Running UART regression test", UVM_LOW)
        
        // Run all test scenarios in sequence
        `uvm_info("VSEQ", "Phase 1: Basic functionality", UVM_MEDIUM)
        simple_seq = uart_simple_seq::type_id::create("simple_seq");
        simple_seq.num_transactions = 20;
        simple_seq.start(p_sequencer.tx_seqr);
        #5000;
        
        `uvm_info("VSEQ", "Phase 2: Baud rate testing", UVM_MEDIUM)
        baud_seq = uart_baud_rate_seq::type_id::create("baud_seq");
        baud_seq.start(p_sequencer.tx_seqr);
        #5000;
        
        `uvm_info("VSEQ", "Phase 3: Parity testing", UVM_MEDIUM)
        parity_seq = uart_parity_seq::type_id::create("parity_seq");
        parity_seq.num_transactions = 15;
        parity_seq.start(p_sequencer.tx_seqr);
        #5000;
        
        `uvm_info("VSEQ", "Phase 4: Frame configuration", UVM_MEDIUM)
        uart_frame_config_seq frame_seq = uart_frame_config_seq::type_id::create("frame_seq");
        frame_seq.start(p_sequencer.tx_seqr);
        #5000;
        
        `uvm_info("VSEQ", "Phase 5: Randomized stress", UVM_MEDIUM)
        uart_random_seq rand_seq = uart_random_seq::type_id::create("rand_seq");
        rand_seq.num_transactions = 50;
        rand_seq.start(p_sequencer.tx_seqr);
    endtask
endclass
