// Nash Stream Cipher Core - Fixed State Machine Implementation
module nash_core #(
    parameter STATE_WIDTH = 4,    // Needs to accommodate states 1-8
    parameter MEM_DEPTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire data_in,
    input wire valid_in,
    output wire data_out,
    output wire valid_out,
    
    // Configuration interface
    input wire [MEM_DEPTH-1:0] red_perm_data,
    input wire [MEM_DEPTH-1:0] red_invert_mask,
    input wire [MEM_DEPTH-1:0] blue_perm_data,
    input wire [MEM_DEPTH-1:0] blue_invert_mask,
    input wire config_valid,
    output reg config_ready,
    
    // Debug outputs
    output wire [STATE_WIDTH-1:0] dbg_state,
    output wire dbg_path_select
);

    // Internal state registers
    reg [STATE_WIDTH-1:0] current_state;
    reg [MEM_DEPTH-1:0] shift_reg;      // Shift register for bits
    reg path_select;                     // Current path selection
    
    // State encoding - one-hot encoding for clarity
    localparam STATE_1 = 4'd1;
    localparam STATE_2 = 4'd2;
    localparam STATE_3 = 4'd3;
    localparam STATE_4 = 4'd4;
    localparam STATE_5 = 4'd5;
    localparam STATE_6 = 4'd6;
    localparam STATE_7 = 4'd7;
    localparam STATE_8 = 4'd8;
    
    // Configuration registers
    reg [STATE_WIDTH-1:0] red_next_state [0:7];  // Next state lookup for red path
    reg [STATE_WIDTH-1:0] blue_next_state [0:7]; // Next state lookup for blue path
    reg red_invert [0:7];                        // Inversion flags for red path
    reg blue_invert [0:7];                       // Inversion flags for blue path
    
    // Internal signals
    wire [STATE_WIDTH-1:0] next_state;
    wire invert_bit;
    wire current_bit;
    
    // Convert configuration to lookup tables
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                red_next_state[i] <= 0;
                blue_next_state[i] <= 0;
                red_invert[i] <= 0;
                blue_invert[i] <= 0;
            end
        end else if (config_valid) begin
            // Load red path configuration
            for (i = 0; i < 8; i = i + 1) begin
                red_next_state[i] <= i + 1; // Default to next sequential state
                if (red_perm_data[i])
                    red_next_state[i] <= red_perm_data[i] + 1; // Add 1 since states are 1-based
                red_invert[i] <= red_invert_mask[i];
            end
            
            // Load blue path configuration
            for (i = 0; i < 8; i = i + 1) begin
                blue_next_state[i] <= i + 1; // Default to next sequential state
                if (blue_perm_data[i])
                    blue_next_state[i] <= blue_perm_data[i] + 1; // Add 1 since states are 1-based
                blue_invert[i] <= blue_invert_mask[i];
            end
        end
    end
    
    // State transition logic
    assign next_state = path_select ? 
                       red_next_state[current_state-1] : 
                       blue_next_state[current_state-1];
    
    assign invert_bit = path_select ? 
                       red_invert[current_state-1] : 
                       blue_invert[current_state-1];
    
    // Current bit from shift register
    assign current_bit = shift_reg[current_state-1];
    
    // State update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_1;
            shift_reg <= 0;
            path_select <= 0;
            config_ready <= 1;
        end else if (config_valid) begin
            current_state <= STATE_1;
            shift_reg <= 0;
            path_select <= 0;
            config_ready <= 0;
        end else if (valid_in) begin
            current_state <= next_state;
            shift_reg <= {shift_reg[MEM_DEPTH-2:0], data_in};
            path_select <= data_in;
            if (current_state == STATE_8)
                current_state <= STATE_1;
        end
    end
    
    // Output generation
    assign data_out = invert_bit ? ~current_bit : current_bit;
    assign valid_out = valid_in;
    
    // Debug outputs
    assign dbg_state = current_state;
    assign dbg_path_select = path_select;

endmodule