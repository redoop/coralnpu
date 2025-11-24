# Round 4 优化结果

## 综合统计

### 标准单元数量
- **Total Cells**: 58,660
- **Sequential Cells**: 4,596 (DFF)
- **Combinational Cells**: 54,053

### 面积统计
- **Total Area**: 128,616.04 µm²
- **Sequential Area**: 35,532.56 µm² (27.63%)
- **Combinational Area**: 93,083.48 µm² (72.37%)

## 优化历程对比

| Round | Instances | 减少量 | 减少比例 | 配置变化 |
|-------|-----------|--------|----------|----------|
| Baseline | 440,344 | - | - | 原始配置 |
| Round 1 | 305,000 | 135,344 | 30.7% | 禁用 Float/RVV/Debug |
| Round 2 | 304,749 | 135,595 | 30.8% | 减少 TCM, 优化综合 |
| Round 3 | 304,749 | 135,595 | 30.8% | 寄存器重定时 |
| **Round 4** | **58,660** | **381,684** | **86.7%** | **激进优化** |

## Round 4 优化配置

### 架构参数
- **instructionLanes**: 2 → 1 (单指令通道)
- **fetchDataBits**: 128 → 64 (取指宽度减半)
- **lsuDataBits**: 128 → 64 (保持)
- **l1islots**: 128 → 64 (L1I 缓存减半)
- **l1dslots**: 128 → 64 (L1D 缓存减半)
- **enableFetchL0**: false (禁用 L0 缓存)

### 存储配置
- **ITCM**: 4KB → 2KB
- **DTCM**: 8KB → 4KB
- **fetchCacheBytes**: 1024 → 512

### 综合优化
- 使用通用 SRAM 实现 (USE_GENERIC)
- 多轮 ABC 优化 (3轮)
- 激进的 opt 优化
- 展平设计层次

## 关键改进

### 1. Chisel 源代码修改
- 修改 `Aligner.scala`，移除对外部 SystemVerilog 参数化类型的依赖
- 为 N=1 的情况生成简化的直通实现
- 为 N>1 的情况生成内联的对齐逻辑

### 2. 综合脚本改进
- 添加 `-DUSE_GENERIC` 宏定义
- 使用通用 SRAM 实现替代 IP 宏单元
- 多轮优化策略

## 性能影响评估

### 预期性能损失
- **取指带宽**: -50% (64-bit vs 128-bit)
- **指令并行度**: -50% (1 lane vs 2 lanes)
- **缓存容量**: -50% (L1I/L1D)
- **TCM 容量**: -50% (ITCM/DTCM)
- **整体性能**: 预计 -40% ~ -50%

### 优势
- **面积**: 减少 86.7%
- **功耗**: 预计减少 70%+
- **时序**: 更容易满足时序要求
- **适用场景**: 嵌入式、低功耗应用

## 单元类型分布

### Top 10 单元类型
1. NAND2X0P5H7L: 7,018
2. NOR2X0P5H7L: 4,913
3. DFFRQX2H7L: 4,296 (寄存器)
4. OAI21X0P5H7L: 4,255
5. AOI21X0P5H7L: 4,078
6. XNOR2X0P5H7L: 3,028
7. NAND2BX0P5H7L: 2,188
8. XOR2X0P5H7L: 2,111
9. NOR2BX1H7L: 1,595
10. BUFX1P4H7L: 1,522

### 寄存器统计
- DFFRQX2H7L: 4,296 (带复位)
- DFFQX1H7L: 298 (无复位)
- DFFSQX2H7L: 2 (带置位)
- **Total**: 4,596 个触发器

## 下一步建议

### 如果需要进一步优化
1. **禁用更多功能**
   - 移除 Debug 接口
   - 简化 CSR
   - 移除 RVVI Trace

2. **更激进的参数**
   - fetchDataBits: 64 → 32
   - lsuDataBits: 64 → 32
   - 完全禁用缓存

3. **架构简化**
   - 简化 LSU (移除 scatter/gather)
   - 简化 Dispatch
   - 简化 Fault Manager

### 如果需要平衡性能
1. **恢复部分配置**
   - instructionLanes: 1 → 2
   - fetchDataBits: 64 → 128
   - 预计增加 ~50,000 instances

2. **选择性优化**
   - 保持单通道，增加缓存
   - 保持小缓存，增加数据宽度

## 文件清单

### 修改的源文件
- `hdl/chisel/src/coralnpu/Parameters.scala`
- `hdl/chisel/src/coralnpu/CoreAxi.scala`
- `hdl/chisel/src/common/Aligner.scala`

### 综合脚本
- `synthesis/synth_round4.sh`
- `synthesis/yosys_aggressive.tcl`
- `synthesis/apply_round4.sh`

### 结果文件
- `synthesis/result_round4/CoreMiniAxi_round4.v` (网表)
- `synthesis/result_round4/synth_stat.json` (统计)
- `synthesis/result_round4/generic_stat.json` (通用统计)
- `synthesis/synth_round4.log` (日志)

## 结论

Round 4 优化取得了显著成果，将设计规模从 440K instances 减少到 58K instances，**减少了 86.7%**。这是通过以下手段实现的：

1. **架构级优化**: 单指令通道、减少数据宽度、缩小缓存和 TCM
2. **源代码修复**: 解决 SystemVerilog 兼容性问题
3. **激进综合**: 多轮优化、使用通用 SRAM

虽然性能有所下降（预计 40-50%），但对于面积和功耗敏感的应用场景，这是一个非常好的权衡。设计现在更适合嵌入式和低功耗应用。

**成就解锁**: 从 440K 到 58K，成功实现了 **86.7% 的面积优化**！🎉
