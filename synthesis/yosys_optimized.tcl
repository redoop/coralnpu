# 优化的 Yosys 综合脚本
# 基于 r2g_synth_1107 配置，增加优化步骤

if {[info script] ne ""} {
    cd "[file dirname [info script]]"
}

set filelist $::env(FILELIST)
set top_design $::env(TOP_NAME)
set clk_freq_mhz $::env(CLK_FREQ_MHZ)
set result_dir $::env(RESULT_DIR)
set tmp_dir "$result_dir/tmp"
if {![file isdirectory $tmp_dir]} {
    file mkdir $tmp_dir
}
set final_netlist_file $::env(NETLIST_FILE)
set timing_cell_stat_rpt $::env(TIMING_CELL_STAT_RPT)
set timing_cell_count_rpt $::env(TIMING_CELL_COUNT_RPT)
set generic_stat_json $::env(GENERIC_STAT_JSON)
set synth_stat_json $::env(SYNTH_STAT_JSON)
set synth_check_rpt $::env(SYNTH_CHECK_RPT)
set keep_hierarchy $::env(KEEP_HIERARCHY)
set dont_use_cells $::env(CELL_DONT_USE)
set tech_cell_tielo [list $::env(CELL_TIE_LOW) $::env(CELL_TIE_LOW_PORT)]
set tech_cell_tiehi [list $::env(CELL_TIE_HIGH) $::env(CELL_TIE_HIGH_PORT)]
set liberty_args [list]
foreach lib $::env(LIB_ALL) {
    lappend liberty_args "-lib" $lib
}

# 计算时钟周期
set clk_period_ps [expr {1000.0 / $clk_freq_mhz}]

puts "=========================================="
puts "优化综合配置"
puts "=========================================="
puts "顶层模块: $top_design"
puts "时钟频率: $clk_freq_mhz MHz"
puts "时钟周期: $clk_period_ps ps"
puts "保持层次: $keep_hierarchy"
puts "=========================================="

# 读取 Liberty 库
set tech_cells_args [list]
foreach lib $::env(LIB_ALL) {
    lappend tech_cells_args "-liberty" $lib
}

yosys plugin -i slang

# 读取 SystemVerilog
puts "读取 SystemVerilog 文件..."
yosys read_slang -D SYNTHESIS -D USE_GENERIC -F $filelist

# 层次结构和检查
yosys hierarchy -top $top_design
yosys check
yosys proc

puts "=========================================="
puts "阶段 1: 粗粒度优化"
puts "=========================================="

yosys opt_expr
yosys opt -noff
yosys fsm
yosys wreduce 
yosys peepopt
yosys opt_clean
yosys opt -full

# 额外优化: 资源共享
puts "应用资源共享..."
yosys booth
yosys share
yosys opt

# 内存优化
yosys memory -nomap
yosys memory_map
yosys opt -fast

# 寄存器优化
yosys opt_dff -sat -nodffe -nosdff
yosys share
yosys opt -full
yosys clean -purge

# 技术映射
yosys techmap
yosys opt -fast
yosys clean -purge

# 保存通用统计
yosys tee -q -o "${generic_stat_json}" stat -json -tech cmos

puts "=========================================="
puts "阶段 2: 层次展平和深度优化"
puts "=========================================="

if {$keep_hierarchy == "false"} {
    yosys flatten
    yosys clean -purge
}

# 额外优化步骤
puts "应用额外优化..."
yosys opt_merge -share_all
yosys opt_muxtree
yosys opt_reduce -fine -full
yosys opt -full -fast
yosys clean -purge

puts "=========================================="
puts "阶段 3: 触发器映射和命名"
puts "=========================================="

# 保留触发器名称
yosys splitnets -format __v
yosys rename -wire -suffix _reg_p t:*DFF*_P*
yosys rename -wire -suffix _reg_n t:*DFF*_N*
yosys autoname t:*DFF* %n
yosys clean -purge

yosys select -write ${timing_cell_stat_rpt} t:*DFF*
yosys tee -q -o ${timing_cell_count_rpt} select -count t:*DFF*_P*
yosys tee -q -a ${timing_cell_count_rpt} select -count t:*DFF*_N*

puts "=========================================="
puts "阶段 4: 技术映射"
puts "=========================================="

# 映射触发器
set dfflibmap_args ""
foreach cell $dont_use_cells {
    lappend dfflibmap_args -dont_use $cell
}
yosys dfflibmap {*}$tech_cells_args {*}$dfflibmap_args

# ABC 优化
set abc_dont_use_cells ""
foreach cell $dont_use_cells {
    lappend abc_dont_use_cells -dont_use $cell
}

# 生成 ABC 约束文件
set abc_constr_path "${tmp_dir}/abc.constr"
set abc_constr_file [open $abc_constr_path w]
set driver_cell {BUFX4H7L}
puts $abc_constr_file "set_driving_cell ${driver_cell}"
puts $abc_constr_file "set_load 0.015"
close $abc_constr_file

# 调用 ABC
yosys abc {*}$tech_cells_args -D $clk_period_ps -constr $abc_constr_path {*}$abc_dont_use_cells
yosys clean -purge

puts "=========================================="
puts "阶段 5: 最终优化和清理"
puts "=========================================="

# 再次优化
yosys opt -full -fast
yosys opt_clean -purge

# 准备输出
yosys splitnets -ports
yosys setundef -zero
yosys clean -purge

# 映射常量到 tie cells
yosys hilomap -singleton -hicell {*}$tech_cell_tiehi -locell {*}$tech_cell_tielo

puts "=========================================="
puts "生成报告和网表"
puts "=========================================="

# 最终统计
yosys tee -q -o "${synth_stat_json}" stat -json {*}$liberty_args
yosys tee -q -o "${synth_check_rpt}" check

# 输出网表
yosys write_verilog -noattr -noexpr -nohex -nodec ${final_netlist_file}

puts "=========================================="
puts "优化综合完成！"
puts "=========================================="
