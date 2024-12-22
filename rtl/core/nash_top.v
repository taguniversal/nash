module nash_top #(
    parameter STATE_WIDTH = 4,
    parameter MEM_DEPTH = 8
) (
    input wire clk,
    input wire rst_n,
    
    // Data interface
    input wire plaintext_in,
    input wire valid_in,
    output wire ciphertext_out,
    output wire valid_out,
    
    // Configuration interface
    input wire [MEM_DEPTH-1:0] red_perm_data,
    input wire [MEM_DEPTH-1:0] red_invert_mask,
    input wire [MEM_DEPTH-1:0] blue_perm_data,
    input wire [MEM_DEPTH-1:0] blue_invert_mask,
    input wire config_valid,
    output wire config_ready,
    
    // Debug interface
    output wire [STATE_WIDTH-1:0] dbg_state,
    output wire dbg_path_select,
    output reg delayed_input
);

    // Internal signals
    wire core_out;
    wire core_valid;
    
    // Instantiate core cipher
    nash_core #(
        .STATE_WIDTH(STATE_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) cipher_core (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(plaintext_in),
        .valid_in(valid_in),
        .data_out(core_out),
        .valid_out(core_valid),
        .red_perm_data(red_perm_data),
        .red_invert_mask(red_invert_mask),
        .blue_perm_data(blue_perm_data),
        .blue_invert_mask(blue_invert_mask),
        .config_valid(config_valid),
        .config_ready(config_ready),
        .dbg_state(dbg_state),
        .dbg_path_select(dbg_path_select)
    );
    
    // Retarder (1-bit delay)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            delayed_input <= 0;
        else if (valid_in)
            delayed_input <= plaintext_in;
    end
    
    // Adder (XOR)
    assign ciphertext_out = core_out ^ delayed_input;
    assign valid_out = core_valid;

endmodule