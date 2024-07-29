# This is the default timescale used by Epochs 
const DEFAULT_EPOCH_TIMESCALE = :TDB

"""
    Epoch{S, T}

A type to represent Epoch-like data. Epochs are internally represented as seconds + fraction of 
seconds since a reference epoch, which is considered to be `2000-01-01T12:00:00`, 
i.e. [`J2000`](@ref).

---

    Epoch(sec::Number, scale::AbstractTimeScale)
    Epoch(sec::Number, scale::Type{<:AbstractTimeScale})
    Epoch{S}(seconds::Number) where {S <: AbstractTimeScale}


Create an `Epoch` object from the number of seconds since [`J2000`](@ref) with the 
timescale `S`.

---

    Epoch(dt::DateTime, scale::AbstractTimeScale)
    Epoch(dt::DateTime, scale::Type{<:AbstractTimeScale})

Create an `Epoch` object from a `DateTime` structure with timescale `scale`.

---

    Epoch(str::AbstractString, scale::AbstractTimeScale)
    Epoch(str::AbstractString)

Create an `Epoch` object from an ISO-formatted string. The timescale can either be 
specified as a second argument or written at the end of the string. 

This constructor requires that the `str` is in the format:

- **ISO** -- `yyyy-mm-ddTHH:MM:SS.ffff` : assume J2000 as origin
- **J2000** -- `DDDD.ffff` : parse Julian Date since J2000, in days
- **JD** -- `JD DDDDDDDDD.ffffff` : parse Julian Date, in days
- **MJD** -- `MJD DDDDDDDDD.ffffff` : parse a Modified Julian Date, in days

A `TimeScale` can be added at the end of the string, separated by a whitespace. 
If it is not declared, [`TDB`](@ref) will be used as a default timescale. 

### Examples 
```julia-repl 
julia> Epoch("2050-01-01T12:35:15.0000 TT")
2050-01-01T12:35:14.9999 TT

julia> Epoch("2050-01-01T12:35:15.0000")
2050-01-01T12:35:14.9999 TDB

julia> Epoch("JD 2400000.5")
1858-11-17T00:00:00.0000 TDB

julia> Epoch("MJD 51544.5")
2000-01-01T12:00:00.0000 TDB

julia> Epoch("12.0")
2000-01-13T12:00:00.0000 TDB

julia> Epoch("12.0 TT")
2000-01-13T12:00:00.0000 TT
```
"""
struct Epoch{S,T}
    scale::S
    dur::Duration{T}
end

function Epoch{S}(seconds::Number) where {S<:AbstractTimeScale}
    d = Duration(seconds)
    return Epoch{S, ftype(d)}(S(), d)
end

Epoch(sec::Number, ::S) where {S<:AbstractTimeScale} = Epoch{S}(sec)
Epoch(sec::Number, ::Type{S}) where {S<:AbstractTimeScale} = Epoch{S}(sec)

Epoch(dt::DateTime, ::S) where {S<:AbstractTimeScale} = Epoch{S}(j2000s(dt))
Epoch(dt::DateTime, ::Type{S}) where {S<:AbstractTimeScale} = Epoch{S}(j2000s(dt))

Epoch(e::Epoch) = e

Epoch{S,T}(e::Epoch{S,T}) where {S,T} = e
Epoch{S,T}(e::Epoch{S,N}) where {S, N, T} = Epoch{S,T}(e.scale, convert(T, e.dur))

# Construct an epoch from an ISO string and a scale
function Epoch(s::AbstractString, scale::S) where {S <: AbstractTimeScale}
    y, m, d, H, M, sec, sf = parse_iso(s)

    # TODO: the precision of this could be improved
    _, jd2 = calhms2jd(y, m, d, H, M, sec + sf)
    return Epoch(jd2 * DAY2SEC, scale)
end

# Construct an epoch from an ISO string
function Epoch(s::AbstractString)

    scale = eval(DEFAULT_EPOCH_TIMESCALE) # default timescale

    # ISO 
    m = match(r"\d{4}-", s)
    if !isnothing(m) && length(m.match) != 0
        sub = split(s, " ")
        if length(sub) == 2 # check for timescale
            scale = eval(Symbol(sub[2]))
        end
        return Epoch(sub[1], scale)
    end

    # JD
    m = match(r"JD", s)
    mjd = match(r"MJD", s)
    if !isnothing(m) && isnothing(mjd) && length(m.match) != 0
        sub = split(s, " ")
        if length(sub) == 3 # check for timescale
            scale = eval(Symbol(sub[3]))
        end
        days = parse(Float64, sub[2])
        sec = (days - DJ2000) * DAY2SEC
        return Epoch(sec, scale)
    end

    # MJD
    m = mjd
    if !isnothing(m) && length(m.match) != 0
        sub = split(s, " ")
        if length(sub) == 3 # check for timescale
            scale = eval(Symbol(sub[3]))
        end
        days = parse(Float64, sub[2])
        sec = (days - DMJD) * DAY2SEC
        return Epoch(sec, scale)
    end

    # J2000
    sub = split(s, " ")
    if length(sub) == 2 # check for timescale
        scale = eval(Symbol(sub[2]))
    end
    return Epoch(parse(Float64, sub[1]) * DAY2SEC, scale)
end

"""
    timescale(e::Epoch)

Epoch timescale.
"""
timescale(e::Epoch) = e.scale

"""
    value(e::Epoch)

Full `Epoch` value.
"""
@inline value(e::Epoch) = value(e.dur)

"""
    j2000(e::Epoch)

Convert `Epoch` in Julian Date days since [`J2000`](@ref).
"""
j2000(e::Epoch) = value(e) / DAY2SEC

"""
    j2000s(e::Epoch)

Convert `Epoch` in Julian Date seconds since [`J2000`](@ref).
"""
j2000s(e::Epoch) = value(e)

"""
    j2000c(e::Epoch)

Convert `Epoch` in Julian Date centuries since [`J2000`](@ref).
"""
j2000c(e::Epoch) = value(e) / CENTURY2SEC

"""
    doy(e::Epoch)

Find day of year.
"""
function doy(e::Epoch) 
    Y, M, D, _ = jd2cal(DJ2000, j2000(e))
    return find_dayinyear(M, D, isleapyear(Y))
end

function Base.show(io::IO, ep::Epoch)
    return print(io, DateTime(ep), " ", timescale(ep))
end

# ----
# Operations

function Base.:-(e1::Epoch{S}, e2::Epoch{S}) where S 
    return e1.dur - e2.dur
end
function Base.:-(::Epoch{S1}, ::Epoch{S2}) where {S1, S2}
    throw(ErrorException("only epochs defined in the same timescale can be subtracted."))
end 

Base.:+(e::Epoch, x::Number) = Epoch(timescale(e), e.dur + x)
Base.:-(e::Epoch, x::Number) = Epoch(timescale(e), e.dur - x)

function (::Base.Colon)(start::Epoch, step::Number, stop::Epoch)
    step = start < stop ? step : -step
    diff = value(stop - start)
    return StepRangeLen(start, step, floor(Int, diff / step) + 1)
end

function (::Base.Colon)(start::Epoch, step::Duration, stop::Epoch)
    return (:)(start, value(step), stop)
end

Base.isless(e1::Epoch{S}, e2::Epoch{S}) where {S} = e1.dur < e2.dur

function Base.isapprox(e1::Epoch{S}, e2::Epoch{S}; kwargs...) where {S}
    return isapprox(value(e1), value(e2); kwargs...)
end

# ---
# Type Conversions and Promotions 

Base.convert(::Type{S}, e::Epoch{S}) where {S<:AbstractTimeScale} = e
Base.convert(::S, e::Epoch{S}) where {S<:AbstractTimeScale} = e

Base.convert(::Type{N}, e::Epoch{S, N}) where {S, N} = e
Base.convert(::Type{T}, e::Epoch{S, N}) where {S, N, T <: Number} = Epoch{S, T}(e)
Base.convert(::Type{Epoch{S, N}}, e::Epoch{S, T}) where {S, T, N <: Number} = Epoch{S, N}(e)

"""
    convert(to::S2, e::Epoch{S1}; system::TimeSystem=TIMESCALES)

Convert `Epoch` with timescale `S1` to `S2`. Allows to use the default `TimeSystem` or 
a custom constructed one. 
"""
function Base.convert(
    to::S2, e::Epoch{S1}; system::TimeSystem = TIMESCALES
) where {S1 <: AbstractTimeScale, S2 <: AbstractTimeScale}

    try
        return Epoch{S2}(apply_offsets(system, value(e), timescale(e), to))

    catch
        throw(EpochConversionError("cannot convert Epoch from the timescale $S1 to $S2."))
    end

end

"""
    DateTime(e::Epoch) 

Construct a `DateTime` object from an [`Epoch`](@ref).
"""
function DateTime(ep::Epoch)
    y, m, d, H, M, S = jd2calhms(DJ2000, j2000(ep))
    s, f = divrem(S, 1)

    return DateTime(y, m, d, H, M, convert(Int, s), f)
end

