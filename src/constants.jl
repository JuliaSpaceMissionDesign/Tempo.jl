
export DJ2000, DMJD, DJM0

const DAY2SEC = 86400
const YEAR2SEC = 60 * 60 * 24 * 365.25
const CENTURY2SEC = 60 * 60 * 24 * 365.25 * 100
const CENTURY2DAY = 36525

"""
    DJ2000

Reference epoch [`J2000`](@ref), Julian Date (`2451545.0`). 
It is `12:00 01-01-2000`.
"""
const DJ2000 = 2451545

"""
    DMJD

Reference epoch [`J2000`](@ref), Modified Julian Date (`51544.5`).
"""
const DMJD = 51544.5

"""
    DJM0

Julian Date of Modified Julian Date zero point (`2400000.5`).
It is `00:00 17-11-1858`.
"""
const DJM0 = 2400000.5
