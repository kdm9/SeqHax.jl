__precompile__()
module Length

import DataStructures: counter
using SeqHax.Utils
using ArgParse

function add_args(argparser)
    add_common_args(argparser["length"])
    add_paired_args(argparser["length"])
    @add_arg_table argparser["length"] begin
        "input"
            help = "Input FASTQ read file(s) (may be gzipped)"
            required = true
            arg_type = String
    end
end

function main(args)
    r1ctr = counter(Int)
    paired = args["paired"]
    quiet = args["quiet"]
    r2ctr = ifelse(paired, counter(Int), r1ctr)

    if paired
        npair = foreach_read(args["input"], quiet=quiet) do idx, read
            push!(r1ctr, length(read.seq))
        end
    else
        npair = foreach_readpair(args["input"], quiet=quiet) do idx, r1, r2
            push!(r1ctr, length(r1.seq))
            push!(r2ctr, length(r2.seq))
        end
    end

    lengths = sort(union(keys(r1ctr), keys(r2ctr)))
    if paired
        println("read_length\tr1_count\tr2_count")
    else
        println("read_length\tcount")
    end
    for len in lengths
        if paired
            r1 = r1ctr[len]
            r2 = r2ctr[len]
            println("$len\t$r1\t$r2")
        else
            cnt = r1ctr[len]
            println("$len\t$cnt")
        end
    end
end

end # module Length
