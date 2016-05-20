module Fastx

import GZip: gzopen, gzdopen
using SeqHax.ProgressLoggers
using BufferedStreams

export 
    FastxRecord,
    writefasta,
    writefastq,
    readfasta!,
    readfastq!,
    foreach_seq,
    foreach_seqpair
  
type FastxRecord
    name::AbstractString
    sequence::AbstractString
    quality::AbstractString
    description::AbstractString
    isfastq::Bool

    function FastxRecord()
        new("", "", "", "", false)
    end

    function FastxRecord(name, seq, qual, desc="")
        new(name, seq, qua, desc)
    end

    function FastxRecord(name, seq; desc="")
        new(name, seq, "", desc)
    end
end


function writefastq(io::IO, rec::FastxRecord)
    if length(rec.description) > 0
        namedescr = @sprintf("%s %s", rec.name, rec.description)
    else
        namedescr = rec.name
    end
    println(io, "@$namedescr")
    println(io, "$(rec.sequence)")
    println(io, "+")
    println(io, "$(rec.quality)")
end

function writefasta(io::IO, rec::FastxRecord)
    if length(rec.description) > 0
        namedescr = @sprintf("%s %s", rec.name, rec.description)
    else
        namedescr = rec.name
    end
    println(io, ">$namedescr")
    for i in 1:80:length(rec.sequence)
        println(io, "$(rec.sequence[i:i+79])")
    end
end

function readnameline(stream)
    namedesc = split(chomp(readuntil(stream, '\n')), ' ', limit=2)
    if length(namedesc) == 2
        name, desc = namedesc
    else
        name = namedesc
        desc = ""
    end
    return name, desc
end

function readfastq!(stream::BufferedInputStream, rec::FastxRecord)
    rec.name = rec.sequence = rec.quality = rec.description = ""

    if read(stream, UInt8) != '@'
        error("Not a valid fastq file")
        return false
    end
    name, desc = readnameline(stream)
    seq = chomp(readuntil(stream, '\n'))
    if read(stream, UInt8) != '+'
        error("Not a valid fastq file")
        return false
    end
    readuntil(stream, '\n')
    qual = chomp(readuntil(stream, '\n'))

    rec.name = name
    rec.sequence = seq
    rec.quality = qual
    rec.description = desc
    rec.isfastq = true
    return rec
end

function readfasta!(stream::BufferedInputStream, rec::FastxRecord)
    rec.name = rec.sequence = rec.quality = rec.description = ""

    if read(stream, UInt8) != '>'
        error("Not a valid fasta file")
        return false
    end
    name, desc = readnameline(stream)
    seq = ""
    while peek(stream) != '>'
        seq *= chomp(readuntil(stream, '\n'))
    end

    rec.name = name
    rec.sequence = seq
    rec.description = desc
    rec.isfastq = false
    return rec
end


function Base.read!(io::BufferedInputStream, rec::FastxRecord)
    if peek(io) == '>'
        return readfasta!(io, rec)
    else
        return readfastq!(io, rec)
    end
end


function Base.write(io::IO, rec::FastxRecord)
    if rec.isfastq
        return writefastq(io, rec)
    else
        return writefasta(io, rec)
    end
end


function foreach_seq(fn::Function, readfile::AbstractString;
                     interval::Int=100000)
    log = ProgressLogger(interval, "sequences")
    nread = 0
    if readfile == "-"
        stream = BufferedInputStream(gzdopen(STDIN))
    else
        stream = BufferedInputStream(gzopen(readfile))
    end
    try
        read = FastxRecord()
        while !eof(stream)
            read!(stream, read)
            update!(log, nread)
            fn(nread += 1, read)
        end
    finally
        close(stream)
        flush!(log, nread)
    end
    return nread
end

function foreach_seqpair(fn::Function, readfile::AbstractString;
                         interval::Int=100000)
    log = ProgressLogger(interval, "sequence pairs")

    npair = 0
    if readfile == "-"
        stream = BufferedInputStream(gzdopen(STDIN))
    else
        stream = BufferedInputStream(gzopen(readfile))
    end
    try
        r1 = FastxRecord()
        r2 = FastxRecord()
        while true
            if eof(stream)
                break
            end
            read!(stream, r1)
            if eof(stream)
                break
            end
            read!(stream, r2)
            fn(npair += 1, r1, r2)
            update!(log, npair)
        end
    finally
        close(stream)
        flush!(log, npair)
    end
    return npair
end

function foreach_seqpair(fn::Function, readfile1::AbstractString,
                         readfile2::AbstractString; interval::Int=100000)
    log = ProgressLogger(interval, "sequence pairs")
    npair = 0
    stream1 = BufferedInputStream(gzopen(readfile1))
    stream2 = BufferedInputStream(gzopen(readfile2))
    try
        r1 = FastxRecord()
        r2 = FastxRecord()
        while true
            if eof(stream1)
                break
            end
            read!(stream1, r1)
            if eof(stream2)
                break
            end
            read!(stream2, r2)
            update!(log, npair)
            fn(npair += 1, r1, r2)
        end
    finally
        close(stream1)
        close(stream2)
        flush!(log, npair)
    end
    return npair
end

end # module Fastx
