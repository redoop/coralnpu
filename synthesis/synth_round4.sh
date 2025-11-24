#!/bin/bash
# Round 4 激进综合脚本

PWD=$(cd "$(dirname "$0")";pwd)

# 使用最小化的 Verilog
export FILELIST="${PWD}/filelist_minimal.f"
export TOP_NAME="CoreMiniAxi"
export CLK_FREQ_MHZ="100"

export RESULT_DIR="${PWD}/result_round4"
mkdir -p ${RESULT_DIR}
mkdir -p ${RESULT_DIR}/tmp

export NETLIST_FILE="${RESULT_DIR}/${TOP_NAME}_round4.v"
export TIMING_CELL_STAT_RPT="${RESULT_DIR}/timing_cell_stat.rpt"
export TIMING_CELL_COUNT_RPT="${RESULT_DIR}/timing_cell_count.rpt"
export GENERIC_STAT_JSON="${RESULT_DIR}/generic_stat.json"
export SYNTH_STAT_JSON="${RESULT_DIR}/synth_stat.json"
export SYNTH_CHECK_RPT="${RESULT_DIR}/synth_check.rpt"

export KEEP_HIERARCHY="false"
export CELL_DONT_USE=""
export CELL_TIE_LOW="TIELOH7R"
export CELL_TIE_LOW_PORT="Z"
export CELL_TIE_HIGH="TIEHIH7R"
export CELL_TIE_HIGH_PORT="Z"

export LIB_STDCELL="/opt/tools/r2g_synth_1107/lib_ics55/ics55_LLSC_H7CL_ss_rcworst_1p08_125_nldm.lib /opt/tools/r2g_synth_1107/lib_ics55/ics55_LLSC_H7CR_ss_rcworst_1p08_125_nldm.lib"
export LIB_ALL=$LIB_STDCELL

echo "=========================================="
echo "Round 4 激进综合"
echo "=========================================="
echo "输入文件: $(cat ${FILELIST})"
echo "文件大小: $(ls -lh CoreMiniAxi_minimal.sv | awk '{print $5}')"
echo "顶层模块: ${TOP_NAME}"
echo "时钟频率: ${CLK_FREQ_MHZ} MHz"
echo "优化配置:"
echo "  - instructionLanes: 1"
echo "  - fetchDataBits: 64"
echo "  - lsuDataBits: 64"
echo "  - l1islots: 64"
echo "  - l1dslots: 64"
echo "  - ITCM: 2KB"
echo "  - DTCM: 4KB"
echo "=========================================="
echo ""

yosys ${PWD}/yosys_aggressive.tcl 2>&1 | tee synth_round4.log

echo ""
echo "=========================================="
echo "综合完成！"
echo "=========================================="
echo "结果目录: ${RESULT_DIR}"
echo "网表文件: ${NETLIST_FILE}"
echo "统计文件: ${SYNTH_STAT_JSON}"
echo ""

# 自动统计
if [ -f "${GENERIC_STAT_JSON}" ]; then
    instances=$(grep -o '"num_cells":[[:space:]]*[0-9]*' ${GENERIC_STAT_JSON} | head -1 | grep -o '[0-9]*')
    if [ ! -z "$instances" ]; then
        echo "=========================================="
        echo "Instance 统计"
        echo "=========================================="
        echo "总 Instances: $instances"
        
        baseline=440344
        round3=304749
        target=200000
        reduction=$((baseline - instances))
        reduction_pct=$(echo "scale=1; $reduction * 100 / $baseline" | bc)
        round4_reduction=$((round3 - instances))
        round4_pct=$(echo "scale=1; $round4_reduction * 100 / $round3" | bc)
        diff=$((instances - target))
        
        echo "基线 (Round 1): $baseline"
        echo "Round 3: $round3"
        echo "Round 4: $instances"
        echo "总减少: $reduction ($reduction_pct%)"
        echo "Round 4 减少: $round4_reduction ($round4_pct%)"
        echo "距离目标: $diff"
        echo "=========================================="
    fi
fi
