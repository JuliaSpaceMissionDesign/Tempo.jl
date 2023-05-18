export TIMESCALES, @timescale, add_timescale!, TimeSystem

"""
    TimeScaleNode{T} <: AbstractGraphNode 

Define a timescale.

### Fields 
- `name` -- timescale name
- `id` -- timescale identification number (ID)
- `parentid` -- ID of the parent timescale
- `ffp` -- offest function from the parent timescale
- `ftp` -- offset function to the parent timescale
"""
struct TimeScaleNode{T} <: AbstractGraphNode
    name::Symbol
    id::Int
    parentid::Int
    ffp::FunctionWrapper{T,Tuple{T}}
    ftp::FunctionWrapper{T,Tuple{T}}
end

get_node_id(s::TimeScaleNode) = s.id

function Base.show(io::IO, s::TimeScaleNode{T}) where {T}
    pstr = "TimeScaleNode{$T}(name=$(s.name), id=$(s.id)"
    s.parentid == s.id || (pstr *= ", parent=$(s.parentid)")
    pstr *= ")"
    return println(io, pstr)
end

# -------------------------------------
# TIMESYSTEM
# -------------------------------------

""" 
    TimeSystem{T}

A `TimeSystem` object manages a collection of default and user-defined [`TimeScaleNode`](@ref)
objects, enabling efficient time transformations between them. It leverages a 
[`MappedDiGraph`](@ref) to keep track of the relationships between the timescales.

---

    TimeSystem{T}()

Create a empty `TimeSystem` object with datatype `T`.

### Examples 
```julia-repl
julia> ts = TimeSystem{Float64}();

julia> @timescale TSA 100 TimeScaleA

julia> add_timescale!(ts, TSA)

# TODO: finish this example
````

### See also 
See also [`@timescale`](@ref) and [`add_timescale!`](@ref).

"""
struct TimeSystem{T<:Number}    
    scales::MappedNodeGraph{TimeScaleNode{T},SimpleDiGraph{Int}}
end

function TimeSystem{T}() where {T}
    return TimeSystem(MappedDiGraph(TimeScaleNode{T}))
end

"""
    add_timescale!(s::TimeSystem, ts::TimeScaleNode)

Register a new node in the `TimeSystem`.

!!! warning 
    This is a low-level function and should not be called by the user.
"""
function add_timescale!(s::TimeSystem{T}, ts::TimeScaleNode{T}) where {T}
    return add_vertex!(s.scales, ts)
end

@inline has_timescale(s::TimeSystem, sid::Int) = has_vertex(s.scales, sid)

@inline timescales(s::TimeSystem) = s.scales

# -------------------------------------
# TIMESCALE
# -------------------------------------

"""
    AbstractTimeScale

All timescales are subtypes of the abstract type `AbstractTimeScale`.
"""
abstract type AbstractTimeScale end

"""
    timescale_alias(scale::AbstractTimeScale)

Return the ID associated to `scale`.
"""
@inline timescale_alias(s::AbstractTimeScale) = timescale_id(s)
timescale_alias(s::Int) = s

"""
    timescale_id(scale::AbstractTimeScale)

Return the ID of `scale`.
"""
timescale_id(::AbstractTimeScale) = nothing

""" 
    timescale_name(scale::AbstractTimeScale)

Return the name of `scale`.
"""
timescale_name(::AbstractTimeScale) = nothing

"""
    @timescale(name, id, type)

Create a new timescale instance to alias the given `id`. This macro creates an 
[`AbstractTimeScale`](@ref) subtype and its singleton instance called `name`. Its `type` 
is obtained by appending `TimeScale` to `name` if it was not provided.

### Examples 
```julia-repl 
julia> @timescale NTS 100 NewTimeScale 

julia> typeof(NTS)

julia> timescale_alias(NTS)
100

julia> @timescale TBH 200

julia> typeof(TBH)

julia> timescale_alias(TBH)
200
```

### See also 
See also [`timescale_alias`](@ref) and [`add_timescale!`](@ref).
"""
macro timescale(name::Symbol, id::Int, type::Union{Symbol, Nothing}=nothing)

    # construct the type name if it was not assigned.
    type = isnothing(type) ? Symbol(name, :TimeScale) : type
    type = Symbol(format_camelcase(Symbol, String(type)))
    type_str = String(type)

    name_split = join(split(type_str, r"(?=[A-Z])"), " ")
    name_str = String(name)

    scaleid_expr = :(@inline Tempo.timescale_id(::$type) = $id)
    name_expr = :(@inline Tempo.timescale_name(::$type) = Symbol($name_str))
    show_expr = :(Base.show(io::IO, ::$type) = print(io, "$($(name_str))"))

    return quote
        """
            $($type_str) <: AbstractTimeScale

        A type representing the $($name_split) ($($name_str)) time scale.
        """
        struct $type <: AbstractTimeScale end

        """
            $($name_str)

        The singleton instance of the [`$($type_str)`](@ref) type representing
        the $($name_split) ($($name_str)) time scale.
        """
        const $(esc(name)) = $(esc(type))()

        $(esc(scaleid_expr))
        $(esc(name_expr))
        $(esc(show_expr))
        nothing
    end
end

function _zero_offset(seconds::T) where {T}
    @error "a zero-offset transformation has been applied in the TimeSystem"
    return T(0.0)
end

""" 
    add_timescale!(system::TimeSystem, scale::AbstractTimeScale)

"""
function add_timescale!(
    ts::TimeSystem{T}, 
    scale::AbstractTimeScale, 
    ffp::Function=_zero_offset;
    ftp=nothing, 
    parent=nothing
) where {T}

    name = Tempo.timescale_name(scale)
    id   = Tempo.timescale_id(scale)
    
    pid = isnothing(parent) ? nothing : timescale_alias(parent)

    if has_timescale(ts, id)
        # Check if a set of timescale with the same ID is already registered within 
        # the given time system 
        throw(
            ArgumentError(
                "TimeScale with id $id is already registered in the given TimeSystem"
            )
        )
    end

    # Check if timescale with the same name also does not already exist
    if name in map(x -> x.name, timescales(ts).nodes)
        throw(
            ArgumentError(
                "TimeScale with name $name is already registered in the given TimeSystem"
            )
        )
    end

    if isnothing(parent)
        # If a root-timescale exists, check that a parent has been specified 
        if !isempty(timescales(ts))
            throw(
                ArgumentError(
                    "a parent timescale is required because the given TimeSystem already "*
                    "contains a root timescale."
                )
            )
        end 

        pid = id  # Root-timescale has parent id = ID 

    else 

        # Check that the parent scale is registered in the time system 
        if !has_timescale(ts, pid)
            throw(
                ArgumentError(
                    "the specified parent timescale with ID $pid is not " *
                    "registered in the given TimeSystem",
                )
            )
        end
    end

    # Create a new timescale node 
    tsnode = TimeScaleNode{T}(name, id, pid, ffp, isnothing(ftp) ? _zero_offset : ftp)

    # Insert the new timescale in the graph
    add_timescale!(ts, tsnode)

    # Connect
    if !isnothing(parent)
        # add transformation from the parent to the new timescale
        add_edge!(timescales(ts), pid, id)

        if !isnothing(ftp)
            # add the transformation from the new timescale to the parent 
            add_edge!(timescales(ts), id, pid)
        end
    end
end


function apply_offsets(
    ts::TimeSystem, sec::Number, from::AbstractTimeScale, to::AbstractTimeScale
)
    apply_offsets(
        ts, sec, get_path(timescales(ts), timescale_alias(from), timescale_alias(to))
    )
end

@inline function apply_offsets(
    scales::TimeSystem{N}, sec::N, path::Vector{Int}
) where {N<:Number}
    # initilize 
    offsec = sec

    tsi = get_mappednode(scales.scales, path[1])
    tsip1 = get_mappednode(scales.scales, path[2])

    offsec += apply_offsets(offsec, tsi, tsip1)

    @inbounds for i in 2:(length(path) - 1)
        tsi = tsip1
        tsip1 = get_mappednode(scales.scales, path[i + 1])
        offsec += apply_offsets(offsec, tsi, tsip1)
    end
    return offsec
end

@inline function apply_offsets(
    sec::N, ts1::TimeScaleNode{N}, ts2::TimeScaleNode{N}
) where {N<:Number}
    if ts1.parentid == ts2.id
        # This is the case in which the inverse transformation (from child to parent)
        # is used 
        offset = ts1.ftp(sec)
    else # ts2.parentid == ts1.id
        # In this case the direct transformation (from parent to child is used)
        offset = ts2.ffp(sec)
    end
    return offset
end

@inline function apply_offsets(
    ::TimeSystem{N}, sec::N, ::S, ::S
) where {N<:Number,S<:AbstractTimeScale}
    return sec
end


# -------------------------------------
# DEFAULT TIMESYSTEM and SCALES
# -------------------------------------

const TIMESCALES_NAMES = (
    :TerrestrialTime,
    :InternationalAtomicTime,
    :CoordinatedUniversalTime,
    :GeocentricCoordinateTime,
    :BarycentricCoordinateTime,
    :BarycentricDynamicalTime,
    :UniversalTime,
    :HighPrecisionBarycentricDynamicalTime,
    :GlobalPositioningSystemTime,
)

const TIMESCALES_ACRONYMS = (:TT, :TAI, :UTC, :TCG, :TCB, :TDB, :UT1, :TDBH, :GPS)

for i in eachindex(TIMESCALES_ACRONYMS)
    @eval begin
        @timescale $(TIMESCALES_ACRONYMS[i]) $i $(TIMESCALES_NAMES[i])
        export $(TIMESCALES_ACRONYMS[i]), $(TIMESCALES_NAMES[i])
    end
end

"""
    TIMESCALES

Default time scales graph, containing at least: $(String.(TIMESCALES_ACRONYMS))

It can be easily extended using the [`@timescale`](@ref) to create new [`TimeScaleNode`](@ref) 
aliases and [`add_timescale!`](@ref) method to define its relation with the other nodes 
in the graph. 

### Example

```@example
# define a new timescale type alias
@timescale NTS 100 NewTimeScale

# define offset to and from another timescale in the graph 
offset_ffp(seconds) = 1.0
offset_ftp(seconds) = -1.0

# connect to the graph, with the parent node (TDB in this example)
add_timescale!(TIMESCALES, NTS, offset_ffp, parent=TDB, ftp=offset_ftp)

### See also 
See also [`@timescale`](@ref), [`TimeScaleNode`](@ref) and [`add_timescale`](@ref).
```
"""
const TIMESCALES::TimeSystem{Float64} = TimeSystem{Float64}()


# FIXME: eventually remove me if the above buit works TIMESCALES

# Populate the default time scales graph
add_timescale!(TIMESCALES, TT, _zero_offset)
add_timescale!(TIMESCALES, TDB, offset_tt2tdb; parent=TT, ftp=offset_tdb2tt)
add_timescale!(TIMESCALES, TAI, offset_tt2tai; parent=TT, ftp=offset_tai2tt)
add_timescale!(TIMESCALES, TCG, offset_tt2tcg; parent=TT, ftp=offset_tcg2tt)
add_timescale!(TIMESCALES, TCB, offset_tdb2tcb; parent=TDB, ftp=offset_tcb2tdb)
add_timescale!(TIMESCALES, UTC, offset_tai2utc; parent=TAI, ftp=offset_utc2tai)
add_timescale!(TIMESCALES, TDBH, offset_tt2tdbh; parent=TT)
add_timescale!(TIMESCALES, GPS, offset_gps2tai; parent=TAI, ftp=offset_tai2gps)