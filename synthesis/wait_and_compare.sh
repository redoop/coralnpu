#!/bin/bash
# 等待综合完成并比较结果

echo "等待最小化配置综合完成..."
echo ""

# 等待进程完成
while ps aux | grep -v grep | grep "yosys.*yosys_optimized.tcl" > /dev/null; do
    echo -n "."
    sleep 5
done

echo ""
echo "综合完成！"
echo ""

# 比较结果
echo "=========================================="
echo "优化结果对比"
echo "=========================================="
echo ""

# 原始配置 (带 Float)
if [ -f "result/generic_stat.json" ]; then
    instances_float=$(grep -o '"num_cells":[[:space:]]*[0-9]*' result/generic_stat.json | head -1 | grep -o '[0-9]*')
    echo "配置 1 (启用 Float): $instances_float instances"
fi

# 最小化配置 (禁用 Float)
if [ -f "result_minimal/generic_stat.json" ]; then
    instances_minimal=$(grep -o '"num_cells":[[:space:]]*[0-9]*' result_minimal/generic_stat.json | head -1 | grep -o '[0-9]*')
    echo "配置 2 (禁用 Float): $instances_minimal instances"
    
    if [ ! -z "$instances_float" ] && [ ! -z "$instances_minimal" ]; then
        diff=$((instances_float - instances_minimal))
        diff_pct=$(echo "scale=1; $diff * 100 / $instances_float" | bc)
        echo ""
        echo "Float 模块占用: $diff instances ($diff_pct%)"
    fi
fi

echo ""
echo "=========================================="
echo "距离目标分析"
echo "=========================================="
echo ""

baseline=440344
target=100000

if [ ! -z "$instances_minimal" ]; then
    reduction=$((baseline - instances_minimal))
    reduction_pct=$(echo "scale=1; $reduction * 100 / $baseline" | bc)
    remaining=$((instances_minimal - target))
    remaining_pct=$(echo "scale=1; $remaining * 100 / $baseline" | bc)
    
    echo "基线: $baseline instances"
    echo "当前: $instances_minimal instances"
    echo "已减少: $reduction instances ($reduction_pct%)"
    echo "距离目标: $remaining instances (还需减少 $remaining_pct%)"
    echo ""
    
    if [ $instances_minimal -le $target ]; then
        echo "🎉 已达到优化目标！"
    else
        echo "⚠️  还需要进一步优化"
        echo ""
        echo "建议:"
        echo "1. 进一步减少数据宽度 (lsuDataBits 128→64)"
        echo "2. 减少缓存大小 (l1islots/l1dslots 256→128)"
        echo "3. 禁用 FetchL0 缓存"
        echo "4. 减少指令通道 (instructionLanes 2→1)"
    fi
fi

echo ""
echo "=========================================="
