# CoreMiniAxi 优化快速开始

## 当前状态

✅ RTL 已优化  
✅ Verilog 已生成  
✅ 工具已就绪  
🔄 综合进行中

## 查看综合进度

```bash
# 实时监控
tail -f synthesis/synth_optimized.log

# 查看最后 50 行
tail -50 synthesis/synth_optimized.log

# 检查进程
ps aux | grep yosys
```

## 综合完成后

### 1. 查看结果

```bash
cd synthesis
./check_results.sh
```

### 2. 查看详细统计

```bash
cat result/synth_stat.json | jq '.modules.CoreMiniAxi'
```

### 3. 提取 instance 数量

```bash
cat result/synth_stat.json | jq '.modules.CoreMiniAxi.num_cells'
```

## 如果需要重新运行

```bash
cd synthesis
rm -rf result
./synth_optimized.sh
```

## 文件位置

- **输入**: `synthesis/CoreMiniAxi.sv`
- **脚本**: `synthesis/synth_optimized.sh`
- **日志**: `synthesis/synth_optimized.log`
- **结果**: `synthesis/result/synth_stat.json`
- **网表**: `synthesis/result/CoreMiniAxi_optimized.v`

## 优化目标

- **基线**: 440,344 instances
- **目标**: 100,000 instances
- **需减少**: 77.3%

## 预期结果

- **RTL 优化**: ~295,000 instances (减少 33%)
- **+ 综合优化**: ~205,000 instances (减少 53%)

## 进一步优化

如果结果未达到目标，参考:
- `doc/optimization/optimization_guide.md`
- `doc/optimization/OPTIMIZATION_CHECKLIST.md`

## 验证

```bash
# 运行测试
bazel test //tests/...
```

---

**详细文档**: `WORK_COMPLETED.md`
