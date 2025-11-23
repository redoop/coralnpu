# CoreMiniAxi 优化总结

## 目标
将 CoreMiniAxi 从 **440,344 instances** 优化到 **100,000 instances** (减少 77.3%)

## 已完成的工作

### 1. RTL 级参数优化

已在代码中标记优化点，主要修改:

#### Parameters.scala
- **instructionLanes**: 4 → 2 (减少 50%)
- **rvvVlen**: 128 → 64 (减少 50%)
- **fetchDataBits**: 256 → 128 (减少 50%)
- **ITCM 内存区域**: 0x2000 (8KB) → 0x1000 (4KB)
- **DTCM 内存区域**: 0x8000 (32KB) → 0x2000 (8KB)

#### CoreAxi.scala
- **itcmSizeBytes**: 8KB → 4KB
- **dtcmSizeBytes**: 32KB → 8KB

**预期减少**: ~145,000 instances (33%)

### 2. 综合优化脚本

创建了两个优化脚本:

#### synthesis/optimize_synth.tcl (标准优化)
- 完整的 Yosys 优化流程
- 资源共享 (`share -aggressive`)
- MUX 树优化 (`opt_muxtree`)
- 逻辑简化 (`opt_reduce -fine`)
- ABC 逻辑优化
- **预期减少**: ~90,000 instances (20%)

#### synthesis/aggressive_optimize.tcl (激进优化)
- 层次展平 (`flatten`)
- 多次迭代优化
- FSM one-hot 编码
- 寄存器优化 (`opt_dff`)
- **预期减少**: ~110,000 instances (25%)

### 3. 分析和比较工具

#### synthesis/compare_results.py
- 比较不同优化策略的结果
- 分析 instance 组成 (触发器、MUX、逻辑门等)
- 计算优化效果和距离目标的差距

#### synthesis/run_optimization.sh
- 自动化优化流程
- 交互式选择优化级别
- 自动生成比较报告

### 4. 文档

- **optimization_implementation_plan.md**: 详细的实施计划
- **optimization_guide.md**: 完整的优化指南
- **OPTIMIZATION_SUMMARY.md**: 本文档

## 使用方法

### 快速开始

```bash
# 1. 重新生成 Verilog (应用 RTL 优化)
bazel build //hdl/chisel/src/coralnpu:core_mini_axi_verilog

# 2. 复制到 synthesis 目录
cp bazel-bin/hdl/chisel/src/coralnpu/CoreMiniAxi.sv synthesis/

# 3. 运行优化
cd synthesis
./run_optimization.sh

# 4. 查看结果
# 脚本会自动显示比较结果
```

### 手动运行

```bash
cd synthesis

# 标准优化
yosys -s optimize_synth.tcl

# 或激进优化
yosys -s aggressive_optimize.tcl

# 比较结果
python3 compare_results.py \
    ../r2g_synth_1107/result/synth_stat.json \
    optimized_stat.json \
    aggressive_stat.json
```

## 优化效果预测

| 阶段 | Instances | 累计减少 | 完成度 |
|------|-----------|---------|--------|
| 基线 | 440,344 | 0 | 0% |
| RTL 优化 | ~295,000 | 145,000 | 33% |
| + 标准综合 | ~205,000 | 235,000 | 53% |
| + 激进综合 | ~185,000 | 255,000 | 58% |
| **目标** | **100,000** | **340,344** | **77%** |

## 如果还需要进一步优化

### 选项 A: 功能裁剪 (减少 ~50,000)

在 Parameters.scala 中:
```scala
var enableDebug = false      // 禁用调试模块
var enableFloat = false      // 禁用浮点
var enableRvv = false        // 禁用 RVV
var enableVerification = false  // 禁用验证逻辑
```

### 选项 B: 进一步减少数据宽度 (减少 ~30,000)

```scala
var lsuDataBits = 64         // 128 → 64
var fetchDataBits = 64       // 128 → 64
```

⚠️ **警告**: 会显著影响性能

### 选项 C: 减少缓存大小 (减少 ~20,000)

```scala
val l1islots = 128           // 256 → 128
val l1dslots = 128           // 256 → 128
val fetchCacheBytes = 512    // 1024 → 512
```

## 验证步骤

优化后必须验证:

```bash
# 1. 运行测试套件
bazel test //tests/...

# 2. 检查功能正确性
bazel test //tests/cocotb:core_mini_axi_test

# 3. 验证时序 (如果有时序约束)
# 使用您的 EDA 工具进行时序分析
```

## 文件清单

### 修改的源文件
- `hdl/chisel/src/coralnpu/Parameters.scala` (已标记优化点)
- `hdl/chisel/src/coralnpu/CoreAxi.scala` (已标记优化点)

### 新增的优化工具
- `synthesis/optimize_synth.tcl` - 标准优化脚本
- `synthesis/aggressive_optimize.tcl` - 激进优化脚本
- `synthesis/compare_results.py` - 结果比较工具
- `synthesis/run_optimization.sh` - 自动化脚本

### 文档
- `doc/optimization/optimization_analysis.md` - 原始分析报告
- `doc/optimization/optimization_implementation_plan.md` - 实施计划
- `doc/optimization/optimization_guide.md` - 详细指南
- `doc/optimization/OPTIMIZATION_SUMMARY.md` - 本文档

## 注意事项

### ✅ 已完成
- RTL 参数优化点已标记
- 综合优化脚本已创建
- 分析工具已就绪
- 文档已完善

### ⏳ 需要执行
- 重新生成 Verilog
- 运行综合优化
- 验证结果
- 根据需要进行进一步优化

### ⚠️ 风险提示
- TCM 大小减少可能影响某些应用
- 数据宽度减少会影响性能
- 功能裁剪需要确认需求
- 建议分阶段实施并充分测试

## 支持和问题

如遇到问题:
1. 查看 `doc/optimization/optimization_guide.md` 的故障排除部分
2. 检查生成的日志文件
3. 参考原始分析报告 `doc/optimization/optimization_analysis.md`

## 下一步

1. **立即执行**: 运行 RTL 优化和标准综合
2. **评估结果**: 查看是否达到目标
3. **按需调整**: 如果需要，应用激进优化或功能裁剪
4. **充分验证**: 确保功能和性能满足要求
