
const MTAB = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
const PREVIOUS_MONTH_END_DAY_LEAP = (0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335)
const PREVIOUS_MONTH_END_DAY = (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334)

"""
    isleapyear(year::Integer)

Return `true` if the given Gregorian year is leap.
"""
function isleapyear(year::Integer)
    return year % 4 == 0 && (year % 400 == 0 || year % 100 != 0)
end

"""
    find_dayinyear(month::Integer, day::Integer, isleap::Bool)

Find the day of the year given the month, the day of the month and whether the year 
is leap or not.
"""
function find_dayinyear(month::Integer, day::Integer, isleap::Bool)
    if isleap 
        return day + PREVIOUS_MONTH_END_DAY_LEAP[month]
    else 
        return day + PREVIOUS_MONTH_END_DAY[month]
    end
end

"""
    find_year(d::Integer)

Return the Gregorian year associated to the given Julian Date day `d` since [`J2000`](@ref).
"""
function find_year(d::Integer)
    
    j2d = ifelse(d isa Int32, widen(d), d)
    year = (400 * j2d + 292194288) ÷ 146097

    # The previous estimate is one unit too high in some rare cases
    # (240 days in the 400 years gregorian cycle, about 0.16%)
    if j2d <= lastj2000dayofyear(year - 1)
        year -= 1
    end

    return year
end

"""
    find_month(dayinyear::Integer, isleap::Bool)

Find the month from the day of the year, depending on whether the year is leap or not.
"""
function find_month(dayinyear::Integer, isleap::Bool)
    offset = ifelse(isleap, 313, 323)
    return ifelse(dayinyear < 32, 1, (10 * dayinyear + offset) ÷ 306)
end

"""
    find_day(dayinyear::Integer, month::Integer, isleap::Bool)

Find the day of the month from the day in the year and the month, depending on whether the 
year is leap or not.
"""
function find_day(dayinyear::Integer, month::Integer, isleap::Bool)
    
    (!isleap && dayinyear > 365) && throw(
        DomainError(dayinyear, " the day cannot be greater than 366 for a non-leap year."),
    )
    previous_days = ifelse(isleap, PREVIOUS_MONTH_END_DAY_LEAP, PREVIOUS_MONTH_END_DAY)
    return dayinyear - previous_days[month]
end

""" 
    lastj2000dayofyear(year::Integer)
"""
function lastj2000dayofyear(year::Integer)
    # TODO: da documentare la roba che fa questa qua
    return 365 * year + year ÷ 4 - year ÷ 100 + year ÷ 400 - 730120
end

"""
    hms2fd(hour::Integer, minute::Integer, second::Number)

Convert hours, minutes and seconds to day fraction.

### Examples 
```julia-repl
julia> Tempo.hms2fd(12, 0, 0.0)
0.5
```
"""
function hms2fd(h::Integer, m::Integer, s::Number)

    # Validate arguments
    if h < 0 || h > 23
        throw(DomainError(h, "the hour shall be between 0 and 23."))
    elseif m < 0 || m > 59
        throw(DomainError(m, "the minutes must be between 0 and 59."))
    elseif s < 0 || s >= 60
        throw(DomainError(s, "the seconds must be between 0.0 and 59.99999999999999."))
    end

    return ((60 * (60 * h + m)) + s) / 86400

end

"""
    fd2hms(fd::Number) 

Convert the day fraction `fd` to hour, minute and seconds.
"""
function fd2hms(fd::Number)

    secinday = fd * 86400
    if secinday < 0 || secinday > 86400
        throw(
            DomainError(secinday, 
                "seconds are out of range: they must be between 0 and 86400."
            ),
        )
    end

    hours = Int(secinday ÷ 3600)
    secinday -= 3600 * hours
    mins = Int(secinday ÷ 60)
    secinday -= 60 * mins

    return hours, mins, secinday

end

"""
    fd2hmsf(fd::Number) 

Convert the day fraction `fd` to hour, minute, second and fraction of seconds.

### Examples 
```julia-repl
julia> Tempo.fd2hms(0.5)
(12, 0, 0.0)
```
"""
function fd2hmsf(fd::Number)

    h, m, sid = fd2hms(fd)
    sec = Int(sid ÷ 1)
    fsec = sid - sec

    return h, m, sec, fsec

end

"""
    cal2jd(year::Integer, month::Integer, day::Integer)

This function converts a given date in the Gregorian calendar (year, month, day) to the 
corresponding two-parts Julian Date. The first part is the [`DJ2000`](@ref), while the 
second output is the number of days since [`J2000`](@ref).

The year must be greater than 1583, and the month must be between 1 and 12. The day must 
also be valid, taking into account whether the year is a leap year. If the input year or 
month or day are invalid, a `DomainError` is thrown.

### Examples 
```julia-repl
julia> Tempo.cal2jd(2021, 1, 1)
(2.4000005e6, 59215.0)

julia> Tempo.cal2jd(2022, 2, 28)
(2.4000005e6, 59638.0)

julia> Tempo.cal2jd(2019, 2, 29)
ERROR: DomainError with 29:
the day shall be between 1 and 28.
```

### References
- Seidelmann P. K., (1992), Explanatory Supplement to the Astronomical Almanac,
    University Science Books, Section 12.92 (p604).
- Klein, A., (2006), A Generalized Kahan-Babuska-Summation-Algorithm.
    Computing, 76, 279-293, Section 3.
- [ERFA software library](https://github.com/liberfa/erfa/blob/master/src/cal2jd.c)
"""
function cal2jd(Y::Integer, M::Integer, D::Integer)
    
    # Validate year and month
    if Y < 1583
        throw(DomainError(Y, "the year shall be greater than 1583."))

    elseif M < 1 || M > 12
        throw(DomainError(M, "the month shall be between 1 and 12."))
    end

    # If February in a leap year, 1, otherwise 0
    isleap = isleapyear(Y)
    ly = (M == 2) && isleap

    # Validate day, taking into account leap years
    if (D < 1) || (D > (MTAB[M] + ly))
        throw(DomainError(D, "the day shall be between 1 and $(MTAB[M]+ly)."))
    end

    Y = Y - 1
    # find j2000 day of the year 
    d1 = 365 * Y + Y ÷ 4 - Y ÷ 100 + Y ÷ 400 - 730120
    # find day in the year
    d2 = find_dayinyear(M, D, isleap)
    # compute days since 01-01-2000 at noon
    d = d1 + d2

    return DJ2000, d
    
end

"""
    calhms2jd(year, month, day, hour, minute, seconds) 

Convert Gregorian Calendar date and time to a two-parts Julian Date. The first part 
is the [`DJ2000`](@ref), while the second output is the number of days since [`J2000`](@ref).

### Examples 
```julia-repl
julia> Tempo.calhms2jd(2000, 1, 1, 12, 0, 0)
(2.451545e6, 0.0)

julia> Tempo.calhms2jd(2022, 1, 1, 0, 0, 0)
(2.451545e6, 8035.5)
```
"""
function calhms2jd(Y::I, M::I, D::I, h::I, m::I, sec::N) where {I <: Integer, N <: Number}
    
    jd1, jd2 = cal2jd(Y, M, D)
    fd = hms2fd(h, m, sec)

    return jd1, jd2 + fd - 0.5

end

""" 
    jd2cal(dj1::Number, dj2::Number)

This function converts a given Julian Date (JD) to a Gregorian calendar date 
(year, month, day, and fraction of a day).

### Examples 

```julia-repl
julia> Tempo.jd2cal(DJ2000, 0.0)
(2000, 1, 1, 0.5)

julia> Tempo.jd2cal(DJ2000, 365.5)
(2001, 1, 1, 0.0)

julia> Tempo.jd2cal(DJ2000 + 365, 0.5)
(2001, 1, 1, 0.0)
```

!!! note
    The Julian Date is apportioned in any convenient way between the arguments 
    `dj1` and `dj2`. For example, `JD = 2450123.7` could be expressed in any of these 
    ways, among others:

    | dj1       	| dj2     	|                      	|
    |-----------	|---------	|----------------------	|
    | 2450123.7 	| 0.0     	| (JD method)          	|
    | 2451545.0 	| -1421.3 	| (J2000 method)       	|
    | 2400000.5 	| 50123.2 	| (MJD method)         	|
    | 2450123.5 	| 0.2     	| (date & time method) 	|

!!! warning
    The earliest valid date is -68569.5 (-4713 Jan 1). The largest value accepted is 1e9.

### References
- Seidelmann P. K., (1992), Explanatory Supplement to the Astronomical Almanac,
    University Science Books, Section 12.92 (p604).

- Klein, A., (2006), A Generalized Kahan-Babuska-Summation-Algorithm.
    Computing, 76, 279-293, Section 3.
    
- [ERFA software library](https://github.com/liberfa/erfa/blob/master/src/jd2cal.c)

"""
function jd2cal(dj1::Number, dj2::Number)

    dj = dj1 + dj2
    if dj < -68569.5 || dj > 1e9
        throw(DomainError(dj, "the Julian Date shall be between -68569.5 and 1e9."))
    end
    
    d1 = round(Int, dj1)
    d2 = round(Int, dj2)
    jd = d1 + d2

    # Separate day and fraction
    f1, f2 = promote(dj1 - d1, dj2 - d2)     

    # Compute f1 + f2 + 0.5 using the compensated summation for improved accuracy.
    s  = 0.5*one(f1) 
    cs = zero(f1)

    for x in (f1, f2)
        t = s + x 
        cs += abs(s) >= abs(x) ? (s-t) + x : (x-t) + s 
        s = t 
        if (s >= 1)
            jd += 1
            s -= 1
        end
    end

    f = s + cs 
    cs = f - s

    # Deal with negative f 
    if f < 0 
        # Compensated summation: assume that |s| <= 1.0 
        f = s + 1 
        cs += (1 - f) + s
        s = f 
        f = s + cs 
        cs = f - s 
        jd -= 1 
    end

    # Deal with f that is 1.0 or more (when rounded to double)
    if ((f-1) >= -eps(f)/4)

        # Compensation summation: assume that |s| <= 1.0 
        t = s - 1 
        cs += (s - t) - 1 
        s = t 
        f = s + cs 
        if (-eps()/2 < f)
            jd += 1 
            f = max(f, zero(f))
        end
    end
    
    # Express day in Gregorian calendar 
    l = jd + 68569 
    n = (4l) ÷ 146097
    l -= (146097n + 3) ÷ 4 
    i = (4000*(l + 1)) ÷ 1461001
    l -= (1461i) ÷ 4 - 31 
    k = (80l) ÷ 2447 

    D = (l - (2447k) ÷ 80)
    l = k ÷ 11 
    M = k + 2 - 12l
    Y = 100*(n - 49) + i + l
    fd = f 

    return Y, M, D, fd

end

"""
    jd2calhms(dj1::Number, dj2::Number)

Convert a two-parts Julian Date to Gregorian year, month, day, hour, minute, seconds. See 
[`jd2cal`](@ref) for more information on the Julian Date composition. 

```julia-repl 
julia> Tempo.jd2calhms(DJ2000, 0.0)
(2000, 1, 1, 12, 0, 0.0)

julia> Tempo.jd2calhms(DJ2000 + 1, 0.25)
(2000, 1, 2, 18, 0, 0.0)

julia> Tempo.jd2calhms(DJ2000, 1.25)
(2000, 1, 2, 18, 0, 0.0)
```
"""
function jd2calhms(dj1::Number, dj2::Number)

    y, m, d, fd = jd2cal(dj1, dj2)
    h, min, sec = fd2hms(fd)

    return y, m, d, h, min, sec

end

"""
    utc2tai(utc1, utc2)

Transform a 2-part (quasi) Julian Date, in days, in Coordinate Universal Time, [`UTC`](@ref) 
to a 2-part Julian Date in the International Atomic Time, [`TAI`](@ref) scale.

!!! note
    `utc1 + utc2` is quasi Julian Date (see Note 2), apportioned in any
    convenient way between the two arguments, for example such that `utc1`
    is the Julian Day Number and `utc2` is the fraction of a day.

!!! note
    JD cannot unambiguously represent UTC during a leap second unless
    special measures are taken.  The convention in the present
    function is that the JD day represents UTC days whether the
    length is 86399, 86400 or 86401 SI seconds.  

### References
    
- Seidelmann P. K., (1992), Explanatory Supplement to the Astronomical Almanac,
    University Science Books, Section 12.92 (p604).

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- [ERFA software library](https://github.com/liberfa/erfa/blob/master/src/utctai.c)
"""
function utc2tai(utc1, utc2)

    # Put the two parts of the UTC into big-first order
    big1 = abs(utc1) >= abs(utc2)

    if big1
        u1, u2 = promote(utc1, utc2)
    else
        u1, u2 = promote(utc2, utc1)
    end

    # Get TAI-UTC at 0h today
    _, _, _, fd = jd2cal(u1, u2)
    Δt0 = leapseconds((u1 - DJ2000) + u2)
    z2 = u2 - fd

    # Get TAI-UTC at 0h tomorrow (to detect jumps)
    Δt24 = leapseconds((u1 - DJ2000) + u2)

    # Detect any jump
    # Spread leap into preceding day
    fd += (Δt24 - Δt0) / 86400

    # Assemble the TAI result, preserving the UTC split and order
    a2 = z2 + fd + Δt0 / 86400

    if big1
        tai1, tai2 = promote(u1, a2)
    else
        tai1, tai2 = promote(a2, u1)
    end

    return tai1, tai2

end

"""
    tai2utc(tai1, tai2)

Transform a 2-part (quasi) Julian Date, in days, in International Atomic Time, [`TAI`](@ref) 
to a 2-part Julian Date in the Coordinated Universal Time, [`UTC`](@ref), scale.

!!! note
    `tai1 + tai2` is Julian Date, apportioned in any convenient way
    between the two arguments, for example such that `tai1` is the Julian
    Day Number and `tai2` is the fraction of a day.  The returned `utc1` 
    and `utc2` form an analogous pair.

!!! note
    JD cannot unambiguously represent UTC during a leap second unless
    special measures are taken.  The convention in the present
    function is that the JD day represents UTC days whether the
    length is 86399, 86400 or 86401 SI seconds.  

### References
    
- Seidelmann P. K., (1992), Explanatory Supplement to the Astronomical Almanac,
    University Science Books, Section 12.92 (p604).

- McCarthy, D. D., Petit, G. (eds.), IERS Conventions (2003),
    IERS Technical Note No. 32, BKG (2004)

- [ERFA software library](https://github.com/liberfa/erfa/blob/master/src/taiutc.c)
"""
function tai2utc(tai1, tai2)

    # Put the two parts of the UTC into big-first order
    big1 = abs(tai1) >= abs(tai2)
    if big1
        a1, a2 = promote(tai1, tai2)
    else
        a1, a2 = promote(tai2, tai1)
    end

    # Initial guess for UTC
    u1 = a1
    u2 = a2
    
    #  Iterate (in most cases just once is enough)
    for _ in 1:2
        g1, g2 = utc2tai(u1, u2)
        u2 += a1 - g1
        u2 += a2 - g2
    end

    # Return the UTC result, preserving the TAI order
    if big1
        utc1, utc2 = promote(u1, u2)
    else
        utc1, utc2 = promote(u2, u1)
    end

    return utc1, utc2
    
end

"""
    j2000(jd)
    j2000(jd1, jd2)

Convert Julian Date in days since J2000
"""
@inline j2000(jd) = jd - DJ2000
@inline j2000(jd1, jd2) = abs(jd1) > abs(jd2) ? (jd1 - DJ2000) + jd2 : (jd2 - DJ2000) + jd1

"""
    j2000s(jd)
    j2000s(jd1, jd2)

Convert Julian Date (in days) in seconds past J2000 
"""
@inline j2000s(jd) = j2000(jd) * DAY2SEC
@inline j2000s(jd1, jd2) = j2000(jd1, jd2) * DAY2SEC

"""
    j2000c(jd)
    j2000c(jd1, jd2)

Convert Julian Date (in days) to Julian Centuries
"""
@inline j2000c(jd) = j2000(jd) / CENTURY2DAY
@inline j2000c(jd1, jd2) = j2000(jd1, jd2) / CENTURY2DAY
