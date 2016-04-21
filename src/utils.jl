module Utils

import GZip: gzopen, gzdopen
using Bio.Seq

export foreach_read, foreach_readpair


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

end # module Utils
