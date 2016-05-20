__precompile__()
module ProgressLoggers

export ProgressLogger,
       update!,
       flush!

@inline isatty(stream::IO) = isa(stream, Base.TTY)

immutable ProgressLogger
    sink::IO
    format::AbstractString
    interval::Int
    printer::Function

    function ProgressLogger(sink::IO, format::AbstractString, interval::Int)
        printer = isatty(sink) ? print : println
        new(sink, format, interval, printer)
    end
end

function ProgressLogger(sink::IO, interval::Int)
    if isatty(sink)
        fmt = "\x1b[1G\x1b[2K- "
    else
        fmt = "    ... "
    end
    ProgressLogger(sink, fmt, interval)
end

function ProgressLogger(interval::Int)
    ProgressLogger(STDERR, interval)
end


function humanreadable(count::Int)
    if count < 1
        logc = 0
    else
        logc = ceil(log10(count))
    end
    if logc <= 2
        # Special case: Just return the
        return @sprintf("%d", count)
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
    return @sprintf("%0.1f%s", count/div, unit)
end

function flush!(log::ProgressLogger, item::Int)
    if log.interval > 0
        item = humanreadable(item)
        println(log.sink, log.format, item)
    end
end

function update!(log::ProgressLogger, item::Int)
    if log.interval > 0 && item % log.interval == 0
        item = humanreadable(item)
        log.printer(log.sink, log.format, item)
    end
end

end # module
