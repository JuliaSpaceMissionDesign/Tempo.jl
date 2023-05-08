using Tempo
using Documenter

makedocs(;
    authors="Julia Space Mission Design Development Team",
    sitename="Tempo.jl",
    modules=[Tempo],
    pages=[
        "Home" => "index.md",
        "API" => "api.md"
    ],
)

deploydocs(; repo="github.com/JuliaSpaceMissionDesign/Tempo.jl", branch="gh-pages")
