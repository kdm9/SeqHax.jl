__precompile__()
module Comp

import DataStructures: counter
using SeqHax.Utils
using ArgParse
using Bio.Seq

function add_args(argparser)
    add_common_args(argparser["comp"])
    @add_arg_table argparser["comp"] begin
        "input"
            help = "Input FASTQ read file(s) (may be gzipped)"
            required = true
            nargs = '+'
            arg_type = String
    end
end


function main(args)
    comp = []

    for readfile in args["input"]
        npair = foreach_read(readfile, quiet=args["quiet"]) do idx, read
            while length(comp) < length(read.seq)
                push!(comp, counter(DNANucleotide))
            end
            for (i, base) in enumerate(read.seq)
                if isambiguous(base)
                    push!(comp[i], DNA_N)
                else
                    push!(comp[i], base)
                end
            end
        end
        println(STDERR, "Finished '$readfile'")
    end
    println("cycle\tA\tC\tG\tT\tN")
    for (i, ctr) in enumerate(comp)
        A, C, G, T, N = [ctr[b] for b in [DNA_A, DNA_C, DNA_G, DNA_T, DNA_N]]
        println("$i\t$A\t$C\t$G\t$T\t$N")
    end
end

end # module Comp

