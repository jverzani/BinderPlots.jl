```@meta
CurrentModule = BinderPlots
```

# BinderPlots

Documentation for [BinderPlots](https://github.com/jverzani/BinderPlots.jl), a simple plotting package for resource-constrained environments using `PlotlyLight.jl` to render graphics described with an interface superficially resembling much of that from `Plots.jl`.

* [Plotly](https://plotly.com/) is a JavaScript library for plotting that is widely used and has supported interfaces for `Python`, `R`, and `Julia` (through `PlotlyJS`).
* [PlotlyLight](https://github.com/JuliaComputing/PlotlyLight.jl) is a very lightweight package to create `Plotly` graphs using the JavaScript interface. The JSON structures are readily created using the clever `Config` constructor on the `Julia` side.
* [Plots.jl](https://github.com/JuliaPlots/Plots.jl) is a popular package for plotting in `Julia` with numerous backends including `Plotly`.


This package provides a light-weight plotting alternative to `Plots.jl` utilizing a subset of the `Plots` interface. It is inspired by `SimplePlots` and is envisioned as being useful within resource-constrained environments such as [`binder.org`](https://mybinder.org/v2/gh/mth229/229-projects/lite?labpath=blank-notebook.ipynb).

This is not a re-implementation of `Plots`; it only bears a superficial resemblance. The `Plots` package is far more developed in terms of its API, its extendable plot recipes, and its extensions like `StatsPlots.jl`. The `BinderPlots` package only provides a small fraction, primarily that part of the interface that makes visualizing functions in low dimensions easier.


## Installation

The package is not registered. It may be installed through `Pkg.add(url="..."))`.

Once installed, the package is loaded in the standard manner.

```@example lite
using BinderPlots
using PlotlyDocumenter # hide
```

The package should load very quickly and the time to first plot should be quite speedy as this is the case for `PlotlyLight`.


## Saving figures

Saving figures is the same as with `PlotlyLight`.

To save a figure to HTML, we have:

```
BinderPlots.PlotlyLight.save(p, "filename.html")
```

To save a figure to an image file, the `PlotlyKaleido` package is used:

```
using PlotlyKaleido
PlotlyKaleido.start()

(;data, layout, config) = p;
PlotlyKaleido.savefig((; data, layout, config), "myplot.png")
```
