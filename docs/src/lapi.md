# [Low-level API](@id tempo_lapi)

These functions are not meant to be used outside of the package. They are documented only to aid future developments of the package.

## Epochs
```@docs 
Tempo.AbstractEpochOrigin 
Tempo.JulianDate 
Tempo.JulianDate2000
Tempo.ModifiedJulianDate
Tempo.ModifiedJulianDate2000
Tempo.EpochConversionError
Tempo.parse_iso
```

## Timescale Offsets 
```@docs
Tempo.offset
Tempo.offset_gps2tai

Tempo.offset_tai2gps
Tempo.offset_tai2tt
Tempo.offset_tai2utc

Tempo.offset_tcb2tdb
Tempo.offset_tcg2tt

Tempo.offset_tdb2tt
Tempo.offset_tdb2tcb

Tempo.offset_tt2tai
Tempo.offset_tt2tcg
Tempo.offset_tt2tdb
Tempo.offset_tt2tdbh

Tempo.offset_utc2tai
```

## Timescale Types 
```@docs 
Tempo.TimeScaleNode
Tempo.AbstractTimeScale
Tempo.GlobalPositioningSystemTime
Tempo.BarycentricDynamicalTime
Tempo.HighPrecisionBarycentricDynamicalTime
Tempo.BarycentricCoordinateTime
Tempo.TerrestrialTime
Tempo.InternationalAtomicTime
Tempo.UniversalTime
Tempo.CoordinatedUniversalTime
Tempo.GeocentricCoordinateTime
```

## Conversions 
```@docs 
Base.convert

Tempo.cal2jd
Tempo.calhms2jd
Tempo.fd2hms
Tempo.fd2hmsf
Tempo.hms2fd
Tempo.jd2cal
Tempo.jd2calhms

Tempo.tai2utc
Tempo.utc2tai
```

## Leapseconds
```@docs 
Tempo.Leapseconds
Tempo.LEAPSECONDS
Tempo.get_leapseconds
Tempo.leapseconds
```

## Miscellaneous 
```@docs 
Tempo.find_year
Tempo.find_month
Tempo.find_day
Tempo.fraction_of_day
Tempo.fraction_of_second
Tempo.isleapyear
Tempo.lastj2000dayofyear
Tempo.second_in_day
```