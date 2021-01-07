`include "VX_platform.vh"

module VX_priority_encoder #( 
    parameter DATAW  = 1,
    parameter LDATAW = `LOG2UP(DATAW)
) (
    input  wire [DATAW-1:0]  data_in,
    output wire [LDATAW-1:0] data_out,
    output wire              valid_out
);    
    reg [LDATAW-1:0] data_out_r;

    always @(*) begin
        data_out_r = 'x;
        for (integer i = 0; i < DATAW; i++) begin
            if (data_in[i]) begin
                data_out_r = LDATAW'(i);
                break;
            end
        end
    end

    assign data_out  = data_out_r;
    assign valid_out = (| data_in);
    
endmodule