__precompile__()
module SeqHax

using ArgParse
using Bio.Seq

include("ProgressLoggers.jl")
include("utils.jl")

include("comp.jl")
include("length.jl")
include("interleave.jl")

function parse_cli()
    s = ArgParseSettings()
    ## Global
    @add_arg_table s begin
        "comp"
            help = "Calculate (mean) nucleotide composition of sequences"
            action = :command
        "length"
            help = "Count read lengths"
            action = :command
        "join"
            help = "Join separate R1/R2 files into an interleaved file"
            action = :command
        "split"
            help = "Split an interleaved file into separate R1/R2 files"
            action = :command
    end
    Comp.add_args(s)
    Length.add_args(s)
    Interleave.add_join_args(s)
    Interleave.add_split_args(s)
    return parse_args(s)
end


function main()
    cli = parse_cli()
    cmd = cli["%COMMAND%"]
    mainfuncs = Dict{AbstractString, Any}(
        "length" => Length.main,
        "join" => Interleave.join_main,
        "split" => Interleave.split_main,
        "comp" => Comp.main,
        #"preappend" => PreApp.main,
    )
    return mainfuncs[cmd](cli[cmd])
end

end # module SeqHax
