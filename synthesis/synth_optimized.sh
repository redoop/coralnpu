#!/bin/bash
# 基于 r2g_synth_1107 的优化综合脚本

PWD=$(cd "$(dirname "$0")";pwd)

export FILELIST="${PWD}/filelist.f"
export TOP_NAME="CoreMiniAxi"
export CLK_FREQ_MHZ="100"

export RESULT_DIR="${PWD}/result"
mkdir -p ${RESULT_DIR}
mkdir -p ${RESULT_DIR}/tmp

export NETLIST_FILE="${RESULT_DIR}/${TOP_NAME}_optimized.v"
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

# 使用 r2g_synth_1107 的库文件
export LIB_STDCELL="/opt/tools/r2g_synth_1107/lib_ics55/ics55_LLSC_H7CL_ss_rcworst_1p08_125_nldm.lib /opt/tools/r2g_synth_1107/lib_ics55/ics55_LLSC_H7CR_ss_rcworst_1p08_125_nldm.lib"
export LIB_ALL=$LIB_STDCELL

echo "开始优化综合..."
echo "输入文件: $(cat ${FILELIST})"
echo "顶层模块: ${TOP_NAME}"
echo "时钟频率: ${CLK_FREQ_MHZ} MHz"
echo ""

yosys ${PWD}/yosys_optimized.tcl

echo ""
echo "综合完成！"
echo "结果目录: ${RESULT_DIR}"
echo "网表文件: ${NETLIST_FILE}"
echo "统计文件: ${SYNTH_STAT_JSON}"
