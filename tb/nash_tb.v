// Nash Cipher Testbench
`timescale 1ns/1ps

module nash_tb();
    // Parameters
    parameter CLK_PERIOD = 10;  // 100MHz clock
    parameter STATE_WIDTH = 4;
    parameter MEM_DEPTH = 8;
    
    // Test bench signals
    reg clk;
    reg rst_n;
    reg plaintext_in;
    reg valid_in;
    reg [MEM_DEPTH-1:0] red_perm_data;
    reg [MEM_DEPTH-1:0] red_invert_mask;
    reg [MEM_DEPTH-1:0] blue_perm_data;
    reg [MEM_DEPTH-1:0] blue_invert_mask;
    reg config_valid;
    
    wire ciphertext_out;
    wire valid_out;
    wire config_ready;
    
    // Test vectors
    reg [7:0] test_message;
    reg [7:0] encrypted_result;
    reg [7:0] decrypted_result;
    
    // Debug signals
    reg [7:0] permuter_outputs;
    reg [7:0] delayed_inputs;
    
    // Instantiate the Nash cipher
    nash_top #(
        .STATE_WIDTH(STATE_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .plaintext_in(plaintext_in),
        .valid_in(valid_in),
        .ciphertext_out(ciphertext_out),
        .valid_out(valid_out),
        .red_perm_data(red_perm_data),
        .red_invert_mask(red_invert_mask),
        .blue_perm_data(blue_perm_data),
        .blue_invert_mask(blue_invert_mask),
        .config_valid(config_valid),
        .config_ready(config_ready)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Set up waveform dumping
        $dumpfile("nash_tb.vcd");
        $dumpvars(0, nash_tb);
        
        // Initialize signals
        test_message = 8'b10110011;
        rst_n = 0;
        plaintext_in = 0;
        valid_in = 0;
        config_valid = 0;
        encrypted_result = 0;
        decrypted_result = 0;
        permuter_outputs = 0;
        delayed_inputs = 0;
        
        // Initial permutation configuration (based on Nash's example)

		// Red path: 1->4->7->5->2->3->6->8
		red_perm_data   = 8'b00100111;  // State transitions
		red_invert_mask = 8'b00011100;  // Inversion mask

		// Blue path: 1->3->4->6->7->2->5->8
		blue_perm_data  = 8'b00011110;  // State transitions
		blue_invert_mask = 8'b11100010; // Inversion mask
        
        // Reset sequence
        #(CLK_PERIOD*2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        // Load configuration
        config_valid = 1;
        #(CLK_PERIOD);
        config_valid = 0;
        
        // Wait for configuration to settle
        #(CLK_PERIOD*2);
        
        // Test 1: Basic encryption
        $display("\n=== Starting Encryption Test ===");
        
        for (integer i = 0; i < 8; i = i + 1) begin
            plaintext_in = test_message[7-i];
            valid_in = 1;
            #(CLK_PERIOD);
            encrypted_result[7-i] = ciphertext_out;
            permuter_outputs[7-i] = dut.cipher_core.data_out;
            delayed_inputs[7-i] = dut.delayed_input;
            
            $display("Cycle %0d:", i);
            $display("  Input bit: %b", plaintext_in);
            $display("  Permuter output: %b", dut.cipher_core.data_out);
            $display("  Delayed input: %b", dut.delayed_input);
            $display("  Final output: %b", ciphertext_out);
            $display("  Current state: %0d", dut.cipher_core.current_state);
            $display("  Path select: %b", dut.cipher_core.path_select);
        end
        valid_in = 0;
        
        $display("\nEncryption Summary:");
        $display("Original message:   %b", test_message);
        $display("Permuter outputs:   %b", permuter_outputs);
        $display("Delayed inputs:     %b", delayed_inputs);
        $display("Encrypted result:   %b", encrypted_result);
        
        // Reset before decryption
        rst_n = 0;
        #(CLK_PERIOD*2);
        rst_n = 1;
        #(CLK_PERIOD*2);
        
        // Reload configuration
        config_valid = 1;
        #(CLK_PERIOD);
        config_valid = 0;
        #(CLK_PERIOD*2);
        
        // Test 2: Decryption
        $display("\n=== Starting Decryption Test ===");
        permuter_outputs = 0;
        delayed_inputs = 0;
        
        for (integer i = 0; i < 8; i = i + 1) begin
            plaintext_in = encrypted_result[7-i];
            valid_in = 1;
            #(CLK_PERIOD);
            decrypted_result[7-i] = ciphertext_out;
            permuter_outputs[7-i] = dut.cipher_core.data_out;
            delayed_inputs[7-i] = dut.delayed_input;
            
            $display("Cycle %0d:", i);
            $display("  Input bit: %b", plaintext_in);
            $display("  Permuter output: %b", dut.cipher_core.data_out);
            $display("  Delayed input: %b", dut.delayed_input);
            $display("  Final output: %b", ciphertext_out);
            $display("  Current state: %0d", dut.cipher_core.current_state);
            $display("  Path select: %b", dut.cipher_core.path_select);
        end
        valid_in = 0;
        
        $display("\nDecryption Summary:");
        $display("Encrypted input:    %b", encrypted_result);
        $display("Permuter outputs:   %b", permuter_outputs);
        $display("Delayed inputs:     %b", delayed_inputs);
        $display("Decrypted result:   %b", decrypted_result);
        $display("Original message:   %b", test_message);
        
        if (decrypted_result === test_message)
            $display("\nTEST PASSED: Decryption matches original message");
        else begin
            $display("\nTEST FAILED: Decryption mismatch!");
            $display("Differences:");
            for (integer i = 0; i < 8; i = i + 1) begin
                if (decrypted_result[i] !== test_message[i])
                    $display("  Bit %0d: Expected %b, Got %b", 
                            i, test_message[i], decrypted_result[i]);
            end
        end
        
        // Test 3: Error recovery
        #(CLK_PERIOD*4);
        $display("\nStarting error recovery test...");
        plaintext_in = 1'b1;
        valid_in = 1;
        #(CLK_PERIOD);
        plaintext_in = 1'bx; // Simulate error
        #(CLK_PERIOD);
        plaintext_in = 1'b0;
        #(CLK_PERIOD*2);
        valid_in = 0;
        
        // End simulation
        #(CLK_PERIOD*10);
        $finish;
    end

endmodule