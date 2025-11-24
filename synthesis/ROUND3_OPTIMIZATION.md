# CoreMiniAxi 第三轮优化方案

## 当前状态

- **当前**: 304,749 instances
- **目标**: 100,000 instances
- **还需减少**: 204,749 instances (67.2%)

## 优化策略

### 策略 1: 减少数据宽度 (最高优先级)

#### 1.1 LSU 数据宽度: 128 → 64

**修改 Parameters.scala**:
```scala
var lsuDataBits = 64  // 从 128 减少到 64
```

**影响**:
- LSU 数据路径宽度减半
- 相关 MUX 和逻辑减少
- 内存访问需要两次操作

**预期减少**: ~40,000 instances (13%)
**性能影响**: -20-30%

#### 1.2 Fetch 数据宽度: 128 → 64

**修改 Parameters.scala**:
```scala
var fetchDataBits = 64  // 从 128 减少到 64
```

**影响**:
- 取指数据路径宽度减半
- 每次取指获取的指令数减少
- fetchInstrSlots: 4 → 2

**预期减少**: ~30,000 instances (10%)
**性能影响**: -15-20%

**策略 1 总计**: ~70,000 instances (23%)
**预期结果**: ~235,000 instances

---

### 策略 2: 减少缓存大小

#### 2.1 L1 Cache Slots

**修改 Parameters.scala**:
```scala
val l1islots = 128  // 从 256 减少到 128
val l1dslots = 128  // 从 256 减少到 128
```

**影响**:
- L1 指令缓存容量减半
- L1 数据缓存容量减半
- 缓存命中率下降

**预期减少**: ~15,000 instances (5%)
**性能影响**: -10-15%

#### 2.2 Fetch Cache

**修改 Parameters.scala**:
```scala
val fetchCacheBytes = 512  // 从 1024 减少到 512
```

**影响**:
- L0 取指缓存容量减半

**预期减少**: ~5,000 instances (2%)
**性能影响**: -5%

**策略 2 总计**: ~20,000 instances (7%)
**预期结果**: ~215,000 instances

---

### 策略 3: 禁用 FetchL0 缓存

**修改 Parameters.scala**:
```scala
var enableFetchL0 = false  // 从 true 改为 false
```

**影响**:
- 移除 L0 取指缓存
- 直接从 ITCM 或内存取指

**预期减少**: ~10,000 instances (3%)
**性能影响**: -5-10%

**策略 3 总计**: ~10,000 instances (3%)
**预期结果**: ~205,000 instances

---

### 策略 4: 减少指令通道

**修改 Parameters.scala**:
```scala
val instructionLanes = 1  // 从 2 减少到 1
```

**影响**:
- 单指令通道，无并行处理
- Dispatch 逻辑简化

**预期减少**: ~20,000 instances (7%)
**性能影响**: -30-40%

**策略 4 总计**: ~20,000 instances (7%)
**预期结果**: ~185,000 instances

---

### 策略 5: 进一步减少 TCM

#### 5.1 ITCM: 4KB → 2KB

**修改 CoreAxi.scala**:
```scala
val itcmSizeBytes: Int = 1024 * 2  // 从 4KB 减少到 2KB
```

**修改 Parameters.scala**:
```scala
new MemoryRegion(0x00000, 0x800, MemoryRegionType.IMEM)  // 2KB
```

**预期减少**: ~5,000 instances (2%)

#### 5.2 DTCM: 8KB → 4KB

**修改 CoreAxi.scala**:
```scala
val dtcmSizeBytes: Int = 1024 * 4  // 从 8KB 减少到 4KB
```

**修改 Parameters.scala**:
```scala
new MemoryRegion(0x10000, 0x1000, MemoryRegionType.DMEM)  // 4KB
```

**预期减少**: ~5,000 instances (2%)

**策略 5 总计**: ~10,000 instances (3%)
**预期结果**: ~175,000 instances

---

### 策略 6: 激进综合优化

**创建新的综合脚本**:
- 多次迭代 opt 命令 (3-5 次)
- 使用更激进的 ABC 参数
- 调整 MUX 优化策略
- 使用 flatten 后再次优化

**预期减少**: ~15,000 instances (5%)
**预期结果**: ~160,000 instances

---

## 组合优化路径

### 路径 A: 保守 (保留基本性能)

| 步骤 | 优化 | Instances | 累计减少 | 性能影响 |
|------|------|-----------|----------|----------|
| 当前 | Round 2 | 304,749 | 30.7% | -5% |
| 1 | 减少缓存 | ~285,000 | 35% | -15% |
| 2 | 禁用 FetchL0 | ~275,000 | 38% | -20% |
| 3 | 激进综合 | ~260,000 | 41% | -20% |

**结论**: 无法达到 100,000

---

### 路径 B: 激进 (牺牲部分性能)

| 步骤 | 优化 | Instances | 累计减少 | 性能影响 |
|------|------|-----------|----------|----------|
| 当前 | Round 2 | 304,749 | 30.7% | -5% |
| 1 | LSU 64-bit | ~265,000 | 40% | -25% |
| 2 | Fetch 64-bit | ~235,000 | 47% | -40% |
| 3 | 减少缓存 | ~215,000 | 51% | -50% |
| 4 | 禁用 FetchL0 | ~205,000 | 53% | -55% |
| 5 | 激进综合 | ~190,000 | 57% | -55% |

**结论**: 无法达到 100,000

---

### 路径 C: 极限 (最小可用配置)

| 步骤 | 优化 | Instances | 累计减少 | 性能影响 |
|------|------|-----------|----------|----------|
| 当前 | Round 2 | 304,749 | 30.7% | -5% |
| 1 | LSU 64-bit | ~265,000 | 40% | -25% |
| 2 | Fetch 64-bit | ~235,000 | 47% | -40% |
| 3 | 指令通道=1 | ~215,000 | 51% | -70% |
| 4 | 减少缓存 | ~195,000 | 56% | -80% |
| 5 | 禁用 FetchL0 | ~185,000 | 58% | -85% |
| 6 | 减少 TCM | ~175,000 | 60% | -85% |
| 7 | 激进综合 | ~160,000 | 64% | -85% |

**结论**: 仍无法达到 100,000

---

## 达到 100,000 的必要条件

要达到 100,000 instances，需要：

### 1. 架构级简化 (~30,000 instances)
- 简化 LSU (移除 scatter/gather)
- 简化 Dispatch (移除多发射)
- 简化 CSR (只保留必要寄存器)
- 简化 Fault Manager

### 2. 移除非核心功能 (~20,000 instances)
- 移除 Debug 接口
- 移除 RVVI Trace
- 移除 SLog
- 简化 AXI 接口

### 3. 极限参数配置 (~10,000 instances)
- ITCM: 1KB
- DTCM: 2KB
- 所有缓存禁用
- 单指令通道
- 32-bit 数据路径

**总计额外减少**: ~60,000 instances
**最终预期**: ~100,000 instances

---

## 推荐方案

### 方案 1: 现实目标 (推荐)

**目标**: 200,000 instances (减少 55%)

**优化步骤**:
1. LSU 64-bit
2. 减少缓存 50%
3. 禁用 FetchL0
4. 激进综合

**时间**: 1-2 天
**性能影响**: -30-40%
**可行性**: ✅ 高

---

### 方案 2: 激进目标

**目标**: 150,000 instances (减少 66%)

**优化步骤**:
1. LSU 64-bit
2. Fetch 64-bit
3. 指令通道=1
4. 减少缓存 50%
5. 禁用 FetchL0
6. 减少 TCM
7. 激进综合

**时间**: 1 周
**性能影响**: -60-70%
**可行性**: ⚠️ 中

---

### 方案 3: 极限目标 (不推荐)

**目标**: 100,000 instances (减少 77%)

**优化步骤**:
- 方案 2 的所有步骤
- 架构级简化
- 移除非核心功能
- 极限参数配置

**时间**: 2-4 周
**性能影响**: -80-90%
**可行性**: ❌ 低

---

## 下一步行动

### 立即执行 (推荐)

实施**方案 1**的前两步:

1. **LSU 64-bit**
   ```bash
   # 修改 Parameters.scala
   sed -i 's/var lsuDataBits = 128/var lsuDataBits = 64/' hdl/chisel/src/coralnpu/Parameters.scala
   ```

2. **减少缓存**
   ```bash
   # 修改 Parameters.scala
   sed -i 's/val l1islots = 256/val l1islots = 128/' hdl/chisel/src/coralnpu/Parameters.scala
   sed -i 's/val l1dslots = 256/val l1dslots = 128/' hdl/chisel/src/coralnpu/Parameters.scala
   sed -i 's/val fetchCacheBytes = 1024/val fetchCacheBytes = 512/' hdl/chisel/src/coralnpu/Parameters.scala
   ```

3. **重新生成和综合**
   ```bash
   cd synthesis
   ./generate_minimal.sh
   ./synth_minimal.sh
   ```

**预期结果**: ~240,000 instances

---

## 结论

- **100,000 目标**: 需要架构重新设计，不推荐
- **150,000 目标**: 可行但性能损失大
- **200,000 目标**: 推荐，平衡优化和性能

**建议**: 先实施方案 1，达到 200,000 instances，然后评估是否需要进一步优化。
