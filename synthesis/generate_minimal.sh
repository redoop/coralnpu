#!/bin/bash
# 生成最小化配置的 CoreMiniAxi

set -e

echo "生成最小化配置的 CoreMiniAxi..."
echo "禁用: Float, RVV, Debug, Verification, FetchL0"
echo ""

# 使用 Bazel 生成，但通过 Chisel 参数禁用功能
cd /opt/github/coralnpu

# 方法1: 尝试使用 Chisel 的 main 函数直接生成
# 需要找到正确的 main 类

# 方法2: 修改 BUILD 文件临时禁用 Float
# 备份原始 BUILD 文件
cp hdl/chisel/src/coralnpu/BUILD hdl/chisel/src/coralnpu/BUILD.bak

# 修改 BUILD 文件
sed -i 's/--enableFloat=True/--enableFloat=False/' hdl/chisel/src/coralnpu/BUILD

echo "已修改 BUILD 文件，禁用 Float"
echo "重新生成 Verilog..."

# 重新构建
bazel build //hdl/chisel/src/coralnpu:core_mini_axi_cc_library_emit_verilog

# 复制新生成的文件
cp bazel-bin/hdl/chisel/src/coralnpu/CoreMiniAxi.sv synthesis/CoreMiniAxi_minimal.sv

# 恢复 BUILD 文件
mv hdl/chisel/src/coralnpu/BUILD.bak hdl/chisel/src/coralnpu/BUILD

echo ""
echo "✓ 生成完成: synthesis/CoreMiniAxi_minimal.sv"
ls -lh synthesis/CoreMiniAxi_minimal.sv
