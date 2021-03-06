`include "VX_define.vh"

module VX_smem_arb (
    input wire              clk,
    input wire              reset,

    // input request
    VX_dcache_core_req_if   core_req_if,

    // output requests
    VX_dcache_core_req_if   cache_req_if,
    VX_dcache_core_req_if   smem_req_if,

    // input responses
    VX_dcache_core_rsp_if   cache_rsp_if,
    VX_dcache_core_rsp_if   smem_rsp_if,

    // output response
    VX_dcache_core_rsp_if   core_rsp_if
);
    localparam REQ_DATAW = `DCORE_ADDR_WIDTH + 1 + `DWORD_SIZE + (`DWORD_SIZE*8) + (`DCORE_TAG_WIDTH-1);
    localparam RSP_DATAW = `NUM_THREADS + `NUM_THREADS * (`DWORD_SIZE*8) + `DCORE_TAG_WIDTH;

    //
    // handle requests
    //

    for (genvar i = 0; i < `NUM_THREADS; ++i) begin

        wire [1:0][REQ_DATAW-1:0] req_data_out;
        
        VX_stream_demux #(
            .NUM_REQS (2),
            .DATAW    (REQ_DATAW),
            .BUFFERED (1)
        ) req_demux (
            .clk       (clk),
            .reset     (reset),
            .sel       (core_req_if.tag[i][0]),
            .valid_in  (core_req_if.valid[i]),
            .data_in   ({core_req_if.addr[i], core_req_if.rw[i], core_req_if.byteen[i], core_req_if.data[i], core_req_if.tag[i][`DCORE_TAG_WIDTH-1:1]}),
            .ready_in  (core_req_if.ready[i]),
            .valid_out ({smem_req_if.valid[i], cache_req_if.valid[i]}),
            .data_out  (req_data_out),
            .ready_out ({smem_req_if.ready[i], cache_req_if.ready[i]})
        );        

        assign {cache_req_if.addr[i], cache_req_if.rw[i], cache_req_if.byteen[i], cache_req_if.data[i], cache_req_if.tag[i]} = req_data_out[0];
        assign {smem_req_if.addr[i], smem_req_if.rw[i], smem_req_if.byteen[i], smem_req_if.data[i], smem_req_if.tag[i]} = req_data_out[1];
    end

    //
    // handle responses
    //

    wire [1:0] rsp_valid_in;
    wire [1:0][RSP_DATAW-1:0] rsp_data_in;        
    wire [`NUM_THREADS-1:0] core_rsp_tmask;
    wire core_rsp_valid;

    assign rsp_valid_in[0] = (| cache_rsp_if.valid);
    assign rsp_valid_in[1] = (| smem_rsp_if.valid);

    assign rsp_data_in[0] = {cache_rsp_if.valid, cache_rsp_if.data, {cache_rsp_if.tag, 1'b0}};
    assign rsp_data_in[1] = {smem_rsp_if.valid,  smem_rsp_if.data,  {smem_rsp_if.tag, 1'b1}};

    VX_stream_arbiter #(
        .NUM_REQS (2),
        .DATAW    (RSP_DATAW),
        .BUFFERED (1)
    ) rsp_arb (
        .clk        (clk),
        .reset      (reset),
        .valid_in   (rsp_valid_in),
        .data_in    (rsp_data_in),
        .ready_in   ({smem_rsp_if.ready, cache_rsp_if.ready}),
        .valid_out  (core_rsp_valid),
        .data_out   ({core_rsp_tmask, core_rsp_if.data, core_rsp_if.tag}),
        .ready_out  (core_rsp_if.ready)
    );

    assign core_rsp_if.valid = {`NUM_THREADS{core_rsp_valid}} & core_rsp_tmask;

endmodule