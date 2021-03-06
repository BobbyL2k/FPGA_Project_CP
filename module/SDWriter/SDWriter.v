`include "../waiter/waiter.v"
`include "../serializer/serializer.v"
`include "../deserializer_with_counter/DeserializerWithCounter.v"
module SDWriter(
    input wire i_reset,
    input wire i_start,
    input wire i_s_clk,
    output wire o_busy,
    input wire MISO,
    input wire [7:0]dip_switch,
    output wire MOSI,
    output wire o_fifo_pop,
    input wire [7:0] i_8_fifo_data_out,
    input wire i_fifo_data_count, // number of data in FIDO
    output wire [7:0] o_8_LED
  );
  reg [7:0] written_block_counter;
  
  reg [4:0]
    c_state, n_state;
    
  /// FIFO handle in sStoreData
  reg [4095:0]
    mem;
  assign o_fifo_pop = c_state == sStoreData;
  assign o_busy = (c_state == sIDLE || c_state == sFINAL) ?  1'b0 : 1'b1;
  assign o_8_LED = {c_state,3'b111};

  always @( posedge i_s_clk or posedge i_reset ) begin
    if( i_reset ) begin
      mem = 0;
    end else begin
      if( c_state == sStoreData ) begin
        mem[ {store_counter,3'b000} ] = i_8_fifo_data_out;
      end
    end
  end
  /// End FIFO handle in sStoreData
  
  /// Serializer handle in sSendCMD24
  reg [31:0] address_to_write_to;
  always @( posedge i_s_clk or posedge i_reset ) begin
    if( i_reset ) begin
      address_to_write_to = 32'h00_F0_00_00;
      written_block_counter = 0;
    end else begin
      if( c_state == sCheckBusy && n_state == sCheckFIFODataCount) begin
        address_to_write_to = address_to_write_to + 1;
        written_block_counter = written_block_counter + 1;
      end
    end
  end
  wire [47:0] cmd24_command = {8'b0101_1000, address_to_write_to, 8'b1111_1111};
  reg [47:0] reverse_cmd24_command;
  
  integer i;
  always @* begin
    for(i=0; i<48; i=i+1) begin
      reverse_cmd24_command[i] = cmd24_command[47-i];
    end
  end
  
  wire isStateInCMD24, sp_isStateInCMD24, serial_CMD24, serializer_is_sending_CMD24;
  assign isStateInCMD24 = c_state == sSendCMD24;
  
  serializer #(
    .DATA_WIDTH(48))
  serializer_cmd24(
    .busy(serializer_is_sending_CMD24),
    .data_out(serial_CMD24),
    .data_in(reverse_cmd24_command),
    .start(isStateInCMD24),
    .clock(i_s_clk),
    .reset(i_reset)
  );
  
  /// End Serializer handle in sSendCMD24
  
  /// Helper Modules for listening in sWaitResponseCMD24
  wire response_CMD24_waiter_busy, response_CMD24_deserialization_response_busy;
  Waiter #(.COUNTER_SIZE(8)) 
    response_CMD24_waiter(
      .busy(response_CMD24_waiter_busy),
      .start(sp_isStateInCMD24),
      .count_to(8'h50),
      .clock(i_s_clk),
      .reset(i_reset));
  DeserializerWithCounter #(.DATA_LENGTH(7),.WORD_SIZE(8)) 
    response_CMD24_deserialization_response(
      // .data_out(),
      .busy(response_CMD24_deserialization_response_busy),
      // .RCO(),
      .start(sp_isStateInCMD24),
      .data_in(MISO),
      .clock(i_s_clk),
      .reset(i_reset)); //Deserializer for response1
  
  /// Helper Module for sSendData
  parameter data_to_send_WIDTH = 8+4096+16;
  wire [data_to_send_WIDTH-1:0] data_to_send;
  assign data_to_send = {8'b1111_1110, mem, {16{1'b1}}};
  reg [data_to_send_WIDTH-1:0] reverse_data_to_send;
  wire serializer_send_data_busy;
  
  //integer i;
  always @* begin
    for(i=0; i<data_to_send_WIDTH; i=i+1) begin
      reverse_data_to_send[i] = data_to_send[data_to_send_WIDTH-1 -i];
    end
  end
  wire isStateSendData; 
  assign isStateSendData = c_state == sSendData;
  serializer #(
    .DATA_WIDTH(data_to_send_WIDTH))
  serializer_send_data(
    .busy(serializer_send_data_busy),
    .data_out(),
    .data_in(),
    .start(isStateSendData),
    .clock(i_s_clk),
    .reset(i_reset)
  );
  /// End Helper Module for sSendData
  
  /// Helper Module for sWaitResponseSendData
  wire response_send_data_waiter_busy;
  Waiter #(.COUNTER_SIZE(14)) 
    response_send_data_waiter(
      .busy(response_send_data_waiter_busy),
      .start(isStateSendData),
      .count_to( data_to_send_WIDTH+256 ), // wait with some padding
      .clock(i_s_clk),
      .reset(i_reset));
  /// End Helper Module for sWaitResponseSendData
  
  always @(*) begin
    if( serializer_is_sending_CMD24 ) begin
      MOSI = serial_CMD24;
    end else begin
      MOSI = 1'b1;
    end
  end
  
  // Modules 
  
  /// Store Counter Module
  wire reset_store_counter;
  assign reset_store_counter = c_state != sStoreData;
  reg [9:0] store_counter;
  always @( posedge i_s_clk or posedge reset_store_counter ) begin
    if( reset_store_counter ) begin
      store_counter = 0;
    end else begin
      store_counter = store_counter + 1;
    end
  end
  /// End Store Counter Module
  
  // Module's main states
  parameter sIdle                 = 5'b00000;
  parameter sCheckFIFODataCount   = 5'b00001;
  parameter sStoreData            = 5'b00010;
  parameter sSendCMD24            = 5'b00011;
  parameter sSendData             = 5'b00100;
  parameter sWaitResponseSendData = 5'b00101;
  parameter sCheckBusy            = 5'b00110;
  parameter sFINAL                = 5'b00111;
  parameter sStoreData_Pop			 = 5'b01000;
  
  assign o_fifo_pop = (c_state == sStoreData_Pop) ? 1'b1 : 1'b0;
  
  always @( posedge i_s_clk or i_reset ) begin
    if( i_reset )begin
      c_state = sIdle;
    end else begin
      c_state = n_state;
    end
  end
  
  always @( * ) begin
    case (c_state)
      sIdle : begin
        if( i_start )begin
          n_state = sCheckFIFODataCount;
        end else begin
          n_state = sIdle;
        end
      end
      sCheckFIFODataCount : begin
        if(written_block_counter == dip_switch) begin
          n_state = sFINAL;
        end
        else if( i_fifo_data_count >= 512 ) begin
          n_state = sStoreData;
        end else begin
          n_state = sCheckFIFODataCount;
        end
      end
      sStoreData : begin
        if( store_counter >= 512 ) begin
          n_state = sSendCMD24;
        end else begin
          n_state = sStoreData_Pop;
        end
      end
		sStoreData_Pop : begin
			ns <= sStoreData;
		end
      sSendCMD24 : begin
        n_state = sWaitResponseCMD24;
      end
      sWaitResponseCMD24 : begin
        if( response_CMD24_waiter_busy && response_CMD24_deserialization_response_busy ) begin
          n_state = sWaitResponseCMD24;
        end else begin
          if( response_CMD24_deserialization_response_busy ) begin
            n_state = sSendCMD24;
          end else begin
            n_state = sSendData;
          end
        end
      end
      sSendData : begin
        n_state = sWaitResponseSendData;
      end
      sWaitResponseSendData : begin
        if( response_send_data_waiter_busy ) begin
          n_state = sWaitResponseSendData;
        end else begin
          n_state = sCheckBusy;
        end
      end
      sCheckBusy : begin
        if( MISO == 1'b0 ) begin
          n_state = sCheckBusy;
        end else begin
          n_state = sCheckFIFODataCount;
        end
      end
      sFINAL : begin
        n_state = sFINAL;
      end
      default: begin
        n_state = sIdle;
      end
    endcase
  end
  

endmodule // SDWriter