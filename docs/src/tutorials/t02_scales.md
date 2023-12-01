# [Creating Custom Timescales](@id tutorial_02_scales)

In Tempo.jl, all timescales connections and epoch conversions are handled through a **directed graph**.  A default graph ([`TIMESCALES`](@ref)), containing a set of predefined timescales is provided by this package. However, this package also provided a set of routines to either extend such graph or create a completely custom one. In this tutorial, we will explore both alternatives.

```@setup init
using Tempo
```

## Defining a New Timescale
Custom timescales can be created with the [`@timescale`](@ref) macro, which automatically creates the required types and structures, given the timescale acronym, an integer ID and, eventually, the full name of the timescale. 

```@repl init 
@timescale ET 15 EphemerisTime 
```

The ID is an integer that is internally used to uniquely represent the timescale, whereas the acronym is used to alias such ID. It is also possible to define multiple acronyms associated to the same ID but you cannot assign multiple IDs to the same acronym. In case a full name is not provided, a default one will be built by appending `TimeScale` to the acronym.

!!! warning
    The IDs from 1 to 10 are used to define the standard timescales of the package. To avoid unexpected behaviors, custom timescales should be registered with higher IDs.

In the previous example, we have created a custom timescale named `EphemerisTime`, with ID 15. We are now able to define epochs with respect to ET, but we cannot perform conversions towards other timescales until we register it in a graph system:

```@setup etScale
using Tempo 
@timescale ET 15 EphemerisTime
```

```@repl etScale
ep = Epoch(20.425, ET)

convert(TT, ep)
```

## Extending the Default Graph
In this section, the goal is to register ET as a zero-offset scale with respect to [`TDB`](@ref). To register this timescale in the default graph, we first need to define the offset functions of ET with respect to TDB: 

```@repl init 
offset_tdb2et(sec::Number) = 0
offset_et2tdb(sec::Number) = 0
```

Since we have assumed that the two scales are identical, our functions will always return a zero offset. Rememeber that timescales graph is **directed**, meaning that if the user desires to go back and forth between two timescales, both transformations must be defined. The input argument of such functions is always the number of seconds since J2000 expressed in the origin timescale.

Finally, the [`add_timescale!`](@ref) method can be used to register ET within the default graph:

```@setup scale1 
using Tempo 
@timescale ET 15 EphemerisTime
offset_tdb2et(sec::Number) = 0
offset_et2tdb(sec::Number) = 0
```

```@repl scale1
add_timescale!(TIMESCALES, ET, offset_tdb2et, parent=TDB, ftp=offset_et2tdb)
```

If the inverse transformation (from ET to TDB) is not provided, only one-way epoch conversions will be allowed. We can now check that the desired timescale has been properly registered and performs the same as TDB: 

```@repl scale1
ep = Epoch("200.432 TT")

convert(TDB, ep)

convert(ET, ep)
```

## Creating a Custom Graph

To create a custom directed graph to handle timescales, Tempo.jl provides the [`TimeSystem`](@ref) type. Therefore, let us define a new time transformation system called `TIMETRANSF`:

```@repl init
const TIMETRANSF = TimeSystem{Float64}()
```

This object contains a graph and the properties associated to the new time-system defined in
`TIMETRANSF`. At the moment, the computational graph is empty and we need to manually populate it with the new transformations.

We begin by creating a new timescale: 
```@repl init 
@timescale DTS 1 DefaultTimeScale
```

Once created, the new timescale is ready to be registered. If it is the first scale registered in the computational graph, nothing else than the type alias is needed and the registration can be performed as follows:

```@setup graph1
using Tempo 
const TIMETRANSF = TimeSystem{Float64}()

@timescale DTS 1 DefaultTimeScale
@timescale NTSA 2 NewTimeScaleA
```

```@repl graph1
add_timescale!(TIMETRANSF, DTS)

TIMETRANSF.scales.nodes
```

Instead, in case the timescale is linked to a parent one, offset functions shall be defined. In this example, assume we want to register the timescales `NTSA` and `NTSB` such that
`NTSA` has `DTS` as parent and a constant offset of 1 second, whereas`NTSB` has `NTSA` as parent and a linear offset with slope of 1/86400.

We begin by creating the first timescale:
```@repl init
@timescale NTSA 2 NewTimeScaleA
```

We then define its offset functions and register it in `TIMETRANSF` via the [`add_timescale!`](@ref) method:

```@repl graph1
const OFFSET_DTS_TO_NTSA = 1.0
offset_dts2ntsa(sec::Number) = OFFSET_DTS_TO_NTSA
offset_ntsa2dts(sec::Number) = -OFFSET_DTS_TO_NTSA

add_timescale!(TIMETRANSF, NTSA, offset_dts2ntsa, parent=DTS, ftp=offset_ntsa2dts)
```

Now, if we have a look to the computational graph, we'll see that `NTSA` is registered:

```@setup graph3
using Tempo 
const TIMETRANSF = TimeSystem{Float64}()

@timescale DTS 1 DefaultTimeScale
@timescale NTSA 2 NewTimeScaleA

const OFFSET_DTS_TO_NTSA = 1.0
@inline offset_dts2ntsa(::Number) = OFFSET_DTS_TO_NTSA
@inline offset_ntsa2dts(::Number) = -OFFSET_DTS_TO_NTSA

add_timescale!(TIMETRANSF, DTS)
add_timescale!(TIMETRANSF, NTSA, offset_dts2ntsa, parent=DTS, ftp=offset_ntsa2dts)
```

```@repl graph3
TIMETRANSF.scales.nodes
```

If now we create a `DTS` epoch, we can leverage our custom time transformation system to convert it to an epoch in the `NTSA` timescale:

```@repl graph3 
e = Epoch(0.0, DTS)

convert(NTSA, e, system=TIMETRANSF)
```

Whenever the conversions are based on a custom time system, the graph must be provided as an additional argument to the [`convert`](@ref) method. 

To conclude the example, we will now add the `NTSB` scale but only register the `NTSA -> NTSB` transformation:

```@repl graph3
@timescale NTSB 3 NewTimeScaleB

offset_ntsa2ntsb(sec::Number) = sec/86400.0
add_timescale!(TIMETRANSF, NTSB, offset_ntsa2ntsb, parent=NTSA)
```

Now, let's have a look to the nodes in the graph:

```@setup graph4
using Tempo 
const TIMETRANSF = TimeSystem{Float64}()

@timescale DTS 1 DefaultTimeScale
@timescale NTSA 2 NewTimeScaleA
@timescale NTSB 3 NewTimeScaleB

const OFFSET_DTS_TO_NTSA = 1.0
@inline offset_dts2ntsa(::Number) = OFFSET_DTS_TO_NTSA
@inline offset_ntsa2dts(::Number) = -OFFSET_DTS_TO_NTSA
@inline offset_ntsa2ntsb(sec::Number) = sec/86400.0

add_timescale!(TIMETRANSF, DTS)
add_timescale!(TIMETRANSF, NTSA, offset_dts2ntsa, parent=DTS, ftp=offset_ntsa2dts)
add_timescale!(TIMETRANSF, NTSB, offset_ntsa2ntsb, parent=NTSA)

e = Epoch(0.0, DTS)
```

```@repl graph4
TIMETRANSF.scales.nodes
```

You can see that the new timescale has been registered with the desired integer ID `3`. To test the complete system, we will translate forwad of 2 days the previous epoch `e` and transform it in both timescales: 

```@repl graph4 

e += 2*86400

ea = convert(NTSA, e, system=TIMETRANSF)

eb = convert(NTSB, e, system=TIMETRANSF)
```

As expected, we obtain translations of 1 and 3 seconds, respectively.
