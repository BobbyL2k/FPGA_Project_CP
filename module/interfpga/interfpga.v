module interfpga_send(
  input wire [7:0] data,
  input wire send,
  output wire busy,
  output reg [3:0] data_o,
  output wire ctrl_o,
  input wire reset,
  input wire clk
);

parameter sWait = 3'b000;
parameter sSend = 3'b100;

reg [2:0] c_state, n_state;

assign busy = c_state[2];
assign ctrl_o = c_state[2];

always @( posedge clk or reset ) begin
  if(reset) begin
    c_state = sWait;
  end else begin
    c_state = n_state;  
  end 
end

always @( * ) begin
  if( c_state[2] == 1 ) begin
    n_state = c_state + 1;
  end else if( send ) begin
    n_state = sSend;
  end else begin
    n_state = sWait;
  end 
end

always @( * ) begin
  if( c_state[1] == 1 ) begin
    data_o = data[7:4];
  end else begin
    data_o = data[3:0];
  end 
end

endmodule // interfpga_send

module interfpga_receive(
  output wire [7:0] data,
  output wire ready,
  input wire reset_ready,
  input wire [3:0] data_i,
  input wire ctrl_i,
  input wire reset,
  input wire clk//,
  //output wire [15:0] bufx
);

reg [7:0] buffer [1:0];
reg c_buffer_select, n_buffer_select;
assign data = buffer[c_buffer_select];
//assign bufx[15:8] = buffer[1];
//assign bufx[7:0] = buffer[0];

parameter sWait      = 3'b000;
parameter sReceiving = 3'b100;

reg [2:0] c_state, n_state;
reg p_state_2;

parameter sNotReady  = 1'b0;
parameter sReady     = 1'b1;

reg c_ready, n_ready;

assign ready = c_ready;

// Module main state
always @( posedge clk or reset ) begin
  if(reset) begin
    c_state = sWait;
  end else begin
    c_state = n_state;
  end 
end

// Module prev-main state
always @( posedge clk or reset ) begin
  if(reset) begin
    p_state_2 = sWait;
  end else begin
    p_state_2 = c_state[2];
  end 
end

always @( * ) begin
  if( c_state[2] == 1 ) begin
    n_state = c_state + 1;
  end else if ( ctrl_i ) begin
    n_state = sReceiving;
  end else begin
    n_state = sWait;
  end 
end

// Ready status state
always @( posedge clk or reset_ready or reset ) begin
  if( reset_ready || reset ) begin
    c_ready = sNotReady;
  end else begin
    c_ready = n_ready;
  end
end

always @( * ) begin
  if( c_state[2] == 0 && p_state_2 == 1 ) begin
    n_ready = sReady;
  end else begin
    n_ready = c_ready;
  end 
end

// Buffer Selector state
always @( posedge clk or reset ) begin
  if( reset ) begin
    c_buffer_select = 0;
  end else begin
    c_buffer_select = n_buffer_select;
  end
end

always @( * ) begin
  if( c_state[2] == 1 && n_state[2] == 0 ) begin
    n_buffer_select = ~c_buffer_select;
  end else begin
    n_buffer_select = c_buffer_select;
  end
end

// Buffer writing
always @( posedge clk or reset ) begin
  if( reset ) begin
    buffer[0] <= 8'h00;
    buffer[1] <= 8'h00;
  end else begin
    if( c_state == 3'b100 ) begin
      buffer[~c_buffer_select][3:0] <= data_i;
      buffer[~c_buffer_select][7:4] <= buffer[~c_buffer_select][7:4];
      buffer[c_buffer_select] <= buffer[c_buffer_select];
    end else if ( c_state == 3'b110 ) begin
      buffer[~c_buffer_select][3:0] <= buffer[~c_buffer_select][3:0];
      buffer[~c_buffer_select][7:4] <= data_i;
      buffer[c_buffer_select] <= buffer[c_buffer_select];
    end else begin
      buffer[0] <= buffer[0];
      buffer[1] <= buffer[1];
    end
  end
end

endmodule // interfpga_receive