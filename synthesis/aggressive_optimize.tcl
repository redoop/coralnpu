# CoreMiniAxi 激进优化综合脚本
# 用于达到 100,000 instances 目标的激进优化策略

# 读取设计
yosys read_verilog -sv CoreMiniAxi.sv
yosys hierarchy -check -top CoreMiniAxi

# ============================================
# 激进优化策略
# ============================================

# 1. 初始处理
yosys proc
yosys flatten  # 展平层次结构以便更好地优化
yosys opt -full

# 2. 激进的资源共享
yosys share -aggressive -fast

# 3. 位宽优化 - 移除所有未使用的位
yosys wreduce -memx
yosys opt_reduce -fine -full

# 4. MUX 优化 - 多次迭代
yosys opt_muxtree
yosys opt_expr -mux_undef -mux_bool
yosys opt_muxtree
yosys opt_expr -mux_undef -mux_bool

# 5. 合并和清理
yosys opt_merge -share_all
yosys opt_clean -purge

# 6. 深度逻辑优化
yosys opt -full -fast
yosys opt -full -fast  # 运行两次

# 7. FSM 优化 - 使用 one-hot 编码
yosys fsm -nomap
yosys fsm_opt
yosys fsm_recode -encoding one-hot
yosys fsm_map

# 8. 内存优化
yosys memory -nomap
yosys memory_collect
yosys memory_dff -wr_only  # 只在写端口添加寄存器
yosys memory_share
yosys memory_narrow
yosys memory_map

# 9. 再次优化
yosys opt -full -fast
yosys clean -purge

# 10. 寄存器优化
yosys opt_dff -nodffe -nosdff  # 移除不必要的使能和同步复位

# 11. 逻辑最小化
yosys opt_reduce -fine -full
yosys opt_merge -share_all

# 12. ABC 优化 - 多次迭代
yosys abc -g AND -fast
yosys opt -fast
yosys abc -g AND -fast

# 13. 技术映射
yosys techmap -max_iter 3

# 14. 映射后优化
yosys opt -full -fast
yosys opt_clean -purge

# 15. 最终清理
yosys clean -purge
yosys opt -fast

# ============================================
# 统计和输出
# ============================================
yosys stat -top CoreMiniAxi -json aggressive_stat.json
yosys stat -top CoreMiniAxi -width
yosys check
yosys write_verilog -noattr -noexpr -nohex -nodec aggressive_CoreMiniAxi.v
yosys write_json aggressive_CoreMiniAxi.json

yosys log "激进优化完成！"
