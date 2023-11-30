# [Timescales graphs and extensions](@id tutorial_02_scales)

In `Tempo`, timescales are connected each other via a **directed graph**. Thanks to the 
structure of the `Tempo` module, it is possible to either extend the current graph of 
scales or create a completely custom one. Both of this possibilities are the subject of 
this tutorial.

```@setup init
using Tempo
```

## Create a timescales graph

To create a computational directed graph to handle timescales, `Tempo` provides the `TimeSystem` type. Therefore, let us define a new time transformation system called `TIMETRANSF`:

```@repl init
const TIMETRANSF = TimeSystem{Float64}()
```

This object contains a graph and the properties associated to the new time-system defined in
`TIMETRANSF`. Note that the computational graph at the moment is empty, thus, we need to 
manually populate it with the new transformations.

## Create a new timescale

In order to insert a new timescale to the graph, a new timescale type alias shall be defined. This can be easily done via the macro `@timescale`. This step requires 3 elements:
- The timescale acronym (user-defined).
- The timescale index (it is an `Int` used to uniquely represent the timescale).
- The timescale fullname.


```@repl init
@timescale DTS 1 DefaultTimeScale
```

## Register the new timescale

Once, created, the new timescale is ready to be registered. If it is the first scale registered in the computational graph, than, nothing else than the type alias is needed and the registration can be performed as follows:

```@setup graph1
using Tempo 
const TIMETRANSF = TimeSystem{Float64}()

@timescale DTS 1 DefaultTimeScale
```

```@repl graph1
add_timescale!(TIMETRANSF, DTS)

TIMETRANSF.scales.nodes
```

Instead, in case the timescale is linked to a parent one, an offset function shall be defined. Remember that the computational graph is **directed**, i.e. the transformation to go back and forth to the parent shall be defined if two-way transformations are desired.

In this example, assume we want to register timescale `NTSA` and a timescale `NTSB`. 
`NTSA` has `DTS` as parent and a constant offset of 1 second. `NTSB` has `NTSA` has parent 
and a linear offset with slope of 1/86400.

Then, first create the new scales:


```@repl init
@timescale NTSA 2 NewTimeScaleA
@timescale NTSB 3 NewTimeScaleB
```

Now, let us define the offset functions for `NTSA`:


```@repl init
const OFFSET_DTS_TO_NTSA = 1.0
@inline offset_dts2ntsa(sec::Number) = OFFSET_DTS_TO_NTSA
@inline offset_ntsa2dts(sec::Number) = -OFFSET_DTS_TO_NTSA
```

We can now register `NTSA` to the computational graph using the `add_timescale!` method:

```@setup graph2
using Tempo 
const TIMETRANSF = TimeSystem{Float64}()

@timescale DTS 1 DefaultTimeScale
@timescale NTSA 2 NewTimeScaleA

add_timescale!(TIMETRANSF, DTS)

const OFFSET_DTS_TO_NTSA = 1.0
@inline offset_dts2ntsa(::Number) = OFFSET_DTS_TO_NTSA
@inline offset_ntsa2dts(::Number) = -OFFSET_DTS_TO_NTSA
```

```@repl graph2
add_timescale!(TIMETRANSF, NTSA, offset_dts2ntsa, parent=DTS, ftp=offset_ntsa2dts)
```

Now, if we have a look to the computational graph, we'll se that `NTSA` is registered:

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

As well as, since we have registered both direct and inverse transformations, there is the 
possibility to transform back and forth from `NTSA` to `DTS`. We can easily see this looking
at the `paths` contained in the computational graph. Here the timescale are represented by means of the type-alias unique integer assigned during the creation of the new type. 

```@repl graph3
TIMETRANSF.scales.paths
```

If now we create a `DTS` epoch, it is possible to use the custom time transformation system
to convert to `NTSA`:

<!-- # Create the new epoch  -->
<!-- # IMPORTANT: only J2000 seconds Epoch parser works with custom timescales. -->
<!-- # Call `convert` using the custom time transformation system  -->

```@repl graph3
e = Epoch(0.0, DTS)

convert(NTSA, e, system=TIMETRANSF)
```

!!! note
    The `system` is an optimal output if the `Tempo` time transformation system is used.

To conclude the example, `NTSB` is has to be inserted. Let's assume that only the transformation `NTSA -> NTSB` can be constructed. Then: 

<!-- # Create the linear offset function -->
<!-- # Register the timescale to the computational graph -->

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

Where the new timescale has been registered with the alias `3`. Note however, that from `3` no transformations are available:

```@repl graph4
TIMETRANSF.scales.paths
```

To conclude, let's test the new time transformation system. Let's take the previous `Epoch` 
translate forward of 2 days and transform to `NTSA` and `NTSB`. We should obtain a translation of `1 sec` and `3 sec` respectively:

<!-- # Translate the epoch -->
```@repl graph4
e += 2*86400
```

<!-- # Convert to `NTSA` -->
```@repl graph4
ea = convert(NTSA, e, system=TIMETRANSF)
```

<!-- # Convert to `NTSB` -->
```@repl graph4
eb = convert(NTSB, e, system=TIMETRANSF)
```


Note that e time transformation system is a **directed** graph! To allow to transform back and forth
a given timescale, two transformations are necessary. An error will be displayed in case a 
single transformation is assigned and the reverse one is called. 
