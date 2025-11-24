#!/bin/bash
# 第三轮优化自动化脚本

set -e

echo "=========================================="
echo "CoreMiniAxi 第三轮优化"
echo "=========================================="
echo ""
echo "当前状态: 304,749 instances"
echo "目标: 降低到 ~200,000 instances"
echo ""
echo "将应用以下优化:"
echo "1. LSU 数据宽度: 128 → 64"
echo "2. L1 Cache Slots: 256 → 128"
echo "3. Fetch Cache: 1024 → 512"
echo "4. 禁用 FetchL0 缓存"
echo ""
read -p "继续? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 1
fi

cd /opt/github/coralnpu

# 备份原始文件
echo "备份原始文件..."
cp hdl/chisel/src/coralnpu/Parameters.scala hdl/chisel/src/coralnpu/Parameters.scala.round2.bak

# 应用优化
echo ""
echo "应用优化..."

# 1. LSU 数据宽度: 128 → 64
echo "1. LSU 数据宽度: 128 → 64"
sed -i 's/var lsuDataBits = 128/var lsuDataBits = 64/' hdl/chisel/src/coralnpu/Parameters.scala

# 2. L1 Cache Slots: 256 → 128
echo "2. L1 Cache Slots: 256 → 128"
sed -i 's/val l1islots = 256/val l1islots = 128/' hdl/chisel/src/coralnpu/Parameters.scala
sed -i 's/val l1dslots = 256/val l1dslots = 128/' hdl/chisel/src/coralnpu/Parameters.scala

# 3. Fetch Cache: 1024 → 512
echo "3. Fetch Cache: 1024 → 512"
sed -i 's/val fetchCacheBytes = 1024/val fetchCacheBytes = 512/' hdl/chisel/src/coralnpu/Parameters.scala

# 4. 禁用 FetchL0
echo "4. 禁用 FetchL0 缓存"
sed -i 's/var enableFetchL0 = true/var enableFetchL0 = false/' hdl/chisel/src/coralnpu/Parameters.scala

echo ""
echo "✓ 优化已应用"
echo ""

# 验证修改
echo "验证修改..."
echo "lsuDataBits: $(grep 'var lsuDataBits' hdl/chisel/src/coralnpu/Parameters.scala)"
echo "l1islots: $(grep 'val l1islots' hdl/chisel/src/coralnpu/Parameters.scala)"
echo "l1dslots: $(grep 'val l1dslots' hdl/chisel/src/coralnpu/Parameters.scala)"
echo "fetchCacheBytes: $(grep 'val fetchCacheBytes' hdl/chisel/src/coralnpu/Parameters.scala)"
echo "enableFetchL0: $(grep 'var enableFetchL0' hdl/chisel/src/coralnpu/Parameters.scala)"
echo ""

# 重新生成 Verilog
echo "=========================================="
echo "重新生成 Verilog..."
echo "=========================================="
echo ""

cd synthesis
./generate_minimal.sh

echo ""
echo "=========================================="
echo "开始综合..."
echo "=========================================="
echo ""

# 创建新的结果目录
export RESULT_DIR="result_round3"
mkdir -p ${RESULT_DIR}

# 修改 synth_minimal.sh 使用新的结果目录
sed "s/result_minimal/result_round3/g" synth_minimal.sh > synth_round3.sh
chmod +x synth_round3.sh

# 运行综合
./synth_round3.sh

echo ""
echo "=========================================="
echo "第三轮优化完成！"
echo "=========================================="
echo ""

# 显示结果
if [ -f "result_round3/generic_stat.json" ]; then
    instances=$(grep -o '"num_cells":[[:space:]]*[0-9]*' result_round3/generic_stat.json | head -1 | grep -o '[0-9]*')
    if [ ! -z "$instances" ]; then
        echo "结果统计:"
        echo "  Round 2: 304,749 instances"
        echo "  Round 3: $instances instances"
        
        diff=$((304749 - instances))
        diff_pct=$(echo "scale=1; $diff * 100 / 304749" | bc)
        
        baseline=440344
        total_reduction=$((baseline - instances))
        total_pct=$(echo "scale=1; $total_reduction * 100 / $baseline" | bc)
        
        target=100000
        remaining=$((instances - target))
        
        echo ""
        echo "  本轮减少: $diff instances ($diff_pct%)"
        echo "  总计减少: $total_reduction instances ($total_pct%)"
        echo "  距离目标: $remaining instances"
        echo ""
        
        if [ $instances -le 200000 ]; then
            echo "🎉 已达到 200,000 目标！"
        elif [ $instances -le 250000 ]; then
            echo "✓ 接近 200,000 目标"
        else
            echo "⚠️  还需要进一步优化"
        fi
    fi
fi

echo ""
echo "备份文件位置: hdl/chisel/src/coralnpu/Parameters.scala.round2.bak"
echo "如需恢复: mv hdl/chisel/src/coralnpu/Parameters.scala.round2.bak hdl/chisel/src/coralnpu/Parameters.scala"
