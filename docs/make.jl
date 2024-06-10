using Documenter
using BinderPlots

DocMeta.setdocmeta!(BinderPlots, :DocTestSetup, :(using BinderPlots); recursive=true)

makedocs(
    modules = [BinderPlots],
    authors="jverzani <jverzani@gmail.com> and contributors",
    repo="https://github.com/jverzani/BinderPlots.jl/blob/{commit}{path}#{line}",
    sitename = "BinderPlots.jl",
    format=Documenter.HTML(;
                           prettyurls=(get(ENV, "CI", "false") == "true"),
                           canonical="https://jverzani.github.io/BinderPlots.jl",
                           edit_link="main",
                           assets=String[],
                           size_threshold_ignore = ["basic-graphics.md","three-d-graphics.md", "three-d-shapes.md", "statistics.md"],
                           ),

    pages=[
        "Home" => "index.md",
        "Features" => [
            "Basics" => "basic-graphics.md",
            "3D graphics" => "three-d-graphics.md",
            "3D shapes" => "three-d-shapes.md",
            "Statistics" => "statistics.md"
        ],
        "Reference/API" => "reference.md",
    ],

)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/jverzani/BinderPlots.jl.git",
)
