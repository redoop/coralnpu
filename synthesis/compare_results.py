#!/usr/bin/env python3
"""
比较不同优化策略的结果
分析 instance 数量、面积和组成
"""

import json
import sys
from pathlib import Path

def load_stats(filename):
    """加载 Yosys 统计 JSON 文件"""
    try:
        with open(filename, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"错误: 找不到文件 {filename}")
        return None
    except json.JSONDecodeError:
        print(f"错误: {filename} 不是有效的 JSON 文件")
        return None

def extract_instance_count(stats):
    """从统计数据中提取 instance 总数"""
    if not stats or 'modules' not in stats:
        return 0
    
    # 查找顶层模块
    for module_name, module_data in stats['modules'].items():
        if 'num_cells' in module_data:
            return module_data['num_cells']
    return 0

def extract_cell_breakdown(stats):
    """提取单元类型分解"""
    if not stats or 'modules' not in stats:
        return {}
    
    for module_name, module_data in stats['modules'].items():
        if 'cells' in module_data:
            return module_data['cells']
    return {}

def categorize_cells(cells):
    """将单元分类"""
    categories = {
        'flip_flops': 0,
        'multiplexers': 0,
        'logic_gates': 0,
        'buffers': 0,
        'other': 0
    }
    
    for cell_type, count in cells.items():
        cell_upper = cell_type.upper()
        if 'DFF' in cell_upper or 'DFFR' in cell_upper:
            categories['flip_flops'] += count
        elif 'MUX' in cell_upper:
            categories['multiplexers'] += count
        elif any(gate in cell_upper for gate in ['NAND', 'NOR', 'AND', 'OR', 'XOR', 'INV', 'AOI', 'OAI']):
            categories['logic_gates'] += count
        elif 'BUF' in cell_upper:
            categories['buffers'] += count
        else:
            categories['other'] += count
    
    return categories

def print_comparison(baseline_file, optimized_files):
    """打印优化结果比较"""
    print("=" * 80)
    print("CoreMiniAxi 优化结果比较")
    print("=" * 80)
    print()
    
    # 加载基线
    baseline = load_stats(baseline_file)
    if not baseline:
        print(f"无法加载基线文件: {baseline_file}")
        return
    
    baseline_count = extract_instance_count(baseline)
    baseline_cells = extract_cell_breakdown(baseline)
    baseline_categories = categorize_cells(baseline_cells)
    
    print(f"基线 ({baseline_file}):")
    print(f"  总 Instances: {baseline_count:,}")
    print(f"  触发器: {baseline_categories['flip_flops']:,} ({baseline_categories['flip_flops']/baseline_count*100:.1f}%)")
    print(f"  多路复用器: {baseline_categories['multiplexers']:,} ({baseline_categories['multiplexers']/baseline_count*100:.1f}%)")
    print(f"  逻辑门: {baseline_categories['logic_gates']:,} ({baseline_categories['logic_gates']/baseline_count*100:.1f}%)")
    print(f"  缓冲器: {baseline_categories['buffers']:,} ({baseline_categories['buffers']/baseline_count*100:.1f}%)")
    print()
    
    # 目标
    target = 100000
    print(f"目标: {target:,} instances")
    print(f"需要减少: {baseline_count - target:,} instances ({(baseline_count - target)/baseline_count*100:.1f}%)")
    print()
    print("-" * 80)
    print()
    
    # 比较优化结果
    for opt_file in optimized_files:
        opt_stats = load_stats(opt_file)
        if not opt_stats:
            continue
        
        opt_count = extract_instance_count(opt_stats)
        opt_cells = extract_cell_breakdown(opt_stats)
        opt_categories = categorize_cells(opt_cells)
        
        reduction = baseline_count - opt_count
        reduction_pct = (reduction / baseline_count * 100) if baseline_count > 0 else 0
        
        print(f"优化结果 ({opt_file}):")
        print(f"  总 Instances: {opt_count:,}")
        print(f"  减少: {reduction:,} ({reduction_pct:.1f}%)")
        print(f"  距离目标: {opt_count - target:,} ({(opt_count - target)/target*100:+.1f}%)")
        print()
        print(f"  触发器: {opt_categories['flip_flops']:,} ({opt_categories['flip_flops']/opt_count*100:.1f}%) " +
              f"[{opt_categories['flip_flops'] - baseline_categories['flip_flops']:+,}]")
        print(f"  多路复用器: {opt_categories['multiplexers']:,} ({opt_categories['multiplexers']/opt_count*100:.1f}%) " +
              f"[{opt_categories['multiplexers'] - baseline_categories['multiplexers']:+,}]")
        print(f"  逻辑门: {opt_categories['logic_gates']:,} ({opt_categories['logic_gates']/opt_count*100:.1f}%) " +
              f"[{opt_categories['logic_gates'] - baseline_categories['logic_gates']:+,}]")
        print(f"  缓冲器: {opt_categories['buffers']:,} ({opt_categories['buffers']/opt_count*100:.1f}%) " +
              f"[{opt_categories['buffers'] - baseline_categories['buffers']:+,}]")
        print()
        print("-" * 80)
        print()

def main():
    if len(sys.argv) < 2:
        print("用法: python3 compare_results.py <baseline.json> [optimized1.json] [optimized2.json] ...")
        print()
        print("示例:")
        print("  python3 compare_results.py synth_stat.json optimized_stat.json aggressive_stat.json")
        sys.exit(1)
    
    baseline_file = sys.argv[1]
    optimized_files = sys.argv[2:] if len(sys.argv) > 2 else []
    
    print_comparison(baseline_file, optimized_files)

if __name__ == '__main__':
    main()
