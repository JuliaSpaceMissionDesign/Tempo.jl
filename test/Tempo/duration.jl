
# TestSet for Duration
@testset "Duration" begin

    # Test Duration constructor with a floating point number
    d1 = Duration(5.75)
    @test d1.seconds == 5
    @test d1.fraction == 0.75

    # Test Duration constructor with an integer and a fractional part
    d2 = Duration(10, 0.25)
    @test d2.seconds == 10
    @test d2.fraction == 0.25

    # Check Constructor with a Big Float
    db1 = Duration(BigFloat(2.5422))

    @test db1.seconds == 2 
    @test db1.fraction ≈ 0.5422 atol=1e-14 rtol=1e-14

    # Test duration type 
    @test Tempo.ftype(db1) == BigFloat

    # Test value function
    @test value(d1) == 5.75
    @test value(d2) == 10.25

    # Test duration conversion 
    db2 = convert(BigFloat, d1)
    @test Tempo.ftype(db2) == BigFloat 
    @test db2.seconds == 5 
    @test db2.fraction ≈ 0.75 atol=1e-14 rtol=1e-14

    # Test isless with a number
    @test d1 < 6.0 
    @test d2 < 10.5 

    # Test isless with another Duration
    @test d1 < d2 
    @test d2 > d1 

    # Test addition of two Durations
    d3 = d1 + d2  # 5.75 + 10.25 = 16.0
    @test d3.seconds == 16
    @test d3.fraction == 0.0

    # Test subtraction of two Durations
    d4 = d2 - d1  # 10.25 - 5.75 = 4.5
    @test d4.seconds == 4
    @test d4.fraction == 0.5

    # Test addition of a Duration and a number
    d5 = d1 + 2.5  # 5.75 + 2.5 = 8.25
    @test d5.seconds == 8
    @test d5.fraction == 0.25

    # Test subtraction of a number from a Duration
    d6 = d2 - 1.75  # 10.25 - 1.75 = 8.5
    @test d6.seconds == 8
    @test d6.fraction == 0.5

    # Test edge cases
    d7 = Duration(0.0)
    d8 = Duration(-1.75)
    @test d7.seconds == 0
    @test d7.fraction == 0.0
    @test d8.seconds == -1
    @test d8.fraction == -0.75

    # Ensure negative subtraction handles correctly
    d9 = d1 - 6.75  # 5.75 - 6.75 = -1.0
    @test d9.seconds == -1
    @test d9.fraction == 0.0

    # Ensure addition and subtraction with zero works
    d10 = d1 + 0.0
    d11 = d1 - 0.0
    @test d10.seconds == d1.seconds
    @test d10.fraction == d1.fraction
    @test d11.seconds == d1.seconds
    @test d11.fraction == d1.fraction

end
