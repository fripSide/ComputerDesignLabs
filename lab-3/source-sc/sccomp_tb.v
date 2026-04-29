`timescale 1ns/1ns 
module sccomp_tb();
   reg    clk, rstn;
   reg  [4:0] reg_sel;
   wire [31:0] reg_data;
   integer errors;

   // instantiation of sccomp
   sccomp sccomp(.clk(clk), .rstn(rstn), .reg_sel(reg_sel), .reg_data(reg_data));

   initial begin
     // input instructions for simulation, rv32_sc_sim
      $readmemh("rv32_sc_sim.dat", sccomp.U_imem.RAM);

      clk = 1;
      rstn = 1;
      errors = 0;
      #10 ;
      rstn = 0;
      reg_sel = 8;
   end
   
   always begin
      #(5) clk = ~clk;
   end

   initial begin
      $dumpfile("sccpu_sim.vcd");
      $dumpvars(0, sccomp_tb);

      #220;
      if (sccomp.U_SCCPU.U_RF.rf[1] !== 32'h0000_003c) begin
         $display("[FAIL] x1 expected 0x0000003c, got %h", sccomp.U_SCCPU.U_RF.rf[1]);
         errors = errors + 1;
      end
      if (sccomp.U_SCCPU.U_RF.rf[2] !== 32'h0000_000c) begin
         $display("[FAIL] x2 expected 0x0000000c, got %h", sccomp.U_SCCPU.U_RF.rf[2]);
         errors = errors + 1;
      end
      if (sccomp.U_SCCPU.U_RF.rf[5] !== 32'h0000_0000) begin
         $display("[FAIL] x5 expected branch skip to keep 0, got %h", sccomp.U_SCCPU.U_RF.rf[5]);
         errors = errors + 1;
      end
      if (sccomp.U_SCCPU.U_RF.rf[6] !== 32'h0000_0002) begin
         $display("[FAIL] x6 expected 0x00000002, got %h", sccomp.U_SCCPU.U_RF.rf[6]);
         errors = errors + 1;
      end
      if (sccomp.U_SCCPU.U_RF.rf[7] !== 32'h0000_0003) begin
         $display("[FAIL] x7 expected 0x00000003, got %h", sccomp.U_SCCPU.U_RF.rf[7]);
         errors = errors + 1;
      end
      if (sccomp.U_SCCPU.U_RF.rf[8] !== 32'h0000_0009) begin
         $display("[FAIL] x8 expected 0x00000009, got %h", sccomp.U_SCCPU.U_RF.rf[8]);
         errors = errors + 1;
      end

      if (errors == 0)
         $display("[PASS] lab-3 source-sc checks passed.");
      else
         $display("[FAIL] lab-3 source-sc checks failed with %0d error(s).", errors);

      #20;
      $finish;
   end 
   
endmodule
