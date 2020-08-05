module uart #(
        parameter real baud     = 9600,     // target baud rate for receive and transmission. should be able to devide the input clock to this value.
        parameter real clk_freq = 100       // clk frequency in mhz. 100 == 100 mhz
    )
    (
        input               clk,            // input clock, for best results, it should be a multiple of the target baud rate and should be substantially faster.
        input               resetn,         // active low reset, sync to clk         
        input               rx,             // input rx stream. can be in another clock domain as it gets double clocked to syncronize it to clk
        output reg[7:0]     dout        = 0,// receive output, valid when rx_complete is high
        output      reg     rx_complete = 0,// high for one clock cycle denoting that dout is valid
        output      reg     tx          = 1,// output tx stream
        input[7:0]          din,            // input data to be transmitted
        output      reg     tx_ready    = 1,// denotes that din is ready to be filled with data. 
        input               tx_valid    = 0 // asserted for one clock cycle by controller to denote that din has data that is ready to be transmitted
    );



    
    parameter real  clk_freq_hz = clk_freq * 1000000;                           // absolute clock frequency in hertz
    parameter integer clocks_per_bit        = clk_freq_hz / baud;               // clock cycles in one bit/baud
    parameter integer clock_counter_width   = $ceil($clog2(clocks_per_bit));    // solves clocks_per_bit == 2^clock_counter_width

    // rx regs
    enum {E_RX_IDLE, E_RX_START, E_RX_DATA, E_RX_STOP} rx_state = E_RX_IDLE;
    reg [clock_counter_width-1:0] rx_clk_counter = 0;
    reg [7:0]  rx_buffer      = 'hCC;
    reg [2:0]  rx_bit_index   = 0;
    reg        rx_meta        = 1;
    reg        rx_stable      = 1;

    // tx regs
    enum {E_TX_IDLE, E_TX_START, E_TX_DATA, E_TX_STOP} tx_state = E_TX_IDLE;
    reg [clock_counter_width-1:0] tx_clk_counter = 0;
    reg [7:0]  tx_buffer      = 'hCC;
    reg [2:0]  tx_bit_index   = 0;


    // receiver
    always@ (posedge clk) begin
         if(~resetn) begin
            rx_state        <= E_RX_IDLE;
            rx_clk_counter  <= 0;
            rx_bit_index    <= 0;
            rx_buffer       <= 'hCC;
            rx_meta         <= 1;
            rx_stable       <= 1;
            dout            <= 0;
         end
         else begin
             // make input metastable
            rx_meta <= rx;
            rx_stable <= rx_meta;

            // to ensure receive_complete is set high for atmost one clock cycle...
            rx_complete <= 0;
            
            case (rx_state)
                E_RX_IDLE: begin
                    // look for start bit...
                    if(~rx_stable) begin
                        // detected start bit...
                        rx_state <= E_RX_START;
                    end
                end
                E_RX_START: begin 
                    rx_clk_counter <= rx_clk_counter + 1;

                    if(rx_clk_counter == (clocks_per_bit - 1)/2) begin
                        rx_state        <= E_RX_DATA;
                        rx_clk_counter  <= 0;
                        rx_bit_index    <= 0;
                    end
                end
                E_RX_DATA: begin
                    rx_clk_counter <= rx_clk_counter + 1;


                    if(rx_clk_counter == (clocks_per_bit - 1)) begin
                        // found center of data bit...
                        rx_buffer[rx_bit_index] <= rx_stable;
                        rx_bit_index            <= rx_bit_index + 1;
                        rx_clk_counter          <= 0;

                        if(rx_bit_index == 7) begin
                            rx_state    <= E_RX_STOP;
                        end
                    end

                end
                E_RX_STOP: begin
                    rx_clk_counter <= rx_clk_counter + 1;
                    if(rx_clk_counter == (clocks_per_bit - 1)) begin
                        // found center of stop bit...
                        rx_state            <= E_RX_IDLE;
                        rx_clk_counter      <= 0;
                        dout                <= rx_buffer;
                        rx_complete    <= 1;
                    end
                end

            endcase

         end
    end

    // transmitter
    always@ (posedge clk) begin
        
        if(~resetn) begin
            // transmitter registers
            tx_state <= E_TX_IDLE;
            tx_clk_counter <= 0;
            tx_buffer      <= 'hCC;
            tx_bit_index   <= 0;
            tx             <= 1;
            tx_ready       <= 1;
        end
        else begin
            case (tx_state) 
                E_TX_IDLE: begin
                    if(tx_valid) begin
                        tx_buffer <= din;
                        tx_state  <= E_TX_START;
                        tx_ready  <= 0;
                        tx_clk_counter <= 0;
                    end
                end
                E_TX_START: begin
                    tx_clk_counter <= tx_clk_counter + 1;

                    tx <= 0; // start bit is low

                    if(tx_clk_counter == clocks_per_bit - 1) begin
                        tx_state        <= E_TX_DATA;
                        tx_clk_counter  <= 0;
                        tx_bit_index    <= 0;
                    end
                end
                E_TX_DATA: begin
                    tx_clk_counter <= tx_clk_counter + 1;

                    tx <= tx_buffer[tx_bit_index];

                    if(tx_clk_counter == clocks_per_bit - 1) begin
                        tx_clk_counter  <= 0;    

                        if(tx_bit_index == 7) begin
                            tx_state <= E_TX_STOP;
                        end
                        else begin
                            tx_bit_index <= tx_bit_index + 1;
                        end
                    end
                end
                E_TX_STOP: begin
                    tx_clk_counter <= tx_clk_counter + 1;

                    tx <= 1; // stop bit is high

                    if(tx_clk_counter == clocks_per_bit - 1) begin
                        tx_clk_counter  <= 0;
                        tx_state        <= E_TX_IDLE;
                        tx_ready        <= 1;
                    end
                end
            endcase
        end
    end
endmodule

      