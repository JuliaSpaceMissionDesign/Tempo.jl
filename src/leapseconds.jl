"""
    get_leapseconds()

Parse leapseconds data and return a `Leapseconds` type. 

The leapsecond kernel is retrieved from the artifacts of this package. This artifact will 
be updated whenever a new leapsecond is added.
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
- `lastupdate`: a `DatesDateTime` object representing the date and time when the Leapseconds struct was last updated.
- `jd2000`: a Vector of type T that stores the Julian Date (JD) of each leap second.
- `leap`: a Vector of type T that stores the number of leap seconds that have been added at each corresponding JD in the jd2000 field.

### Example

```julia
jd2000 = [2000.5, 2000.75]
leap = [1, 2]
ls = Leapseconds{Float64}(now(), jd2000, leap)
```
This code creates a new `Leapseconds` object ls, with the current date and time as the 
`lastupdate`, and the `jd2000` and `leap` fields set to the given values. This means that 
1 leap second was added at JD 2000.5 and 2 leap seconds were added at JD 2000.75.
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

For a given UTC date, in Julian days since [`J2000`](@ref) calculate Delta(AT) = TAI - UTC.
"""
function leapseconds(jd2000::Number)
    return LEAPSECONDS.leap[searchsortedlast(LEAPSECONDS.jd2000, jd2000)]
end
