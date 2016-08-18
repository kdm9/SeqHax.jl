__precompile__()
module Utils

import GZip: gzopen, gzdopen
using ArgParse
using Bio.Seq
using SeqHax.ProgressLoggers

export  add_common_args,
        add_paired_args,
        open_zipped,
        foreach_read,
        foreach_readpair


function add_common_args(argparser)
    @add_arg_table argparser begin
        "--quiet", "-q"
            help = "Don't print any logging to STDERR"
            action = :store_true
    end
end

function add_paired_args(argparser)
    @add_arg_table argparser begin
        "--paired", "-p"
            help = "Process reads in paired mode"
            action = :store_true
    end
end

"Opens a file or stream, using gzip or not"
function open_zipped(file_or_io, mode="r", ziplevel::Int=0)
    stream = ifelse(startswith(mode, "w"), STDOUT, STDIN)
    zmode = ifelse(startswith(mode, "r"), "r", "w$ziplevel")
    if typeof(file_or_io) <: IO
        stream = file_or_io
    end
    if file_or_io == "-" || typeof(file_or_io) <: IO
        if ziplevel > 0
            return gzdopen(stream, zmode)
        else
            return stream
        end
    else
        if ziplevel > 0 || startswith(mode, "r")
            return gzopen(file_or_io, zmode)
        else
            return open(file_or_io, mode)
        end
    end
end


function foreach_read(fn::Function, readfile::AbstractString;
                      quiet::Bool=false)
    log = ProgressLogger(ifelse(quiet, 0, 100000), "sequences")
    nread = 0
    fp = open_zipped(readfile, "r")
    stream = open(fp, FASTQ, Seq.SANGER_QUAL_ENCODING)
    try
        read = eltype(stream)()
        while !eof(stream)
            update!(log, nread)
            read!(stream, read)
            fn(nread += 1, read)
        end
        return nread
    catch e
        throw(e)
    finally
        close(stream)
        flush!(log, nread)
    end
end

function foreach_readpair(fn::Function, readfile::AbstractString;
                          quiet::Bool=false)
    log = ProgressLogger(ifelse(quiet, 0, 100000), "reads")
    nread = 0
    fp = open_zipped(readfile, "r")
    stream = open(fp, FASTQ, Seq.SANGER_QUAL_ENCODING)
    try
        r1 = eltype(stream)()
        r2 = eltype(stream)()
        while !eof(stream)
            update!(log, nread)
            read!(stream, r1)
            if eof(stream)
                println(STDERR, "Non-paired file (unexpected eof after ",
                        "$nread reads")
                break
            end
            read!(stream, r2)
            fn(nread += 2, r1, r2)
        end
        return nread
    catch e
        throw(e)
    finally
        close(stream)
        flush!(log, nread)
    end
end

function foreach_readpair(fn::Function, readfile1::AbstractString,
                          readfile2::AbstractString; quiet::Bool=false)
    log = ProgressLogger(ifelse(quiet, 0, 100000), "reads")
    nread = 0
    r1fp = open_zipped(readfile1, "r")
    r2fp = open_zipped(readfile2, "r")
    r1s = open(r1fp, FASTQ, Seq.SANGER_QUAL_ENCODING)
    r2s = open(r2fp, FASTQ, Seq.SANGER_QUAL_ENCODING)
    try
        r1 = eltype(r1s)()
        r2 = eltype(r1s)() # deliberately using r1s here to keep them the same
        while !eof(r1s)
            update!(log, nread)
            read!(r1s, r1)
            if eof(r2s)
                println(STDERR, "Non-paired file (unexpected eof in R2 after ",
                        "$nread reads")
                break
            end
            read!(r2s, r2)
            fn(nread += 2, r1, r2)
        end
        if !eof(r2s)
            println(STDERR, "Non-paired file (unexpected eof in R1 after ",
                    "$nread reads")
        end
        return nread
    catch e
        throw(e)
    finally
        close(r1s)
        close(r2s)
        flush!(log, nread)
    end
end


end # module Utils
