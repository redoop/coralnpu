# CoreMiniAxi 优化综合脚本
# 目标: 将 instances 从 440,344 降低到 100,000

# 读取设计
read_verilog -sv -noassert -noassume -norestrict CoreMiniAxi.sv

# 层次结构处理
hierarchy -check -top CoreMiniAxi

# ============================================
# 阶段 1: 初始优化和清理
# ============================================
proc
opt -full
opt_clean -purge

# ============================================
# 阶段 2: 资源共享和逻辑简化
# ============================================
# 激进的资源共享
share -aggressive

# 位宽优化 - 移除未使用的高位
wreduce -memx

# 优化 MUX 树
opt_muxtree

# 逻辑简化
opt_reduce -fine -full

# 合并相同的单元
opt_merge -share_all

# 再次清理
opt_clean -purge

# ============================================
# 阶段 3: 表达式优化
# ============================================
# 公共子表达式消除
opt_expr -mux_undef -mux_bool -undriven -noclkinv

# 深度优化
opt -full -fast

# ============================================
# 阶段 4: FSM 和内存优化
# ============================================
# FSM 提取和优化
fsm -nomap
fsm_opt
fsm_recode -encoding one-hot

# 内存优化
memory -nomap
memory_collect
memory_dff
memory_share
memory_narrow
memory_map

# ============================================
# 阶段 5: 技术映射前的最终优化
# ============================================
# 再次进行完整优化
opt -full -fast

# 清理未使用的信号
clean -purge

# 优化 MUX (再次)
opt_muxtree

# 逻辑最小化
opt_reduce -fine -full

# ============================================
# 阶段 6: ABC 逻辑优化
# ============================================
# 使用 ABC 进行高级逻辑优化
# -g: 使用 AND-INVERTER 图
# -fast: 快速模式
abc -g AND -fast

# ============================================
# 阶段 7: 技术映射
# ============================================
# 假设使用标准单元库 (需要根据实际库调整)
# dfflibmap -liberty your_library.lib
# abc -liberty your_library.lib

# 如果没有库文件，使用通用映射
techmap

# ============================================
# 阶段 8: 映射后优化
# ============================================
opt -fast
opt_clean -purge

# ============================================
# 阶段 9: 统计和输出
# ============================================
# 生成统计报告
stat -top CoreMiniAxi -json optimized_stat.json
stat -top CoreMiniAxi -width

# 检查设计
check

# 输出优化后的网表
write_verilog -noattr -noexpr -nohex -nodec optimized_CoreMiniAxi.v

# 输出 JSON 格式 (用于进一步分析)
write_json optimized_CoreMiniAxi.json

# 完成
log "优化完成！请检查 optimized_stat.json 查看结果"
