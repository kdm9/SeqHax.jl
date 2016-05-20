__precompile__()
module ProgressLoggers

export ProgressLogger,
       update!

immutable ProgressLogger
    sink::IO
    format::AbstractString
    interval::Int

    function ProgressLogger(sink::IO, format::AbstractString, interval::Int)
        new(sink, format, interval)
    end
end

@inline isatty(stream::IO) = isa(stream, Base.TTY)

function ProgressLogger(sink::IO, interval::Int)
    if isatty(sink)
        fmt = "\x1b[1G\x1b[2K  - $(item)"
    else
        fmt = "    ... $(item)"
    end
    ProgressLogger(sink, fmt, interval)
end

function ProgressLogger(interval::Int)
    ProgressLogger(STDERR, interval)
end


function humanreadable(count::Int)
    logc = Int(ceil(log10(count)))
    if logc <= 2
        unit = ""
        div = 1
    elseif logc <= 5
        unit = "K"
        div = 1000
    elseif logc <= 7
        unit = "M"
        div = 1000000
    elseif logc <= 10
        unit = " Billion"
        div = 1000000000
    else
        unit = " Trillion"
        div =  1000000000000
    end
    return @sprintf("%0.2f%s", count/div, unit)
end


function update!(log::ProgressLogger, item::Int)
    if item % log.interval == 0
        item = humanreadable(item)
        log.print(log.io, log.format)
    end
end

end # module
