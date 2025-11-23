# CoreMiniAxi 源代码修改指南

本文档详细说明需要在源代码中进行的修改以实现优化目标。

---

## 文件 1: hdl/chisel/src/coralnpu/Parameters.scala

### 修改 1: 指令通道数 (第 60 行)

**当前代码**:
```scala
val instructionLanes = 4  // Reduced from 4 to 2 for area optimization
```

**修改为**:
```scala
val instructionLanes = 2  // Reduced from 4 to 2 for area optimization
```

**影响**: 减少并行指令处理能力，降低面积
**预期减少**: ~30,000 instances

---

### 修改 2: RVV 向量长度 (第 66 行)

**当前代码**:
```scala
val rvvVlen = 64  // Reduced from 128 to 64 for area optimization
```

**已经是优化值**: ✅ 无需修改 (如果当前是 128，改为 64)

**影响**: 减少向量处理单元大小
**预期减少**: ~50,000 instances (如果启用 RVV)

---

### 修改 3: Fetch 数据宽度 (第 79 行)

**当前代码**:
```scala
var fetchDataBits = 128  // Reduced from 256 to 128 for area optimization
```

**已经是优化值**: ✅ 无需修改 (如果当前是 256，改为 128)

**影响**: 减少取指数据路径宽度
**预期减少**: ~40,000 instances

---

### 修改 4: 内存区域定义 (第 42-46 行)

**当前代码**:
```scala
val default = Seq(
  new MemoryRegion(0x00000, 0x1000, MemoryRegionType.IMEM), // ITCM - Reduced from 8KB to 4KB
  new MemoryRegion(0x10000, 0x2000, MemoryRegionType.DMEM), // DTCM - Reduced from 32KB to 8KB
  new MemoryRegion(0x30000, 0x1000, MemoryRegionType.Peripheral), // CSR
)
```

**已经是优化值**: ✅ 无需修改

如果当前值不同，修改为:
- ITCM: `0x1000` (4KB)
- DTCM: `0x2000` (8KB)

**影响**: 减少 TCM 大小
**预期减少**: ~25,000 instances

---

## 文件 2: hdl/chisel/src/coralnpu/CoreAxi.scala

### 修改 1: ITCM 大小 (第 113 行)

**当前代码**:
```scala
val itcmSizeBytes: Int = 1024 * (if (p.tcmHighmem) { 1024 } else { 4 }) // Reduced from 8 kB to 4 kB for area optimization, highmem 1MB
```

**已经是优化值**: ✅ 无需修改

如果当前值是 8，修改为:
```scala
val itcmSizeBytes: Int = 1024 * (if (p.tcmHighmem) { 1024 } else { 4 })
```

**影响**: ITCM 从 8KB 减少到 4KB
**预期减少**: ~10,000 instances

---

### 修改 2: DTCM 大小 (第 137 行)

**当前代码**:
```scala
val dtcmSizeBytes: Int = 1024 * (if (p.tcmHighmem) { 1024 } else { 8 }) // Reduced from 32 kB to 8 kB for area optimization, highmem 1MB
```

**已经是优化值**: ✅ 无需修改

如果当前值是 32，修改为:
```scala
val dtcmSizeBytes: Int = 1024 * (if (p.tcmHighmem) { 1024 } else { 8 })
```

**影响**: DTCM 从 32KB 减少到 8KB
**预期减少**: ~15,000 instances

---

## 快速修改脚本

如果需要批量修改，可以使用以下脚本:

```bash
#!/bin/bash
# 自动应用优化修改

# 备份原始文件
cp hdl/chisel/src/coralnpu/Parameters.scala hdl/chisel/src/coralnpu/Parameters.scala.bak
cp hdl/chisel/src/coralnpu/CoreAxi.scala hdl/chisel/src/coralnpu/CoreAxi.scala.bak

# 修改 Parameters.scala
sed -i 's/val instructionLanes = 4/val instructionLanes = 2/' hdl/chisel/src/coralnpu/Parameters.scala
sed -i 's/val rvvVlen = 128/val rvvVlen = 64/' hdl/chisel/src/coralnpu/Parameters.scala
sed -i 's/var fetchDataBits = 256/var fetchDataBits = 128/' hdl/chisel/src/coralnpu/Parameters.scala

# 修改 CoreAxi.scala
sed -i 's/1024 \* 8 \/\/ Reduced from 8 kB/1024 * 4 \/\/ Reduced from 8 kB/' hdl/chisel/src/coralnpu/CoreAxi.scala
sed -i 's/1024 \* 32 \/\/ Reduced from 32 kB/1024 * 8 \/\/ Reduced from 32 kB/' hdl/chisel/src/coralnpu/CoreAxi.scala

echo "修改完成！原始文件已备份为 .bak"
```

**注意**: 使用前请仔细检查，确保不会覆盖已有的优化。

---

## 验证修改

修改后，验证更改:

```bash
# 检查 Parameters.scala
grep "instructionLanes" hdl/chisel/src/coralnpu/Parameters.scala
grep "rvvVlen" hdl/chisel/src/coralnpu/Parameters.scala
grep "fetchDataBits" hdl/chisel/src/coralnpu/Parameters.scala

# 检查 CoreAxi.scala
grep "itcmSizeBytes" hdl/chisel/src/coralnpu/CoreAxi.scala
grep "dtcmSizeBytes" hdl/chisel/src/coralnpu/CoreAxi.scala
```

---

## 可选的进一步优化

如果需要更激进的优化，考虑以下修改:

### 选项 A: 禁用功能模块

在 `Parameters.scala` 中添加或修改:

```scala
var enableDebug = false      // 禁用调试模块
var enableFloat = false      // 禁用浮点
var enableRvv = false        // 禁用 RVV
var enableVerification = false  // 禁用验证逻辑
```

**预期减少**: ~50,000 instances
**风险**: 功能受限

---

### 选项 B: 进一步减少数据宽度

```scala
var lsuDataBits = 64         // 从 128 减少到 64
var fetchDataBits = 64       // 从 128 减少到 64 (如果还未修改)
```

**预期减少**: ~30,000 instances
**风险**: 性能显著下降

---

### 选项 C: 减少缓存大小

```scala
val fetchCacheBytes = 512    // 从 1024 减少到 512
val l1islots = 128           // 从 256 减少到 128
val l1dslots = 128           // 从 256 减少到 128
```

**预期减少**: ~20,000 instances
**风险**: 缓存命中率下降

---

## 修改总结

### 必须修改 (达到基本优化目标)

| 文件 | 参数 | 原值 | 新值 | 减少 |
|------|------|------|------|------|
| Parameters.scala | instructionLanes | 4 | 2 | ~30K |
| Parameters.scala | rvvVlen | 128 | 64 | ~50K |
| Parameters.scala | fetchDataBits | 256 | 128 | ~40K |
| CoreAxi.scala | itcmSizeBytes | 8KB | 4KB | ~10K |
| CoreAxi.scala | dtcmSizeBytes | 32KB | 8KB | ~15K |

**总计**: ~145,000 instances (33%)

### 可选修改 (达到最终目标)

根据需要选择性应用，以达到 100,000 instances 的目标。

---

## 下一步

1. ✅ 审查本文档
2. ⏳ 应用必须的修改
3. ⏳ 重新生成 Verilog
4. ⏳ 运行综合优化
5. ⏳ 评估结果
6. ⏳ 根据需要应用可选修改

---

## 注意事项

- 修改前建议备份原始文件
- 修改后需要重新编译和测试
- 某些修改可能影响性能
- 建议分阶段应用并验证

---

**最后更新**: 2024年
**版本**: 1.0
