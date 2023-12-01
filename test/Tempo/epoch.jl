
@testset "Epoch" verbose = true begin

    dt = DateTime("2004-05-14T16:43:32.0000")
    e = Epoch(dt, TDB)

    @test Epoch(dt, TDB) == Epoch("2004-05-14T16:43:32.0000 TDB")        
    @test Epoch(86400.0, Tempo.TerrestrialTime) == Epoch("2000-01-02T12:00:00.0000 TT")
    @test Epoch(dt, Tempo.TerrestrialTime) == Epoch("2004-05-14T16:43:32.0000 TT")
    @test Epoch(e) == e

    @test repr(e) == "2004-05-14T16:43:32.0000 TDB"

    epn = Epoch{BarycentricDynamicalTime, BigFloat}(e) 
    @test typeof(epn) == Epoch{BarycentricDynamicalTime, BigFloat}
    @test typeof(j2000s(epn)) == BigFloat 
    @test j2000s(epn) ≈ j2000s(e) atol=1e-12 rtol=1e-12

    @test convert(TDB, e) == e
    @test convert(BarycentricDynamicalTime, e) == e
    @test convert(Float64, e) == e
    
    @test typeof(convert(BigFloat, e)) == typeof(epn)
    @test j2000s(convert(BigFloat, e)) == j2000s(epn) 

    @testset "String constructors" begin
        s, ry, rm, rd, rH, rM, rS, rF = _random_epoch()
        e = Epoch(s)
        dt = DateTime(e)
        @test Epoch("-0.5") ≈ Epoch("2000-01-01T00:00:00.0000 TDB")
        @test Epoch("0.5") ≈ Epoch("2000-01-02T00:00:00.0000 TDB")
        @test Epoch("JD 2400000.5") ≈ Epoch("1858-11-17T00:00:00.0000 TDB")
        @test Epoch("JD 2400000.5") ≈ Epoch("MJD 0.0")
    end

    @testset "DateTime and offset constructors" begin
        s, ry, rm, rd, rH, rM, rS, rF = _random_epoch()
        e = Epoch(s)
        dt = DateTime(e)
        @test DateTime(e) ≈ dt

        rn = rand(0:10000)
        @test value(e + rn) ≈ value(e) + rn
        rn = rand(0:10000)
        @test value(e - rn) ≈ value(e) - rn

        rn0 = rand(-2000:2000)
        rn1 = rand(-1000:1000)
        @test Epoch("$rn0") - Epoch("$rn1") ≈ (rn0 - rn1) * Tempo.DAY2SEC
        @test all(
            collect(Epoch("0"):86400.0:Epoch("2")) .== [Epoch("0"), Epoch("1"), Epoch("2")]
        )

        @test Epoch(0.0, TDB) ≈ Epoch("2000-01-01T12:00:00.0000 TDB")

        # Test rounding errors
        t = DateTime(Epoch(21, TT)).time
        @test t.second == 21 
        @test t.fraction == 0.0
    end

    # Colon Operator
    e1 = Epoch("2004-05-14T16:43:00 UTC")
    e2 = e1 + floor(10000*rand())*86400

    e3 = Epoch("232.0 TT")

    @test_throws ErrorException e3-e1

    ems = e1:e2 
    for j = 2:lastindex(ems)
        @test ems[j] == e1 + 86400*(j-1)
    end

    # Based on Vallado "Fundamental of astrodynamics" page 196
    e = Epoch("2004-05-14T16:43:00 UTC")
    @test DateTime("2004-05-14T16:43:32.0000") ≈ DateTime(convert(TAI, e))
    @test DateTime("2004-05-14T16:44:04.1840") ≈ DateTime(convert(TT, e))
    @test DateTime("2004-05-14T16:44:04.1856") ≈ DateTime(convert(TDB, e))
    @test DateTime("2004-05-14T16:44:17.5255") ≈ DateTime(convert(TCB, e))
    @test DateTime("2004-05-14T16:44:04.7836") ≈ DateTime(convert(TCG, e))
end
