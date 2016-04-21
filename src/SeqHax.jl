module SeqHax

using ArgParse

include("utils.jl")
include("length.jl")

function parse_cli()
    s = ArgParseSettings()
    ## Global
    @add_arg_table s begin
        "length"
            help = "Count read lengths"
            action = :command
    end

    ## Length
    @add_arg_table s["length"] begin
        "--paired", "-p"
            help = "Count in paired mode"
            arg_type = Bool
            default = false
            required = false
        "input"
            help = "Input FASTQ read file(s) (may be gzipped)"
            required = true
            arg_type = ByteString
    end
    return parse_args(s)
end

function main()
    cli = parse_cli()
    cmd = cli["%COMMAND%"]
    if cmd == "length"
        return Length.main(cli["length"])
    end
end

end # module SeqHax
