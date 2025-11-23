# CoreMiniAxi 优化文档索引

本目录包含 CoreMiniAxi 从 440,344 instances 优化到 100,000 instances 的完整文档。

---

## 📋 快速导航

### 🚀 快速开始
1. 阅读 [优化总结](OPTIMIZATION_SUMMARY.md) 了解整体情况
2. 查看 [源代码修改指南](SOURCE_CODE_CHANGES.md) 了解需要修改的代码
3. 使用 [检查清单](OPTIMIZATION_CHECKLIST.md) 跟踪进度

### 📚 详细文档
- [优化指南](optimization_guide.md) - 完整的优化步骤和说明
- [实施计划](optimization_implementation_plan.md) - 分阶段优化策略
- [原始分析](optimization_analysis.md) - 详细的分析报告

### 🛠️ 工具
- [综合工具](../../synthesis/) - 优化脚本和分析工具
- [自动化脚本](../../synthesis/run_optimization.sh) - 一键优化

---

## 📖 文档说明

### [OPTIMIZATION_SUMMARY.md](OPTIMIZATION_SUMMARY.md)
**用途**: 快速了解优化工作
**内容**:
- 已完成的工作总结
- 使用方法
- 预期结果
- 文件清单

**适合**: 项目经理、新成员

---

### [SOURCE_CODE_CHANGES.md](SOURCE_CODE_CHANGES.md)
**用途**: 源代码修改参考
**内容**:
- 需要修改的文件和位置
- 修改前后对比
- 快速修改脚本
- 验证方法

**适合**: 开发人员

---

### [OPTIMIZATION_CHECKLIST.md](OPTIMIZATION_CHECKLIST.md)
**用途**: 跟踪优化进度
**内容**:
- 详细的检查清单
- 每个阶段的任务
- 结果记录表格
- 问题跟踪

**适合**: 执行人员、项目跟踪

---

### [optimization_guide.md](optimization_guide.md)
**用途**: 完整的优化指南
**内容**:
- 优化策略层次
- 详细步骤说明
- 风险评估
- 故障排除
- 参考资料

**适合**: 技术人员、深入了解

---

### [optimization_implementation_plan.md](optimization_implementation_plan.md)
**用途**: 实施计划
**内容**:
- 分阶段优化计划
- 预期效果分析
- 关键优化点
- 风险评估

**适合**: 技术负责人、规划

---

### [optimization_analysis.md](optimization_analysis.md)
**用途**: 原始分析报告
**内容**:
- 当前状态分析
- 详细组成分析
- 优化路径
- 技术细节

**适合**: 深入技术分析

---

## 🎯 优化目标

| 指标 | 当前值 | 目标值 | 减少量 | 减少比例 |
|------|--------|--------|--------|---------|
| Instances | 440,344 | 100,000 | 340,344 | 77.3% |

---

## 📊 优化策略

### 阶段 1: RTL 参数优化 (33%)
- 修改 Parameters.scala
- 修改 CoreAxi.scala
- 预期: 440,344 → ~295,000

### 阶段 2: 标准综合优化 (20%)
- 运行 optimize_synth.tcl
- 预期: ~295,000 → ~205,000

### 阶段 3: 激进综合优化 (5%)
- 运行 aggressive_optimize.tcl
- 预期: ~205,000 → ~185,000

### 阶段 4: 功能裁剪 (可选, 19%)
- 禁用不需要的功能
- 预期: ~185,000 → ~100,000

---

## 🚦 使用流程

### 方案 A: 自动化流程 (推荐)

```bash
# 1. 修改源代码 (参考 SOURCE_CODE_CHANGES.md)
vim hdl/chisel/src/coralnpu/Parameters.scala
vim hdl/chisel/src/coralnpu/CoreAxi.scala

# 2. 重新生成 Verilog
bazel build //hdl/chisel/src/coralnpu:core_mini_axi_verilog
cp bazel-bin/hdl/chisel/src/coralnpu/CoreMiniAxi.sv synthesis/

# 3. 运行自动化优化
cd synthesis
./run_optimization.sh
```

### 方案 B: 手动流程

参考 [optimization_guide.md](optimization_guide.md) 的详细步骤。

---

## 📁 相关文件

### 源代码
- `hdl/chisel/src/coralnpu/Parameters.scala` - 参数配置
- `hdl/chisel/src/coralnpu/CoreAxi.scala` - 核心实现

### 工具
- `synthesis/optimize_synth.tcl` - 标准优化脚本
- `synthesis/aggressive_optimize.tcl` - 激进优化脚本
- `synthesis/compare_results.py` - 结果比较工具
- `synthesis/run_optimization.sh` - 自动化脚本

### 文档
- 本目录下的所有 .md 文件

---

## ✅ 检查清单

使用前确认:
- [ ] 已阅读 OPTIMIZATION_SUMMARY.md
- [ ] 已了解需要修改的代码
- [ ] 已准备好开发环境
- [ ] 已备份原始代码

开始优化:
- [ ] 修改源代码
- [ ] 重新生成 Verilog
- [ ] 运行综合优化
- [ ] 验证结果

---

## 🆘 获取帮助

### 常见问题
参考 [optimization_guide.md](optimization_guide.md) 的故障排除部分

### 工具使用
参考 [synthesis/README.md](../../synthesis/README.md)

### 详细步骤
参考 [OPTIMIZATION_CHECKLIST.md](OPTIMIZATION_CHECKLIST.md)

---

## 📝 文档版本

- **版本**: 1.0
- **创建日期**: 2024年
- **最后更新**: 2024年
- **状态**: 完成

---

## 📞 支持

如有问题或建议，请参考:
- 项目 README: `../../README.md`
- 集成指南: `../integration_guide.md`
- 仿真指南: `../simulation.md`

---

## 🎓 学习路径

### 初学者
1. OPTIMIZATION_SUMMARY.md
2. SOURCE_CODE_CHANGES.md
3. synthesis/README.md

### 实施者
1. OPTIMIZATION_CHECKLIST.md
2. optimization_guide.md
3. 运行 run_optimization.sh

### 深入研究
1. optimization_analysis.md
2. optimization_implementation_plan.md
3. 研究综合脚本

---

**祝优化顺利！** 🚀
