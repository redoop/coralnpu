# CoralNPU Area Optimization - Quick Reference

## Changes at a Glance

| Component | Before | After | Reduction |
|-----------|--------|-------|-----------|
| **VLEN** | 128 bits | 64 bits | 2x |
| **Instruction Lanes** | 4 | 2 | 2x |
| **Memory Bus Width** | 256 bits | 128 bits | 2x |
| **ITCM** | 8 KB | 4 KB | 2x |
| **DTCM** | 32 KB | 8 KB | 4x |
| **Vector ALUs** | 2 | 1 | 2x |
| **Vector MUL Units** | 2 | 1 | 2x |
| **Command Queue** | 16 | 8 | 2x |
| **Uop Queue** | 16 | 8 | 2x |
| **Reorder Buffer** | 8 | 4 | 2x |

## Quick Commands

```bash
# Verify changes
./verify_optimization.sh

# Build design
bazel build //hdl/chisel/src/coralnpu:RvvCoreMiniAxi

# Run tests
bazel test //hdl/chisel/src/coralnpu:all

# View changes
git diff main dev

# Check status
git status
```

## Key Files Modified

### Configuration
- `hdl/chisel/src/coralnpu/Parameters.scala`
- `hdl/verilog/rvv/inc/rvv_backend_define.svh`

### Implementation
- `hdl/chisel/src/coralnpu/CoreAxi.scala`
- `hdl/chisel/src/coralnpu/scalar/Csr.scala`

### Tests/SoC
- `hdl/chisel/src/coralnpu/FabricTest.scala`
- `hdl/chisel/src/soc/CrossbarConfig.scala`

## Expected Impact

### Area: 3-5x reduction ✓
### Performance: 2-4x slower ⚠️

## Documentation

- **AREA_OPTIMIZATION_README.md** - Start here
- **AREA_OPTIMIZATION_PLAN.md** - Strategy details
- **OPTIMIZATION_CHANGES_SUMMARY.md** - Complete change list

## If Still Over Budget

Try these in order:
1. Reduce NUM_LSU: 2 → 1
2. Reduce buffer depths further
3. Remove DTCM (external memory only)
4. Reduce VLEN: 64 → 32
5. Consider scalar-only core

## Rollback

```bash
# Revert all changes
git checkout main

# Revert specific file
git checkout main -- <filename>
```
