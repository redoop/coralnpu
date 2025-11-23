# CoreMiniAxi 优化综合状态

## 当前状态

**综合正在进行中...**

### 已完成的步骤

1. ✅ 修改 RTL 参数
   - instructionLanes: 4 → 2
   - rvvVlen: 128 → 64  
   - fetchDataBits: 256 → 128
   - ITCM: 8KB → 4KB
   - DTCM: 32KB → 8KB

2. ✅ 重新生成 Verilog
   - 使用 Bazel 构建系统
   - 生成的文件: CoreMiniAxi.sv (1.2MB)

3. ✅ 创建优化综合脚本
   - 基于 /opt/tools/r2g_synth_1107 配置
   - 使用 Yosys + slang 插件
   - 使用 ICS55 标准单元库

4. 🔄 运行优化综合
   - 当前阶段: DFF 优化
   - 预计完成时间: 待定

### 综合配置

- **顶层模块**: CoreMiniAxi
- **时钟频率**: 100 MHz
- **标准单元库**: ICS55 LLSC H7CL/H7CR
- **工艺角**: ss_rcworst_1p08_125
- **层次展平**: 是

### 优化策略

1. 粗粒度优化
   - FSM 优化
   - 位宽缩减 (wreduce)
   - 资源共享 (share)
   - 内存映射

2. 深度优化
   - 层次展平
   - MUX 树优化
   - 逻辑简化
   - 单元合并

3. 技术映射
   - 触发器映射 (dfflibmap)
   - ABC 逻辑优化
   - 时序约束应用

### 预期结果

基于 RTL 参数优化:
- **基线**: 440,344 instances
- **预期**: ~295,000 instances (减少 33%)
- **目标**: 100,000 instances

加上综合优化:
- **预期**: ~205,000 instances (减少 53%)

### 下一步

1. 等待综合完成
2. 分析结果统计
3. 如果未达到目标，考虑:
   - 激进优化策略
   - 功能裁剪
   - 架构优化

### 文件位置

- **输入**: synthesis/CoreMiniAxi.sv
- **脚本**: synthesis/yosys_optimized.tcl
- **日志**: synthesis/synth_optimized.log
- **结果**: synthesis/result/
  - synth_stat.json (统计)
  - CoreMiniAxi_optimized.v (网表)
  - generic_stat.json (通用统计)

### 监控命令

```bash
# 查看综合进度
tail -f synthesis/synth_optimized.log

# 检查结果
./synthesis/check_results.sh

# 查看进程状态
ps aux | grep yosys
```

---

**更新时间**: 2024-11-23
**状态**: 综合进行中
