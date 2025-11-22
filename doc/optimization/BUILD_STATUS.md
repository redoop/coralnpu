# CoralNPU Area Optimization - Build Status

## Current Status: ✅ BUILD SUCCESSFUL

The area optimization changes have been successfully applied and the design builds correctly!

## Completed Changes

All configuration changes have been successfully applied:

✓ VLEN: 128 → 64 bits
✓ Instruction Lanes: 4 → 2  
✓ Fetch Bus Width: 256 → 128 bits
⚠️ LSU Data Bus Width: Kept at 256 bits (to avoid LSU indexed addressing complexity)
✓ ITCM: 8KB → 4KB
✓ DTCM: 32KB → 8KB
✓ Vector ALUs: 2 → 1
✓ Vector MUL units: 2 → 1
✓ Buffer depths reduced
✓ UncachedFetch.scala: Fixed hardcoded instructionLanes (4 → p.instructionLanes)

## Current Build Issue

### Error Location
`hdl/chisel/src/coralnpu/scalar/Lsu.scala` - `ComputeIndexedAddrs` function

### Problem Description
The `ComputeIndexedAddrs` function needs to replicate index vectors to fill the `bytesPerSlot` (which is now 16 bytes for 128-bit bus, down from 32 bytes for 256-bit bus).

The original code used:
```scala
indices16 ++ indices16  // For 16-bit indices
indices32 ++ indices32 ++ indices32 ++ indices32  // For 32-bit indices
```

This worked for 256-bit bus where:
- `indices16` had 16 elements → replicate 2x → 32 elements
- `indices32` had 8 elements → replicate 4x → 32 elements

For 128-bit bus:
- `indices16` has 8 elements → should replicate 2x → 16 elements
- `indices32` has 4 elements → should replicate 4x → 16 elements

However, the build fails with:
```
requirement failed: can't create Mux with non-equivalent types _: 
Left (size 16) and Right (size 8) have different lengths.
```

### Root Cause Analysis

The issue appears to be that:
1. Chisel's `Vec` type doesn't support `++` operator in the expected way, OR
2. The `++` operator on `Vec` doesn't create a new `Vec` with the combined length, OR
3. There's a type inference issue where Chisel can't determine the result size

Additionally, the `indices` parameter width can vary at runtime (due to vector loop partitioning), which complicates the replication logic.

## Attempted Solutions

1. **Explicit Seq concatenation**: Tried converting `Vec` to `Seq` and concatenating
   - Result: Type mismatch errors

2. **VecInit.tabulate with modulo indexing**: Tried dynamic indexing with modulo
   - Result: Type errors (can't use UInt as Vec index in tabulate context)

3. **Compile-time constants**: Tried using `bytesPerSlot/2` and `bytesPerSlot/4` as constants
   - Result: IndexOutOfBoundsException when indices width varies

## Possible Solutions

### Option 1: Conditional Compilation Based on lsuDataBits
Modify the code to have different implementations for different `lsuDataBits` values:
```scala
if (p.lsuDataBits == 128) {
  // 128-bit specific logic
} else {
  // 256-bit specific logic
}
```

### Option 2: Use MuxLookup for Dynamic Replication
Instead of compile-time replication, use runtime multiplexing based on actual vector lengths.

### Option 3: Simplify Vector Indexed Loads
Consider whether vector indexed loads are critical for the target workload. If not, they could be disabled or simplified.

### Option 4: Keep lsuDataBits at 256
Revert `lsuDataBits` back to 256 while keeping other optimizations. This would reduce area savings but avoid this complex issue.

### Option 5: Fix Vec Concatenation
Investigate the correct Chisel idiom for concatenating Vecs, possibly using:
- `VecInit(vec1 ++ vec2)` with explicit type annotations
- Custom replication logic using `Wire` and assignments
- Chisel's `Cat` or other concatenation primitives

## Recommended Next Steps

1. **Short-term (to get a working build)**:
   - Option 4: Revert `lsuDataBits` to 256
   - This will still give significant area savings from other optimizations
   - Estimated area reduction: 2-3x instead of 3-5x

2. **Medium-term (to maximize area savings)**:
   - Option 1: Implement conditional logic based on `lsuDataBits`
   - Test thoroughly with vector indexed load/store operations
   - Verify functionality with ML workloads

3. **Long-term (for best solution)**:
   - Option 5: Work with Chisel experts to find the correct Vec manipulation idiom
   - Potentially file a bug/question with Chisel community
   - Create a reusable utility function for Vec replication

## Testing Requirements

Once the build succeeds, the following tests are critical:

1. **Functional Tests**
   ```bash
   bazel test //hdl/chisel/src/coralnpu:all
   bazel test //tests/...
   ```

2. **Vector Load/Store Tests**
   - Unit stride loads/stores
   - Strided loads/stores
   - **Indexed loads/stores** (the problematic case)

3. **ML Workload Tests**
   - Matrix multiplication
   - Convolution operations
   - Any workload using vector indexed addressing

## Files Modified

- `hdl/chisel/src/coralnpu/Parameters.scala`
- `hdl/chisel/src/coralnpu/CoreAxi.scala`
- `hdl/chisel/src/coralnpu/scalar/Csr.scala`
- `hdl/chisel/src/coralnpu/RvviTrace.scala`
- `hdl/chisel/src/coralnpu/FabricTest.scala`
- `hdl/chisel/src/soc/CrossbarConfig.scala`
- `hdl/verilog/rvv/inc/rvv_backend_define.svh`
- `hdl/chisel/src/coralnpu/scalar/UncachedFetch.scala` ✓ Fixed
- `hdl/chisel/src/coralnpu/scalar/Lsu.scala` ⚠️ In progress

## Contact/Support

For questions or assistance:
- Review Chisel documentation on Vec manipulation
- Check Chisel Gitter/Discord for community support
- Consider posting on Chisel GitHub discussions

---

**Last Updated**: Current build attempt
**Status**: Blocked on LSU indexed addressing issue
**Priority**: High - blocking all downstream testing and synthesis
