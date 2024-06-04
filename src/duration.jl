
"""
    Duration{T}

A `Duration` represents a period of time, split into an integer number of seconds and a 
fractional part.

### Fields
- `seconds`: The integer number of seconds.
- `fraction`: The fractional part of the duration, where `T` is a subtype of `Number`.
"""
struct Duration{T} 
    seconds::Int 
    fraction::T 
end

function Duration(seconds::T) where {T<:Number}
    i, f = divrem(seconds, 1)
    return Duration{T}(i, f)
end

function Duration(sec::Int, frac::T) where {T<:Number}
    return Duration{T}(sec, frac)
end

value(d::Duration{T}) where T = d.seconds + d.fraction

function Base.isless(d::Duration{T}, q::Number) where T
    return value(d) < q 
end

function Base.isless(d::Duration{T1}, d2::Duration{T2}) where {T1, T2}
    return value(d) < value(d2)
end

function fmasf(a, b, mul)
    amulb = fma(mul, a, b)
    i, f = divrem(amulb, 1)
    return i, f 
end

function Base.:-(d1::Duration, d2::Duration) 
    s1, f1 = d1.seconds, d1.fraction
    s2, f2 = d2.seconds, d2.fraction
    ds, df = divrem(f1 - f2, 1)
    sec = s1 - s2 + ds 
    if df < 0
        sec -= 1
        df += 1
    end
    return Duration(convert(Int, sec), df)
end

function Base.:+(d1::Duration, d2::Duration) 
    s1, f1 = d1.seconds, d1.fraction
    s2, f2 = d2.seconds, d2.fraction
    s, f = fmasf(f1, f2, 1)
    return Duration(convert(Int, s1 + s2 + s), f)
end

function Base.:+(d::Duration, x::Number)
    es, ef = d.seconds, d.fraction
    xs, xf = divrem(x, 1)
    s, f = fmasf(ef, xf, 1)
    return Duration(convert(Int, es + xs + s), f)
end

function Base.:-(d::Duration, x::Number)
    es, ef = d.seconds, d.fraction
    xs, xf = divrem(x, 1)
    ds, df = divrem(ef - xf, 1)
    sec = es - xs + ds
    if df < 0
        sec -= 1
        df += 1
    end
    return Duration(convert(Int, sec), df)
end

