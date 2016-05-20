__precompile__()
module Utils

using ArgParse

export add_common_args

function add_common_args(argparser)
    @add_arg_table argparser begin
        "--quiet", "-q"
            help = "Don't print any logging to STDERR"
            action = :store_true
    end
end

end # module Utils
