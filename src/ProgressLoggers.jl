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
    noun::AbstractString
    starttime::UInt64

    function ProgressLogger(sink::IO, format::AbstractString, interval::Int,
                            noun::AbstractString)
        printer = isatty(sink) ? print : println
        new(sink, format, interval, printer, noun, time_ns())
    end
end

function ProgressLogger(sink::IO, interval::Int, noun::AbstractString)
    if isatty(sink)
        fmt = "\x1b[1G\x1b[2K- "
    else
        fmt = "    ... "
    end
    ProgressLogger(sink, fmt, interval, noun)
end

function ProgressLogger(interval::Int, noun::AbstractString)
    ProgressLogger(STDERR, interval, noun)
end

function ProgressLogger(interval::Int)
    ProgressLogger(STDERR, interval, "item")
end

function humanreadable(count::Real)
    if count < 1
        logc = 0
    else
        logc = ceil(log10(count))
    end
    if logc <= 3
        # Special case: Just return the
        return @sprintf("%d", count)
    elseif logc <= 6
        unit = "K"
        div = 1000
    elseif logc <= 9
        unit = "M"
        div = 1000000
    elseif logc <= 12
        unit = "G"
        div = 1000000000
    else
        unit = "T"
        div =  1000000000000
    end
    return @sprintf("%0.0f%s", count/div, unit)
end

function flush!(log::ProgressLogger, item::Int, etc...)
    if log.interval > 0
        elapsed = (time_ns() - log.starttime) / 1e9
        persec = humanreadable(item / elapsed)
        item = humanreadable(item)
        println(log.sink, log.format, item,
                " $(log.noun) ($(persec) / sec)", etc...)
    end
end

function update!(log::ProgressLogger, item::Int, etc...)
    if log.interval > 0 && item % log.interval == 0
        item = humanreadable(item)
        log.printer(log.sink, log.format, item, " $(log.noun)", etc...)
    end
end

end # module
