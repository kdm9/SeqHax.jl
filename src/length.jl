module Length

import DataStructures: counter
using SeqHax.Utils

function main(args)
    r1ctr = counter(Int)
    r2ctr = counter(Int)
    foreach_readpair(args["input"]) do idx, r1, r2
        push!(r1ctr, length(r1.seq))
        if args["paired"]
            push!(r2ctr, length(r2.seq))
        else
            push!(r1ctr, length(r2.seq))
        end
    end
    println(r1ctr)
end

end # module Length
