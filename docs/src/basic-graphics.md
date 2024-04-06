# Basics of BinderPlots

The plotting interface provided picks some of the many parts of `Plots.jl` that prove useful for the graphics of calculus and provides a stripped-down, though reminiscent, interface using `PlotlyLight`, a package which otherwise is configured in a manner very-much like the underlying `JavaScript` implementation. The `Plots` package is great -- and has a `Plotly` backend -- but for resource-constrained usage can be too demanding.


Some principles of `Plots` are:

* The `Plots.jl` interface uses positional arguments for data (with data possibly including reference to some existing figure) and keyword arguments for modifying underlying attributes.

The `BinderPlots.jl` interface *mostly* follows this. However, only *some* of the `Plots.jl` keyword arguments are supported. Other keyword arguments are passed directly to [Plotly](https://plotly.com/javascript/) and so should follow the naming conventions therein.

The `PlotlyLight` interface is essentially the `JavaScript` interface for `Plotly` only with the cleverly convenient `Config` constructor used to create the nested JavaScript data structures needed through conversion with `JSON3`. All arguments are like keyword arguments.

* In Plots.jl, every column is a series, a set of related points which form lines, surfaces, or other plotting primitives.

`Plotly` refers to series as traces. This style is only partially supported in `BinderPlots`, though multiple layers are suggested. (E.g. plot each column of a matrix.)

* In `Plots.jl` for keyword arguments many aliases are used, allowing for shorter calling patterns for experienced users.

This is only partially the case with `BinderPlots`.

* In `Plots.jl` some arguments encompass magic [arguments](https://docs.juliaplots.org/latest/attributes/#magic-arguments) for setting many related arguments at the same time.

This is only partially the case with `BinderPlots`.

* In `Plots.jl` the available plot types are specified through `seriestype` and there are shorthands to produce different methods (e.g., `scatter` is a shorthand for the seriestype `:scatter`.

This is only partially the case with `BinderPlots`, though the more direct calling methods are suggested.


Altogether, most basic graphics created through `Plots` can be produced with `BinderPlots`, but the showcase of [examples](https://github.com/JuliaPlots/Plots.jl/blob/master/src/examples.jl), which utilize many conveniences, and mostly not runnable as is.


## Supported plotting functions

We load the package in the typical manner:

```@example lite
using BinderPlots
using PlotlyDocumenter # hide
```

This package directly implements some of the `Plots` recipes for functions that lessen the need to manipulate data.

### `plot(f, a, b)`

The `plot` function from `PlotlyLight` is given several methods through dispatch to create line graphs.

The simplest means to plot a function `f` over the interval `[a,b]` is the declarative pattern `plot(f, a, b)`. For example:

```@example lite
plot(sin, 0, 2pi)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```


The `sin` object refers to a the underlying function to compute sine. More commonly, the function is user-defined as `f`, or some such, and that function object is plotted.

The interval may be specified using two numbers or with a container, in which case the limits come from calling a method of `extrema` for `Plot` objects. A default of ``(-5,5)`` is used when no interval is specified.


For line plots, as created by this usage, the supported key words include

* `linecolor` to specify the color of the line
* `linewidth` to adjust width in pixels
* `linestyle` to adjust how line is drawn
* `legend` to indicate if no legend should be given. Otherwise, `label` can be used to name the entry for given trace.

!!! note
    All plotting functions in `BinderPlots` return an instance of `PlotlyLight.Plot`. These objects can be directly modified and re-displayed. The `show` method creates the graphic for viewing. The `current` function returns the last newly created plot.

!!! note "Twice may be a charm"
    For the first plot, the plotting command may need to be re-run if the underlying JavasScript libraries are loaded out of order. This may be the case with the `Jupyter` environment.


### `plot(xs, ys, [zs])` and `plot(pts)`

The points to plot may be specified directly.

Points can be given as ``\{(x_1, y_1), (x_2,y_2), \dots, (x_n, y_n)\}`` or as two vectors ``(x_1, x_2, \dots, x_n)`` and ``(y_1, y_2, \dots, y_n)``. When the latter, they must be of equal length, as internally they are paired off.

For example, we might bypass the automatic selection of points to plot and create these directly:

```@example lite
xs = range(0, pi, length=251)
f(x) = sin(sin(x^2))
ys = f.(xs)
plot(xs, ys)

g(x) = (x, sin(sin(x^3)))
plot!(g.(xs))

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

At times it is more convenient to generate pairs of points. In the above example, `g` returns ``(x,y)`` pairs. Containers of points can be plotted directly, as just shown.

The `plot(xs, ys)` function simply connects the points
``(x_1,y_1), (x_2,y_2), \dots``  sequentially with lines in a dot-to-dot manner (the `lineshape` argument can modify this). If values in `y` are non finite, then a break in the dot-to-dot graph is made.

Use `plot(xs, ys, zs)` for line plots in 3 dimensions, which is illustrated in a different section.


*If* one or more `x` or `y` (or `z`) is a matrix, then each *column* will be treated as specifying a trace. In this case, most keyword arguments will be cycled over (except for the magic ones like `line`, `markers`, and `fill`). For example:

```@example lite
m, n = 10, 3
x = 1:m
y = rand(m, n)
plot(x, y; label=("one","two","three"), linecolor=(:red, :green, :blue))
```

!!! note "Plotting a vector"
    The `Plots.jl` interface has a recipe for `plot(x::Vector)` which will plot `x` against the values `1:length(x)` **unless** `x` is a vector of tuples, in which case it will plot as points (as above). This is **not** supported. If only a vector for `x` is specified, it is assumed to contain a vector of points; if not an error for `unzip` will be thrown. If only a **matrix** is passed for x then each column is plotted against `1:size(x)[1]`. (In the last example `plot(y;...)` would produce the same figure as `plot(x, y; ...)`.)



### `plot!`

Layers can be added to a figure created by `plot`. The notation follows `Plots.jl` and uses `Julia`'s convention of indicating functions which mutate their arguments with a `!`. The underlying plot is mutated (by adding a layer) and reference to this may or may not be in the `plot!` call. (When missing, the current plotting figure, determined by `current()`, is used.)

```@example lite
plot(sin, 0, 2pi)

plot!(cos)    # no limits needed, as they are computed from the current figure

plot!(x -> x, 0, pi/2)      # limits can be specified
plot!(x -> 1 - x^2/2, 0, pi/2)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

### `plot([f,g,...], a, b)`

As a convenience, to plot two or more traces in a graphic, a vector of functions can be passed in. In which case, each is plotted over the interval. (Similar to using `plot` to plot the first and `plot!` to add the rest.)

The `Plots` keyword `line` arguments are recycled. For more control, using `plot!`, as above.


### `plot(fs::NTuple{N,Function}, a, b)`

Two dimensional parametric plots show the trace of ``(f(t), g(t))`` for ``t`` in ``[a,b]``. These are easily created by `plot(x,y)` where the `x` and `y` values are produced by broadcasting, say, such as `f.(ts)` where `ts = range(a,b,n)`.

!!! note "Not supported"
    The `Plots.jl` convenience signature is `plot(f::Function, g::Function, a, b)`. This is not supported. Rather, pass a tuple of functions, as in `plot((f,g), a, b)`.

### `plot(::Array{<:Plot,N})`

Arrange an array of plot objects into a regular layout for display.

(`Plots.jl` uses a different convention.)


### `plot(; seriestype::Symbol, kwargs...)`

There are a few series types for which the underlying `PlotlyLight` `Plot` function is basically called. A few examples from statistics, might be:

```@example lite
p1 = plot(; values = [19, 26, 55], labels=["a","b", "c"], seriestype=:pie)
p2 = plot(randn(100); seriestype=:histogram)
p3 = plot(nothing, randn(100); seriestype=:boxplot)
animals = ["giraffes", "orangutans", "monkeys"]
p4 = plot(animals, [10,20,30]; seriestype=:bar, label="Zoo 1")
plot!(p4, animals, [5,6,8];    seriestype=:bar, label="Zoo 2")
p4.layout.barmode="group";

plot([p1 p2; p3 p4])   # lost labels are a bug

to_documenter(current())           # hide
```

The keyword arguments defined within this package are processed; the rest passed onto the data configuration of Plotly. The bar plot required a specification of the layout configuration.

!!! note "seriestype"
    The `seriestype` argument refers to a plotly `type` and `mode` which could be specified directly. For example, `plot(x,y; type="scatter", mode="markers+lines", ...) would produce a scatter plot along with lines connecting the points, a task otherwise done by combinign `plot` with `scatter!` (introduced next).

### `scatter(xs, ys, [zs])` or `scatter(pts)`

Save for a few methods, the `plot` method represents the data with type `line` which instructs `Plotly` to connect points with lines.

Related to `plot` and `plot!` are `scatter` and `scatter!`; which render just the points, without connecting the dots.


The following `Plots.jl` marker attributes are supported:

* `markershape` to set the shape
* `markersize` to set the marker size
* `markercolor` to adjust the color

A specification like `marker=(:diamond, 20, :blue)` will set the 3 attributes above with matching by type.


### Text and arrows

The `annotate!`, `quiver!`, `arrow` and `arrow!` functions are used to add text and/or arrows to a graphic.

The `annotate!` function takes a a tuple of `(x,y,txt)` points or vectors of each and places text at the `x-y` coordinate. Text attributes can be adjusted.

The `quiver!` function plots arrows with optional text labels. Due to the underlying use of `Plotly`, `quiver` is restricted to 2 dimensions. The arguments to quiver are tail position(s) in `x` and `y` and arrow lengths, passed to `quiver` as `dx` and `dy`. The optional `txt` argument can be used to label the anchors.

The `arrow!` function is not from `Plots.jl`. It provides a different interface to arrow drawing than `quiver`. For `arrow!` the tail and vectors are passed in as vectors. (so for a single arrow from `p=[1,2]` with direction `v=[3,1]` one call would be `arrow!(p, v)` (as compared with `quiver([1],[2], quiver=([3],[1]))`). The latter more efficient for many arrows.

The `arrows!` function borrows the `Makie.jl` interface to specify an arrow (basically `arrows!(x,y,u,v)` is `quiver!(x,y,quiver=(u,v))`.


The following `Plots.jl` text attributes are supported:

* `color`
* `family`
* `pointsize`
* `rotation`

For labels and annotations, the call `text(str, args...)` can be used to specify font properties. For example `text("label", :red, 20)` specifies the color and text size for the string when used to label a graphic. The `font` function takes the `args...` and returns a `Font` object, which allow various text attributes to be customized.

### Shapes

There are a few simple shapes, including lines:

* `hline!(y; xmin=0,xmax=1)` draws a horizontal line at elevation `y` across the computed axis, or adjusted via `xmin` and `xmax`.  The `extrema` function computes the axis sizes. If `y` is a container, multiple lines are drawn.
* `vline(x)`  draws a vertical line at  `x` across the computed axis, or adjusted via `ymin` and `ymax`. The `extrema` function computes the axis sizes. If `x` is a container, multiple lines are drawn.
* `ablines!(intercept, slope)` for drawing lines `a + bx` in the current frame.

The following create regions which can be filled.  Shapes have an interior and exterior boundary. The exterior line has attributes that can be adjusted with `linecolor`, `linewidth`, and `linestyle`.

The following `Plots.jl` fill attributes are supported:

* `fillcolor`
* `fill` (one of `0`, `"tonexty"`, `"tozerox"`)

The `plotly` `opacity` argument can adjust the interior color's transparency level.

Plots that create 2d-regions are:

* `rect!(x0, x1, y0, y1)` draws a rectangle between `(x0,y0)` and `(x1,y1)`.
* `hspan!(ys,YS; xmin=0.0, xmax=1.0)` draws horizontal rectangle(s) with bottom and top vertices specified by `ys` and `YS`.
* `vspan!(xs,XS; ymin=0.0, ymax=1.0)` draws vertical rectangle(s) with left and right vertices specified by `xs` and `XS`.
* `circle!(x0, x1, y0, y1)` draws a "circular" shape in the rectangle given by `(x0, y0)` and `(x1, y1)`.
* `poly!(points; kwargs...)` where points is a container of ``(x,y)`` or ``(x,y,z)`` coordinates.
* `band!(lower, upper, args...; kwargs...)` draws a ribbon or band between `lower` and `upper`. These are either containers of `(x,y)` points or functions, in which case `args...` is read as `a,b,n=251` to specify a range of values to plot over. The function can be scalar valued or parameterizations of a space curve in ``2`` or ``3`` dimensions. The `ribbon` argument of `Plots` is not supported.


----


For example, this shows how one could visualize the points chosen in a plot, showcasing both `plot` and `scatter!` in addition to a few other plotting commands:

```@example lite
f(x) = x^2 * (108 - 2x^2)/4x
x, y = unzip(f, 0, sqrt(108/2))
plot(x, y; legend=false)
scatter!(x, y, markersize=10)

quiver!([2,4.3,6],[10,50,10], ["sparse","concentrated","sparse"],
        quiver=([-1,0,1/2],[10,15,5]))

# add rectangles to emphasize plot regions
y0, y1 = extrema(current()).y  # get extent in `y` direction
rect!(0, 2.5, y0, y1, fillcolor="#d3d3d3", opacity=0.2)
rect!(2.5, 6, y0, y1, linecolor="black", fillcolor="orange", opacity=0.2)
x1 = last(x)
rect!(6, x1, y0, y1, fillcolor="rgb(150,150,150)", opacity=0.2)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

The values returned by `unzip(f, a, b)` are not uniformly chosen, rather where there is more curvature there is more sampling. For illustration purposes, this is emphasized in a few ways: using `quiver!` to add labeled arrows and `rect!` to add rectangular shapes with transparent filling.

As seen in this overblown example, there are other methods besides `plot` for other useful tasks. These include:

* `scatter!` is used to plot points using markers.

* `quiver!` is used to add arrows to a plot. These can optionally have their tails labeled, so this method can be repurposed to add annotations.  The `quiver` command allows for text rotation. Also `arrow` and `arrows` for different interfaces for drawing arrows. The `annotate!` function is used to add annotations at a given point. There are keyword arguments to adjust the text size, color, font-family, etc.

* `rect!` is used to make a rectangle. There are also `hspan!` and `vspan!`. For lines, there are `hline!` and `vline!` to draw horizontal or vertical lines across the extent of the plotting region. There is also `ablines!` to draw lines specified in intercept-slope form across the extent of the plotting region. Other regions can be draws. For example, `circle!` to draw a circle, and, more generally, `poly` can be used to draw a polygonal region.




### Keyword arguments

The are several keyword arguments used to adjust the defaults for the graphic, for example, `legend=false` and `markersize=10`. Some keyword names utilize `Plots.jl` naming conventions and are translated back to their `Plotly` counterparts. Additional keywords are passed as is, so should use the `Plotly` names.

Some keywords chosen to mirror `Plots.jl` are:

| Argument | Used by | Notes |
|:---------|:--------|:------|
| `size=(width=..., height=...)` | new plot calls | set figure size, cf. `size!` with named tuple; alias `windowsize` |
| `xlims`, `ylims`  | new plot calls | set figure boundaries, cf `xlims!`, `ylims!`, `extrema` |
| `legend`          | new plot calls | set or disable legend |
|`aspect_ratio`     | new plot calls | set to `:equal` for equal `x`-`y` (and `z`) axes |
|`label`	    	| `plot`, `plot!`| set with a name for trace in legend |
|`linecolor`		| `plot`, `plot!`| set with a color; alias `lc` |
|`linewidth`		| `plot`, `plot!`| set with an integer; aliases `lw`, `width` |
|`linestyle`		| `plot`, `plot!`| set with `"solid"`, `"dot"`, `"dash"`, `"dotdash"`, [...](https://plotly.com/javascript/reference/#scatter-line-dash); aliases `style`, `ls` |
|`lineshape`		| `plot`, `plot!`| set with `"linear"`, `"hv"`, `"vh"`, `"hvh"`, `"vhv"`, `"spline"`; from [plotly](https://plotly.com/javascript/reference/#scatter-line-shape) |
|`line`             | `plot`, `plot!` | set with tuple of magic line arguments |
|`markershape`		| `scatter`, `scatter!` | set with `"diamond"`, `"circle"`, ...; alias `shape` |
|`markersize`		| `scatter`, `scatter!` | set with integer; alias `ms` |
|`markercolor`		| `scatter`, `scatter!` | set with color; alias `mc` |
|`marker`           | `plot`, `plot!` | set with tuple of magic marker arguments |
|`fillcolor`        | shapes                | interior color of a 2D shape; alias `fc` |
|`fill`             | shapes                | set with magic fill arguments |
|`color`			| `annotate!` | set with color argument of `text`  |
|`family`			| `annotate!` | set with string (font family) |
|`pointsize`		| `annotate!` | set with integer |
|`rotation`        	| `annotate!` | set with angle, degrees, real  |
|`center`		   	| new ``3``d plots | set with tuple, see [controls](https://plotly.com/python/3d-camera-controls/) |
|`up`				| new ``3``d plots | set with tuple, see [controls](https://plotly.com/python/3d-camera-controls/) |
|`eye`				| new ``3``d plots | set with tuple, see [controls](https://plotly.com/python/3d-camera-controls/) |

As seen in the example there are *many* ways to specify a color. These can be by name (as a string); by name (as a symbol), using HEX colors, using `rgb` (the use above passes a JavaScript command through a string). There are likely more.

Some exported names are used to adjust a plot after construction:

* `title!`, `xlabel!`, `ylabel!`, `zlabel!`: to adjust title; ``x``-axis label; ``y``-axis label
* `xlims!`, `ylims!`, `zlims!`: to adjust limits of viewing window
* `xticks!`, `yticks!`, `zticks!`: to adjust axis ticks
* `xaxis!`, `yaxis!`, `zaxis!`: to adjust the axis properties

!!! note "Subject to change"
    There are some names for keyword arguments that should be changed.
