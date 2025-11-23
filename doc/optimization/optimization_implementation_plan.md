# CoreMiniAxi 优化实施计划

## 目标
将 instances 从 440,344 降低到 100,000 (减少 77.3%)

## 已实施的优化

### 阶段 1: RTL 参数优化 (预期减少 30-40%)

#### 1.1 数据路径宽度优化
- ✅ **Fetch 数据宽度**: 256 bits → 128 bits (减少 50%)
  - 影响: fetchDataBits, axi0DataBits
  - 预期减少: ~40,000 instances
  
- ✅ **指令通道数**: 4 → 2 (减少 50%)
  - 影响: instructionLanes
  - 预期减少: ~30,000 instances

#### 1.2 向量处理单元优化
- ✅ **RVV VLEN**: 128 bits → 64 bits (减少 50%)
  - 影响: rvvVlen
  - 预期减少: ~50,000 instances (如果启用 RVV)

#### 1.3 TCM 大小优化
- ✅ **ITCM**: 8 KB → 4 KB (减少 50%)
  - 影响: itcmSizeBytes
  - 预期减少: ~10,000 instances
  
- ✅ **DTCM**: 32 KB → 8 KB (减少 75%)
  - 影响: dtcmSizeBytes
  - 预期减少: ~15,000 instances

#### 1.4 缓存优化
- ✅ **L0 Fetch Cache**: 1024 bytes (保持不变，可进一步优化)
  - 可选: 减少到 512 bytes
  - 额外减少: ~5,000 instances

**阶段 1 总计预期减少**: ~145,000 instances (33%)

### 阶段 2: 综合优化策略

#### 2.1 创建优化的综合脚本
已创建 `synthesis/optimize_synth.tcl` 包含:
- 完整的 Yosys 优化流程
- 资源共享和逻辑简化
- MUX 树优化
- 寄存器优化

**预期减少**: ~90,000 instances (20%)

### 阶段 3: 进一步优化建议

#### 3.1 可选的架构优化
如果需要进一步减少 instances:

1. **禁用功能模块**:
   - 禁用 Debug Module: `enableDebug = false`
   - 禁用 Float: `enableFloat = false`
   - 禁用 RVV: `enableRvv = false`
   - 禁用 Verification: `enableVerification = false`

2. **进一步减少数据宽度**:
   - LSU 数据宽度: 128 bits → 64 bits
   - 需要评估性能影响

3. **减少缓存大小**:
   - L1I slots: 256 → 128
   - L1D slots: 256 → 128
   - Fetch cache: 1024 → 512 bytes

## 优化效果预测

| 优化阶段 | 减少 Instances | 剩余 Instances | 完成度 |
|---------|---------------|---------------|--------|
| 初始状态 | 0 | 440,344 | 0% |
| RTL 参数优化 | 145,000 | 295,344 | 33% |
| 综合优化 | 90,000 | 205,344 | 53% |
| 架构优化 (可选) | 105,344 | 100,000 | 77% |

## 实施步骤

### 立即执行
1. ✅ 修改 Parameters.scala 中的关键参数
2. ✅ 更新 CoreAxi.scala 中的 TCM 大小
3. ✅ 创建优化的综合脚本
4. ⏳ 重新综合并验证结果

### 短期执行 (如果需要)
1. 评估功能需求，决定是否禁用某些模块
2. 进一步减少缓存大小
3. 优化数据路径宽度

### 验证要求
- 运行现有测试套件确保功能正确
- 检查时序是否满足要求
- 评估性能影响

## 风险评估

### 低风险
- ✅ 参数调整 (已实施)
- ✅ 综合优化脚本 (已实施)

### 中风险
- TCM 大小减少可能影响某些应用
- 数据宽度减少可能影响性能

### 高风险
- 禁用功能模块需要确认需求
- 过度优化可能导致时序违例

## 下一步行动

1. 使用新参数重新生成 Verilog
2. 运行优化的综合脚本
3. 分析新的 instance 统计
4. 根据结果决定是否需要阶段 3 优化
