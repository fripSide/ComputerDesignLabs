#!/usr/bin/env python3
"""
验证单周期CPU仿真波形的快速脚本
直接提取关键信号值
"""

from pathlib import Path


def parse_vcd_simple(vcd_file):
    """简单快速的VCD解析器"""
    content = Path(vcd_file).read_text(encoding='utf8')
    lines = content.split('\n')
    
    # 信号代码映射 (从VCD文件的var行提取)
    signal_map = {}
    
    for line in lines:
        line = line.strip()
        
        # 解析信号定义
        if line.startswith('$var'):
            parts = line.split()
            if len(parts) >= 4:
                code = parts[3]
                name = ' '.join(parts[4:]).replace('$end', '').strip()
                signal_map[code] = name
        
        # 检查是否进入数据部分
        if line.startswith('$dumpvars'):
            break
    
    # 提取关键信号
    timeline = {}
    current_time = 0
    
    # 关键信号代码（从VCD中直接提取）
    key_signals = {
        ',': 'PC',          # sccomp.PC
        '(': 'instr',       # sccomp.instr
        '\'': 'reg_data',   # sccomp.reg_data
        '#': 'reg_sel',     # reg_sel [4:0]
        'R': 'WD',          # U_SCCPU.WD (写入数据)
        '@': 'aluout',      # U_SCCPU.aluout (ALU输出)
    }
    
    for line in lines:
        line = line.strip()
        
        if line.startswith('#'):
            current_time = int(line[1:])
            if current_time not in timeline:
                timeline[current_time] = {}
        
        elif line and line[0] in '01xXzZ-':
            code = line[-1]
            value = line[:-1]
            
            if code in key_signals:
                if current_time not in timeline:
                    timeline[current_time] = {}
                timeline[current_time][key_signals[code]] = value
    
    return timeline


def binary_to_hex(binary_str):
    """将二进制字符串转换为十六进制"""
    if not binary_str:
        return 'N/A'
    if 'x' in binary_str.lower():
        return f'0x{binary_str}'
    try:
        value = int(binary_str, 2)
        return f'0x{value:08x}'
    except:
        return binary_str


def verify_waveform(vcd_file):
    """验证波形"""
    print("\n" + "="*80)
    print("单周期CPU仿真波形验证")
    print("="*80 + "\n")
    
    timeline = parse_vcd_simple(vcd_file)
    
    # 预期结果
    expected = {
        'PC增长': '每个时钟周期 +0x4',
        'x7结果': '0x12344000 (0x12345000 + 0xfffff000)',
        'x5初值': '0x12345000',
        'x6初值': '0xfffff000',
    }
    
    # 关键时间点（每个时钟周期约10ns）
    checkpoints = {
        0: 'clk上升沿, rstn=1, 初始化',
        10: 'PC首次更新, 执行第一条指令',
        50: '执行中期',
        100: '执行中期',
        200: '执行后期',
        300: '仿真结束',
    }
    
    print("📊 关键时间点的信号变化:\n")
    print(f"{'时间(ns)':<12} {'PC':<12} {'指令':<12} {'写入数据':<12} {'ALU输出':<12}")
    print("-" * 65)
    
    # 显示所有时间点的更新
    times = sorted(timeline.keys())
    for time in times[:50]:  # 显示前50个更新点
        signals = timeline.get(time, {})
        
        pc_val = signals.get('PC', '')
        instr_val = signals.get('instr', '')
        wd_val = signals.get('WD', '')
        alu_val = signals.get('aluout', '')
        
        # 只显示有关键信号更新的时间点
        if any([pc_val, wd_val, alu_val]):
            pc_hex = binary_to_hex(pc_val) if pc_val else '-'
            instr_hex = binary_to_hex(instr_val) if instr_val else '-'
            wd_hex = binary_to_hex(wd_val) if wd_val else '-'
            alu_hex = binary_to_hex(alu_val) if alu_val else '-'
            
            print(f"{time:<12} {pc_hex:<12} {instr_hex:<12} {wd_hex:<12} {alu_hex:<12}")
    
    print(f"\n✅ 验证总结:")
    print(f"   VCD文件: {Path(vcd_file).name}")
    print(f"   信号更新事件: {len(timeline)} 个")
    print(f"   时间范围: 0 ~ {max(times) if times else 0} ns")
    
    print(f"\n📋 预期结果:")
    for key, value in expected.items():
        print(f"   • {key}: {value}")
    
    print(f"\n💡 手动检查步骤:")
    print(f"   1. 在GTKWave中打开 sccpu_sim.vcd")
    print(f"   2. 添加信号: PC, instr, reg_data, reg_sel")
    print(f"   3. 对比 reg_sel=7 (x7寄存器) 时 reg_data 是否为 0x12344000")
    print(f"   4. 查看PC是否在分支后跳转\n")


def main():
    vcd_file = Path(__file__).parent / "sccpu_sim.vcd"
    
    if not vcd_file.exists():
        print(f"\n❌ VCD文件不存在: {vcd_file}\n")
        print("请先运行仿真:")
        print("  python build.py run\n")
        return
    
    verify_waveform(vcd_file)


if __name__ == "__main__":
    main()
