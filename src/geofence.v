

/*

for i in range(1,len-1):
  for j in range(i+1,len):
    ax = x[i]-x[0]
    ay = y[i]-y[0]

    bx = x[j]-x[0]
    by = y[j]-y[0]

    if(ax*by - ay*bx > 0):
      swap(x[i],x[j])
*/

module geofence ( clk,reset,X,Y,R,valid,is_inside);
  input clk;
  input reset;
  input [9:0] X;
  input [9:0] Y;
  input [10:0] R;
  output valid;
  output is_inside;
  reg is_inside;


  reg [19:0] sqrt_a;
  wire [9:0] sqrt_root;


  //sqrt
  DW_sqrt #(
    .width(20),
    .tc_mode(1'b0)
	)
	sqrt_u1(
    .a(sqrt_a),
    .root(sqrt_root)
  );



  reg [9:0]   DATA_X [5:0];
  reg [9:0]   DATA_Y [5:0];
  reg [10:0]  DATA_R [5:0];

  reg signed [31:0] CALCULATE_REG1;
  reg signed [26:0] CALCULATE_REG2;
  reg [31:0] AREA_1,AREA_2;
  reg [11:0] a;
  reg [11:0] S;




  //multiplier
  reg signed [11:0]  ma,mb;
  wire signed [23:0] mo;
  assign mo = ma * mb;





  // State machine
  parameter DATA_READ         =   0 ;
  parameter SORT              =   1 ;
  parameter CALCULATE_AREA_1  =   2 ;
  parameter CALCULATE_AREA_2  =   3 ;
  parameter DATA_OUT          =   4 ;

  reg [2:0] state;
  reg [3:0] state_counter1;
  reg [3:0] state_counter2;
  reg [3:0] state_counter3;



  assign valid = state == DATA_OUT ? 1:0 ;
  integer i;
  always@(posedge clk or posedge reset)begin
    if(reset)begin

      state <= DATA_READ;
      state_counter1 <= 0;
      state_counter2 <= 0;
      state_counter3 <= 0;

      is_inside <= 0;
      
    end 
    else begin
      case(state)


        DATA_READ:begin

          DATA_X[state_counter1] <= X;
          DATA_Y[state_counter1] <= Y;
          DATA_R[state_counter1] <= R;
          
          if(state_counter1 == 5)begin
            state <= SORT;
            state_counter1 <= 1;
            state_counter2 <= 2;
            //#10
            //for(i=0;i<6;i=i+1)begin
            //  $display("%d:X:%d Y%d R:%d",i,DATA_X[i],DATA_Y[i],DATA_R[i]);
            //end
            //$display("");
          end
          else begin
            state_counter1 <= state_counter1 + 1;
          end
          

        end



        SORT:begin
          case(state_counter3)
            0:begin //Calculate state_counter1 and state_counter2 *
              //AX * BY
              ma <=  $signed(DATA_X[state_counter1] - $signed({1'b0,DATA_X[0]})); // AX
              mb <=  $signed(DATA_Y[state_counter2] - $signed({1'b0,DATA_Y[0]})); // BY
              state_counter3 <= state_counter3+1;
            end
            1:begin
              //BX * AY
              ma <=  $signed(DATA_X[state_counter2] - $signed({1'b0,DATA_X[0]})); // AX
              mb <=  $signed(DATA_Y[state_counter1] - $signed({1'b0,DATA_Y[0]})); // BY
              CALCULATE_REG1 <= mo;
              state_counter3 <= state_counter3+1;
            end
            2:begin
              CALCULATE_REG1 <= CALCULATE_REG1 - mo;
            
              state_counter3 <= state_counter3+1;
            end
            3:begin
              if(CALCULATE_REG1 > 0)begin
                //swap state_counter1 and state_counter2
                DATA_X[state_counter1] <= DATA_X[state_counter2];
                DATA_Y[state_counter1] <= DATA_Y[state_counter2];
                DATA_R[state_counter1] <= DATA_R[state_counter2];
                DATA_X[state_counter2] <= DATA_X[state_counter1];
                DATA_Y[state_counter2] <= DATA_Y[state_counter1];
                DATA_R[state_counter2] <= DATA_R[state_counter1];
              end
              state_counter3 <= state_counter3+1;
            end
            4:begin
              if(state_counter1 == 4 && state_counter2==5)begin
                state <= CALCULATE_AREA_1;
                AREA_1 <= 0;
                AREA_2 <= 0;
                state_counter1 <= 0;
                state_counter2 <= 0;
                //#1
                //for(i=0;i<6;i=i+1)begin
                //  $display("%d:X:%d Y%d R:%d",i,DATA_X[i],DATA_Y[i],DATA_R[i]);
                //end
                //$display("");
              end
              else if(state_counter2 == 5)begin
                state_counter1 <= state_counter1 + 1;
                state_counter2 <= state_counter1 + 1 ;
              end
              else begin
                state_counter2 <= state_counter2 + 1;
              end
              state_counter3 <= 0;
              
            end
          endcase
        end








        CALCULATE_AREA_1:begin
          case(state_counter3)
            0:begin
              ma <= (DATA_X[(state_counter1+1)%6] > DATA_X[state_counter1]) ? DATA_X[(state_counter1+1)%6] - DATA_X[state_counter1] : DATA_X[state_counter1] - DATA_X[(state_counter1+1)%6];
              mb <= (DATA_X[(state_counter1+1)%6] > DATA_X[state_counter1]) ? DATA_X[(state_counter1+1)%6] - DATA_X[state_counter1] : DATA_X[state_counter1] - DATA_X[(state_counter1+1)%6];
              state_counter3 <= state_counter3+1;
            end
            1:begin
              CALCULATE_REG1 <= mo;
              ma <= (DATA_Y[(state_counter1+1)%6] > DATA_Y[state_counter1]) ? DATA_Y[(state_counter1+1)%6] - DATA_Y[state_counter1] : DATA_Y[state_counter1] - DATA_Y[(state_counter1+1)%6];
              mb <= (DATA_Y[(state_counter1+1)%6] > DATA_Y[state_counter1]) ? DATA_Y[(state_counter1+1)%6] - DATA_Y[state_counter1] : DATA_Y[state_counter1] - DATA_Y[(state_counter1+1)%6];
              state_counter3 <= state_counter3+1;
            end
            2:begin
              sqrt_a <= (CALCULATE_REG1 + mo);
              state_counter3 <= state_counter3+1;
            end
            3:begin
              a <= sqrt_root;
              S <= (sqrt_root + DATA_R[state_counter1] + DATA_R[(state_counter1+1)%6])>>1;
              //#1 $display("line:%d S:%d",sqrt_root,S);
              //$display("R0:%d R1:%d",DATA_R[state_counter1],DATA_R[(state_counter1+1)%6]);
              state_counter3 <= state_counter3+1;
            end
            4:begin
              ma <= S;
              mb <= S-a;
              //mb <= S>a? (S-a) : (a-S);
              //#1 $display("s(s-a):%d %d %d",mo,ma,mb);
              state_counter3 <= state_counter3+1;
            end
            5:begin
              sqrt_a <= mo ; 
              //#1 $display("sqrt:s(s-a):%d",sqrt_root);
              ma <= S-DATA_R[state_counter1];
              mb <= S-DATA_R[(state_counter1+1)%6]; 
              //ma <= S>DATA_R[state_counter1] ? S-DATA_R[state_counter1] : DATA_R[state_counter1]-S;
              //mb <= S>DATA_R[(state_counter1+1)%6] ? S-DATA_R[(state_counter1+1)%6] : DATA_R[(state_counter1+1)%6]-S;
              //#1 $display("(s-r0)*(s-r1):%d %d %d",mo ,ma,mb);
              state_counter3 <= state_counter3+1;
            end
            6:begin
              CALCULATE_REG1 <= sqrt_root ;
              sqrt_a <= mo ;
              //#1 $display("sqrt(s-r0)*(s-r1):%d ",sqrt_root);
              state_counter3 <= state_counter3+1;
            end
            7:begin
              ma <= sqrt_root  ;
              mb <= CALCULATE_REG1;
              state_counter3 <= state_counter3+1;
            end
            8:begin
              AREA_1 <= AREA_1 + mo  ;
              #1 $display("%d\n\n",mo);
              if(state_counter1==5)begin
                state_counter1 <= 0;
                state_counter3 <= state_counter3+1;
              end
              else begin 
                state_counter1 <= state_counter1 + 1;
                state_counter3 <= 0;
              end
            end
            9:begin
              state <= CALCULATE_AREA_2;
              state_counter1 <= 0;
              state_counter2 <= 0;
              state_counter3 <= 0;

              //sum
              $display("AREA_1:%d",AREA_1);
              
            end
          endcase
        end











        CALCULATE_AREA_2:begin
          case(state_counter3)
            0:begin
              ma <= DATA_X[(state_counter1+1)%6];
              mb <= DATA_Y[state_counter1];
              state_counter3 <= state_counter3 + 1;
            end
            1:begin
              AREA_2 <= AREA_2 + mo;
              ma <= DATA_X[state_counter1];
              mb <= DATA_Y[(state_counter1+1)%6];
              state_counter3 <= state_counter3 + 1;
            end
            2:begin
              AREA_2 <= AREA_2 - mo;
              state_counter3 <= state_counter3 + 1;
            end
            3:begin
              if(state_counter1==5)begin
                AREA_2 <= AREA_2 >> 1;
                #1 $display("AREA_2:%d",AREA_2);
                state_counter3 <= state_counter3 + 1;
              end
              else begin
                state_counter1 <= state_counter1 + 1;
                state_counter3 <= 0;
              end
            end
            4:begin
              if(AREA_1 <= AREA_2)begin
                is_inside <= 1;
              end
              else begin
                is_inside <= 0;
              end
              state <= DATA_OUT;
              state_counter1 <= 0;
              state_counter2 <= 0;
              state_counter3 <= 0;
            end
          endcase
        end



        DATA_OUT:begin
          //$finish();
          state <= DATA_READ;
        end



        default:begin
          state <= DATA_READ;
          state_counter1 <= 0;
        end



      endcase
    end

  end









endmodule

