# CoralNPU Area Optimization Plan

## Current Configuration Analysis

### Memory Configuration
- **ITCM**: 8 KB (default) / 1 MB (highmem mode)
- **DTCM**: 32 KB (default) / 1 MB (highmem mode)
- **Memory Width**: 256 bits (lsuDataBits)

### Vector Configuration
- **VLEN**: 128 bits
- **Vector ALUs**: 2 (`NUM_ALU = 2`)
- **Vector MUL Units**: 2 (`NUM_MUL = 2`)
- **Vector DIV Units**: 1 (`NUM_DIV = 1`)
- **Vector PMT/RDT Units**: 1 (`NUM_PMTRDT = 1`)
- **Vector LSU Units**: 2 (`NUM_LSU = 2`)
- **Instruction Lanes**: 4 (dispatch width)

### Buffer Depths
- **Command Queue (CQ)**: 16
- **Uop Queue (UQ)**: 16
- **ALU Reservation Station**: 4-8
- **MUL Reservation Station**: 4-8
- **DIV Reservation Station**: 4-8
- **PMT/RDT Reservation Station**: 8
- **LSU Reservation Station**: 4-8
- **Reorder Buffer (ROB)**: 8

## Optimization Strategy (Aggressive Area Reduction)

### Phase 1: Memory Optimization (High Impact)
1. **Reduce DTCM**: 32 KB → 8 KB (4x reduction)
   - Still sufficient for small ML workloads
   - Can use external memory for larger datasets
   
2. **Reduce ITCM**: 8 KB → 4 KB (2x reduction)
   - Sufficient for typical embedded ML kernels
   
3. **Reduce Memory Width**: 256 bits → 128 bits
   - Matches VLEN, simplifies design
   - Performance penalty on memory-intensive workloads

### Phase 2: Vector Unit Reduction (High Impact)
1. **Reduce VLEN**: 128 bits → 64 bits (2x reduction)
   - Major area savings in vector register file
   - Requires more iterations for same computation
   
2. **Reduce Vector ALUs**: 2 → 1 (2x reduction)
   - Significant area savings
   - 2x performance penalty on ALU-bound workloads
   
3. **Reduce Vector MUL Units**: 2 → 1 (2x reduction)
   - Area savings in multipliers
   - 2x performance penalty on multiply-heavy workloads

4. **Reduce Instruction Lanes**: 4 → 2 (2x reduction)
   - Reduces dispatch width
   - Simplifies frontend logic

### Phase 3: Buffer Depth Reduction (Medium Impact)
1. **Command Queue**: 16 → 8
2. **Uop Queue**: 16 → 8
3. **ALU RS**: 4-8 → 4
4. **MUL RS**: 4-8 → 4
5. **DIV RS**: 4-8 → 4
6. **LSU RS**: 4-8 → 4
7. **ROB**: 8 → 4

### Phase 4: Optional Further Reductions
1. **Remove DTCM entirely** if external memory is always available
2. **Reduce VLEN to 32 bits** for extreme area constraints
3. **Single-issue scalar core** (instructionLanes = 1)

## Implementation Files to Modify

### Chisel Configuration
- `hdl/chisel/src/coralnpu/Parameters.scala`
  - rvvVlen: 128 → 64
  - instructionLanes: 4 → 2
  - lsuDataBits: 256 → 128
  - fetchDataBits: 256 → 128

### Verilog Configuration
- `hdl/verilog/rvv/inc/rvv_backend_define.svh`
  - VLEN: 128 → 64
  - NUM_ALU: 2 → 1
  - NUM_MUL: 2 → 1
  - CQ_DEPTH: 16 → 8
  - UQ_DEPTH: 16 → 8
  - ALU_RS_DEPTH: 4-8 → 4
  - MUL_RS_DEPTH: 4-8 → 4
  - DIV_RS_DEPTH: 4-8 → 4
  - LSU_RS_DEPTH: 4-8 → 4
  - ROB_DEPTH: 8 → 4

### Memory Configuration
- `hdl/chisel/src/coralnpu/CoreAxi.scala`
  - itcmSizeBytes: 8KB → 4KB
  - dtcmSizeBytes: 32KB → 8KB

## Expected Area Reduction

Rough estimates (multiplicative):
- Memory: ~4x reduction (ITCM 2x + DTCM 4x)
- Vector Register File: ~2x reduction (VLEN 2x)
- Vector ALUs: ~2x reduction (NUM_ALU 2x)
- Vector MUL: ~2x reduction (NUM_MUL 2x)
- Buffers: ~1.5x reduction
- Frontend: ~1.5x reduction (dispatch width 2x)

**Total estimated reduction: 3-5x** (conservative estimate)

## Performance Impact

- Memory-bound workloads: 2-4x slower (memory width + size)
- ALU-bound workloads: 2-4x slower (VLEN 2x + NUM_ALU 2x)
- Multiply-heavy workloads: 2-4x slower (VLEN 2x + NUM_MUL 2x)
- Instruction throughput: 2x slower (dispatch width 2x)

## Next Steps

1. Apply Phase 1 & 2 changes (memory + vector units)
2. Synthesize and measure area
3. If still >10x budget, apply Phase 3 (buffer depths)
4. If still over budget, consider Phase 4 (extreme reductions)
5. Run performance benchmarks to quantify impact
