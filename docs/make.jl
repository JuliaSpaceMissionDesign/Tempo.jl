using Tempo
using Documenter

const CI = get(ENV, "CI", "false") == "true"

makedocs(;
    authors="Julia Space Mission Design Development Team",
    sitename="Tempo.jl",
    modules=[Tempo],
    format=Documenter.HTML(; prettyurls=CI, highlights=["yaml"], ansicolor=true),
    pages=[
        "Home" => "index.md",
        
        "Tutorials" => [
            "Epochs" => "tutorials/t01_epochs.md",
            "Scales" => "tutorials/t02_scales.md"
        ],

        "API" => [
            "Public API" => "api.md",
            "Low-level API" => "lapi.md"
        ],
    ],
)

deploydocs(; repo="github.com/JuliaSpaceMissionDesign/Tempo.jl", branch="gh-pages")
