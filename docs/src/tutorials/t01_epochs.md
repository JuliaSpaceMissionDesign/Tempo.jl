# [Epochs Handling and Conversions](@id tutorial_01_epochs)

```@setup init
using Tempo
```

In this tutorial, the general workflow to be followed when dealing with time representations and their transformations is presented. In particular, most of the features of this package are designed around the [`Epoch`](@ref) data type, which differently from the [`DateTime`](@ref) object, provides the capability to represent time in different standard and user-define time scales.

## Creating Epochs
Time representions for space applications embed three different concepts: 

1. The representation type (e.g. Gregorian or Julian calendar representation)
2. The origin (e.g. J2000, JD, MJD, ...)
3. The time scale (e.g. TAI, TT, TDB, UTC, UT, ...)

All three infromation are considered when building an [`Epoch`](@ref). In particular, within `Tempo`, the (interal) time representation is always based upon the Julian calendar, with the origin fixed at [`J2000`](@ref), i.e., the 1st of January 2000 at noon. Different timescales are instead available, with the default one being the [`TDB`](@ref). The set of pre-defined time scales supported by this package is: 

* [`TT`](@ref): [Terrestrial Time](https://en.wikipedia.org/wiki/Terrestrial_Time), is a time scale that is used for the prediction or recording of the positions of celestial bodies as measured by an observer on Earth. 
* [`TDB`](@ref): [Barycentric Dynamical Time](https://en.wikipedia.org/wiki/Barycentric_Dynamical_Time) is a relativistic time scale that is used for the prediction or recording of the positions of celestial bodies relative to the solar system's barycenter.
* [`TAI`](@ref): [International Atomic Time](https://en.wikipedia.org/wiki/International_Atomic_Time) is a time scale based on the average frequency of a set of atomic clocks.
* [`TCG`](@ref): [Geocentric Coordinate Time](https://en.wikipedia.org/wiki/Geocentric_Coordinate_Time) is a relativistic coordinate time scale that is used for precise calculations of objects relative to the Earth. 
* [`TCB`](@ref): [Barycentric Coordinate Time](https://en.wikipedia.org/wiki/Barycentric_Coordinate_Time) is a relativistic coordinate time scale that is used for precise calculations of objects in the Solar System.
* [`UTC`](@ref): [Coordinated Universal Time](https://en.wikipedia.org/wiki/Coordinated_Universal_Time) is the primary civil time standard which is kept within one second from the mean solar time (UT1). However, since the rotation of the Earth is irregular, leap seconds are periodically inserted to keep UTC within 0.9 seconds of UT1. 
* [`TDBH`](@ref): Although TDBH is not an official time scale, it is here used to provide a more accurate transformation between [`TT`](@ref) and [`TDB`](@ref), with a maximum error fo about 10 μs between 1600 and 2200. See [`Tempo.offset_tt2tdbh`](@ref) for more details. 
* [`GPS`](@ref): [GPS Time](https://gssc.esa.int/navipedia/index.php/Time_References_in_GNSS) is a continuous time scale defined by the GPS Control segment defined as a constant offset of 19s from [`TAI`](@ref).


### ISO Strings
With this in mind, many different ways are available to create a new `Epoch` object. The first is based upon the [ISO 8601](https://it.wikipedia.org/wiki/ISO_8601) concept, an international standard to represent dates and times. The desired timescale can be either specified by appending its acronym to the string or as a second argument, as follows:

```@repl init
e = Epoch("2022-01-02T06:30:00.0 TT")
e = Epoch("2022-01-02T06:30:00.0")
e = Epoch("2022-01-02T06:30:00.0", TAI)
```

As you can see, when we did not specify a timescale, [`TDB`](@ref) has been used by default. The usage of partial ISO strings is also supported:

```@repl init
e = Epoch("2020-01-01")

e = Epoch("2021-01-30T01")

e = Epoch("2022-06-12 UTC")
```

### Julian Dates 

[`Epoch`](@ref) objects can also be created from Julian Dates, Modified Julian Dates as well as Julian days or seconds since [`J2000`](@ref). To parse a Julian Date, in days, the input string must be in the format `JD DDDDDDDDD.ffffff`:

```@repl init
e = Epoch("JD 2451545.04")
e = Epoch("JD 2451545.04 TT")
```

Similarly, for Modified Julian Dates, the string format is `MJD DDDDDDDDD.ffffff`:

```@repl init
e = Epoch("MJD 51544.54")
e = Epoch("MJD 51544.54 TT")
```

When a prefix is not specified, the epoch constructor assumes the input is expressed as Julian days since [`J2000`](@ref):

```@repl init
e = Epoch("9.0")
e = Epoch("9.0 TT")
```

As you can see, the timescale acronym can always be appended to the predefined string format to override the default time scale. Finally, it is also possible to create an epoch by specifing the number of seconds since [`J2000`](@ref). In the latter case, the constructor has a slightly different form and always requires the timescale argument:

```@repl init
e = Epoch(60.0, TT)
e = Epoch(60.0, TerrestrialTime)
e = Epoch{TerrestrialTime}(60.0)
```

### DateTime 
Finally, an [`Epoch`](@ref) can also be constructed from the [`DateTime`](@ref) object defined within this package:

```@repl init
dt = DateTime(2001, 6, 15, 0, 0, 0, 0.0)
e = Epoch(dt, TT)
e = Epoch(dt, TerrestrialTime)
```

## Working with Epochs

### Basic Operations
The [`Epoch`](@ref) type supports a limited subset of basic mathematical and logical operations on it. For example, the offset, in seconds, between two epochs can be computed by subtracting them: 
```@repl init 
e1 = Epoch(90.0, TT)
e2 = Epoch(50.0, TT)

Δe = e1 - e2

value(Δe)

e3 = Epoch(40, TAI)
e1 - e3
```
Notice that this operation can be performed only if the two epochs are defined on the same timescale. When computing the difference between two epochs, the result is returned in the 
form of a [`Duration`](@ref) object. The [`value`](@ref) can then be used to retrieve the 
actual number of seconds it represents.

Epochs can also be shifted forward and backwards in time by adding or subtracting an arbitrary number of seconds: 
```@repl init 
e1 = Epoch(30.0, TDB)
e1 += 50
e1 -= 30.42
```

You can check whether an epoch is greater than an other with the logical operators:
```@repl init 
e1 = Epoch(50.0, UTC)
e2 = Epoch(50.0, UTC)

e1 > e2 

e1 == e2
```
Again, the operations are supported only if the two epochs belong to the same timescale.

Finally, it is also possible to construct ranges with [`Epoch`](@ref)s, with a default timestep of one Julian day. User-defined timesteps are assumed to be expressed in seconds.

```@repl init 
e1 = Epoch("2024-01-01T12:00:00")

e2 = Epoch("2024-01-05T12:00:00")

collect(e1:e2)

collect(e1:172800:e2)
```

### Julian Dates

A predefined set of functions is also provided to easily convert [`Epoch`] objects to Julian seconds, days and centuries since [`J2000`](@ref):

```@repl init 
e = Epoch("2024-01-01T12:00:00 TAI")

j2000(e)
j2000s(e)
j2000c(e)
```

## Converting Between Time Scales

Epoch transformations between the standard and user-defined timescales are simply performed through the [`convert`](@ref) method by specifying the target time scale

```@repl init
e = Epoch(90.0, TT)
eTAI = convert(TAI, e)

eTCG = convert(TCG, e)
```

These transformations are based on a **directed** graph of timescales ([`TIMESCALES`](@ref)) existing within `Tempo`. Set of functions provide then the offsets in seconds between each pair of connected timescales, offering a simple, effective and efficient way to compute these transformations.

```@repl init
e = Epoch(90.0, TT)
eTAI = convert(TAI, e)
```

### UTC and Leap Seconds

A special remark must be made on the conversion between TAI and UTC. The offset between these two timescales is defined by a leap seconds, which are introduced to keep the UTC time scale within 0.9 seconds from UT1. Since the rotation of the Earth is irregular, it is not possible to predict when a new leap second will be introduced in the future. 

A leapsecond table is embedded within `Tempo` and will be manually updated each time a new 
leapsecond is introduced, so that the effort required from the user side is minimised. Indeed, transforming an [`Epoch`](@ref) from a generic timescale to UTC is a simple as:

```@repl init
e = Epoch(90.0, TT)
eUTC = convert(UTC, e)
```

### UTC to UT1

The offset between UT1 and UTC, which depends upon the rotation of the Earth, is available in the Earth Orientation Parameters (EOP) provided by the International Earth Rotation and Reference System Service ([IERS](https://www.iers.org/IERS/EN/Home/home_node.html)). Since those parameters are also required to compute the orientation of the ITRF with respect to the ICRF, a decision has been made to define the UT1 timescale in [FrameTransformations.jl](https://github.com/JuliaSpaceMissionDesign/FrameTransformations.jl), a different package which enhances `Tempo` with the capability to transform from and to UT1.