# 简化的综合脚本 - 只做基本统计

# 读取设计 - 使用更宽松的选项
read_verilog -sv -defer CoreMiniAxi.sv

# 层次结构处理
hierarchy -check -top CoreMiniAxi

# 基本处理
proc

# 统计原始设计
stat -top CoreMiniAxi -json baseline_stat.json
log "基线统计已保存到 baseline_stat.json"

# 基本优化
opt -full
opt_clean -purge

# 资源共享
share -aggressive

# 位宽优化
wreduce -memx

# MUX 优化
opt_muxtree

# 逻辑简化
opt_reduce -fine -full

# 合并
opt_merge -share_all

# 清理
opt_clean -purge

# 再次优化
opt -full -fast

# 统计优化后
stat -top CoreMiniAxi -json optimized_stat.json
stat -top CoreMiniAxi -width

# 输出网表
write_verilog -noattr -noexpr optimized_CoreMiniAxi.v

log "优化完成！"
log "基线: baseline_stat.json"
log "优化后: optimized_stat.json"
