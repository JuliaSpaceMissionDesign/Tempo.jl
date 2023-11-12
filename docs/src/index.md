# Welcome to Tempo.jl!

_Efficient Astronomical Time transformations in Julia._

Tempo.jl is an astronomical library that enables fast, efficient and high-accuracy time transformations between common and user-defined time scales and time representations.

## Installation 
This package can be installed using Julia's package manager:
```julia
julia> import Pkg

julia> Pkg.add("Tempo.jl");
```

## Quickstart
Create an [`Epoch`](@ref): 
```julia
# Create an Epoch from an ISO-formatted string
tai = Epoch("2022-10-02T12:04:23.043 TAI")

# Create an Epoch from a Julian Date
jd = Epoch("JD 2451545.0")

# Create an Epoch from a DateTime object and a timescale
dt = DateTime(2001, 6, 15, 0, 0, 0, 0.0)
e = Epoch(dt, TT)
```

Efficiently transform epochs between various timescales:
```julia 
# Convert an Epoch from TAI to TDB 
tai = Epoch("2022-10-02T12:04:23.043 TAI")
tdb = convert(TDB, tai)

# Convert an Epoch from TAI to UTC automatically handling leapseconds 
utc = convert(UTC, tai)
```

## Tempo.jl vs AstroTime.jl 
Tempo.jl and [AstroTime.jl](https://github.com/JuliaAstro/AstroTime.jl) are very similar libraries that allow transformations between 
various astronomical time representations. The major differences are:

- AstroTime.jl supports accurate Epoch transformations by leveraging high 
    precision arithmetics.
- Tempo.jl is more efficient when multiple timescales conversions must be 
    performed to convert a given Epoch (e.g., it does not allocate memory).

