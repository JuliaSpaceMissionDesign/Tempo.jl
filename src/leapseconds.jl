"""
    get_leapseconds()

Parse leapseconds data and return a [`Leapseconds`](@ref) type. 

!!! note 
    The leapsecond kernel is retrieved from the artifacts of this package. This artifact 
    will be updated whenever a new leapsecond is added.
"""
function get_leapseconds()
    
    t = Vector{Float64}()
    leap = Vector{Float64}()
    re = r"(?<dat>[0-9]{2}),\s+@(?<date>[0-9]{4}-[A-Z]{3}-[0-9])"

    leap_path = artifact"leapseconds"
    lines = readlines(joinpath(leap_path, "leapseconds.tls"))

    for line in lines
        s = string(line)
        if occursin(re, s)
            m = match(re, s)
            push!(leap, parse(Float64, m["dat"]))
            push!(t, datetime2julian(DatesDateTime(m["date"], "y-u-d")) - Tempo.DJ2000)
        end
    end

    return Leapseconds(now(), t, leap)

end

"""
    Leapseconds{T}

Stores information about leap seconds that have been added to Coordinated Universal Time (UTC) 
since the start of the year 2000.

### Fields
- `lastupdate`: a `DatesDateTime` object representing the date and time when the Leapseconds 
    struct was last updated.
- `jd2000`: a vector storing the Julian Date, in days since J2000, of each leap second.
- `leap`: a vector storing the number of leap seconds at each corresponding entry of the 
        `jd2000` field.
"""
struct Leapseconds{T}
    lastupdate::DatesDateTime
    jd2000::Vector{T}
    leap::Vector{T}
end

function Base.show(io::IO, ls::Leapseconds)
    return println(io, "Leapseconds(last_update=$(ls.lastupdate))")
end

"""
    LEAPSECONDS

Leapseconds data.
"""
const LEAPSECONDS::Leapseconds{Float64} = get_leapseconds()

"""
    leapseconds(jd2000::Number)

For a given UTC date, in Julian days since [`J2000`](@ref), calculate Delta(AT) = TAI - UTC.
"""
function leapseconds(jd2000::Number)
    return LEAPSECONDS.leap[searchsortedlast(LEAPSECONDS.jd2000, jd2000)]
end
