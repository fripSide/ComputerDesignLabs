
单周期处理器需要实现的指令：  
slt, sltu, andi, ori, xori, srli, srai, slli, slti, sltui, bne, bge, bgeu, blt, bltu, jalr

流水线处理器需要实现的指令：  
slt, sltu, andi, ori, xori, srli, srai, slli, slti, sltui, beq, bne, bge, bgeu, blt, bltu, jal, jalr

基于上待实现的指令，需要给出按点给分的iverlog的测试用例（tb文件），每条指令需要有多个测试点。让学生基于这个tb文件，以及现有的sc/pl demo去实现指令。
- slt和sltu指令需要测试正数、负数、零的情况，以及相等和不相等的情况。
- andi、ori、xori指令需要测试不同的立即数值，以及不同的寄存器值的情况。
- srli、srai、slli指令需要测试不同的移位数值，以及不同的寄存器值的情况。
- slti、sltui指令需要测试正数、负数、零的情况，以及相等和不相等的情况。
- beq、bne、bge、bgeu、blt、bltu指令需要测试不同的分支条件，以及不同的寄存器值的情况。
- jal和jalr指令需要测试不同的跳转地址，以及不同的寄存器值的情况。	

