# Round 4 激进综合 TCL 脚本
# 基于 yosys_optimized.tcl，增加更多优化轮次

yosys -import

# 读取文件列表
set filelist_file $::env(FILELIST)
set filelist_fp [open $filelist_file r]
set filelist_data [read $filelist_fp]
close $filelist_fp
set filelist [split $filelist_data "\n"]

# 读取 Verilog 文件
foreach file $filelist {
    if {$file != ""} {
        puts "Reading: $file"
        read_verilog -sv -DUSE_GENERIC -DSYNTHESIS $file
    }
}

# 层次化处理
hierarchy -check -top $::env(TOP_NAME)

# 第一轮优化 - 基础清理
puts "=== Round 1: Basic Optimization ==="
procs
opt -full
opt_expr -mux_undef -mux_bool
opt_merge -share_all
opt_clean -purge

# FSM 优化
puts "=== FSM Optimization ==="
fsm -expand
fsm_opt

# 第二轮优化 - FSM 后
puts "=== Round 2: Post-FSM Optimization ==="
opt -full
opt_expr -mux_undef -mux_bool
opt_reduce -full
opt_merge -share_all
opt_clean -purge

# Memory 优化
puts "=== Memory Optimization ==="
memory -nomap
memory_collect
memory_dff
opt -full

# 第三轮优化 - Memory 后
puts "=== Round 3: Post-Memory Optimization ==="
opt -full
opt_expr -mux_undef -mux_bool
opt_merge -share_all
opt_clean -purge

# 展平设计（可选，根据 KEEP_HIERARCHY 决定）
if {$::env(KEEP_HIERARCHY) == "false"} {
    puts "=== Flattening Design ==="
    flatten
    opt -full
    opt_merge -share_all
    opt_clean -purge
}

# 第四轮优化 - 展平后
puts "=== Round 4: Post-Flatten Optimization ==="
opt -full
opt_expr -mux_undef -mux_bool
opt_reduce -full
opt_merge -share_all
opt_clean -purge

# 技术映射前的统计
puts "=== Generic Statistics ==="
tee -o $::env(GENERIC_STAT_JSON) stat -json

# 技术映射
puts "=== Technology Mapping ==="
techmap -map +/techmap.v
opt -fast

# ABC 优化 - 多轮激进优化
puts "=== ABC Optimization Round 1 ==="
abc -g AND,NAND,OR,NOR -fast
opt -fast

puts "=== ABC Optimization Round 2 ==="
abc -g AND,NAND,OR,NOR -fast
opt -fast

puts "=== ABC Optimization Round 3 ==="
abc -g AND,NAND,OR,NOR -fast
opt -fast

# 第五轮优化 - ABC 后
puts "=== Round 5: Post-ABC Optimization ==="
opt -full
opt_expr -mux_undef -mux_bool
opt_merge -share_all
opt_clean -purge

# 使用标准单元库进行综合
puts "=== Synthesis with Standard Cells ==="
set lib_files [split $::env(LIB_ALL)]
foreach lib $lib_files {
    if {$lib != ""} {
        puts "Reading liberty: $lib"
        read_liberty -lib $lib
    }
}

# DFFlibmap - handle multiple liberty files
set lib_files [split $::env(LIB_STDCELL)]
set first_lib [lindex $lib_files 0]
dfflibmap -liberty $first_lib

# ABC 映射到标准单元
puts "=== ABC Mapping to Standard Cells ==="
set lib_files [split $::env(LIB_STDCELL)]
set first_lib [lindex $lib_files 0]
# Create empty constraint file if it doesn't exist
set constr_file "$::env(RESULT_DIR)/tmp/abc.constr"
if {![file exists $constr_file]} {
    set fp [open $constr_file w]
    close $fp
}
abc -liberty $first_lib -constr $constr_file -D [expr {1000.0 / $::env(CLK_FREQ_MHZ)}]

# 最终优化
puts "=== Final Optimization ==="
opt -full
opt_expr -mux_undef -mux_bool
opt_merge -share_all
opt_clean -purge

# 清理未使用的单元
clean -purge

# 统计
puts "=== Final Statistics ==="
set lib_files [split $::env(LIB_STDCELL)]
set first_lib [lindex $lib_files 0]
tee -o $::env(SYNTH_STAT_JSON) stat -json -liberty $first_lib
tee -o $::env(TIMING_CELL_STAT_RPT) stat -liberty $first_lib
tee -o $::env(TIMING_CELL_COUNT_RPT) select -count t:*

# 检查
tee -o $::env(SYNTH_CHECK_RPT) check

# 写出网表
write_verilog -noattr -noexpr $::env(NETLIST_FILE)

puts "=== Synthesis Complete ==="
