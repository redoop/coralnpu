# Round 4 优化方案

## 当前状态 (Round 3)
- **当前**: ~304,749 instances
- **配置**:
  - instructionLanes: 2
  - fetchDataBits: 128
  - lsuDataBits: 64
  - l1islots: 128
  - l1dslots: 128
  - fetchCacheBytes: 512
  - enableFetchL0: false

## Round 4 优化目标
**目标**: 减少到 ~200,000 instances (减少 35%)

## 优化策略

### 1. 减少 Fetch 数据宽度: 128 → 64
- fetchDataBits: 128 → 64
- fetchInstrSlots: 4 → 2
- 预期减少: ~30,000 instances (10%)

### 2. 单指令通道
- instructionLanes: 2 → 1
- 预期减少: ~25,000 instances (8%)

### 3. 进一步减少缓存
- l1islots: 128 → 64
- l1dslots: 128 → 64
- 预期减少: ~15,000 instances (5%)

### 4. 减少 TCM 大小
- ITCM: 4KB → 2KB
- DTCM: 8KB → 4KB
- 预期减少: ~10,000 instances (3%)

### 5. 激进综合优化
- 多轮 opt 优化
- 更激进的 ABC 参数
- 预期减少: ~25,000 instances (8%)

**总计预期减少**: ~105,000 instances (35%)
**目标结果**: ~200,000 instances

## 性能影响评估
- 取指带宽: -50%
- 指令并行度: -50%
- 缓存命中率: -10-15%
- 整体性能: -40-50%

## 实施步骤
1. 修改 Parameters.scala
2. 修改 CoreAxi.scala (TCM 大小)
3. 重新生成 Verilog
4. 使用激进综合脚本
5. 验证结果
