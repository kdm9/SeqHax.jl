module Length

import DataStructures: counter
using SeqHax.Utils
using ArgParse

function add_args(argparser)
    @add_arg_table argparser["length"] begin
        "--paired", "-p"
            help = "Count in paired mode"
            action = :store_true
        "input"
            help = "Input FASTQ read file(s) (may be gzipped)"
            required = true
            arg_type = ByteString
    end
end

function main(args)
    r1ctr = counter(Int)
    r2ctr = counter(Int)
    paired = args["paired"]
    foreach_readpair(args["input"]) do idx, r1, r2
        push!(r1ctr, length(r1.seq))
        if paired
            push!(r2ctr, length(r2.seq))
        else
            push!(r1ctr, length(r2.seq))
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
