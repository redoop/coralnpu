#!/bin/bash
# CoreMiniAxi 自动优化脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}CoreMiniAxi 优化流程${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 检查必要的工具
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}错误: $1 未安装${NC}"
        exit 1
    fi
}

echo "检查必要工具..."
check_tool yosys
check_tool python3
echo -e "${GREEN}✓ 所有工具已就绪${NC}"
echo ""

# 检查输入文件
if [ ! -f "CoreMiniAxi.sv" ]; then
    echo -e "${YELLOW}警告: 当前目录没有 CoreMiniAxi.sv${NC}"
    echo "请先生成 Verilog 文件或复制到当前目录"
    echo ""
    echo "建议命令:"
    echo "  bazel build //hdl/chisel/src/coralnpu:core_mini_axi_verilog"
    echo "  cp bazel-bin/hdl/chisel/src/coralnpu/CoreMiniAxi.sv synthesis/"
    exit 1
fi

# 选择优化级别
echo "选择优化级别:"
echo "  1) 标准优化 (推荐)"
echo "  2) 激进优化"
echo "  3) 两者都运行"
echo ""
read -p "请选择 [1-3]: " choice

run_standard=false
run_aggressive=false

case $choice in
    1)
        run_standard=true
        ;;
    2)
        run_aggressive=true
        ;;
    3)
        run_standard=true
        run_aggressive=true
        ;;
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac

# 运行标准优化
if [ "$run_standard" = true ]; then
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}运行标准优化...${NC}"
    echo -e "${GREEN}======================================${NC}"
    
    if yosys -s optimize_synth.tcl > optimize_synth.log 2>&1; then
        echo -e "${GREEN}✓ 标准优化完成${NC}"
        
        # 提取统计信息
        if [ -f "optimized_stat.json" ]; then
            instances=$(python3 -c "import json; data=json.load(open('optimized_stat.json')); print(data['modules']['CoreMiniAxi']['num_cells'])" 2>/dev/null || echo "N/A")
            echo "  总 Instances: $instances"
        fi
    else
        echo -e "${RED}✗ 标准优化失败${NC}"
        echo "查看 optimize_synth.log 了解详情"
    fi
fi

# 运行激进优化
if [ "$run_aggressive" = true ]; then
    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}运行激进优化...${NC}"
    echo -e "${GREEN}======================================${NC}"
    
    if yosys -s aggressive_optimize.tcl > aggressive_optimize.log 2>&1; then
        echo -e "${GREEN}✓ 激进优化完成${NC}"
        
        # 提取统计信息
        if [ -f "aggressive_stat.json" ]; then
            instances=$(python3 -c "import json; data=json.load(open('aggressive_stat.json')); print(data['modules']['CoreMiniAxi']['num_cells'])" 2>/dev/null || echo "N/A")
            echo "  总 Instances: $instances"
        fi
    else
        echo -e "${RED}✗ 激进优化失败${NC}"
        echo "查看 aggressive_optimize.log 了解详情"
    fi
fi

# 比较结果
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}结果比较${NC}"
echo -e "${GREEN}======================================${NC}"

baseline="../r2g_synth_1107/result/synth_stat.json"
if [ ! -f "$baseline" ]; then
    baseline="../doc/optimization/synth_stat.json"
fi

if [ -f "$baseline" ]; then
    results=""
    [ -f "optimized_stat.json" ] && results="$results optimized_stat.json"
    [ -f "aggressive_stat.json" ] && results="$results aggressive_stat.json"
    
    if [ -n "$results" ]; then
        python3 compare_results.py $baseline $results
    fi
else
    echo -e "${YELLOW}警告: 找不到基线统计文件${NC}"
    echo "无法进行比较"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}优化完成！${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "生成的文件:"
[ -f "optimized_CoreMiniAxi.v" ] && echo "  - optimized_CoreMiniAxi.v (标准优化网表)"
[ -f "optimized_stat.json" ] && echo "  - optimized_stat.json (标准优化统计)"
[ -f "aggressive_CoreMiniAxi.v" ] && echo "  - aggressive_CoreMiniAxi.v (激进优化网表)"
[ -f "aggressive_stat.json" ] && echo "  - aggressive_stat.json (激进优化统计)"
echo ""
echo "日志文件:"
[ -f "optimize_synth.log" ] && echo "  - optimize_synth.log"
[ -f "aggressive_optimize.log" ] && echo "  - aggressive_optimize.log"
echo ""
