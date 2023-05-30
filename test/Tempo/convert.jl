@testset "Function isleapyear" begin
    for y in (2004, 2008, 2012, 2016)
        @test Tempo.isleapyear(y)
    end

    for y in (2003, 2005, 2015, 2017)
        @test !Tempo.isleapyear(y)
    end
end

@testset "Function find_dayinyear" begin
    @test find_dayinyear(1, 24, false) == 24
    @test find_dayinyear(12, 30, false) == 364
end

@testset "Function hms2fd" begin
    for _ in 1:10
        h = rand(0:23)
        m = rand(0:59)
        s = rand(0.0:59.0)
        @test Tempo.hms2fd(h, m, s) ≈ ((s / 60 + m) / 60 + h) / 24 atol=1e-11 rtol=1e-11
    end

    @test_throws DomainError Tempo.hms2fd(24, 0, 0.0)
    @test_throws DomainError Tempo.hms2fd(23, 61, 0.0)
    @test_throws DomainError Tempo.hms2fd(20, 1, 61.0)
end

@testset "Function fd2hms" begin
    for _ in 1:10
        fd = rand()
        secinday = fd * 86400.0
        hours = Integer(secinday ÷ 3600)
        secinday -= 3600 * hours
        mins = Integer(secinday ÷ 60)
        secinday -= 60 * mins

        @test all(Tempo.fd2hms(fd) .≈ (hours, mins, secinday))
        @test all(
            Tempo.fd2hmsf(Float64(fd)) .≈
            (hours, mins, secinday ÷ 1, secinday - secinday ÷ 1),
        )
    end

    @test_throws DomainError Tempo.fd2hms(-0.1)
    @test_throws DomainError Tempo.fd2hms(1.5)
    @test_throws DomainError Tempo.fd2hmsf(-0.1)
    @test_throws DomainError Tempo.fd2hmsf(1.5)
end

@testset "Function jd2cal" begin 
    
    @test Tempo.jd2cal(Tempo.DJ2000, 0.0) == (2000, 1, 1, 0.5)
    @test_throws DomainError Tempo.jd2cal(1e10, 0.0)
    @test_throws DomainError Tempo.jd2cal(-68569.4, -1.0) 

    # Test with negative dates 
    jd1, jd2 = Tempo.calhms2jd(1840, 1, 13, 12, 32, 41)
    @test Tempo.jd2cal(jd1, jd2)[1:3] == (1840, 1, 13)

    # Test against ERFA 
    for _ in 1:250
        
        jd1 = -10000 + 20000*rand()
        jd2 = Tempo.DJ2000 


        ye, me, de, fe = ERFA.jd2cal(jd1, jd2)
        yt, mt, dt, ft = Tempo.jd2cal(jd1, jd2) 
        
        @test ye == yt 
        @test me == mt 
        @test de == dt 
        @test fe ≈ ft atol=1e-11 rtol=1e-11
        
    end
end

@testset "Function cal2jd" begin
    Y, M, D = 2022, 6, 15
    h, m, s = 11, 51, 55.05

    @test sum(Tempo.cal2jd(Y, M, D)) - 0.5 + Tempo.hms2fd(h, m, s) ≈
        sum(Tempo.calhms2jd(Y, M, D, h, m, s)) atol=1e-11 rtol=1e-11

    @test_throws DomainError Tempo.cal2jd(
        rand(0:1580), rand(1:12), rand(1:28)
    )
    @test_throws DomainError Tempo.cal2jd(rand(1600:2600), rand(1:12), 0)
    @test_throws DomainError Tempo.cal2jd(1850, 0, rand(1:28))
    @test_throws DomainError Tempo.cal2jd(2500, 13, 0)
    @test_throws DomainError Tempo.cal2jd(2150, 1, 32)
    @test_throws DomainError Tempo.cal2jd(1999, 6, 0)
    @test_throws DomainError Tempo.cal2jd(2000, 2, 32)
    @test sum(Tempo.calhms2jd(1970, 1, 1, 15, 0, 0.0)) ≈ 2440588.125
end

@testset "Function cal2jd vs ERFA (cal2jd.c)" begin
    for _ in 1:250
        y, m, d, _, _, _, _ = _random_datetime()
        ejd = sum(ERFA.cal2jd(y, m, d))
        bjd = sum(Tempo.cal2jd(y, m, d))
        @test ejd + 0.5 ≈ bjd atol = 1e-11 rtol=1e-11
    end
end

@testset "Function calhms2jd vs ERFA (dtf2d.c)" begin
    for _ in 1:250
        y, m, d, H, M, S, f = _random_datetime()
        ejd = sum(ERFA.dtf2d("NONE", y, m, d, H, M, S + f))
        bjd = sum(Tempo.calhms2jd(y, m, d, H, M, S + f))
        @test ejd ≈ bjd atol = 1e-11 rtol=1e-11
    end
end

@testset "Function utc2tai" begin
    for _ in 1:10
        Y, M, D = rand(1975:2015), rand(1:12), rand(1:28)
        h, m, s = rand(0:23), rand(0:59), rand(0.0:59.999)
        utc1, utc2 = Tempo.calhms2jd(Y, M, D, h, m, s)
        tai1, tai2 = Tempo.utc2tai(utc1, utc2)
        @test any((
            (tai2 - utc2) * 86400 ≈ Tempo.leapseconds(utc1 - Tempo.DJ2000 + utc2),
            (tai2 - utc2) * 86400 ≈ Tempo.leapseconds(utc1 - Tempo.DJ2000 + utc2) + 1,
        )) 
    end
end

@testset "Function utc2tai vs ERFA (utctai.c)" begin
    for _ in 1:250
        Y, M, D = rand(1975:2015), rand(1:12), rand(1:28)
        h, m, s = rand(0:23), rand(0:59), rand(0.0:59.999)
        utc1, utc2 = Tempo.calhms2jd(Y, M, D, h, m, s)

        tai1, tai2 = Tempo.utc2tai(utc1, utc2)
        tai1e, tai2e = ERFA.utctai(utc1, utc2)

        @test tai2 ≈ tai2e atol=1e-11 rtol=1e-11
        @test tai1 ≈ tai1e atol=1e-11 rtol=1e-11
    end
end

@testset "Function tai2utc" begin
    for _ in 1:10
        Y, M, D = rand(1975:2015), rand(1:12), rand(1:28)
        h, m, s = rand(0:23), rand(0:59), rand(0.0:0.0001:59.999)
        
        # TODO: sistemare utc2tai qui
        utc1, utc2 = Tempo.calhms2jd(Y, M, D, h, m, s)
        tai1, tai2 = Tempo.utc2tai(utc1, utc2)

        invOrder = rand([false, true])
        tms = invOrder ? (tai2, tai1) : (tai1, tai2)
        u1, u2 = Tempo.tai2utc(tms...)

        if invOrder 
            @test u1 ≈ utc2 atol=1e-11 rtol=1e-11
            @test u2 ≈ utc1 atol=1e-11 rtol=1e-11
        else 
            @test u1 ≈ utc1 atol=1e-11 rtol=1e-11
            @test u2 ≈ utc2 atol=1e-11 rtol=1e-11
        end
    end

    # test limit case
    Y, M, D = 2008, 12, 31
    h, m, s = 23, 59, 59.99999999999999
    utc1, utc2 = Tempo.calhms2jd(Y, M, D, h, m, s)
    tai1, tai2 = Tempo.utc2tai(utc1, utc2)
    u1, u2 = Tempo.tai2utc(tai1, tai2)

    @test u2 ≈ utc2 atol=1e-11 rtol=1e-11
end

@testset "Function tai2utc vs ERFA (taiutc.c)" begin
    for _ in 1:250
        Y, M, D = rand(1975:2015), rand(1:12), rand(1:28)
        h, m, s = rand(0:23), rand(0:59), rand(0.0:59.999)
        tai1, tai2 = Tempo.calhms2jd(Y, M, D, h, m, s)

        utc1, utc2 = Tempo.tai2utc(tai1, tai2)
        utc1e, utc2e = ERFA.taiutc(tai1, tai2)

        @test utc2 ≈ utc2e atol=1e-11 rtol=1e-11 
        @test utc1 ≈ utc1e atol=1e-11 rtol=1e-11
    end
end

@testset "JulianDates" begin 

    @test j2000(DJ2000)  ≈ 0 atol=1e-11 rtol=1e-11 
    @test j2000s(DJ2000) ≈ 0 atol=1e-11 rtol=1e-11
    @test j2000c(DJ2000) ≈ 0 atol=1e-11 rtol=1e-11

    for _ in 1:250 
        jd1 = DJ2000 
        jd2 = -10000 + 20000*rand()

        @test j2000(jd1+jd2) ≈ j2000(jd1, jd2) atol=1e-11 rtol=1e-11

        @test j2000c(jd1, jd2)*Tempo.CENTURY2DAY ≈ j2000(jd1, jd2) atol=1e-11 rtol=1e-11
        @test j2000c(jd1+jd2)*Tempo.CENTURY2DAY ≈ j2000(jd1+jd2) atol=1e-11 rtol=1e-11

        @test j2000s(jd1, jd2) ≈ j2000(jd1, jd2)*86400 atol=1e-11 rtol=1e-11
        @test j2000s(jd1+jd2) ≈ j2000(jd1+jd2)*86400 atol=1e-11 rtol=1e-11 

    end


end