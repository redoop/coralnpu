# 第三轮优化方案

## 当前状态

- **第一轮** (RTL优化 + Float): 330,041 instances
- **第二轮** (禁用 Float): 304,749 instances
- **Float 模块**: 25,292 instances (7.6%)
- **已减少**: 135,595 instances (30.7%)
- **距离目标**: 204,749 instances (46.4%)

## 第三轮优化策略

### 组合优化方案

同时应用以下优化以达到最大效果：

1. **减少数据宽度**: lsuDataBits 128 → 64
2. **减少 Fetch 宽度**: fetchDataBits 128 → 64
3. **减少缓存大小**: l1islots/l1dslots 256 → 128
4. **减少 Fetch Cache**: fetchCacheBytes 1024 → 512
5. **禁用 FetchL0**: enableFetchL0 = false

### 预期效果

| 优化项 | 预期减少 |
|--------|----------|
| LSU 64-bit | ~30,000 |
| Fetch 64-bit | ~20,000 |
| 缓存减半 | ~20,000 |
| Fetch Cache 减半 | ~5,000 |
| 禁用 FetchL0 | ~10,000 |
| **总计** | **~85,000** |

**预期结果**: 304,749 - 85,000 = **~220,000 instances**

## 实施步骤

1. 修改 Parameters.scala
2. 重新生成 Verilog
3. 运行综合
4. 分析结果

如果还不够，第四轮考虑：
- 减少指令通道 (2 → 1): ~15,000
- 进一步减少 TCM: ~10,000
- 预期: ~195,000 instances
