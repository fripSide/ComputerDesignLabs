#!/usr/bin/env python3
"""
验证流水线CPU仿真波形的脚本
"""

from pathlib import Path


def parse_vcd_simple(vcd_file):
    """简单快速的VCD解析器"""
    content = Path(vcd_file).read_text(encoding='utf8')
    lines = content.split('\n')
    
    # 提取关键信号代码
    timeline = {}
    current_time = 0
    
    # 关键信号代码
    key_signals = {
        ',': 'PC',          # plcomp.PC
        '(': 'instr',       # plcomp.instr
        '\'': 'reg_data',   # plcomp.reg_data
        '#': 'reg_sel',     # reg_sel
        'R': 'WD',          # 写入数据
        '@': 'aluout',      # ALU输出
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
    print("流水线CPU仿真波形验证")
    print("="*80 + "\n")
    
    timeline = parse_vcd_simple(vcd_file)
    
    # 预期结果
    expected = {
        'PC增长': '流水线执行，每个时钟周期 +0x4',
        'x7结果': '0x12344000 (0x12345000 + 0xfffff000)',
        '流水线阶段': '取指 → 译码 → 执行 → 访存 → 写回',
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
    
    print(f"\n📋 流水线CPU特点:")
    for key, value in expected.items():
        print(f"   • {key}: {value}")
    
    print(f"\n💡 检查要点:")
    print(f"   1. PC是否每个时钟周期递增0x4")
    print(f"   2. 指令是否正确译码并执行")
    print(f"   3. 寄存器写回是否延后（流水线延迟）")
    print(f"   4. 数据冒险是否被正确处理")
    print(f"   5. 分支预测和刷新是否正确\n")


def main():
    vcd_file = Path(__file__).parent / "plcpu_sim.vcd"
    
    if not vcd_file.exists():
        print(f"\n❌ VCD文件不存在: {vcd_file}\n")
        print("请先运行仿真:")
        print("  python build.py run\n")
        return
    
    verify_waveform(vcd_file)


if __name__ == "__main__":
    main()
