// module for sending signal from and FPGA to another FPGA
module interfpga_send(
  input wire [7:0] data,    // Input data
  input wire send,          // Signal the module to send the data 
                            // (data is ready) - active high
  output wire busy,         // Indicating that the module is busy
                            // sending data - active high
  output reg [3:0] data_o,  // lines used to send data
  output wire ctrl_o,       // line used to send control signal
  input wire reset,         // reset - active high
  input wire clk            // clock, this module uses positive edge
                            // to update it's FF
);

// state of this module contains the following
parameter sWait = 3'b000;   // indicates that the module is waiting to
                            // send data
parameter sSend = 3'b100;   // indicates that the module is sending data
                            // has 4 sub states (to send 8 bits, 4x2)
                            // 100, 101, 110, 111
                            // the same data is held for 2 clocks
                            // ex. 100 and 101 has the same data

reg [2:0] c_state, n_state; // module state
                            // c_state - current state
                            // n_state - next state

assign busy = c_state[2];   // the module sends a busy signal while in
                            // 1XX state 
assign ctrl_o = c_state[2]; // while sending the control line is high

// current state (c_state) block
// assign the next state (n_state) to the current state
always @( posedge clk or reset ) begin
  if(reset) begin
    c_state = sWait;
  end else begin
    c_state = n_state;  
  end 
end

// next state (n_state) block
// calculate the next state (sequential logic)
// if the current state is in sSend the and until overflow to sWait
// if recived send signal then go to sSend
// else stay at sWait
always @( * ) begin
  if( c_state[2] == 1 ) begin
    n_state = c_state + 1;
  end else if( send ) begin
    n_state = sSend;
  end else begin
    n_state = sWait;
  end 
end

// send the 4 least singificant bit first (c_state = 10X)
// then send the 4 most singificant bit first (c_state = 11X)
always @( * ) begin
  if( c_state[1] == 0 ) begin
    data_o = data[3:0];
  end else begin
    data_o = data[7:4];
  end 
end

endmodule // interfpga_send


// module for reciving signal from another FPGA
module interfpga_receive(
  output wire [7:0] data,   // Outputs data recived 
  output wire ready,        // Indicate that the data recived is 
                            // ready to be read - active high
  input wire reset_ready,   // resets the ready signal - active high
  input wire [3:0] data_i,  // lines used to recive data 
  input wire ctrl_i,        // line used to recive control signal
  input wire reset,         // reset - active high
  input wire clk            // clock, this module uses positive edge
                            // to update it's FF
);

reg [7:0] buffer [1:0];     // buffer for stroing data recived
                            // this module uses double buffering
reg c_buffer_select, n_buffer_select;
                            // buffer selector state
                            // c_buffer_select - current state
                            // n_buffer_select - next state
assign data = buffer[c_buffer_select];
                            //  data outputed is from
                            // the selected buffer

// state of this module contains the following
parameter sWait      = 3'b000;
                            // indicates that the module is waiting to
                            // recive data
parameter sReceiving = 3'b100;
                            // indicates that the module is reciving data
                            // has 4 sub states (to recive 8 bits, 4x2)
                            // 100, 101, 110, 111
                            // the same data is held for 2 clocks
                            // ex. 100 and 101 has the same data

reg [2:0] c_state, n_state; // module state
                            // c_state - current state
                            // n_state - next state 
reg p_state_2;              // p_state_2 stores c_state[2] in
                            // in the last clock

// states of data outputed contains the following
parameter sNotReady  = 1'b0;// data is ready to be read 
parameter sReady     = 1'b1;// data is not ready to be read

reg c_ready, n_ready;       // data ready state
                            // c_ready - current state
                            // n_ready - next state

assign ready = c_ready;     // send ready signal when in
                            // ready state
                            
// current state (c_state) block
// assign the next state (n_state) to the current state
always @( posedge clk or reset ) begin
  if(reset) begin
    c_state = sWait;
  end else begin
    c_state = n_state;
  end 
end

// Module prev-main state
// assign the last c_state[2] to p_state_2
always @( posedge clk or reset ) begin
  if(reset) begin
    p_state_2 = sWait;
  end else begin
    p_state_2 = c_state[2];
  end 
end

// next state (n_state) block
// calculate the next state (sequential logic)
// if the current state is in sReceiving the and until overflow to sWait
// if recived send signal then go to sReceiving
// else stay at sWait
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