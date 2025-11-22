# CoralNPU Area Optimization - Changes Summary

## Overview
Applied aggressive area optimization to reduce core size by approximately 3-5x to meet area budget constraints.

## Changes Applied

### 1. Chisel Parameters (hdl/chisel/src/coralnpu/Parameters.scala)

#### Vector Configuration
- **rvvVlen**: 128 → 64 bits (2x reduction)
  - Reduces vector register file size by ~2x
  - Requires 2x more iterations for same vector operations

#### Scalar Core Configuration  
- **instructionLanes**: 4 → 2 (2x reduction)
  - Reduces dispatch width and frontend complexity
  - Halves instruction throughput

#### Memory Bus Width
- **fetchDataBits**: 256 → 128 bits (2x reduction)
- **lsuDataBits**: 256 → 128 bits (2x reduction)
  - Reduces memory interface width
  - Matches VLEN for simpler design
  - Performance penalty on memory-intensive workloads

#### Memory Regions
- **ITCM**: 0x2000 (8KB) → 0x1000 (4KB) (2x reduction)
- **DTCM**: 0x8000 (32KB) → 0x2000 (8KB) (4x reduction)
  - Significant area savings in SRAM
  - May require external memory for larger workloads

### 2. Memory Implementation (hdl/chisel/src/coralnpu/CoreAxi.scala)

- **itcmSizeBytes**: 8KB → 4KB
- **dtcmSizeBytes**: 32KB → 8KB

### 3. RVV Backend Configuration (hdl/verilog/rvv/inc/rvv_backend_define.svh)

#### Vector Length
- **VLEN**: 128 → 64 bits (2x reduction)

#### Execution Units
- **NUM_ALU**: 2 → 1 (2x reduction)
  - Halves ALU throughput
  - Significant area savings
  
- **NUM_MUL**: 2 → 1 (2x reduction)
  - Halves multiply throughput
  - Saves multiplier area

#### Scalar Core Issue Width
- **ISSUE_LANE**: 4 → 2 (2x reduction)

#### Buffer Depths (All reduced for area optimization)
- **CQ_DEPTH** (Command Queue): 16 → 8 (2x reduction)
- **UQ_DEPTH** (Uop Queue): 16 → 8 (2x reduction)
- **PMTRDT_RS_DEPTH**: 8 → 4 (2x reduction)
- **ROB_DEPTH** (Reorder Buffer): 8 → 4 (2x reduction)
- **ALU_RS_DEPTH**: 4 (unchanged)
- **MUL_RS_DEPTH**: 4 (unchanged)
- **DIV_RS_DEPTH**: 4 (unchanged)
- **LSU_RS_DEPTH**: 4 (unchanged)

### 4. CSR Configuration (hdl/chisel/src/coralnpu/scalar/Csr.scala)

- **VLENB CSR value**: 16 → 8 (reflects VLEN change from 128 to 64)

### 5. RVVI Trace (hdl/chisel/src/coralnpu/RvviTrace.scala)

- **VLEN parameter**: 128 → 64

## Area Impact Estimation

### Major Contributors to Area Reduction:
1. **Memory (ITCM + DTCM)**: ~3-4x reduction
   - ITCM: 2x smaller
   - DTCM: 4x smaller
   
2. **Vector Register File**: ~2x reduction
   - VLEN halved from 128 to 64 bits
   
3. **Vector Execution Units**: ~2x reduction
   - NUM_ALU: 2 → 1
   - NUM_MUL: 2 → 1
   
4. **Memory Interfaces**: ~1.5x reduction
   - Bus width halved (256 → 128 bits)
   
5. **Frontend/Dispatch**: ~1.5x reduction
   - Instruction lanes: 4 → 2
   
6. **Buffers/Queues**: ~1.5x reduction
   - Various buffer depths halved

### Total Estimated Area Reduction: 3-5x

## Performance Impact Estimation

### Workload-Specific Impact:

1. **Memory-Bound Workloads**: 2-4x slower
   - Memory width reduced 2x
   - Memory size reduced (may cause more external accesses)

2. **ALU-Bound Workloads**: 2-4x slower
   - VLEN reduced 2x (more iterations needed)
   - NUM_ALU reduced 2x (half throughput)

3. **Multiply-Heavy Workloads**: 2-4x slower
   - VLEN reduced 2x
   - NUM_MUL reduced 2x

4. **Instruction Throughput**: 2x slower
   - Dispatch width reduced 2x

5. **Buffer Pressure**: Moderate impact
   - Smaller buffers may cause more stalls
   - Impact depends on instruction mix

## Verification Steps Required

1. **Rebuild and Synthesize**
   ```bash
   bazel build //hdl/chisel/src/coralnpu:RvvCoreMiniAxi
   ```

2. **Check Area Reports**
   - Compare synthesized area with budget
   - Identify remaining bottlenecks if still over budget

3. **Run Functional Tests**
   - Verify all tests still pass with reduced configuration
   - May need to adjust test expectations for smaller memories

4. **Performance Benchmarks**
   - Run ML workloads to quantify actual performance impact
   - Compare against baseline configuration

## Further Optimization Options (If Still Over Budget)

### Aggressive Options:
1. **Remove DTCM entirely** - rely on external memory only
2. **Reduce VLEN to 32 bits** - extreme area savings
3. **Single-issue scalar core** - instructionLanes = 1
4. **Reduce NUM_LSU** from 2 to 1
5. **Further reduce buffer depths** to 2

### Alternative Approach:
Consider using the scalar-only core (without RVV) if ML performance requirements can be relaxed significantly.

## Notes

- All changes maintain architectural compatibility
- Software will run correctly but slower
- Memory-constrained applications may need code size optimization
- Consider using external memory for data-heavy workloads
- Performance/area tradeoff is configurable - can adjust individual parameters as needed
