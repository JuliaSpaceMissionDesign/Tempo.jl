
"""
    Duration{T} <: Number

A `Duration` represents a period of time, split into an integer number of seconds and a 
fractional part for increased precision.

### Fields
- `seconds`: The integer number of seconds.
- `fraction`: The fractional part of the duration, where `T` is a subtype of `Number`.

---

    Duration(seconds::Number)

Create a `Duration` object from a number of seconds. The type of the fractional part will 
be inferred from the type of the input argument. 

---

    Duration{T}(seconds::Number)

Create a `Duration` object from a number of seconds with the fractional part of type `T`. 

### Examples 
```julia-repl 
julia> d = Duration(10.783)
Duration{Float64}(10, 0.7829999999999995)

julia> value(d) 
10.783

julia> d = Duration{BigFloat64}(10.3)
Duration{BigFloat}(10, 0.300000000000000710542735760100185871124267578125)
```
"""
struct Duration{T} <: Number 
    seconds::Int 
    fraction::T 
end

function Duration{T}(seconds::Number) where {T <: Number}
    i,f = divrem(seconds, 1)
    return Duration{T}(convert(Int, i), T(f))
end

function Duration(seconds::T) where {T <: Number}
    Duration{T}(seconds)  
end 

ftype(::Duration{T}) where T = T

"""
    value(d::Duration)

Return the duration `d`, in seconds.
"""
value(d::Duration{T}) where T = d.seconds + d.fraction

# ---
# Type Conversions and Promotions 

function Base.convert(::Type{Duration{T}}, d::Duration{S}) where {T,S}
    return Duration(d.seconds, convert(T, d.fraction))
end

function Base.convert(::Type{T}, d::Duration{S}) where {T<:Number,S}
    return Duration(d.seconds, convert(T, d.fraction))
end

function Base.promote_rule(::Type{Duration{T}}, ::Type{Duration{S}}) where {T,S}
    return promote_rule(T, S)
end

# ----
# Operations

Base.isless(d::Duration, q::Number) = value(d) < q
Base.isless(q::Number, d::Duration) = q < value(d)
Base.isless(d1::Duration, d2::Duration) = value(d1) < value(d2)

function Base.:+(d::Duration, x::Number)
    es, ef = d.seconds, d.fraction
    xs, xf = divrem(x, 1)
    s, f = fmasf(ef, xf, 1)
    return Duration(convert(Int, es + xs + s), f)
end

function Base.:+(d1::Duration, d2::Duration) 
    s1, f1 = d1.seconds, d1.fraction
    s2, f2 = d2.seconds, d2.fraction
    s, f = fmasf(f1, f2, 1)
    return Duration(convert(Int, s1 + s2 + s), f)
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


function fmasf(a, b, mul)
    amulb = fma(mul, a, b)
    i, f = divrem(amulb, 1)
    return i, f 
end
