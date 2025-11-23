class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)
    
    uart_agent      tx_agent;
    uart_agent      rx_agent;
    uart_scoreboard scoreboard;
    uart_coverage   coverage;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        tx_agent = uart_agent::type_id::create("tx_agent", this);
        rx_agent = uart_agent::type_id::create("rx_agent", this);
        
        // Configure RX agent as passive
        uvm_config_db#(uvm_active_passive_enum)::set(this, "rx_agent", "is_active", UVM_PASSIVE);
        
        scoreboard = uart_scoreboard::type_id::create("scoreboard", this);
        coverage = uart_coverage::type_id::create("coverage", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect TX monitor to scoreboard and coverage
        tx_agent.analysis_port.connect(scoreboard.expected_fifo.analysis_export);
        tx_agent.analysis_port.connect(coverage.analysis_export);
        
        // Connect RX monitor to scoreboard
        rx_agent.analysis_port.connect(scoreboard.actual_fifo.analysis_export);
    endfunction
endclass
