#!/bin/bash

echo "=========================================="
echo "Instance Count Analysis"
echo "=========================================="
echo ""

# 分析 synth_stat.json
echo "1. synth_stat.json (Technology-mapped cells):"
echo "-------------------------------------------"
python3 << 'EOF'
import json

with open('/opt/tools/r2g_synth_1107/result/synth_stat.json', 'r') as f:
    data = json.load(f)

cells = data['design']['num_cells_by_type']
total = data['design']['num_cells']

print(f"总 Instances: {total:,}")
print(f"不同类型数量: {len(cells)}")
print(f"总面积: {data['design']['area']:,.2f}")
print(f"时序面积: {data['design']['sequential_area']:,.2f}")
print(f"组合面积: {data['design']['area'] - data['design']['sequential_area']:,.2f}")
print("")

# 统计主要类型
print("Top 10 最多的 cell 类型:")
sorted_cells = sorted(cells.items(), key=lambda x: x[1], reverse=True)
for i, (cell_type, count) in enumerate(sorted_cells[:10], 1):
    percentage = (count / total) * 100
    print(f"  {i:2d}. {cell_type:20s}: {count:7,} ({percentage:5.2f}%)")

# 按功能分类统计
dff_count = sum(v for k, v in cells.items() if 'DFF' in k)
mux_count = sum(v for k, v in cells.items() if 'MUX' in k)
buf_count = sum(v for k, v in cells.items() if 'BUF' in k)
inv_count = sum(v for k, v in cells.items() if 'INV' in k)
logic_count = total - dff_count - mux_count - buf_count - inv_count

print("")
print("按功能分类:")
print(f"  触发器 (DFF):     {dff_count:7,} ({dff_count/total*100:5.2f}%)")
print(f"  多路复用器 (MUX): {mux_count:7,} ({mux_count/total*100:5.2f}%)")
print(f"  缓冲器 (BUF):     {buf_count:7,} ({buf_count/total*100:5.2f}%)")
print(f"  反相器 (INV):     {inv_count:7,} ({inv_count/total*100:5.2f}%)")
print(f"  逻辑门:           {logic_count:7,} ({logic_count/total*100:5.2f}%)")

EOF

echo ""
echo ""

# 分析 generic_stat.json
echo "2. generic_stat.json (Generic cells before mapping):"
echo "-----------------------------------------------------"
python3 << 'EOF'
import json

with open('/opt/tools/r2g_synth_1107/result/generic_stat.json', 'r') as f:
    data = json.load(f)

cells = data['design']['num_cells_by_type']
total = data['design']['num_cells']

print(f"总 Instances: {total:,}")
print(f"不同类型数量: {len(cells)}")
print(f"估计晶体管数: {data['design']['estimated_num_transistors']}")
print("")

print("所有 cell 类型及数量:")
sorted_cells = sorted(cells.items(), key=lambda x: x[1], reverse=True)
for cell_type, count in sorted_cells:
    percentage = (count / total) * 100
    print(f"  {cell_type:20s}: {count:7,} ({percentage:5.2f}%)")

# 按功能分类
dff_count = sum(v for k, v in cells.items() if 'DFF' in k)
mux_count = sum(v for k, v in cells.items() if 'MUX' in k)
and_count = cells.get('$_AND_', 0)
or_count = cells.get('$_OR_', 0)
nor_count = cells.get('$_NOR_', 0)
not_count = cells.get('$_NOT_', 0)
xor_count = cells.get('$_XOR_', 0)
xnor_count = cells.get('$_XNOR_', 0)
latch_count = cells.get('$_DLATCH_N_', 0)

print("")
print("按功能分类:")
print(f"  触发器 (DFF/DFFE): {dff_count:7,} ({dff_count/total*100:5.2f}%)")
print(f"  多路复用器 (MUX):  {mux_count:7,} ({mux_count/total*100:5.2f}%)")
print(f"  与门 (AND):        {and_count:7,} ({and_count/total*100:5.2f}%)")
print(f"  或门 (OR):         {or_count:7,} ({or_count/total*100:5.2f}%)")
print(f"  异或门 (XOR):      {xor_count:7,} ({xor_count/total*100:5.2f}%)")
print(f"  反相器 (NOT):      {not_count:7,} ({not_count/total*100:5.2f}%)")
print(f"  锁存器 (LATCH):    {latch_count:7,} ({latch_count/total*100:5.2f}%)")

EOF

echo ""
echo ""

# 优化建议
echo "=========================================="
echo "优化建议：如何将 instances 降低到 10万"
echo "=========================================="
echo ""
echo "当前状态："
echo "  - Technology-mapped: 440,344 instances"
echo "  - Generic cells:     330,041 instances"
echo "  - 目标:              100,000 instances"
echo "  - 需要减少:          ~340,000 instances (77%)"
echo ""
echo "主要优化方向："
echo ""
echo "1. 减少触发器数量 (当前 ~106,558 个，24.2%)"
echo "   - 寄存器共享：合并功能相似的寄存器"
echo "   - 流水线优化：减少不必要的流水级"
echo "   - 状态机优化：使用更紧凑的状态编码"
echo "   - 移除冗余寄存器：通过时序分析识别可合并的寄存器"
echo ""
echo "2. 减少多路复用器 (当前 ~83,716 个，19%)"
echo "   - 简化数据路径选择逻辑"
echo "   - 减少配置选项和模式"
echo "   - 使用更高效的仲裁机制"
echo "   - 合并相似的选择逻辑"
echo ""
echo "3. 减少缓冲器 (当前 ~40,770 个，9.3%)"
echo "   - 优化时序约束，减少插入的缓冲器"
echo "   - 改进布局布线策略"
echo "   - 使用更合理的驱动强度"
echo ""
echo "4. 优化逻辑门 (当前 ~209,300 个，47.5%)"
echo "   - 逻辑简化：使用 Yosys 的 opt 命令"
echo "   - 资源共享：合并相似的逻辑功能"
echo "   - 移除死代码和未使用的逻辑"
echo "   - 使用更高级的综合策略"
echo ""
echo "5. 架构级优化"
echo "   - 减少总线宽度"
echo "   - 简化接口协议"
echo "   - 移除不必要的功能模块"
echo "   - 使用更紧凑的数据结构"
echo ""
echo "6. Yosys 综合优化命令"
echo "   - opt -full          # 完整优化"
echo "   - opt_clean          # 清理未使用的信号"
echo "   - opt_merge          # 合并相同的单元"
echo "   - opt_muxtree        # 优化多路复用器树"
echo "   - opt_reduce         # 减少逻辑深度"
echo "   - share              # 资源共享"
echo "   - wreduce            # 减少信号宽度"
echo ""
echo "预估优化效果："
echo "  - 触发器减少 50%:      -53,000"
echo "  - MUX 减少 60%:        -50,000"
echo "  - 逻辑门减少 70%:      -146,000"
echo "  - 缓冲器减少 50%:      -20,000"
echo "  --------------------------------"
echo "  总计可减少:            -269,000"
echo "  优化后预估:            ~171,000 instances"
echo ""
echo "  需要更激进的架构优化才能达到 10 万目标"
echo ""
