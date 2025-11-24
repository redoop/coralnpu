// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package common

import chisel3._
import chisel3.util._

object GenerateAlignerSource {
    def apply[T <: Data](t: T, n: Int): String = {
        // Generate module interface
        var moduleInterface =  "module Aligner_T_WIDTH_GENN(\n".replaceAll("T_WIDTH", t.getWidth.toString)
                                                                 .replaceAll("GENN", n.toString)
        for (i <- 0 until n) {
            moduleInterface += "  input logic in_GENI_valid,\n".replaceAll("GENI", i.toString)
        }
        for (i <- 0 until n) {
            moduleInterface += "  input logic [T_WIDTH-1:0] in_GENI_bits,\n".replaceAll("GENI", i.toString)
                                                                            .replaceAll("T_WIDTH", t.getWidth.toString)
        }
        for (i <- 0 until n) {
            moduleInterface += "  output logic out_GENI_valid,\n".replaceAll("GENI", i.toString)
        }
        for (i <- 0 until n) {
            moduleInterface += "  output logic [T_WIDTH-1:0] out_GENI_bits,\n".replaceAll("GENI", i.toString)
                                                                              .replaceAll("T_WIDTH", t.getWidth.toString)
        }
        moduleInterface = moduleInterface.dropRight(2)
        moduleInterface += ");\n\n"

        // For N=1, just pass through (optimization)
        if (n == 1) {
            var passthrough = "  // Simplified for N=1: just pass through\n"
            passthrough += "  assign out_0_valid = in_0_valid;\n"
            passthrough += "  assign out_0_bits = in_0_bits;\n"
            return moduleInterface + passthrough + "endmodule\n"
        }

        // For N>1, generate full aligner logic inline (without using parameterized types)
        var implementation = "  // Aligner implementation\n"
        implementation += "  logic [GENN-1:0] valid_in;\n".replaceAll("GENN", n.toString)
        for (i <- 0 until n) {
            implementation += "  assign valid_in[GENI] = in_GENI_valid;\n".replaceAll("GENI", i.toString)
        }
        implementation += "  logic [GENN-1:0][T_WIDTH-1:0] data_in;\n".replaceAll("GENN", n.toString)
                                                                       .replaceAll("T_WIDTH", t.getWidth.toString)
        for (i <- 0 until n) {
            implementation += "  assign data_in[GENI] = in_GENI_bits;\n".replaceAll("GENI", i.toString)
        }
        
        // Generate alignment logic
        implementation += "\n  // Alignment logic\n"
        implementation += "  logic [GENN-1:0] valid_out;\n".replaceAll("GENN", n.toString)
        implementation += "  logic [GENN-1:0][T_WIDTH-1:0] data_out;\n".replaceAll("GENN", n.toString)
                                                                       .replaceAll("T_WIDTH", t.getWidth.toString)
        
        // Simple alignment: move valid entries to front
        implementation += "\n  always_comb begin\n"
        implementation += "    integer write_idx = 0;\n"
        implementation += "    valid_out = '0;\n"
        implementation += "    data_out = '0;\n"
        implementation += "    for (integer i = 0; i < GENN; i++) begin\n".replaceAll("GENN", n.toString)
        implementation += "      if (valid_in[i]) begin\n"
        implementation += "        valid_out[write_idx] = 1'b1;\n"
        implementation += "        data_out[write_idx] = data_in[i];\n"
        implementation += "        write_idx = write_idx + 1;\n"
        implementation += "      end\n"
        implementation += "    end\n"
        implementation += "  end\n\n"
        
        // Output assignments
        for (i <- 0 until n) {
            implementation += "  assign out_GENI_valid = valid_out[GENI];\n".replaceAll("GENI", i.toString)
        }
        for (i <- 0 until n) {
            implementation += "  assign out_GENI_bits = data_out[GENI];\n".replaceAll("GENI", i.toString)
        }

        moduleInterface + implementation + "endmodule\n"
    }
}

class Aligner[T <: Data](t: T, n: Int) extends BlackBox with HasBlackBoxInline {
    override val desiredName = "Aligner_T_WIDTH_GENN".replaceAll("T_WIDTH", t.getWidth.toString)
                                                       .replaceAll("GENN", n.toString)
    val io = IO(new Bundle {
        val in = Input(Vec(n, Valid(UInt(t.getWidth.W))))
        val out = Output(Vec(n, Valid(UInt(t.getWidth.W))))
    })
    // Don't use external resource, generate everything inline
    setInline(s"$desiredName.sv", GenerateAlignerSource(t, n))
}

object Aligner {
    def apply[T <: Data](in: Seq[ValidIO[T]]): Vec[ValidIO[T]] = {
        val t = chiselTypeOf(in(0).bits)
        val aligner = Module(new Aligner(t, in.length))
        aligner.io.in := in.map(v => v.map(_.asUInt))
        suppressEnumCastWarning {
          VecInit(aligner.io.out.map(v => v.map(_.asTypeOf(t))))
        }
    }
}