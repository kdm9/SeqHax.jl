__precompile__()
module SeqHax

using ArgParse

include("ProgressLoggers.jl")
include("utils.jl")
include("length.jl")
include("interleave.jl")

function parse_cli()
    s = ArgParseSettings()
    ## Global
    @add_arg_table s begin
        "length"
            help = "Count read lengths"
            action = :command
        "interleave"
            help = "Count read lengths"
            action = :command
    end
    Length.add_args(s)
    Interleave.add_args(s)
    return parse_args(s)
end


function main()
    cli = parse_cli()
    cmd = cli["%COMMAND%"]
    mainfuncs = Dict{AbstractString, Any}(
        "length" => Length.main,
        "interleave" => Interleave.main,
    )
    return mainfuncs[cmd](cli[cmd])
end

end # module SeqHax
