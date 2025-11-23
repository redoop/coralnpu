# 当前状态

## 第二轮综合进行中 🔄

**配置**: 禁用 Float 模块  
**输入**: CoreMiniAxi_minimal.sv (616KB)  
**状态**: ABC 技术映射阶段  
**预计完成**: 5-10 分钟

## 查看进度

```bash
# 实时监控
tail -f synthesis/synth_minimal.log

# 查看最后 50 行
tail -50 synthesis/synth_minimal.log

# 检查进程
ps aux | grep yosys
```

## 完成后自动比较

```bash
cd synthesis
./wait_and_compare.sh
```

## 手动检查结果

```bash
# 查看统计
cat synthesis/result_minimal/generic_stat.json | grep num_cells

# 运行比较脚本
cd synthesis
bash instance_count.sh result_minimal/generic_stat.json
```

## 预期结果

- **第一轮** (启用 Float): 330,041 instances
- **第二轮** (禁用 Float): ~250,000 instances (预期)
- **Float 模块占用**: ~80,000 instances (预期)

## 下一步

根据第二轮结果决定:
1. 如果 < 200,000: 继续减少数据宽度和缓存
2. 如果 200,000-250,000: 评估是否需要更激进优化
3. 如果 > 250,000: 重新评估优化策略

---

**更新**: 2024-11-23 19:15
