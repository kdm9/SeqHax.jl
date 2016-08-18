__precompile__()
module Interleave

using SeqHax.Utils
using ArgParse

function add_join_args(argparser)
    add_common_args(argparser["join"])
    @add_arg_table argparser["join"] begin
        "--r1", "-f"
            help = "R1 read file"
            required = true
            arg_type = ByteString
        "--r2", "-r"
            help = "R1 read file"
            required = true
            arg_type = ByteString
        "--il", "-i"
            help = "Interleaved read file (default stdout)"
            arg_type = ByteString
            default = "-"
        "--force"
            help = "Force overwriting output file(s)"
            action = :store_true
        "--zip", "-z"
            help = "GZip compression level"
            default = 0
            arg_type = Int
            required = false
    end
end

function join_main(args)
    r1f = args["r1"]
    r2f = args["r2"]
    ilf = args["il"]
    ziplvl = clamp(args["zip"], 0, 9)

    if isfile(ilf) && !args["force"]
        println(STDERR, "Output file exists. Refusing to overwrite it.")
        println(STDERR, "(NB, you're joining R1/R2 to '$ilf')")
        println(STDERR, "Use '--force' to force overwriting")
        return 1
    end
    ilout = open_zipped(ilf, "w", ziplvl)

    npair = foreach_seqpair(r1f, r2f) do idx, r1, r2
        write(ilout, r1)
        write(ilout, r2)
    end
end


function add_split_args(argparser)
    add_common_args(argparser["split"])
    @add_arg_table argparser["split"] begin
        "--il", "-i"
            help = "Interleaved read file"
            required = true
            arg_type = ByteString
        "--r1", "-f"
            help = "R1 read file"
            required = true
            arg_type = ByteString
        "--r2", "-r"
            help = "R1 read file"
            required = true
            arg_type = ByteString
        "--force"
            help = "Force overwriting output file(s)"
            action = :store_true
        "--zip", "-z"
            help = "GZip compression level"
            default = 0
            arg_type = Int
            required = false
    end
end

function split_main(args)
    r1f = args["r1"]
    r2f = args["r2"]
    ilf = args["il"]
    ziplvl = clamp(args["zip"], 0, 9)
    if (isfile(r1f) || isfile(r2f)) && !args["force"]
        println(STDERR, "Output files exist. Refusing to overwrite them.")
        println(STDERR, "(NB, you're splitting '$ilf' to '$r1f' and '$r2f')")
        println(STDERR, "Use '--force' to force overwriting")
        return 1
    end
    r1out = open_zipped(r1f, "w", ziplvl)
    r2out = open_zipped(r2f, "w", ziplvl)
    npair = foreach_readpair(ilf) do idx, r1, r2
        write(r1out, r1)
        write(r2out, r2)
    end
end

end # module Interleave
