using Tempo
using Documenter

makedocs(;
    authors="Julia Space Mission Design Development Team",
    sitename="Tempo.jl",
    modules=[Tempo],
    pages=[
        "Home" => "index.md",
        "API" => "api.md",
        "Tutorials" => [
            "Epochs" => "tutorials/t01_epochs.md",
            "Scales" => "tutorials/t02_scales.md"
        ]
    ],
)

deploydocs(; repo="github.com/JuliaSpaceMissionDesign/Tempo.jl", branch="gh-pages")
