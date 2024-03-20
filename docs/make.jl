using BinderPlots
using Documenter

DocMeta.setdocmeta!(BinderPlots, :DocTestSetup, :(using BinderPlots); recursive=true)

makedocs(;
    modules=[BinderPlots],
    authors="jverzani <jverzani@gmail.com> and contributors",
    sitename="BinderPlots.jl",
    format=Documenter.HTML(;
        canonical="https://jverzani.github.io/BinderPlots.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jverzani/BinderPlots.jl",
    devbranch="main",
)
