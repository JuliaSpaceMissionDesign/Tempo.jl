
export Date,
    Time,
    year,
    month,
    day,
    find_dayinyear,
    j2000,
    j2000s,
    j2000c,
    hour,
    minute,
    second,
    DateTime


# -------------------------------------
# DATE
# -------------------------------------

"""
    Date

A type to represent a calendar date by storing the year, month and day.

---

    Date(year::Int, month::Int, day::Int)

Construct a `Date` object given the `year`, `month` and `day`.

---

    Date(offset::Integer)

Create a `Date` object given an integer number of days since `2000-01-01`.

---

    Date(year::Integer, dayinyear::Integer)

Create a `Date` object given the `year` and the day of the year `dayinyear`.

### Examples 

```julia-repl 
julia> Date(2020, 1)
2020-01-01

julia> Date(2020, 300)
2020-10-26
```

--- 

    Date(dt::DateTime)

Extract the `Date` object from a [`DateTime`](@ref) structure. 

### See also 
See also [`Time`](@ref) and [`DateTime`](@ref).
"""
struct Date
    year::Int
    month::Int
    day::Int
end

# Constructor given the number of days since J2000.
function Date(offset::Integer)

    year = find_year(offset)
    dayinyear = offset - lastj2000dayofyear(year - 1)
    ly = isleapyear(year)

    month = find_month(dayinyear, ly)
    day = find_day(dayinyear, month, ly)

    return Date(year, month, day)
end

# Constructor given a year and the day of the year
function Date(year::Integer, dayinyear::Integer)
    if dayinyear <= 0
        throw(DomainError("day in year must me ≥ than 0! $dayinyear provided."))
    end

    ly = isleapyear(year)
    month = find_month(dayinyear, ly)
    day = find_day(dayinyear, month, ly)

    return Date(year, month, day)
end

# Constructor given a date and the number of days since that date
Date(d::Date, offset::Integer) = Date(convert(Int, j2000(d)) + offset)

"""
    year(d::Date)

Get year associated to a [`Date`](@ref).
"""
@inline year(d::Date) = d.year

"""
    month(d::Date)

Get month associated to a [`Date`](@ref).
"""
@inline month(d::Date) = d.month

"""
    day(d::Date)

Get day associated to a [`Date`](@ref).
"""
@inline day(d::Date) = d.day

"""
    isleapyear(d::Date)

True if [`Date`](@ref) is within a leap year.
"""
isleapyear(d::Date) = isleapyear(year(d))

"""
    find_dayinyear(d::Date)

Find the day in the year.
"""
find_dayinyear(d::Date) = find_dayinyear(month(d), day(d), isleapyear(d))

"""
    cal2jd(d::Date)

Convert Gregorian calendar [`Date`](@ref) to a Julian Date, in days.

### Outputs
- `j2000` -- J2000 zero point: always 2451545
- `d` -- J2000 Date for 12 hrs
"""
cal2jd(d::Date) = cal2jd(year(d), month(d), day(d))

"""
    j2000(d::Date)

Convert Gregorian calendar date [`Date`](@ref) to a Julian Date since [`J2000`](@ref), 
in days.
"""
j2000(d::Date) = j2000(cal2jd(d)...)


function Base.show(io::IO, d::Date)
    return print(io, year(d), "-", lpad(month(d), 2, '0'), "-", lpad(day(d), 2, '0'))
end

# Operations 
function Base.isapprox(a::Date, b::Date; kwargs...)
    return a.year == b.year && a.month == b.month && a.day == b.day
end

Base.:+(d::Date, x::Integer) = Date(d, x)
Base.:-(d::Date, x::Integer) = Date(d, -x)


# -------------------------------------
# TIME
# -------------------------------------

"""
    Time{T}

A type representing the time of the day storing the hour, minute, seconds and fraction 
of seconds.

---

    Time(hour::Int, minute::Int, second::Int, fraction::T) where {T <: Number}

Create a `Time` object of type `T`.

---

    Time(hour::Int, minute::Int, second::Number)

Construct a `Time` object given the `hour`, `minute` and `seconds`. In this case, the 
seconds can either be an integer or a floating point number. The fraction of seconds will
be computed under the hood.

---

    Time(secondinday::Int, fraction::Number)
    Time(secondinday::Number)

Create a `Time` object given the seconds of the day `secondinday` and/or the fraction of 
seconds. 

---

    Time(dt::DateTime)

Extract the `Time` object from a [`DateTime`](@ref) structure. 

### See also 
See also [`Date`](@ref) and [`DateTime`](@ref).
"""
struct Time{T}
    hour::Int
    minute::Int
    second::Int
    fraction::T

    function Time(
        hour::Integer, minute::Integer, second::Integer, fraction::T
    ) where {T <: Number}
        if hour < 0 || hour > 23
            throw(DomainError(hour, "the hour must be an integer between 0 and 23."))
        elseif minute < 0 || minute > 59
            throw(DomainError(minute, "minutes must be an integer between 0 and 59."))
        elseif second < 0 || second >= 61
            throw(DomainError(second, "seconds must be an integer between 0 and 61."))
        elseif fraction < 0 || fraction > 1
            throw(DomainError(fraction, "fraction must be a number between 0 and 1."))
        end

        return new{T}(hour, minute, second, fraction)
    end
end

# Constructor given hour, minute and seconds as a floating point number
function Time(hour::Integer, minute::Integer, second::Number)
    sec, frac = divrem(second, 1)
    return Time(hour, minute, convert(Int, sec), frac)
end

# Constructor given an integer number of seconds in a day and the fraction of seconds.
function Time(secondinday::Integer, fraction::Number)
    if secondinday < 0 || secondinday > 86400
        throw(
            DomainError(secondinday,
                "the seconds must be between 0 and 86400.",
            ),
        )
    end

    hour = secondinday ÷ 3600
    secondinday -= 3600 * hour
    minute = secondinday ÷ 60
    secondinday -= 60 * minute

    return Time(hour, minute, secondinday, fraction)
end

# Constructor given the seconds in a day as an integer or floating-point number.
function Time(secondinday::Number)
    sec, frac = divrem(secondinday, 1)
    return Time(sec, frac)
end

"""
    hour(t::Time)

Get the current hour.
"""
@inline hour(t::Time) = t.hour

"""
    minute(t::Time)

Get the current minute.
"""
@inline minute(t::Time) = t.minute

"""
    second(::Type{<:AbstractFloat}, t::Time)
    second(::Type{<:Integer}, t::Time)
    second(t::Time)

Get the current second.
"""
second(::Type{<:AbstractFloat}, t::Time) = t.fraction + t.second
second(::Type{<:Integer}, t::Time) = t.second
second(t::Time) = second(Int, t)

function subsecond(fraction, n, r)
    n % 3 == 0 || throw(ArgumentError("`n` must be divisible by 3."))
    factor = ifelse(Int === Int32, widen(10), 10)^n
    rounded = round(fraction, r; digits=n)
    return round(Int, rounded * factor, r) % 1000
end

function subsecond(fraction, n)
    r = ifelse(subsecond(fraction, n + 3, RoundNearest) == 0, RoundNearest, RoundToZero)
    return subsecond(fraction, n, r)
end

subsecond(t::Time, n) = subsecond(t.fraction, n)

"""
    millisecond(t::Time)

Get the current millisecond.
"""
millisecond(t::Time) = subsecond(t.fraction, 3)

"""
    microsecond(t::Time)

Get the current microsecond.
"""
microsecond(t::Time) = subsecond(t.fraction, 6)

"""
    nanosecond(t::Time)

Get the current nanosecond.
"""
nanosecond(t::Time) = subsecond(t.fraction, 9)

hms2fd(t::Time) = hms2fd(t.hour, t.minute, t.second + t.fraction)

"""
    fraction_of_day(t::Time)
    hms2fd(t::Time)

Find the fraction of the day.

### Example

```julia-repl
julia> t = Time(12, 30, 40.3424)
12:30:40.3423

julia> Tempo.fraction_of_day(t)
0.5213002592592593
```
"""
fraction_of_day(t::Time) = hms2fd(t::Time)

"""
    fraction_of_second(t::Time)

Find the fraction of seconds.

### Example

```julia-repl
julia> t = Time(12, 30, 40.3424)
12:30:40.3423

julia> Tempo.fraction_of_second(t)
0.3423999999999978
```
"""
fraction_of_second(t::Time) = t.fraction

"""
    second_in_day(t::Time)

Find the second in the day.

### Example

```julia-repl
julia> t = Time(12, 30, 40.3424)
12:30:40.3423

julia> Tempo.second_in_day(t)
45040.3424
```
"""
second_in_day(t::Time) = t.fraction + t.second + 60 * t.minute + 3600 * t.hour

function Base.show(io::IO, t::Time)
    h = lpad(hour(t), 2, '0')
    m = lpad(minute(t), 2, '0')
    s = lpad(second(t), 2, '0')
    f = lpad(millisecond(t), 3, '0')
    return print(io, h, ":", m, ":", s, ".", f)
end


# -------------------------------------
# DATETIME
# -------------------------------------


"""
    DateTime{T}

A type wrapping a [`Date`](@ref) and a [`Time`](@ref) object.

---

    DateTime(date::Date, time::Time{T})

Construct a `DateTime` object of type `T` from its `Date` and `Time` components.

---

    DateTime(year::Int, month::Int, day::Int, hour::Int, min::Int, sec::Int, frac::Number)

Create a `DateTime` object by parts. 

---

    DateTime(iso::AbstractString)

Create a `DateTime` object from by parsing an ISO datetime string `iso`, in the format 
`YYYY-MM-DDThh:mm:ss.ffffffff`. The DateTime parts not provided in the string will be 
assigned default values.

### Examples 
```julia-repl
julia> DateTime("2023-05-18T20:14:55.02")
2023-05-18T20:14:55.020

julia> Tempo.DateTime("2022-05-12")
2022-05-12T00:00:00.00
```
---

    DateTime(seconds::Number)

Create a `DateTime` object given the number of seconds elapsed since [`J2000`](@ref).

---

    DateTime(d::Date, sec::Number)

Create a `DateTime` object given a `Date` and the number of seconds since midnight.

### Examples 
```julia-repl 
julia> d = Date(2023, 5, 18)
2023-05-18

julia> DateTime(d, 0)
2023-05-18T12:00:00.000

julia> DateTime(d, 1)
2023-05-18T12:00:01.000
```

### See also 
See also [`Date`](@ref), [`Time`](@ref) and [`Epoch`](@ref).
"""
struct DateTime{T}
    date::Date
    time::Time{T}
end

# Default constructor
function DateTime(
    year::N, month::N, day::N, hour::N, min::N, sec::N, frac::Number=0
) where {N<:Integer}

    return DateTime(Date(year, month, day), Time(hour, min, sec, frac))
    
end

# Constructor to parse an ISO string
function DateTime(s::AbstractString)

    length(split(s)) != 1 && throw(error("unable to parse $s as a `DateTime`."))
    dy, dm, dd, th, tm, ts, tms = parse_iso(s)

    return DateTime(dy, dm, dd, th, tm, ts, tms)

end

# Constructor with the number of seconds since J2000
function DateTime(seconds::Number)

    y, m, d, H, M, Sf = jd2calhms(DJ2000, seconds / DAY2SEC)
    s = floor(Int64, Sf)

    return DateTime(y, m, d, H, M, s, Sf - s)

end

# Constructor with the number of seconds in the day
function DateTime(d::Date, sec::Number)

    jd1 = j2000(d) + sec / DAY2SEC
    y, m, d, H, M, Sf = jd2calhms(DJ2000, jd1)
    s = floor(Int64, Sf)

    return DateTime(y, m, d, H, M, s, Sf - s)

end

DateTime{T}(dt::DateTime{T}) where {T} = dt

@inline Date(dt::DateTime) = dt.date
@inline Time(dt::DateTime) = dt.time

"""
    year(d::DateTime)

Get year associated to a [`DateTime`](@ref) type.
"""
year(dt::DateTime) = year(Date(dt))

"""
    month(d::DateTime)

Get month associated to a [`DateTime`](@ref) type.
"""
month(dt::DateTime) = month(Date(dt))

"""
    day(d::DateTime)

Get day associated to a [`DateTime`](@ref) type.
"""
day(dt::DateTime) = day(Date(dt))

"""
    hour(d::DateTime)

Get hour associated to a [`DateTime`](@ref) type.
"""
hour(dt::DateTime) = hour(Time(dt))

"""
    minute(d::DateTime)

Get minute associated to a [`DateTime`](@ref) type.
"""
minute(dt::DateTime) = minute(Time(dt))

"""
    second(::Type{<:AbstractFloat}, t::Time)
    second(d::DateTime)

Get the seconds associated to a [`DateTime`](@ref) type. If a floating-point type is given 
as first argument, the returned value will also account for the fraction of seconds.
"""
second(::Type{T}, dt::DateTime) where T = second(T, Time(dt))
second(dt::DateTime) = second(Time(dt))
# FIXME: qui sopra quale valore si vuole ritornare? Dovrebbe essere consistente con 
# l'utilizzo in `Time`

Base.show(io::IO, dt::DateTime) = print(io, Date(dt), "T", Time(dt))

"""
    j2000(dt::DateTime)

Convert a [`DateTime`](@ref) `dt` in Julian days since [`J2000`](@ref).
"""
function j2000(dt::DateTime)
    jd1, jd2 = calhms2jd(year(dt), month(dt), day(dt), hour(dt), minute(dt), second(dt))
    return j2000(jd1, jd2)
end

"""
    j2000s(dt::DateTime)

Convert a [`DateTime`](@ref) `dt` to seconds since [`J2000`](@ref).
"""
j2000s(dt::DateTime) = j2000(dt::DateTime) * DAY2SEC


"""
    j2000c(dt::DateTime)

Convert  a [`DateTime`](@ref) `dt` in a Julian Date since [`J2000`](@ref), in centuries.
"""
j2000c(dt::DateTime) = j2000(dt) / CENTURY2DAY

# Operations 

Base.isless(d1::DateTime, d2::DateTime) = j2000(d1) < j2000(d2)
Base.:(==)(d1::DateTime, d2::DateTime) = j2000(d1) == j2000(d2)

function Base.isapprox(d1::DateTime, d2::DateTime; kwargs...)
    return isapprox(j2000(d1), j2000(d2); kwargs...)
end

Base.:+(d1::DateTime, δs::Number) = DateTime(j2000s(d1) + δs)
Base.:-(d1::DateTime, δs::Number) = DateTime(j2000s(d1) - δs)



