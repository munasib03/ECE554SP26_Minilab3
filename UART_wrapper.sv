module UART_wrapper(clr_cmd_rdy, cmd_rdy, cmd, trmt, resp, tx_done, clk, rst_n, RX, TX);

        input logic clr_cmd_rdy, clk, rst_n, RX, trmt;
        input logic [7:0] resp;
        output logic [15:0] cmd;
        output logic tx_done, TX;
        output logic cmd_rdy;

        // internal output signals for UART Wrapper State Machine
        logic clr_rdy, store, rx_rdy;
        logic [7:0] rx_data;

        // internal high byte storing flop
        logic [7:0] FF_sig;

        // instantiate UART
        UART iUart(.clkc(clk),
                   .rst_n(rst_n),
                   .TX(TX),
                   .RX(RX),
                   .trmt(trmt),
                   .tx_data(resp),
                   .rx_data(rx_data),
                   .tx_done(tx_done),
                   .clr_rx_rdy(clr_rdy),
                   .rx_rdy(rx_rdy));

        // high byte storing flop and select mux logic
        always_ff @(posedge clk, negedge rst_n)
                if (!rst_n)
                        FF_sig <= 16'h0000;
                else if (store)
                        FF_sig <= rx_data;

        // cmd output
        assign cmd = {FF_sig, rx_data};

        // statemachine states
        typedef enum reg {IDLE, HIGHBYTE} state_t;

        state_t state, nxt_state;

        // infer state flop
        always_ff @(posedge clk, negedge rst_n)
                if (!rst_n)
                        state <= IDLE;
                else
                        state <= nxt_state;

        always_comb begin
                // default ouputs
                store = 0;
                clr_rdy = 0;
                cmd_rdy = 0;
                nxt_state = state;      // default state, meaning stay in the
                                                        // same state until state transition input is received

                case (state)
                        IDLE: if (rx_rdy) begin
                                        //cmd_rdy = 0;
                                        store = 1;
                                        clr_rdy = 1;
                                        nxt_state = HIGHBYTE;
                                  end

                        HIGHBYTE: if (rx_rdy) begin
                                                clr_rdy = 1;
                                                cmd_rdy = 1;
                                                nxt_state = IDLE;
                                          end

                        // default case
                        default: nxt_state = IDLE;

                endcase
        end

        // flop to make cmd_rdy low when clr_cmd_rdy is asserted
        always_ff @(posedge clk, negedge rst_n)
                if (!rst_n)
                        cmd_rdy <= 1'b0;
                else if (clr_cmd_rdy)
                        cmd_rdy <= 1'b1;

endmodule
