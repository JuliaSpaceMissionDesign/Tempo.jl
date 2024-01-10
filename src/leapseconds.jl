
"""
    LeapsecondEntry{T}

Store informations about a leap second entry.
"""
struct LeapsecondEntry{T}
    year::Int
    month::Int
    day::Int
    Δs::T
end

const LEAPSECONDS_DATA = [
    LeapsecondEntry(1972,  1, 1, 10.0),
    LeapsecondEntry(1972,  7, 1, 11.0),
    LeapsecondEntry(1973,  1, 1, 12.0),
    LeapsecondEntry(1974,  1, 1, 13.0),
    LeapsecondEntry(1975,  1, 1, 14.0),
    LeapsecondEntry(1976,  1, 1, 15.0),
    LeapsecondEntry(1977,  1, 1, 16.0),
    LeapsecondEntry(1978,  1, 1, 17.0),
    LeapsecondEntry(1979,  1, 1, 18.0),
    LeapsecondEntry(1980,  1, 1, 19.0),
    LeapsecondEntry(1981,  7, 1, 20.0),
    LeapsecondEntry(1982,  7, 1, 21.0),
    LeapsecondEntry(1983,  7, 1, 22.0),
    LeapsecondEntry(1985,  7, 1, 23.0),
    LeapsecondEntry(1988,  1, 1, 24.0),
    LeapsecondEntry(1990,  1, 1, 25.0),
    LeapsecondEntry(1991,  1, 1, 26.0),
    LeapsecondEntry(1992,  7, 1, 27.0),
    LeapsecondEntry(1993,  7, 1, 28.0),
    LeapsecondEntry(1994,  7, 1, 29.0),
    LeapsecondEntry(1996,  1, 1, 30.0),
    LeapsecondEntry(1997,  7, 1, 31.0),
    LeapsecondEntry(1999,  1, 1, 32.0),
    LeapsecondEntry(2006,  1, 1, 33.0),
    LeapsecondEntry(2009,  1, 1, 34.0),
    LeapsecondEntry(2012,  7, 1, 35.0),
    LeapsecondEntry(2015,  7, 1, 36.0),
    LeapsecondEntry(2017,  1, 1, 37.0)
]

"""
    Leapseconds{T}

Stores information about the leap seconds that have been added to Coordinated Universal Time 
(UTC).

### Fields
- `jd2000`: a vector storing the Julian Date, in days since J2000, of each leap second.
- `leap`: a vector storing the number of leap seconds at each corresponding entry of the 
        `jd2000` field.
"""
struct Leapseconds{T}
    jd2000::Vector{T}
    leap::Vector{T}
end

function Leapseconds{T}() where T
    jd2000 = T[]
    leap = T[]

    for leapEntry in LEAPSECONDS_DATA
        _, d = cal2jd(leapEntry.year, leapEntry.month, leapEntry.day)
        push!(jd2000, d)
        push!(leap, leapEntry.Δs)
    end

    return Leapseconds{T}(jd2000, leap)
end

"""
    LEAPSECONDS

Leapseconds data.
"""
const LEAPSECONDS = Leapseconds{Float64}();

"""
    leapseconds(jd2000::Number)

For a given UTC date, in Julian days since [`J2000`](@ref), calculate Delta(AT) = TAI - UTC.
"""
function leapseconds(jd2000::Number)
    idx = searchsortedlast(LEAPSECONDS.jd2000, jd2000)
    if idx < 1
        @warn "Leapsecond of date $jd2000 not available, returning 0."
        return 0.0
    end

    return LEAPSECONDS.leap[idx]
end
