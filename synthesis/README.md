# CoreMiniAxi 综合优化工具

本目录包含用于优化 CoreMiniAxi 设计的综合脚本和分析工具。

## 文件说明

### 综合脚本

- **optimize_synth.tcl** - 标准优化综合脚本
  - 适用于大多数情况
  - 平衡优化效果和综合时间
  - 预期减少 ~20% instances

- **aggressive_optimize.tcl** - 激进优化综合脚本
  - 用于需要最大化优化的场景
  - 综合时间较长
  - 预期减少 ~25% instances

### 分析工具

- **compare_results.py** - 结果比较工具
  - 比较不同优化策略的效果
  - 分析 instance 组成
  - 生成详细的优化报告

- **run_optimization.sh** - 自动化优化脚本
  - 交互式选择优化级别
  - 自动运行综合和比较
  - 生成完整的优化报告

## 快速开始

### 1. 准备 Verilog 文件

```bash
# 从项目根目录
bazel build //hdl/chisel/src/coralnpu:core_mini_axi_verilog
cp bazel-bin/hdl/chisel/src/coralnpu/CoreMiniAxi.sv synthesis/
```

### 2. 运行优化

```bash
cd synthesis
./run_optimization.sh
```

按提示选择优化级别:
- 选项 1: 标准优化 (推荐)
- 选项 2: 激进优化
- 选项 3: 两者都运行

### 3. 查看结果

脚本会自动显示:
- 优化前后的 instance 数量
- 各类单元的分布
- 距离目标的差距

## 手动使用

### 运行标准优化

```bash
yosys -s optimize_synth.tcl
```

输出文件:
- `optimized_CoreMiniAxi.v` - 优化后的网表
- `optimized_stat.json` - 统计信息

### 运行激进优化

```bash
yosys -s aggressive_optimize.tcl
```

输出文件:
- `aggressive_CoreMiniAxi.v` - 优化后的网表
- `aggressive_stat.json` - 统计信息

### 比较结果

```bash
python3 compare_results.py \
    baseline_stat.json \
    optimized_stat.json \
    aggressive_stat.json
```

## 优化策略

### 标准优化包含

1. 资源共享 (`share -aggressive`)
2. MUX 树优化 (`opt_muxtree`)
3. 逻辑简化 (`opt_reduce`)
4. 位宽优化 (`wreduce`)
5. ABC 逻辑优化
6. FSM 优化

### 激进优化额外包含

1. 层次展平 (`flatten`)
2. 多次迭代优化
3. FSM one-hot 编码
4. 寄存器优化 (`opt_dff`)
5. 更激进的资源共享

## 输出文件

### 网表文件
- `optimized_CoreMiniAxi.v` - 标准优化网表
- `aggressive_CoreMiniAxi.v` - 激进优化网表

### 统计文件
- `optimized_stat.json` - 标准优化统计
- `aggressive_stat.json` - 激进优化统计

### 日志文件
- `optimize_synth.log` - 标准优化日志
- `aggressive_optimize.log` - 激进优化日志

## 故障排除

### 问题: 找不到 CoreMiniAxi.sv

**解决方案**:
```bash
# 确保已生成 Verilog
bazel build //hdl/chisel/src/coralnpu:core_mini_axi_verilog

# 复制到当前目录
cp bazel-bin/hdl/chisel/src/coralnpu/CoreMiniAxi.sv .
```

### 问题: Yosys 综合失败

**解决方案**:
1. 检查 Verilog 语法:
   ```bash
   verilator --lint-only CoreMiniAxi.sv
   ```

2. 尝试简单综合:
   ```bash
   yosys -p "read_verilog CoreMiniAxi.sv; synth; stat"
   ```

3. 查看日志文件了解详细错误

### 问题: 优化效果不明显

**解决方案**:
1. 确认使用了优化后的 RTL 参数
2. 尝试激进优化脚本
3. 考虑功能裁剪 (参见优化指南)

## 相关文档

- [优化指南](../doc/optimization/optimization_guide.md) - 完整的优化指南
- [优化总结](../doc/optimization/OPTIMIZATION_SUMMARY.md) - 优化工作总结
- [实施计划](../doc/optimization/optimization_implementation_plan.md) - 详细实施计划
- [分析报告](../doc/optimization/optimization_analysis.md) - 原始分析报告

## 要求

- Yosys (>= 0.9)
- Python 3 (>= 3.6)
- Bash shell

## 许可证

与 CoreMiniAxi 项目相同的许可证。
