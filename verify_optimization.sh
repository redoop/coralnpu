#!/bin/bash
# Verification script for CoralNPU area optimization changes

set -e

echo "========================================="
echo "CoralNPU Area Optimization Verification"
echo "========================================="
echo ""

echo "1. Checking modified files..."
echo ""

# Check if key files were modified
files_to_check=(
    "hdl/chisel/src/coralnpu/Parameters.scala"
    "hdl/chisel/src/coralnpu/CoreAxi.scala"
    "hdl/chisel/src/coralnpu/scalar/Csr.scala"
    "hdl/chisel/src/coralnpu/RvviTrace.scala"
    "hdl/verilog/rvv/inc/rvv_backend_define.svh"
    "hdl/chisel/src/coralnpu/FabricTest.scala"
    "hdl/chisel/src/soc/CrossbarConfig.scala"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file NOT FOUND"
        exit 1
    fi
done

echo ""
echo "2. Verifying key parameter changes..."
echo ""

# Check VLEN in Parameters.scala
if grep -q "val rvvVlen = 64" hdl/chisel/src/coralnpu/Parameters.scala; then
    echo "✓ VLEN reduced to 64 in Parameters.scala"
else
    echo "✗ VLEN not properly set in Parameters.scala"
    exit 1
fi

# Check instructionLanes
if grep -q "val instructionLanes = 2" hdl/chisel/src/coralnpu/Parameters.scala; then
    echo "✓ instructionLanes reduced to 2"
else
    echo "✗ instructionLanes not properly set"
    exit 1
fi

# Check lsuDataBits
if grep -q "var lsuDataBits = 128" hdl/chisel/src/coralnpu/Parameters.scala; then
    echo "✓ lsuDataBits reduced to 128"
else
    echo "✗ lsuDataBits not properly set"
    exit 1
fi

# Check VLEN in rvv_backend_define.svh
if grep -q "\`define VLEN.*64" hdl/verilog/rvv/inc/rvv_backend_define.svh; then
    echo "✓ VLEN reduced to 64 in rvv_backend_define.svh"
else
    echo "✗ VLEN not properly set in rvv_backend_define.svh"
    exit 1
fi

# Check NUM_ALU
if grep -q "\`define NUM_ALU.*1" hdl/verilog/rvv/inc/rvv_backend_define.svh; then
    echo "✓ NUM_ALU reduced to 1"
else
    echo "✗ NUM_ALU not properly set"
    exit 1
fi

# Check NUM_MUL
if grep -q "\`define NUM_MUL.*1" hdl/verilog/rvv/inc/rvv_backend_define.svh; then
    echo "✓ NUM_MUL reduced to 1"
else
    echo "✗ NUM_MUL not properly set"
    exit 1
fi

# Check ITCM size
if grep -q "new MemoryRegion(0x00000, 0x1000" hdl/chisel/src/coralnpu/Parameters.scala; then
    echo "✓ ITCM reduced to 4KB (0x1000)"
else
    echo "✗ ITCM size not properly set"
    exit 1
fi

# Check DTCM size
if grep -q "new MemoryRegion(0x10000, 0x2000" hdl/chisel/src/coralnpu/Parameters.scala; then
    echo "✓ DTCM reduced to 8KB (0x2000)"
else
    echo "✗ DTCM size not properly set"
    exit 1
fi

# Check VLENB in CSR
if grep -q "vlenbEn.get -> 8.U" hdl/chisel/src/coralnpu/scalar/Csr.scala; then
    echo "✓ VLENB CSR value set to 8"
else
    echo "✗ VLENB CSR value not properly set"
    exit 1
fi

echo ""
echo "========================================="
echo "All verification checks passed! ✓"
echo "========================================="
echo ""
echo "Summary of changes:"
echo "  - VLEN: 128 → 64 bits"
echo "  - Instruction Lanes: 4 → 2"
echo "  - Memory Bus Width: 256 → 128 bits"
echo "  - ITCM: 8KB → 4KB"
echo "  - DTCM: 32KB → 8KB"
echo "  - NUM_ALU: 2 → 1"
echo "  - NUM_MUL: 2 → 1"
echo "  - Buffer depths reduced"
echo ""
echo "Next steps:"
echo "  1. Build the design: bazel build //hdl/chisel/src/coralnpu:RvvCoreMiniAxi"
echo "  2. Run synthesis to measure area"
echo "  3. Run functional tests"
echo "  4. Benchmark performance impact"
echo ""
