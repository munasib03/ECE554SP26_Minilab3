module UART_tx(input clk, input rst_n, input trmt, input logic [7:0] tx_data, output logic tx_done, output logic TX);

        logic init, transmitting, shift, set_done, byte_valid;
        logic [8:0] tx_shft_reg;
        logic [11:0] baud_cnt;
        logic [3:0] bit_cnt;

        // rightmost block (shifts the data bits)
        always_ff @(posedge clk, negedge rst_n)
                if (!rst_n)
                        tx_shft_reg <= 9'h1FF;
                else if (init)
                        tx_shft_reg <= {tx_data, 1'b0};
                else if (shift)
                        tx_shft_reg <= {1'b1, tx_shft_reg[8:1]};

        assign TX = tx_shft_reg[0];

        // Middle block (counts baud period)
        always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n)
                        baud_cnt <= 12'h000;
                else if (init | shift)
                        baud_cnt <= 12'h000;
                else if (transmitting)
                        baud_cnt <= baud_cnt + 1;
        end

        assign shift = (baud_cnt == 12'd2604) ? 1'b1 : 1'b0;

        // leftmost block (counts total bits sent)
        always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n)
                        bit_cnt <= 4'h0;
                else if (init)
                        bit_cnt <= 4'h0;
                else if (shift)
                        bit_cnt <= bit_cnt + 1;
        end

        assign byte_valid = (bit_cnt == 4'b1010) ? 1'b1 : 1'b0;

        typedef enum reg {IDLE, TRANSMIT} state_t;

        state_t state, nxt_state;

        always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n)
                        state <= IDLE;
                else
                        state <= nxt_state;
        end

        always_comb begin
                init = 0;
                transmitting = 0;
                set_done = 0;
                nxt_state = state;

                case (state)
                        IDLE : if (trmt) begin
                                init = 1;
                                nxt_state = TRANSMIT;
                        end

                        TRANSMIT : begin
                                transmitting = 1;
                                if (byte_valid) begin
                                        set_done = 1;
                                        nxt_state = IDLE;
                                end
                        end

                        default : nxt_state = IDLE;

                endcase
        end

        always_ff @(posedge clk, negedge rst_n) begin
                if (!rst_n)
                        tx_done <= 1'b0;
                else if (init)
                        tx_done <= 1'b0;
                else if (set_done)
                        tx_done <= 1'b1;
        end

endmodule
