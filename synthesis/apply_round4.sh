#!/bin/bash

# Round 4 优化应用脚本
# 目标: 减少到 ~200,000 instances

echo "=== Round 4 优化配置 ==="
echo ""
echo "优化项:"
echo "1. instructionLanes: 2 → 1"
echo "2. fetchDataBits: 128 → 64"
echo "3. l1islots: 128 → 64"
echo "4. l1dslots: 128 → 64"
echo "5. ITCM: 4KB → 2KB"
echo "6. DTCM: 8KB → 4KB"
echo ""
echo "预期减少: ~105,000 instances (35%)"
echo "目标: ~200,000 instances"
echo ""

# 配置已经在 Parameters.scala 和 CoreAxi.scala 中修改完成
echo "✓ 配置文件已更新"
echo ""
echo "下一步:"
echo "1. 重新生成 Verilog: cd synthesis && ./generate_minimal.sh"
echo "2. 运行综合: ./synth_round4.sh"
