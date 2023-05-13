# [Epoch handling and timescales conversions](@id tutorial_01_epochs)

```@setup init
using Tempo
```

In this tutorial, the general workflow to be followed when dealing with time representations and their transformations is presented.

The first step is to load the module:

```@repl
using Tempo
```

This package contains the basic routines needed to handle `Epoch`s and their transformations 
as well as some additional types to represent `Date`s, `Time` and `DateTime` objects.

**Then, how and epoch may be represented when using `Tempo`?** 

Well, depends on the actual use case.

As already said, there are different time representations in `Tempo` and they do
depends on the actual information needed for the particular application. In general, when
dealing with _space_ applications, the a time representation shall _embed_ different informations:

1. The representation type (e.g. Gregorian or Julian calendar representation);
2. The origin (e.g. J2000, JD, MJD, ...);
3. The time scale (e.g. TAI, TT, TDB, UTC, UT, ...).

These three informations are considered when building an `Epoch`, which is the most complete
time representation available within `Tempo` and is the one suggested to the user. Then, to 
handle such _complex_ time representation, different constructors are available for `Epoch`
and a _time transformation system_ is available. However, there are some assumptions that
are considered:

1. The (internal) representation type of `Epoch` is always exploiting Julian calendar;
2. The (internal) `Epoch` origin is always `J2000`, i.e. 01 Jan 2000 at noon;
3. The `Epoch` timescale could be any of the _time transformation system_ ones.
4. The default timescale is `TDB`.

## Epoch creation

To create a new `Epoch` object, there are different ways:

### From a ISO string (without scale):

```@example init
e = Epoch("2022-01-02T06:30:00.0")
```

### From ISO string (with scale):

```@example init
e = Epoch("2022-01-02T06:30:00.0 TT")
```

### From a (partial) ISO string:

```@example init
e = Epoch("2020-01-01")
```

```@example init
e = Epoch("2021-01-30T01")
```

```@example init
e = Epoch("2022-06-12 UTC")
```

### From a Julian date:

```@example init
e = Epoch("JD 2451545.0")
```

### From a Modified Julian date:

```@example init
e = Epoch("MJD 51544.5")
```

### From Julian days since J2000:

```@example init
e = Epoch("9.0 TT")
```

### From seconds since J2000:

```@example init
e = Epoch(60.0, TAI)
```

### From `DateTime`:

```@example init
dt = DateTime(2001, 6, 15, 0, 0, 0, 0.0)
e = Epoch(dt, TT)
```

## Epoch transformations

The epoch transformations are allowed by means of a **directed** graph of timescales available in
`Tempo`. While the `offset_xxx` functions provides the offsets in seconds between two timescales 
(e.g. `offset_tai2tt` provide the offset in seconds to convert from `TAI` to `TT`), there
is a simple, effective and efficient entrypoint to all time transformations: the `convert` method.


```@example init
e = Epoch(90.0, TT)
# Convert to TAI
eTAI = convert(TAI, e)
```

Note that e time transformation system is a **directed** graph! To allow to transform back and forth
a given timescale, two transformations are necessary. An error will be displayed in case a 
single transformation is assigned and the reverse one is called. 
