
  // Part 2 skeleton
  // `timescale time_unit/time_precision
  module lblock
          (
                  CLOCK_50,                                               //      On Board 50 MHz
                  // Your inputs and outputs here
          KEY,
          SW,
                    LEDR,
                  // The ports below are for the VGA output.  Do not change.
                  VGA_CLK,                                                 //      VGA Clock
                  VGA_HS,                                                 //      VGA H_SYNC
                  VGA_VS,                                                 //      VGA V_SYNC
                  VGA_BLANK_N,                                    //      VGA BLANK               
                  VGA_SYNC_N,                                             //      VGA SYNC                        
                  VGA_R,                                                   //      VGA Red[9:0]
                  VGA_G,                                            //      VGA Green[9:0]
                  VGA_B                                            //      VGA Blue[9:0]
          );

          input                   CLOCK_50;                               //      50 MHz
          input   [9:0]   SW;
          input   [3:0]   KEY;
          output reg [9:0] LEDR;
          // Declare your inputs and outputs here
          // Do not change the following outputs
          output                  VGA_CLK;                                 //      VGA Clock
          output                  VGA_HS;                                 //      VGA H_SYNC
          output                  VGA_VS;                                 //      VGA V_SYNC
          output                  VGA_BLANK_N;                    //      VGA BLANK
          output                  VGA_SYNC_N;                             //      VGA SYNC
          output  [9:0]   VGA_R;                                   //      VGA Red[9:0]
          output  [9:0]   VGA_G;                            //      VGA Green[9:0]
          output  [9:0]   VGA_B;                                   //      VGA Blue[9:0]
          
          wire resetn;
          assign resetn = KEY[0];
          
          // Create the colour, x, y and writeEn wires that are inputs to the controller.
          wire [2:0] colour;
          reg [7:0] x;
          reg [6:0] y;
          wire writeEn;
          
          // Create an Instance of a VGA controller - there can be only one!
          // Define the number of colours as well as the initial background
          // image file (.MIF) for the controller.
          
          vga_adapter VGA(
                          .resetn(resetn),
                          .clock(CLOCK_50),
                          .colour(current_color),
                          .x(x),
                          .y(y),
                          .plot(1'b1),
                          .VGA_R(VGA_R),
                          .VGA_G(VGA_G),
                          .VGA_B(VGA_B),
                          .VGA_HS(VGA_HS),
                          .VGA_VS(VGA_VS),
                          .VGA_BLANK(VGA_BLANK_N),        
                          .VGA_SYNC(VGA_SYNC_N),                  
                          .VGA_CLK(VGA_CLK));
                  defparam VGA.RESOLUTION = "160x120";
                  defparam VGA.MONOCHROME = "FALSE";
                  defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
                  defparam VGA.BACKGROUND_IMAGE = "black.mif";
          // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
          // for the VGA controller, in addition to any other functionality your design may require.
      
          wire counterReset;
          wire counterEnable;
          wire resetRegisters;
          wire [3:0] counterCount;
          
          wire loadX;
          wire loadY;
          
          reg [3:0] simulate_keys = 4'b1111;
          reg [4:0] current_step = 5'b00000;
          
          reg [6:0] current_block_value;
          reg [6:0] current_reference_x = 7'b0111111;  //Initial x
          reg [6:0] current_reference_y = 7'b1000111; //Initial y

          //Parameters
          parameter ROTATION_0 = 2'b00, ROTATION_1 = 2'b01, ROTATION_2 = 2'b10, ROTATION_3 = 2'b11;
          parameter NEUTRAL_STATE = 5'b00000, RESET_COUNTER_FOR_ERASE_ROTATION = 5'b00001, ERASE_FOR_ROTATION = 5'b00010, ROTATE = 5'b00011, RESET_COUNTER_FOR_NEUTRAL = 5'b00100, RESET_COUNTER_FOR_MOVE_LEFT = 5'b00101, RESET_COUNTER_FOR_MOVE_RIGHT = 5'b00110, MOVE_LEFT = 5'b00111, MOVE_RIGHT = 5'b01000, ERASE_FOR_MOVE_LEFT = 5'b01001, ERASE_FOR_MOVE_RIGHT = 5'b01010;
          parameter PINK_COLOR = 3'b101, BLACK_COLOR = 3'b000;

          reg [4:0] current_state = NEUTRAL_STATE;
          reg [4:0] next_state = NEUTRAL_STATE;
          reg [2:0] current_color = PINK_COLOR;
          reg [1:0] current_rotation_state = ROTATION_0;
          
          reg [6:0] tempX;
          reg [6:0] tempY; //Holding values

          wire draw_clock;
          RateDivider r(
                  .clk(CLOCK_50),
                  .b0(1'b0),
                  .b1(1'b1),
                  .q(draw_clock)
          );

          always @(posedge CLOCK_50) begin
             current_state <= next_state;
          end

          //Current adder incrementer
          always@(posedge draw_clock) 
          begin
             // current_adder_step <= (current_adder_step == 3'b011 || current_state == RESET_COUNTER_FOR_NEUTRAL || current_state == RESET_COUNTER_FOR_ERASE_ROTATION || current_state == RESET_COUNTER_FOR_MOVE_LEFT || current_state == RESET_COUNTER_FOR_MOVE_RIGHT) ? 3'b000 : current_adder_step + 1;
             current_adder_step = (current_adder_step == 3'b011 || current_state == RESET_COUNTER_FOR_MOVE_LEFT || current_state == RESET_COUNTER_FOR_MOVE_RIGHT) ? 3'b000 : current_adder_step + 1;
          end

          always@(*) begin
                  case(current_state)
                          NEUTRAL_STATE:
                          begin
                             current_color = PINK_COLOR;
                             current_rotation_state = current_rotation_state;
                             current_reference_x = current_reference_x;
                             current_reference_y = current_reference_y;
                             has_moved = 1'b0;
                          end
                         ERASE_FOR_MOVE_LEFT:
                         begin
                             current_color = BLACK_COLOR;
                             current_rotation_state = current_rotation_state;
                             current_reference_x = current_reference_x;
                             current_reference_y = current_reference_y;
                             has_moved = 1'b0;
                         end
                         ERASE_FOR_MOVE_RIGHT:
                         begin
                             current_color = BLACK_COLOR;
                             current_rotation_state = current_rotation_state;
                             current_reference_x = current_reference_x;
                             current_reference_y = current_reference_y;
                             has_moved = 1'b0;
                         end
                         MOVE_LEFT:
                         begin
                             if (has_moved == 1'b0) begin
                                 has_moved = 1'b1;
                                 current_reference_x <= current_reference_x - 1;
                                 current_reference_y <= current_reference_y;  
                                 current_color = BLACK_COLOR;
                                 current_rotation_state = current_rotation_state;
                             end else begin
                                 has_moved = 1'b0;
                                 current_reference_x = current_reference_x;
                                 current_reference_y = current_reference_y;  
                                 current_color = BLACK_COLOR;
                                 current_rotation_state = current_rotation_state;
                             end
                         end
                         MOVE_RIGHT:
                         begin
                             if (has_moved == 1'b0) begin
                                 has_moved = 1'b1;
                                 current_reference_x <= current_reference_x + 1;
                                 current_reference_y <= current_reference_y;  
                                 current_color = BLACK_COLOR;
                                 current_rotation_state = current_rotation_state;
                             end else begin
                                 has_moved = 1'b0;
                                 current_reference_x = current_reference_x;
                                 current_reference_y = current_reference_y;  
                                 current_color = BLACK_COLOR;
                                 current_rotation_state = current_rotation_state;
                             end
                         end
                         default:
                         begin
                             has_moved = 1'b0;
                             current_color = BLACK_COLOR;
                             current_rotation_state = current_rotation_state;
                             current_reference_x = current_reference_x;
                             current_reference_y = current_reference_y;
                         end
                  endcase
          end

          //State transitions
          always@(*) 
          begin
              case(current_state)
                 NEUTRAL_STATE:
                 begin
                     if (~KEY[3]) begin
                         next_state = RESET_COUNTER_FOR_MOVE_LEFT;
                     end else if (~KEY[1]) begin
                         next_state = RESET_COUNTER_FOR_MOVE_RIGHT;
                     end else begin
                         next_state = NEUTRAL_STATE;
                     end
                 end
                 RESET_COUNTER_FOR_MOVE_LEFT: next_state = (current_adder_step == 3'b000) ? ERASE_FOR_MOVE_LEFT : RESET_COUNTER_FOR_MOVE_LEFT;
                 RESET_COUNTER_FOR_MOVE_RIGHT: next_state = (current_adder_step == 3'b000) ? ERASE_FOR_MOVE_RIGHT : RESET_COUNTER_FOR_MOVE_RIGHT;
                 ERASE_FOR_MOVE_RIGHT: next_state = (current_adder_step == 3'b011) ? MOVE_RIGHT : ERASE_FOR_MOVE_RIGHT;
                 ERASE_FOR_MOVE_LEFT: next_state = (current_adder_step == 3'b011) ? MOVE_LEFT: ERASE_FOR_MOVE_LEFT;
                 MOVE_LEFT: next_state = (has_moved == 3'b1) ? RESET_COUNTER_FOR_NEUTRAL : MOVE_LEFT;
                 MOVE_RIGHT: next_state = (has_moved == 3'b1) ? RESET_COUNTER_FOR_NEUTRAL : MOVE_RIGHT;
                 RESET_COUNTER_FOR_NEUTRAL: next_state = (current_adder_step == 3'b000) ? NEUTRAL_STATE : RESET_COUNTER_FOR_NEUTRAL;
                 default: next_state = NEUTRAL_STATE;
              endcase
          end

          reg [2:0] current_adder_step = 3'b000;
          reg has_moved = 1'b0;

          always@(current_adder_step) begin
              case (current_adder_step)
                 3'b000:
                 begin
                     //Draw the first block
                     x <= current_reference_x;
                     y <= current_reference_y;
                 end
                 3'b001:
                 begin
                     if (current_rotation_state == ROTATION_0) begin
                         x <= current_reference_x - 1; 
                         y <= current_reference_y;
                     end else if (current_rotation_state == ROTATION_1) begin
                         x <= current_reference_x;
                         y <= current_reference_y - 1;
                     end else if (current_rotation_state == ROTATION_2) begin
                         x <= current_reference_x - 1;
                         y <= current_reference_y;
                     end else begin
                         x <= current_reference_x - 1;
                         y <= current_reference_y - 1;
                     end
                 end
                 3'b010:
                 begin
                     if (current_rotation_state == ROTATION_0) begin
                         x <= current_reference_x + 1; 
                         y <= current_reference_y;
                     end else if (current_rotation_state == ROTATION_1) begin
                         x <= current_reference_x;
                         y <= current_reference_y + 1;
                     end else if (current_rotation_state == ROTATION_2) begin
                         x <= current_reference_x - 1;
                         y <= current_reference_y + 1;
                     end else begin
                         x <= current_reference_x;
                         y <= current_reference_y - 1;
                     end
                 end
                 3'b011:
                 begin
                     if (current_rotation_state == ROTATION_0) begin
                         x <= current_reference_x + 1; 
                         y <= current_reference_y - 1;
                     end else if (current_rotation_state == ROTATION_1) begin
                         x <= current_reference_x + 1;
                         y <= current_reference_y + 1;
                     end else if (current_rotation_state == ROTATION_2) begin
                         x <= current_reference_x + 1;
                         y <= current_reference_y;
                     end else begin
                         x <= current_reference_y;
                         y <= current_reference_y + 1;
                     end
                 end
                 default:
                 begin
                     x <= current_reference_x;
                     y <= current_reference_y;
                 end
             endcase
          end

          // //Draw an l block continously

          // always @(current_step)
          // begin
          //         if (current_state == ERASE_FOR_ROTATION) begin
          //                 if (current_step == 5'b00000) begin
          //                         //Draw the first block
          //                         current_block_value = current_reference_x;
          //                         simulate_keys <= 4'b0111; 
          //                         //LEDR[6:0] <= current_reference_x;
          //                 end else if (current_step == 5'b00001) begin
          //                         //Release the key
          //                         simulates_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b00010) begin
          //                         //Load y
          //                         simulate_keys <= 4'b0111;
          //                         current_block_value = current_reference_y;
          //                         //LEDR[6:0] <= current_reference_y;
          //                 end else if (current_step == 5'b00011) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b00100) begin
          //                         //Now draw the first block
          //                         simulate_keys <= 4'b1101;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b00101) begin
          //                         //Now release the key to begin drawing the second block
          //                         simulate_keys <= 4'b1111;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b00110) begin
          //                         //Load x value of 2nd block (labelled 1)
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempX = current_reference_x - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempX = current_reference_x;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempX = current_reference_x - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempX = current_reference_x - 3'b100;
          //                         end
          //                         current_block_value = tempX; //Set the wire to the correct value
          //                         simulate_keys <= 4'b0111; 
          //                         //LEDR[6:0] <= current_block_value;
          //                 end 
          //                 else if (current_step == 5'b00111) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01000) begin
          //                         //Load y for the 1st block (labelled 1)
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempY = current_reference_y;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempY = current_reference_y - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempY = current_reference_y;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempY = current_reference_y - 3'b100;
          //                         end
          //                         current_block_value = tempY;
          //                         simulate_keys <= 4'b0111;
          //                         //LEDR[6:0] <= current_block_value;
          //                 end else if (current_step == 5'b01001) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01010) begin
          //                         //Now draw the second block
          //                         simulate_keys <= 4'b1101;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01011) begin
          //                         //Now release the key to begin drawing the third block
          //                         simulate_keys <= 4'b1111;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01100) begin
          //                         //Load x value of 3rd block
          //                         simulate_keys <= 4'b0111;
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempX = current_reference_x + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempX = current_reference_x;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempX = current_reference_x - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempX = current_reference_x;
          //                         end
          //                         current_block_value = tempX;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01101) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01110) begin
          //                         //Load y
          //                         simulate_keys <= 4'b0111;
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempY = current_reference_y;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempY = current_reference_y + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempY = current_reference_y + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempY = current_reference_y - 3'b100;
          //                         end
          //                         current_block_value = tempY;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01111) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10000) begin
          //                         //Now draw the third block
          //                         simulate_keys <= 4'b1101;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10001) begin
          //                         //Now release the key to begin drawing the fourth block
          //                         simulate_keys <= 4'b1111;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10010) begin
          //                         //Load x value of 4th block
          //                         simulate_keys <= 4'b0111; 
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempX = current_reference_x + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempX = current_reference_x + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempX = current_reference_x + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempX = current_reference_x;
          //                         end
          //                         current_block_value = tempX;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10011) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10100) begin
          //                         //Load y
          //                         simulate_keys <= 4'b0111;
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempY = current_reference_y - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempY = current_reference_y + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempY = current_reference_y;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempY = current_reference_y + 3'b100;
          //                         end
          //                         current_block_value = tempY;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10101) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10110) begin
          //                         //Now draw the third block
          //                         simulate_keys <= 4'b1101;
          //                         //LEDR[6:0] <= current_step;
          //                 end
          //         end else if (current_state == NEUTRAL_STATE) begin
          //                 if (current_step == 5'b00000) begin
          //                         //Draw the first block
          //                         current_block_value = current_reference_x;
          //                         simulate_keys <= 4'b0111; 
          //                         //LEDR[6:0] <= current_reference_x;
          //                 end else if (current_step == 5'b00001) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b00010) begin
          //                         //Load y
          //                         simulate_keys <= 4'b0111;
          //                         current_block_value = current_reference_y;
          //                         //LEDR[6:0] <= current_reference_y;
          //                 end else if (current_step == 5'b00011) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b00100) begin
          //                         //Now draw the first block
          //                         simulate_keys <= 4'b1101;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b00101) begin
          //                         //Now release the key to begin drawing the second block
          //                         simulate_keys <= 4'b1111;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b00110) begin
          //                         //Load x value of 2nd block (labelled 1)
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempX = current_reference_x - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempX = current_reference_x;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempX = current_reference_x - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempX = current_reference_x - 3'b100;
          //                         end
          //                         current_block_value = tempX; //Set the wire to the correct value
          //                         simulate_keys <= 4'b0111; 
          //                         //LEDR[6:0] <= current_block_value;
          //                 end 
          //                 else if (current_step == 5'b00111) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01000) begin
          //                         //Load y for the 1st block (labelled 1)
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempY = current_reference_y;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempY = current_reference_y - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempY = current_reference_y;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempY = current_reference_y - 3'b100;
          //                         end
          //                         current_block_value = tempY;
          //                         simulate_keys <= 4'b0111;
          //                         //LEDR[6:0] <= current_block_value;
          //                 end else if (current_step == 5'b01001) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01010) begin
          //                         //Now draw the second block
          //                         simulate_keys <= 4'b1101;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01011) begin
          //                         //Now release the key to begin drawing the third block
          //                         simulate_keys <= 4'b1111;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01100) begin
          //                         //Load x value of 3rd block
          //                         simulate_keys <= 4'b0111;
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempX = current_reference_x + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempX = current_reference_x;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempX = current_reference_x - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempX = current_reference_x;
          //                         end
          //                         current_block_value = tempX;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01101) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01110) begin
          //                         //Load y
          //                         simulate_keys <= 4'b0111;
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempY = current_reference_y;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempY = current_reference_y + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempY = current_reference_y + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempY = current_reference_y - 3'b100;
          //                         end
          //                         current_block_value = tempY;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b01111) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10000) begin
          //                         //Now draw the third block
          //                         simulate_keys <= 4'b1101;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10001) begin
          //                         //Now release the key to begin drawing the fourth block
          //                         simulate_keys <= 4'b1111;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10010) begin
          //                         //Load x value of 4th block
          //                         simulate_keys <= 4'b0111; 
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempX = current_reference_x + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempX = current_reference_x + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempX = current_reference_x + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempX = current_reference_x;
          //                         end
          //                         current_block_value = tempX;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10011) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10100) begin
          //                         //Load y
          //                         simulate_keys <= 4'b0111;
          //                         if (current_rotation_state == ROTATION_0) begin
          //                                 tempY = current_reference_y - 3'b100;
          //                         end else if (current_rotation_state == ROTATION_1) begin
          //                                 tempY = current_reference_y + 3'b100;
          //                         end else if (current_rotation_state == ROTATION_2) begin
          //                                 tempY = current_reference_y;
          //                         end else if (current_rotation_state == ROTATION_3) begin
          //                                 tempY = current_reference_y + 3'b100;
          //                         end
          //                         current_block_value = tempY;
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10101) begin
          //                         //Release the key
          //                         simulate_keys <= 4'b1111; //Load
          //                         //LEDR[6:0] <= current_step;
          //                 end else if (current_step == 5'b10110) begin
          //                         //Now draw the third block
          //                         simulate_keys <= 4'b1101;
          //                         //LEDR[6:0] <= current_step;
          //                 end
          //         end
          // end
          // always @(posedge draw_clock)
          // begin
          //       if (current_step == 5'b00000) begin
          //               //Draw the first block
          //               current_block_value = current_reference_x;
          //               simulate_keys <= 4'b0111; 
          //              current_step <= current_step + 1;
          //               LEDR <= current_reference_x;
          //       end else if (current_step == 5'b00001) begin
          //               //Release the key
          //               simulate_keys <= 4'b1111; //Load
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b00010) begin
          //               //Load y
          //               simulate_keys <= 4'b0111;
          //               current_block_value = current_reference_y;
          //               current_step <= current_step + 1;
          //               LEDR <= current_reference_y;
          //       end else if (current_step == 5'b00011) begin
          //               //Release the key
          //               simulate_keys <= 4'b1111;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b00100) begin
          //               //Now draw the first block
          //               simulate_keys <= 4'b1101;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b00101) begin
          //               //Now release the key to begin drawing the second block
          //               simulate_keys <= 4'b1111;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b00110) begin
          //               //Load x value of 2nd block (labelled 1)
          //               if (current_rotation_state == ROTATION_0) begin
          //                       tempX = current_reference_x - 3'b100;
          //               end else if (current_rotation_state = ROTATION_1) begin
          //                       tempX = current_reference_x;
          //               end else if (current_rotation_state == ROTATION_2) begin
          //                       tempX = current_reference_x - 3'b100;
          //               end else if (current_rotation_state == ROTATION_3) begin
          //                       tempX = current_reference_x - 3'b100;
          //               end
          //               current_block_value = tempX; //Set the wire to the correct value
          //               simulate_keys <= 4'b0111; 
          //               current_step <= current_step + 1;
          //               LEDR <= current_block_value;
          //       end 
          //       else if (current_step == 5'b00111) begin
          //               //Release the key
          //               simulate_keys <= 4'b1111; //Load
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b01000) begin
          //               //Load y for the 1st block (labelled 1)
          //               if (current_rotation_state == ROTATION_0) begin
          //                       tempY = current_reference_y;
          //               end else if (current_rotation_state == ROTATION_1) begin
          //                       tempY = current_reference_y - 3'b100;
          //               end else if (current_rotation_state == ROTATION_2) begin
          //                       tempY = current_reference_y;
          //               end else if (current_rotation_state == ROTATION_3) begin
          //                       tempY = current_reference_y - 3'b100;
          //               end
          //               current_block_value = tempY;
          //               simulate_keys <= 4'b0111;
          //               current_step <= current_step + 1;
          //               LEDR <= current_block_value;
          //       end else if (current_step == 5'b01001) begin
          //               //Release the key
          //               simulate_keys <= 4'b1111; //Load
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b01010) begin
          //               //Now draw the second block
          //               simulate_keys <= 4'b1101;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b01011) begin
          //               //Now release the key to begin drawing the third block
          //               simulate_keys <= 4'b1111;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b01100) begin
          //               //Load x value of 3rd block
          //               simulate_keys <= 4'b0111;
          //               if (current_rotation_state == ROTATION_0) begin
          //                       tempX = current_reference_x + 3'b100;
          //               end else if (current_rotation_state == ROTATION_1) begin
          //                       tempX = current_reference_x;
          //               end else if (current_rotation_state == ROTATION_2) begin
          //                       tempX = current_reference_x - 3'b100;
          //               end else if (current_rotation_state == ROTATION_3) begin
          //                       tempX = current_reference_x;
          //               end
          //               current_block_value = tempX;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b01101) begin
          //               //Release the key
          //               simulate_keys <= 4'b1111; //Load
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b01110) begin
          //               //Load y
          //               simulate_keys <= 4'b0111;
          //               if (current_rotation_state == ROTATION_0) begin
          //                       tempY = current_reference_y;
          //               end else if (current_rotation_state == ROTATION_1) begin
          //                       tempY = current_reference_y + 3'b100;
          //               end else if (current_rotation_state == ROTATION_2) begin
          //                       tempY = current_reference_y + 3'b100;
          //               end else if (current_rotation_state == ROTATION_3) begin
          //                       tempY = current_reference_y - 3'b100;
          //               end
          //               current_block_value = tempY;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b01111) begin
          //               //Release the key
          //               simulate_keys <= 4'b1111; //Load
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b10000) begin
          //               //Now draw the third block
          //               simulate_keys <= 4'b1101;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b10001) begin
          //               //Now release the key to begin drawing the fourth block
          //               simulate_keys <= 4'b1111;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b10010) begin
          //               //Load x value of 4th block
          //               simulate_keys <= 4'b0111; 
          //               if (current_rotation_state == ROTATION_0) begin
          //                       tempX = current_reference_x + 3'b100;
          //               end else if (current_rotation_state == ROTATION_1) begin
          //                       tempX = current_reference_x + 3'b100;
          //               end else if (current_rotation_state == ROTATION_2) begin
          //                       tempX = current_reference_x + 3'b100;
          //               end else if (current_rotation_state == ROTATION_3) begin
          //                       tempX = current_reference_x;
          //               end
          //               current_block_value = tempX;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b10011) begin
          //               //Release the key
          //               simulate_keys <= 4'b1111; //Load
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b10100) begin
          //               //Load y
          //               simulate_keys <= 4'b0111;
          //               if (current_rotation_state == ROTATION_0) begin
          //                       tempY = current_reference_y - 3'b100;
          //               end else if (current_rotation_state == ROTATION_1) begin
          //                       tempY = current_reference_y + 3'b100;
          //               end else if (current_rotation_state == ROTATION_2) begin
          //                       tempY = current_reference_y;
          //               end else if (current_rotation_state == ROTATION_3) begin
          //                       tempY = current_reference_y + 3'b100;
          //               end
          //               current_block_value = tempY;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b10101) begin
          //               //Release the key
          //               simulate_keys <= 4'b1111; //Load
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end else if (current_step == 5'b10110) begin
          //               //Now draw the third block
          //               simulate_keys <= 4'b1101;
          //               current_step <= current_step + 1;
          //               LEDR <= current_step;
          //       end
          // end
         /**
                  
          // Instansiate FSM control
          // control c0(...);
          control c(counterCount, CLOCK_50, simulate_keys, counterEnable, counterReset, resetRegisters, loadX, loadY, writeEn); 
          
          // Increment the counter
          counter4Bit c4b(CLOCK_50, counterReset, counterEnable, counterCount);                                   
          
          // Instansiate datapath
          // datapath d0(...);
          datapath d(CLOCK_50, current_color, current_block_value, counterCount, loadX, loadY, resetRegisters, y, x, colour);
          **/
  endmodule


  module RateDivider(clk, b0, b1, q);
          input clk;
          input b0, b1;
          output reg q;
          reg [26:0] counter0;
          reg [26:0] counter1;
          reg [26:0] counter2;
          reg [26:0] counter3;
                 reg [12:0] counterA;

          always @(posedge clk)
          begin
                  if (b0 == 0 && b1 == 0) begin
                          q <= ~q;
                  end else if (b0 == 0 && b1 == 1) begin
                          if (counterA == 13'b1001110001000) begin
                                  q <= 1;
                                  counterA <= 0;
                          end else begin
                                  q <= 0;
                                  counterA <= counterA + 1'b1;
                          end
                  end else if (b0 == 1 && b1 == 0) begin
                          if (counter0 == 26'b10111110101111000010000000) begin
                                  if (counter1 == 26'b10111110101111000010000000) begin
                                          q <= 1;
                                          counter0 <= 0;
                                          counter1 <= 0;
                                  end else begin
                                          q <= 0;
                                          counter1 <= counter1 + 1'b1;
                                  end
                          end else begin
                                  q <= 0;
                                  counter0 <= counter0 + 1'b1;
                          end
                  end else if (b0 == 1 && b1 == 1) begin
                          if (counter0 == 26'b10111110101111000010000000) begin
                                  if (counter1 == 26'b10111110101111000010000000) begin
                                          if (counter2 == 26'b10111110101111000010000000) begin
                                                  if (counter3 == 26'b10111110101111000010000000) begin
                                                          q <= 1;
                                                          counter0 <= 0;
                                                          counter1 <= 0;
                                                          counter2 <= 0;
                                                          counter3 <= 0;
                                                  end else begin
                                                          q <= 0;
                                                          counter3 <= counter3 + 1'b1;
                                                  end
                                          end else begin
                                                  q <= 0;
                                                  counter2 <= counter2 + 1'b1;
                                          end
                                  end else begin
                                          q <= 0;
                                          counter1 <= counter1 + 1'b1;
                                  end
                          end else begin
                                  q <= 0;
                                  counter0 <= counter0 + 1'b1;
                          end
                  end
          end
  endmodule

  module datapath(clock, color, swIn, counterCount, loadX, loadY, resetRegisters, yOut, xOut, colorOut);
          
          input clock;
          input [2:0] color;
          input [6:0]swIn;
          input[3:0] counterCount;
          input loadX, loadY, resetRegisters;
          
          wire [6:0] plotY;
          wire [7:0] plotX;
          wire [6:0] initialX, initialY;
          
          output reg [6:0] yOut;
          output reg [7:0] xOut;
          output reg [2:0] colorOut;
          
          // Initialize the x and y values
          register xReg(loadX, swIn, initialX, resetRegisters, clock);
          register yReg(loadY, swIn, initialY, resetRegisters, clock);
          
          // Pick x and y based on the counter
          assign plotY= initialY + counterCount[1:0];
          assign plotX= initialX + counterCount[3:2];
          
          always@ (*) begin
                  yOut= plotY+1;
                  xOut=plotX+1;
                  colorOut= color;
          end
  endmodule



  module control(counterCount, clock, key, counterEnable, counterReset, resetRegisters, loadX, loadY, plot);
          input [3:0] counterCount;
          input clock;
          input [3:0]key;
          
          output reg counterEnable, counterReset, resetRegisters, loadX, loadY, plot;
          
          reg [2:0] currentState, nextState;
          
          parameter reset= 3'b000, counterEnabled= 3'b001, counterDisabled= 3'b010, loadRegX= 3'b011, loadRegY= 3'b100; //states
          
          //Controlling datapath signals.
          always@(*) begin
                  case(currentState)
                  
                          //Loadings the registers
                          loadRegX: begin
                                  counterEnable= 0;
                                  counterReset=0;
                                  resetRegisters=0;
                                  loadX=1;
                                  loadY=0;
                                  plot=0;
                          end
                          
                          loadRegY: begin
                                  counterEnable= 0;
                                  counterReset=0;
                                  resetRegisters=0;
                                  loadX=0;
                                  loadY=1;
                                  plot=0;
                          end
                          
                          reset: begin
                                  counterReset=1;
                                  counterEnable=0;
                                  resetRegisters=1;
                                  loadX=0;
                                  loadY=0;
                                  plot=0;
                          end
                          
                          //Plotting and counting.
                          counterEnabled: begin
                                  counterReset=0;
                                  counterEnable=1;
                                  resetRegisters=0;
                                  loadX=0;
                                  loadY=0;
                                  plot=1;
                          end
                          
                          counterDisabled: begin
                                  counterReset=0;
                                  counterEnable=0;
                                  resetRegisters=0;
                                  loadX=0;
                                  loadY=0;
                                  plot=1;
                          end
                          
                          //DEFAULT: nothing in it.
                          default: begin
                                  counterReset=1;
                                  counterEnable=0;
                                  resetRegisters=1;
                                  loadX=0;
                                  loadY=0;
                                  plot=0;
                          end
                  endcase
          end
          
          always@(posedge clock) begin
                  if(key[0]==0) 
                          currentState= reset;
                  else
                          currentState= nextState;
          end
          
          //States table for transitions here.
          always@(*) begin
                  case(currentState)
                          reset: nextState= (key[3]==0)? loadRegX: reset;
                          loadRegX: nextState= loadRegY;
                          //loadRegX: nextState= (key[3] == 0)? loadRegX:loadRegY;
                          loadRegY: nextState= (key[1]==0)? counterEnabled: loadRegY;
                          counterEnabled: nextState= (counterCount==15)? counterDisabled:counterEnabled;
                          counterDisabled: nextState= reset;
                          default: nextState= reset;
                  endcase
          end
  endmodule

  module counter4Bit(clock, reset, enable, count);
          input clock;
          input reset, enable;
          
          output reg [3:0] count;
          
          initial count=0;
          
          always@ (posedge clock) begin
                  if(reset==1)
                          count<=0;
                  else if(enable)
                          count<= count+1;
          end
  endmodule

  module register(load, in, out, reset, clock);
          input load, clock, reset;
          input [6:0] in;
          output reg[6:0] out;
          
          always@(posedge clock) begin
                  if(reset==1)
                          out<=0;
                  else if(load==1) begin
                          out<=in;
                  end
          end
  endmodule





 /**
 // Part 2 skeleton
 // `timescale time_unit/time_precision
 module lblock
         (
                 CLOCK_50,                                               //      On Board 50 MHz
                 // Your inputs and outputs here
         KEY,
         SW,
                   LEDR,
                 // The ports below are for the VGA output.  Do not change.
                 VGA_CLK,                                                 //      VGA Clock
                 VGA_HS,                                                 //      VGA H_SYNC
                 VGA_VS,                                                 //      VGA V_SYNC
                 VGA_BLANK_N,                                    //      VGA BLANK               
                 VGA_SYNC_N,                                             //      VGA SYNC                        
                 VGA_R,                                                   //      VGA Red[9:0]
                 VGA_G,                                            //      VGA Green[9:0]
                 VGA_B                                            //      VGA Blue[9:0]
         );

         input                   CLOCK_50;                               //      50 MHz
         input   [9:0]   SW;
         input   [3:0]   KEY;
         output reg [9:0] LEDR;
         // Declare your inputs and outputs here
         // Do not change the following outputs
         output                  VGA_CLK;                                 //      VGA Clock
         output                  VGA_HS;                                 //      VGA H_SYNC
         output                  VGA_VS;                                 //      VGA V_SYNC
         output                  VGA_BLANK_N;                    //      VGA BLANK
         output                  VGA_SYNC_N;                             //      VGA SYNC
         output  [9:0]   VGA_R;                                   //      VGA Red[9:0]
         output  [9:0]   VGA_G;                            //      VGA Green[9:0]
         output  [9:0]   VGA_B;                                   //      VGA Blue[9:0]
         
         wire resetn;
         assign resetn = KEY[0];
         
         // Create the colour, x, y and writeEn wires that are inputs to the controller.
         wire [2:0] colour;
         wire [7:0] x;
         wire [6:0] y;
         wire writeEn;
         
         // Create an Instance of a VGA controller - there can be only one!
         // Define the number of colours as well as the initial background
         // image file (.MIF) for the controller.
         
         vga_adapter VGA(
                         .resetn(resetn),
                         .clock(CLOCK_50),
                         .colour(colour),
                         .x(x),
                         .y(y),
                         .plot(writeEn),
                         .VGA_R(VGA_R),
                         .VGA_G(VGA_G),
                         .VGA_B(VGA_B),
                         .VGA_HS(VGA_HS),
                         .VGA_VS(VGA_VS),
                         .VGA_BLANK(VGA_BLANK_N),        
                         .VGA_SYNC(VGA_SYNC_N),                  
                         .VGA_CLK(VGA_CLK));
                 defparam VGA.RESOLUTION = "160x120";
                 defparam VGA.MONOCHROME = "FALSE";
                 defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
                 defparam VGA.BACKGROUND_IMAGE = "black.mif";
         // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
         // for the VGA controller, in addition to any other functionality your design may require.
     
         wire counterReset;
         wire counterEnable;
         wire resetRegisters;
         wire [3:0] counterCount;
         
         wire loadX;
         wire loadY;
         
         
         
         reg [3:0] simulate_keys = 4'b1111;
         reg [4:0] current_step = 5'b00000;
         
         reg current_rotation_state = ROTATION_2;
         reg [6:0] current_block_value;
         reg [6:0] current_reference_x = 7'b0111111;  //Initial x
         reg [6:0] current_reference_y = 7'b1000111; //Initial y

         parameter ROTATION_0 = 2'b00, ROTATION_1 = 2'b01, ROTATION_2 = 2'b10, ROTATION_3 = 2'b11;
         
         reg [6:0] tempX; 
         reg [6:0] tempY; //Holding values

         wire draw_clock;
         RateDivider r(
                 .clk(CLOCK_50),
                 .b0(1'b0),
                 .b1(1'b1),
                 .q(draw_clock)
         );
         
         //Draw an l block continously
         
         always @(posedge draw_clock)
         begin
                 if (current_step == 5'b00000) begin
                         //Draw the first block
                         current_block_value = current_reference_x;
                         simulate_keys <= 4'b0111; 
                         current_step <= current_step + 1;
                         LEDR <= current_reference_x;
                 end else if (current_step == 5'b00001) begin
                         //Release the key
                         simulate_keys <= 4'b1111; //Load
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b00010) begin
                         //Load y
                         simulate_keys <= 4'b0111;
                         current_block_value = current_reference_y;
                         current_step <= current_step + 1;
                         LEDR <= current_reference_y;
                 end else if (current_step == 5'b00011) begin
                         //Release the key
                         simulate_keys <= 4'b1111;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b00100) begin
                         //Now draw the first block
                         simulate_keys <= 4'b1101;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b00101) begin
                         //Now release the key to begin drawing the second block
                         simulate_keys <= 4'b1111;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b00110) begin
                         //Load x value of 2nd block (labelled 1)
                         if (current_block_type == L_BLOCK) begin
                         if (current_rotation_state == ROTATION_0) begin
                                 tempX = current_reference_x - 3'b100;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempX = current_reference_x;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempX = current_reference_x - 3'b100;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempX = current_reference_x - 3'b100;
                         end end
                         if (current_block_type == O_BLOCK) begin
                         if (current_rotation_state == ROTATION_0) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempX = current_reference_x + 3'b100;
                         end end
                         if (current_block_type == I_BLOCK) begin
                         if (current_rotation_state == ROTATION_0) begin
                                 tempX = current_reference_x - 3'b100;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempX = current_reference_x;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempX = current_reference_x - 3'b100;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempX = current_reference_x + 3'b100;
                         end end
                         current_block_value = tempX; //Set the wire to the correct value
                         simulate_keys <= 4'b0111; 
                         current_step <= current_step + 1;
                         LEDR <= current_block_value;
                 end 
                 else if (current_step == 5'b00111) begin
                         //Release the key
                         simulate_keys <= 4'b1111; //Load
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b01000) begin
                         //Load y for the 1st block (labelled 1)
                         if (current_block_type == L_BLOCK) begin
                         if (current_rotation_state == ROTATION_0) begin
                                 tempY = current_reference_y;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempY = current_reference_y - 3'b100;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempY = current_reference_y;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempY = current_reference_y - 3'b100;
                         end end
                         if (current_block_type == O_BLOCK) begin
                         if (current_rotation_state == ROTATION_0) begin
                                 tempY = current_reference_y;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempY = current_reference_y;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempY = current_reference_y;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempY = current_reference_y;
                         end end
                         if (current_block_type == I_BLOCK) begin
                         if (current_rotation_state == ROTATION_0) begin
                                 tempY = current_reference_y;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempY = current_reference_y + 3'b100;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempY = current_reference_y + 3'b100;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempY = current_reference_y - 3'b100;
                         end end
                         current_block_value = tempY;
                         simulate_keys <= 4'b0111;
                         current_step <= current_step + 1;
                         LEDR <= current_block_value;
                 end else if (current_step == 5'b01001) begin
                         //Release the key
                         simulate_keys <= 4'b1111; //Load
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b01010) begin
                         //Now draw the second block
                         simulate_keys <= 4'b1101;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b01011) begin
                         //Now release the key to begin drawing the third block
                         simulate_keys <= 4'b1111;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b01100) begin
                         //Load x value of 3rd block
                         simulate_keys <= 4'b0111;
                         if (current_block_type == L_BLOCK) begin
                         if (current_rotation_state == ROTATION_0) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempX = current_reference_x;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempX = current_reference_x - 3'b100;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempX = current_reference_x;
                         end end
                         if (current_block_type == O_BLOCK) begin
                         if (current_rotation_state == ROTATION_0) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempX = current_reference_x + 3'b100;
                         end end
                         if (current_block_type == I_BLOCK) begin
                         if (current_rotation_state == ROTATION_0) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempX = current_reference_x;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempX = current_reference_x + 3'b100;
                         end end
                         current_block_value = tempX;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b01101) begin
                         //Release the key
                         simulate_keys <= 4'b1111; //Load
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b01110) begin
                         //Load y
                         simulate_keys <= 4'b0111;
                         if (current_rotation_state == ROTATION_0) begin
                                 tempY = current_reference_y;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempY = current_reference_y + 3'b100;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempY = current_reference_y + 3'b100;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempY = current_reference_y - 3'b100;
                         end
                         current_block_value = tempY;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b01111) begin
                         //Release the key
                         simulate_keys <= 4'b1111; //Load
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b10000) begin
                         //Now draw the third block
                         simulate_keys <= 4'b1101;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b10001) begin
                         //Now release the key to begin drawing the fourth block
                         simulate_keys <= 4'b1111;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b10010) begin
                         //Load x value of 4th block
                         simulate_keys <= 4'b0111; 
                         if (current_rotation_state == ROTATION_0) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempX = current_reference_x + 3'b100;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempX = current_reference_x;
                         end
                         current_block_value = tempX;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b10011) begin
                         //Release the key
                         simulate_keys <= 4'b1111; //Load
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b10100) begin
                         //Load y
                         simulate_keys <= 4'b0111;
                         if (current_rotation_state == ROTATION_0) begin
                                 tempY = current_reference_y - 3'b100;
                         end else if (current_rotation_state == ROTATION_1) begin
                                 tempY = current_reference_y + 3'b100;
                         end else if (current_rotation_state == ROTATION_2) begin
                                 tempY = current_reference_y;
                         end else if (current_rotation_state == ROTATION_3) begin
                                 tempY = current_reference_y + 3'b100;
                         end
                         current_block_value = tempY;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b10101) begin
                         //Release the key
                         simulate_keys <= 4'b1111; //Load
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end else if (current_step == 5'b10110) begin
                         //Now draw the third block
                         simulate_keys <= 4'b1101;
                         current_step <= current_step + 1;
                         LEDR <= current_step;
                 end
         end
                 
         // Instansiate FSM control
         // control c0(...);
         control c(counterCount, CLOCK_50, simulate_keys, counterEnable, counterReset, resetRegisters, loadX, loadY, writeEn); 
         
         // Increment the counter
         counter4Bit c4b(CLOCK_50, counterReset, counterEnable, counterCount);                                   
         
         // Instansiate datapath
         // datapath d0(...);
         datapath d(CLOCK_50, SW[9:7], current_block_value, counterCount, loadX, loadY, resetRegisters, y, x, colour);
 endmodule


 module RateDivider(clk, b0, b1, q);
         input clk;
         input b0, b1;
         output reg q;
         reg [26:0] counter0;
         reg [26:0] counter1;
         reg [26:0] counter2;
         reg [26:0] counter3;

         always @(posedge clk)
         begin
                 if (b0 == 0 && b1 == 0) begin
                         q <= ~q;
                 end else if (b0 == 0 && b1 == 1) begin
                         if (counter0 == 26'b10111110101111000010000000) begin
                                 q <= 1;
                                 counter0 <= 0;
                         end else begin
                                 q <= 0;
                                 counter0 <= counter0 + 1'b1;
                         end
                 end else if (b0 == 1 && b1 == 0) begin
                         if (counter0 == 26'b10111110101111000010000000) begin
                                 if (counter1 == 26'b10111110101111000010000000) begin
                                         q <= 1;
                                         counter0 <= 0;
                                         counter1 <= 0;
                                 end else begin
                                         q <= 0;
                                         counter1 <= counter1 + 1'b1;
                                 end
                         end else begin
                                 q <= 0;
                                 counter0 <= counter0 + 1'b1;
                         end
                 end else if (b0 == 1 && b1 == 1) begin
                         if (counter0 == 26'b10111110101111000010000000) begin
                                 if (counter1 == 26'b10111110101111000010000000) begin
                                         if (counter2 == 26'b10111110101111000010000000) begin
                                                 if (counter3 == 26'b10111110101111000010000000) begin
                                                         q <= 1;
                                                         counter0 <= 0;
                                                         counter1 <= 0;
                                                         counter2 <= 0;
                                                         counter3 <= 0;
                                                 end else begin
                                                         q <= 0;
                                                         counter3 <= counter3 + 1'b1;
                                                 end
                                         end else begin
                                                 q <= 0;
                                                 counter2 <= counter2 + 1'b1;
                                         end
                                 end else begin
                                         q <= 0;
                                         counter1 <= counter1 + 1'b1;
                                 end
                         end else begin
                                 q <= 0;
                                 counter0 <= counter0 + 1'b1;
                         end
                 end
         end
 endmodule

 module datapath(clock, color, swIn, counterCount, loadX, loadY, resetRegisters, yOut, xOut, colorOut);
         
         input clock;
         input [2:0] color;
         input [6:0]swIn;
         input[3:0] counterCount;
         input loadX, loadY, resetRegisters;
         
         wire [6:0] plotY;
         wire [7:0] plotX;
         wire [6:0] initialX, initialY;
         
         output reg [6:0] yOut;
         output reg [7:0] xOut;
         output reg [2:0] colorOut;
         
         // Initialize the x and y values
         register xReg(loadX, swIn, initialX, resetRegisters, clock);
         register yReg(loadY, swIn, initialY, resetRegisters, clock);
         
         // Pick x and y based on the counter
         assign plotY= initialY + counterCount[1:0];
         assign plotX= initialX + counterCount[3:2];
         
         always@ (*) begin
                 yOut= plotY+1;
                 xOut=plotX+1;
                 colorOut= color;
         end
 endmodule



 module control(counterCount, clock, key, counterEnable, counterReset, resetRegisters, loadX, loadY, plot);
         input [3:0] counterCount;
         input clock;
         input [3:0]key;
         
         output reg counterEnable, counterReset, resetRegisters, loadX, loadY, plot;
         
         reg [2:0] currentState, nextState;
         
         parameter reset= 3'b000, counterEnabled= 3'b001, counterDisabled= 3'b010, loadRegX= 3'b011, loadRegY= 3'b100; //states
         
         //Controlling datapath signals.
         always@(*) begin
                 case(currentState)
                 
                         //Loadings the registers
                         loadRegX: begin
                                 counterEnable= 0;
                                 counterReset=0;
                                 resetRegisters=0;
                                 loadX=1;
                                 loadY=0;
                                 plot=0;
                         end
                         
                         loadRegY: begin
                                 counterEnable= 0;
                                 counterReset=0;
                                 resetRegisters=0;
                                 loadX=0;
                                 loadY=1;
                                 plot=0;
                         end
                         
                         reset: begin
                                 counterReset=1;
                                 counterEnable=0;
                                 resetRegisters=1;
                                 loadX=0;
                                 loadY=0;
                                 plot=0;
                         end
                         
                         //Plotting and counting.
                         counterEnabled: begin
                                 counterReset=0;
                                 counterEnable=1;
                                 resetRegisters=0;
                                 loadX=0;
                                 loadY=0;
                                 plot=1;
                         end
                         
                         counterDisabled: begin
                                 counterReset=0;
                                 counterEnable=0;
                                 resetRegisters=0;
                                 loadX=0;
                                 loadY=0;
                                 plot=1;
                         end
                         
                         //DEFAULT: nothing in it.
                         default: begin
                                 counterReset=1;
                                 counterEnable=0;
                                 resetRegisters=1;
                                 loadX=0;
                                 loadY=0;
                                 plot=0;
                         end
                 endcase
         end
         
         always@(posedge clock) begin
                 if(key[0]==0) 
                         currentState= reset;
                 else
                         currentState= nextState;
         end
         
         //States table for transitions here.
         always@(*) begin
                 case(currentState)
                         reset: nextState= (key[3]==0)? loadRegX: reset;
                         loadRegX: nextState= loadRegY;
                         //loadRegX: nextState= (key[3] == 0)? loadRegX:loadRegY;
                         loadRegY: nextState= (key[1]==0)? counterEnabled: loadRegY;
                         counterEnabled: nextState= (counterCount==15)? counterDisabled:counterEnabled;
                         counterDisabled: nextState= reset;
                         default: nextState= reset;
                 endcase
         end
 endmodule

 module counter4Bit(clock, reset, enable, count);
         input clock;
         input reset, enable;
         
         output reg [3:0] count;
         
         initial count=0;
         
         always@ (posedge clock) begin
                 if(reset==1)
                         count<=0;
                 else if(enable)
                         count<= count+1;
         end
 endmodule

 module register(load, in, out, reset, clock);
         input load, clock, reset;
         input [6:0] in;
         output reg[6:0] out;
         
         always@(posedge clock) begin
                 if(reset==1)
                         out<=0;
                 else if(load==1) begin
                         out<=in;
                 end
         end
 endmodule
 **/

