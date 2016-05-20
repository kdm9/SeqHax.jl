__precompile__()
module Interleave

using SeqHax.Utils
using SeqHax.Fastx
using ArgParse

function add_join_args(argparser)
    add_common_args(argparser["join"])
    @add_arg_table argparser["join"] begin
        "--r1"
            help = "R1 read file"
            required = true
            arg_type = ByteString
        "--r2"
            help = "R1 read file"
            required = true
            arg_type = ByteString
        "--il"
            help = "Interleaved read file (default stdout)"
            arg_type = ByteString
            default = "-"
        "--force", "-f"
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

    if ilf == "-"
        if ziplvl > 0
            ilout = gzdopen(STDOUT, "w$ziplvl")
        else
            ilout = STDOUT
        end
    else
        if isfile(ilf) && !args["force"]
            println(STDERR, "Output file exists. Refusing to overwrite it.")
            println(STDERR, "(NB, you're joining R1/R2 to '$ilf')")
            println(STDERR, "Use '--force' to force overwriting")
            return 1
        end

        if ziplvl > 0
            ilout = gzopen(ilf, "w$ziplvl")
        else
            ilout = open(ilf, "w")
        end
    end

    npair = foreach_seqpair(r1f, r2f) do idx, r1, r2
        write(ilout, r1)
        write(ilout, r2)
    end
end


function add_split_args(argparser)
    add_common_args(argparser["split"])
    @add_arg_table argparser["split"] begin
        "--il"
            help = "Interleaved read file"
            required = true
            arg_type = ByteString
        "--r1"
            help = "R1 read file"
            required = true
            arg_type = ByteString
        "--r2"
            help = "R1 read file"
            required = true
            arg_type = ByteString
        "--force", "-f"
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
    r1f =  args["r1"]
    r2f = args["r2"]
    ilf = args["il"]
    ziplvl = clamp(args["zip"], 0, 9)
    if (isfile(r1f) || isfile(r2f)) && !args["force"]
        println(STDERR, "Output files exist. Refusing to overwrite them.")
        println(STDERR, "(NB, you're splitting the interleaved file to R1/R2)")
        println(STDERR, "Use '--force' to force overwriting")
        return 1
    end
    if ziplvl > 0
        r1out = gzopen(r1f, "w$ziplvl")
        r2out = gzopen(r2f, "w$ziplvl")
    else
        r1out = open(r1f, "w")
        r2out = open(r2f, "w")
    end
    npair = foreach_readpair(ilf) do idx, r1, r2
        write!(r1out, r1)
        write!(r2out, r2)
    end
end

end # module Interleave
