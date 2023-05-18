@testset "Date" begin
    ry = rand(1800:2100)
    rm = rand(1:12)
    ly = Tempo.isleapyear(ry)
    if ly && rm == 2
        rd = rand(1:29)
    elseif rm == 2
        rd = rand(1:28)
    else
        rd = rand(1:Tempo.MTAB[rm])
    end

    d = Date(ry, rm, rd)
    @test year(d) == ry
    @test month(d) == rm
    @test day(d) == rd
    @test Tempo.isleapyear(d) == ly

    d = Date(2000, 1, 1)
    @test d == Date(0)
    @test d == Date(2000, 1)
    @test Tempo.j2000(d) == 0
    @test Tempo.find_dayinyear(d) == 1

    @test Tempo.find_month(32, true) == 2
    @test Tempo.find_day(32, 2, true) == 1
    @test d + 1 == Date(1)
    @test Date(1) - 1 == d
end

@testset "Time" begin
    t0 = Time(12, 0, 0.0)
    @test t0 == Time(86400 ÷ 2, 0.0)

    t = Time(12, 1, 15.300300300)
    @test Tempo.millisecond(t) == 300
    @test Tempo.microsecond(t) == 300
    @test Tempo.nanosecond(t) == 300
    @test Tempo.second(Float64, t) == 15.300300300
    @test Tempo.second(Int64, t) == 15
    @test Tempo.fraction_of_second(t) ≈ 0.300300300

    @test_throws Exception Time(-1, 0, 0.0) 
    @test_throws Exception Time(25, 0, 0.0)
    @test_throws Exception Time(1, 61, 0, 0.0)
    @test_throws Exception Time(1, 0, 61, 0.0)
    @test_throws Exception Time(1, 0, 0, 61.0)  
    @test_throws Exception Time(86401, 0.0)

    @test second(t) == 15
    @test Tempo.hms2fd(t0) == 0.5
    @test Tempo.fraction_of_second(t0) == 0.0
    for _ in 1:30
        fs = rand(0.0:0.99999)
        t1 = Time(0, 0, 0, fs)
        @test Tempo.fraction_of_second(t1) == fs
    end
    @test Tempo.second_in_day(t0) == 43200.0
end

@testset "DateTime" begin
    d = Date(2000, 1, 1)
    t0 = Time(12, 0, 0.0)
    J2000 = DateTime(d, 0.0)
    @test t0 == Time(J2000)
    @test d == Date(J2000)

    s = "2000-01-01T12:00:00.0"
    @test J2000 == DateTime(s)
    @test J2000 == DateTime(0.0)

    D2 = DateTime(Tempo.DAY2SEC / 3)
    @test Tempo.j2000(D2) ≈ 1 / 3 atol=1e-11 rtol=1e-11
    @test Tempo.j2000s(D2) ≈ 1 / 3 * Tempo.DAY2SEC atol=1e-11 rtol=1e-11
    @test Tempo.j2000c(D2) ≈ 1 / 3 / Tempo.CENTURY2DAY atol=1e-11 rtol=1e-11

    _, ry, rm, rd, rH, rM, rS, rF = _random_datetime_isostr()
    dt = DateTime(ry, rm, rd, rH, rM, rS, rF)
    @test year(dt) == ry
    @test month(dt) == rm
    @test day(dt) == rd
    @test hour(dt) == rH
    @test minute(dt) == rM
    @test second(dt) == rS
    @test second(Float64, dt) == rS + rF

    dtr = rand(0.0:1.0:(365.25 * 86400.0))
    dt2 = dt + dtr
    @test Tempo.j2000s(dt2) - Tempo.j2000s(dt) ≈ dtr atol=1e-11 rtol=1e-11
    
    d = Date(2000, 1, 1)
    dt = DateTime(d, 0.0)
    @test DateTime{Float64}(dt) == dt
    dt1 = dt + 1.0
    @test dt < dt1
end