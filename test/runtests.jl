using Tempo
using ERFA
using Test

@testset "Tempo.jl" verbose = true begin
    include(joinpath("Tempo", "Tempo.jl"))
end;
