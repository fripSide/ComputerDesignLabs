
### 测试代码  
`rv32_sc_sim.asm` 可用 rars DUMP为 hex text

```C
#include <stdint.h>

int main() {
    // 定义 32 位寄存器和内存
    uint32_t x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15;
    uint32_t x16, x17, x18, x19, x20;
    uint32_t mem[256] = {0};  // 数据存储器，256 个 32 位字
    
    // 初始化阶段
    x5 = 0x12345000;    // lui x5, 0x12345
    x6 = 0xfffff000;    // lui x6, 0xfffff
    x12 = 0x4;          // addi x12, x0, 4
    
    // 算术运算阶段
    x7 = x5 + x6;       // add x7, x5, x6
    x8 = x5 - x6;       // sub x8, x5, x6
    x9 = x5 ^ x6;       // xor x9, x5, x6
    x10 = x5 | x6;      // or x10, x5, x6
    x11 = x5 & x6;      // and x11, x5, x6
    
    // 比较运算阶段
    x13 = (x6 < x12) ? 1 : 0;              // sltu x13, x6, x12（无符号比较）
    x14 = ((int32_t)x6 < (int32_t)x12) ? 1 : 0;  // slt x14, x6, x12（有符号比较）
    x15 = (x5 < 12) ? 1 : 0;               // sltiu x15, x5, 12（无符号立即数比较）
    
    // 内存访问阶段
    mem[x12 / 4] = x10;           // sw x10, 0(x12) - 存储到地址 4
    mem[(x12 + 4) / 4] = x11;     // sw x11, 4(x12) - 存储到地址 8
    
    x16 = mem[x12 / 4];           // lw x16, 0(x12) - 加载内存地址 4
    x17 = mem[(x12 + 4) / 4];     // lw x17, 4(x12) - 加载内存地址 8
    
    // 分支循环阶段
    if (x11 != x16) {             // beq x11, x16 - 如果不相等，分支
        x18 = 0x18;               // addi x18, x0, 24
    }
    
    if (x11 != x17) {             // beq x11, x17 - 如果不相等，分支
        x19 = 0x19;               // addi x19, x0, 25
    }
    
    x20 = 0x20;                   // addi x20, x0, 32
    
    // 无限循环（对应 jal x0, -20）
    while (1) {
        // 循环体（程序会在这里无限循环）
    }
    
    return 0;
}
```

### 预期运行结果  
```
# 单周期CPU
cd lab-2/source-sc
python build.py run          # 生成VCD文件
python verify_sccpu_waveform.py  # 验证波形

# 流水线CPU
cd lab-2/source-pl
python build.py run          # 生成VCD文件
python verify_plcpu_waveform.py  # 验证波形
```


✅ 验证总结:   
   VCD文件: sccpu_sim.vcd  
   信号更新事件: 61 个  
   时间范围: 0 ~ 300 ns  

📋 预期结果:    
   • PC增长: 每个时钟周期 +0x4  
   • x7结果: 0x12344000 (0x12345000 + 0xfffff000)  
   • x5初值: 0x12345000  
   • x6初值: 0xfffff000  

💡 手动检查步骤:  
   1. 在GTKWave中打开 sccpu_sim.vcd  
   2. 添加信号: PC, instr, reg_data, reg_sel  
   3. 对比 reg_sel=7 (x7寄存器) 时 reg_data 是否为 0x12344000  
   4. 查看PC是否在分支后跳转  