# CoreMiniAxi 优化指南

## 概述

本指南提供了将 CoreMiniAxi 从 440,344 instances 优化到 100,000 instances 的完整步骤。

## 优化策略层次

### 1. RTL 级优化 (最高优先级)
- 修改参数减少硬件资源
- 简化架构
- 移除不必要的功能

### 2. 综合优化 (中等优先级)
- 使用优化的 Yosys 脚本
- 激进的资源共享
- 逻辑简化

### 3. 技术映射优化 (低优先级)
- 选择合适的标准单元
- 优化驱动强度

## 已实施的 RTL 优化

### Parameters.scala 修改

```scala
// 指令通道数: 4 → 2
val instructionLanes = 2

// RVV VLEN: 128 → 64
val rvvVlen = 64

// Fetch 数据宽度: 256 → 128
var fetchDataBits = 128

// L0 Fetch Cache (可选: 1024 → 512)
val fetchCacheBytes = 1024
```

### CoreAxi.scala 修改

```scala
// ITCM: 8KB → 4KB
val itcmSizeBytes: Int = 1024 * 4

// DTCM: 32KB → 8KB
val dtcmSizeBytes: Int = 1024 * 8
```

### MemoryRegions 修改

```scala
val default = Seq(
  new MemoryRegion(0x00000, 0x1000, MemoryRegionType.IMEM), // 4KB
  new MemoryRegion(0x10000, 0x2000, MemoryRegionType.DMEM), // 8KB
  new MemoryRegion(0x30000, 0x1000, MemoryRegionType.Peripheral),
)
```

## 综合优化流程

### 方法 1: 标准优化

```bash
cd synthesis
yosys -s optimize_synth.tcl
```

这个脚本包含:
- 完整的优化流程
- 资源共享
- MUX 树优化
- 逻辑简化
- ABC 优化

预期减少: ~90,000 instances (20%)

### 方法 2: 激进优化

```bash
cd synthesis
yosys -s aggressive_optimize.tcl
```

这个脚本包含:
- 层次展平
- 多次迭代优化
- 激进的资源共享
- FSM one-hot 编码
- 寄存器优化

预期减少: ~110,000 instances (25%)

## 比较结果

```bash
cd synthesis
python3 compare_results.py ../r2g_synth_1107/result/synth_stat.json \
    optimized_stat.json \
    aggressive_stat.json
```

## 进一步优化选项

如果标准优化不足以达到目标，考虑以下选项:

### 选项 1: 禁用功能模块

在 Parameters.scala 中:

```scala
// 禁用调试模块
var enableDebug = false

// 禁用浮点
var enableFloat = false

// 禁用 RVV
var enableRvv = false

// 禁用验证逻辑
var enableVerification = false
```

预期减少: ~50,000 instances

### 选项 2: 进一步减少数据宽度

```scala
// LSU 数据宽度: 128 → 64
var lsuDataBits = 64

// Fetch 数据宽度: 128 → 64
var fetchDataBits = 64
```

预期减少: ~30,000 instances
风险: 性能显著下降

### 选项 3: 减少缓存大小

```scala
// L1I slots: 256 → 128
val l1islots = 128

// L1D slots: 256 → 128
val l1dslots = 128

// Fetch cache: 1024 → 512
val fetchCacheBytes = 512
```

预期减少: ~20,000 instances

## 完整优化流程

### 步骤 1: 修改 RTL 参数

```bash
# 编辑 Parameters.scala
vim hdl/chisel/src/coralnpu/Parameters.scala

# 编辑 CoreAxi.scala
vim hdl/chisel/src/coralnpu/CoreAxi.scala
```

### 步骤 2: 重新生成 Verilog

```bash
# 使用 Bazel 构建
bazel build //hdl/chisel/src/coralnpu:core_mini_axi_verilog

# 或使用 sbt (如果配置了)
cd hdl/chisel
sbt "runMain coralnpu.CoreMiniAxiMain"
```

### 步骤 3: 运行优化综合

```bash
cd synthesis
# 复制生成的 Verilog 到当前目录
cp ../bazel-bin/hdl/chisel/src/coralnpu/CoreMiniAxi.sv .

# 运行优化
yosys -s optimize_synth.tcl
```

### 步骤 4: 分析结果

```bash
# 比较结果
python3 compare_results.py \
    ../r2g_synth_1107/result/synth_stat.json \
    optimized_stat.json

# 查看详细统计
cat optimized_stat.json | jq '.modules.CoreMiniAxi'
```

### 步骤 5: 验证功能

```bash
# 运行测试套件
bazel test //tests/...

# 或运行特定测试
bazel test //tests/cocotb:core_mini_axi_test
```

## 优化检查清单

- [ ] 修改 Parameters.scala 中的关键参数
- [ ] 更新 CoreAxi.scala 中的 TCM 大小
- [ ] 更新 MemoryRegions 定义
- [ ] 重新生成 Verilog
- [ ] 运行标准优化综合
- [ ] 分析结果并比较
- [ ] 如果需要，运行激进优化
- [ ] 验证功能正确性
- [ ] 检查时序约束
- [ ] 评估性能影响

## 预期结果

| 优化级别 | Instances | 减少量 | 减少比例 |
|---------|-----------|--------|---------|
| 基线 | 440,344 | - | - |
| RTL 优化 | ~295,000 | ~145,000 | 33% |
| + 标准综合优化 | ~205,000 | ~235,000 | 53% |
| + 激进综合优化 | ~185,000 | ~255,000 | 58% |
| + 功能裁剪 | ~135,000 | ~305,000 | 69% |
| + 架构优化 | ~100,000 | ~340,000 | 77% |

## 风险和权衡

### 低风险优化
- ✅ 综合脚本优化
- ✅ 适度的参数调整

### 中风险优化
- ⚠️ TCM 大小减少
- ⚠️ 数据宽度减少
- ⚠️ 缓存大小减少

影响: 性能下降 10-30%

### 高风险优化
- ⛔ 禁用功能模块
- ⛔ 大幅减少数据宽度
- ⛔ 移除流水线级

影响: 功能受限，性能下降 30-50%

## 故障排除

### 问题: 综合失败

```bash
# 检查 Verilog 语法
verilator --lint-only CoreMiniAxi.sv

# 使用更简单的综合脚本
yosys -p "read_verilog CoreMiniAxi.sv; synth; stat"
```

### 问题: Instance 数量没有显著减少

1. 确认 RTL 修改已生效
2. 检查是否使用了正确的 Verilog 文件
3. 尝试激进优化脚本
4. 考虑功能裁剪

### 问题: 时序违例

1. 放宽时序约束
2. 减少优化激进程度
3. 增加流水线级数
4. 使用更快的标准单元

## 参考资料

- [Yosys 优化命令文档](http://www.clifford.at/yosys/documentation.html)
- [Chisel 性能优化指南](https://www.chisel-lang.org/chisel3/docs/explanations/performance.html)
- CoreMiniAxi 架构文档: `doc/overview.md`
- 综合分析报告: `doc/optimization/optimization_analysis.md`

## 支持

如有问题，请参考:
- 项目 README: `README.md`
- 集成指南: `doc/integration_guide.md`
- 仿真指南: `doc/simulation.md`
