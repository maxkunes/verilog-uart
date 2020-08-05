module top(
        input           sys_clk,
        input  [3:0]    btn,
        output          uart_rxd_out,
        input           uart_txd_in
    );

    wire clk_out1;
    
    clk_wiz_0 clk_gen(
        .sys_clk(sys_clk),
        .clk_out1(clk_out1) // 92.16102 mhz
    );

    reg resetn = 1;
    reg fifo_write_en = 0;
    reg fifo_read_en = 0;
    wire fifo_empty;
    wire fifo_full;
    wire fifo_almost_full;
    wire read_data_ready;
    wire[7:0] fifo_output;

    // reset logic
    always @(posedge clk_out1)
        resetn = ~btn[0];
    

    fifo_uart_loopback loopback_fifo(
        .clk(clk_out1),
        .din(dout),
        .wr_en(fifo_write_en),
        .full(fifo_full),
        .empty(fifo_empty),
        .dout(fifo_output),
        .rd_en(fifo_read_en),
        .valid(read_data_ready),
        .almost_full(fifo_almost_full)
    );
    
    always @(posedge clk_out1) begin

        if(~fifo_almost_full && rx_complete) begin
            fifo_write_en <= 1;
        end
        else begin
            fifo_write_en <= 0;
        end

        if(tx_ready) begin

            if(~fifo_empty) begin
                fifo_read_en <= 1;
            end
            else begin
                fifo_read_en <= 0;
            end

            if(read_data_ready) begin
                din <= fifo_output;
                tx_valid <= 1;
            end
            else begin
                tx_valid <= 0;
            end
        end
        else begin
                tx_valid <= 0;
        end

    end
    
    wire[7:0] dout;
    wire rx_complete;
    reg[7:0] din = 0;
    wire tx_ready;
    reg tx_valid = 0;

    uart #(
        .baud(921600),
        .clk_freq(92.16102) 
    ) uart_arty (
        .clk(clk_out1),
        .resetn(resetn),
        .rx(uart_txd_in),
        .dout(dout),
        .rx_complete(rx_complete),
        .tx(uart_rxd_out),
        .din(din),
        .tx_ready(tx_ready),
        .tx_valid(tx_valid)
    );


endmodule
