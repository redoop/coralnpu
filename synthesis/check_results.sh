#!/bin/bash
# 检查综合结果

RESULT_DIR="result"

echo "检查综合结果..."
echo ""

if [ -f "${RESULT_DIR}/synth_stat.json" ]; then
    echo "✓ 综合统计文件已生成"
    
    # 提取 instance 数量
    if command -v jq &> /dev/null; then
        instances=$(jq '.modules.CoreMiniAxi.num_cells' ${RESULT_DIR}/synth_stat.json 2>/dev/null)
        if [ ! -z "$instances" ]; then
            echo ""
            echo "=========================================="
            echo "优化后的 Instance 数量: $instances"
            echo "=========================================="
            echo ""
            
            # 计算与目标的差距
            target=100000
            baseline=440344
            diff=$((instances - target))
            reduction=$((baseline - instances))
            reduction_pct=$(echo "scale=1; $reduction * 100 / $baseline" | bc)
            
            echo "基线: $baseline instances"
            echo "当前: $instances instances"
            echo "减少: $reduction instances ($reduction_pct%)"
            echo "距离目标: $diff instances"
            echo ""
            
            if [ $instances -le $target ]; then
                echo "🎉 已达到优化目标！"
            else
                remaining_pct=$(echo "scale=1; ($instances - $target) * 100 / $baseline" | bc)
                echo "还需要减少 $remaining_pct% 才能达到目标"
            fi
        fi
    else
        echo "安装 jq 以查看详细统计"
    fi
else
    echo "✗ 综合统计文件未生成"
    echo "综合可能还在进行中或失败"
fi

echo ""
echo "文件列表:"
ls -lh ${RESULT_DIR}/ 2>/dev/null || echo "结果目录不存在"
