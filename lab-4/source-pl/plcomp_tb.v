`timescale 1ns/1ns 
module plcomp_tb();
  reg   clk, rstn;
  integer i=0;  //for debug
  integer errors;

  // instantiation of plcomp
  plcomp plcomp(clk, rstn);
  
  initial begin
    // input instructions for simulation
    $readmemh("rv32_pl_sim.dat", plcomp.U_imem.RAM);
    clk = 0;
    rstn = 1;
    errors = 0;
    #50 ;
    rstn = 0;
  end
  
  always begin
    #(5) clk = ~clk;
  end

  always @(posedge clk) begin   //for debug
       i=i+1;
       if (clk) $write("\n cycle=%d, IF_PC=%h, IF_ins=%h, ", i, plcomp.PC, plcomp.instr );
       if (plcomp.U_PLCPU.U_RF.RFWr && plcomp.U_PLCPU.U_RF.A3) $write("x%d = %h  ", plcomp.U_PLCPU.U_RF.A3, plcomp.U_PLCPU.U_RF.WD) ;
  end

  initial begin
      $dumpfile("plcpu_sim.vcd");
      $dumpvars(0, plcomp_tb);

      #260;
      if (plcomp.U_PLCPU.U_RF.rf[1] !== 32'h0000_0005) begin
          $display("[FAIL] x1 expected 0x00000005, got %h", plcomp.U_PLCPU.U_RF.rf[1]);
          errors = errors + 1;
      end
      if (plcomp.U_PLCPU.U_RF.rf[2] !== 32'h0000_0001) begin
          $display("[FAIL] x2 expected 0x00000001 from andi, got %h", plcomp.U_PLCPU.U_RF.rf[2]);
          errors = errors + 1;
      end
      if (plcomp.U_PLCPU.U_RF.rf[3] !== 32'h0000_0018) begin
          $display("[FAIL] x3 expected 0x00000018 from jal link, got %h", plcomp.U_PLCPU.U_RF.rf[3]);
          errors = errors + 1;
      end
      if (plcomp.U_PLCPU.U_RF.rf[4] !== 32'h0000_0000) begin
          $display("[FAIL] x4 expected flushed instruction to keep 0, got %h", plcomp.U_PLCPU.U_RF.rf[4]);
          errors = errors + 1;
      end
      if (plcomp.U_PLCPU.U_RF.rf[5] !== 32'h0000_0000) begin
          $display("[FAIL] x5 expected flushed instruction to keep 0, got %h", plcomp.U_PLCPU.U_RF.rf[5]);
          errors = errors + 1;
      end
      if (plcomp.U_PLCPU.U_RF.rf[6] !== 32'h0000_0009) begin
          $display("[FAIL] x6 expected 0x00000009, got %h", plcomp.U_PLCPU.U_RF.rf[6]);
          errors = errors + 1;
      end

      if (errors == 0)
          $display("[PASS] lab-4 source-pl checks passed.");
      else
          $display("[FAIL] lab-4 source-pl checks failed with %0d error(s).", errors);

      #20;
      $finish;
  end
      
endmodule
