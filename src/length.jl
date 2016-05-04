module Length

import DataStructures: counter
using SeqHax.Utils
using ArgParse

function add_args(argparser)
    add_common_args(argparser["length"])
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
    read_type = paired ? "Read Pairs" : "Reads"
    npair = foreach_readpair(args["input"]) do idx, r1, r2
        push!(r1ctr, length(r1.seq))
        if paired
            push!(r2ctr, length(r2.seq))
        else
            push!(r1ctr, length(r2.seq))
        end
        if !args["quiet"] && idx % 100000 == 1
            progress = ((paired ? idx : idx * 2) - 1) / 1000000
            println(STDERR, "    ... $(progress)M $read_type")
        end
    end
    if !args["quiet"]
        npair = (paired ? npair * 2 : npair) / 1000000
        println(STDERR, "    ... $(npair)M $read_type")
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
