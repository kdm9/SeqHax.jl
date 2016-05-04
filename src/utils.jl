module Utils

import GZip: gzopen, gzdopen
using Bio.Seq
using ArgParse

export foreach_read, foreach_readpair, add_common_args

function add_common_args(argparser)
    @add_arg_table argparser begin
        "--quiet", "-q"
            help = "Don't print any logging to STDERR"
            action = :store_true
    end
end


function foreach_read(fn::Function, readfile::AbstractString)
    nread = 0
    if readfile == "-"
        fp = gzdopen(STDIN)
    else
        fp = gzopen(readfile)
    end
    try
        stream = open(fp, FASTQ)
        read = eltype(stream)()
        while read!(stream, read)
            fn(nread += 1, read)
        end
    finally
        close(fp)
    end
    return nread
end


function foreach_readpair(fn::Function, readfile::AbstractString)
    npair = 0
    if readfile == "-"
        fp = gzdopen(STDIN)
    else
        fp = gzopen(readfile)
    end
    try
        stream = open(fp, FASTQ)
        r1 = eltype(stream)()
        r2 = eltype(stream)()
        while read!(stream, r1) && read!(stream, r2)
            fn(npair += 1, r1, r2)
        end
    finally
        close(fp)
    end
    return npair
end

function foreach_readpair(fn::Function, readfile1::AbstractString,
                          readfile2::AbstractString)
    npair = 0
    fp1 = gzopen(readfile1)
    fp2 = gzopen(readfile2)
    try
        stream1 = open(fp1, FASTQ)
        stream2 = open(fp2, FASTQ)
        r1 = eltype(stream1)()
        r2 = eltype(stream2)()
        while read!(stream1, r1) && read!(stream2, r2)
            fn(npair += 1, r1, r2)
        end
    finally
        close(fp1)
        close(fp2)
    end
    return npair
end
end # module Utils
