# Basics of BinderPlots

The plotting interface provided picks some of the many parts of `Plots.jl` that prove useful for the graphics of calculus and provides a stripped-down, though reminiscent, interface around `PlotlyLight`, a package which otherwise is configured in a manner very-much like the underlying `JavaScript` implementation. The `Plots` package is great -- and has a `Plotly` backend -- but for resource-constrained usage can be too demanding.


Some principles of `Plots` are:

* The `Plots.jl` interface uses positional arguments for data (with data possibly including reference to some existing figure) and keyword arguments for modifying underlying attributes.

The `BinderPlots.jl` interface *mostly* follows this. However, only *some* of the `Plots.jl` keyword arguments are supported. Other keyword arguments are passed directly to [Plotly](https://plotly.com/javascript/) and so should follow the naming conventions therein.

The `PlotlyLight` interface is essentially the `JavaScript` interface for `Plotly` only with the cleverly convenient `Config` constructor used to create the nested JavaScript data structures needed through conversion with `JSON3`. All arguments are like keyword arguments.

* In Plots.jl, every column is a series, a set of related points which form lines, surfaces, or other plotting primitives.

`Plotly` refers to series as traces. This style is mostly supported in `BinderPlots`. Using multiple layers is suggested, but matrices can be used to specify multiple series.

* In `Plots.jl` for keyword arguments many aliases are used, allowing for shorter calling patterns for experienced users.

Many, but not all, of the aliases are available. (The shorter ones are not, as they are as cryptic as magic arguments and more work to type.)

* In `Plots.jl` some arguments encompass magic [arguments](https://docs.juliaplots.org/latest/attributes/#magic-arguments) for setting many related arguments at the same time.

`BinderPlots` allows for magic arguments.


* In `Plots.jl` the available plot types are specified through `seriestype` and there are shorthands to produce different methods (e.g., `scatter` is a shorthand for the seriestype `:scatter`.

This is only partially the case with `BinderPlots`, as not all plot types have a shorthand defined.


Altogether, most basic graphics created through `Plots` can be produced with `BinderPlots`, but of the showcase of 66 [examples](https://github.com/JuliaPlots/Plots.jl/blob/master/src/examples.jl), which utilize many corners of the `Plots.jl` interface, only about 23 are fully runnable.


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

* `linecolor` to specify the color of the line; `linealpha` for the transparency
* `linewidth` to adjust width in pixels
* `linestyle` to adjust how line is drawn
* `lineshape` to adjust how the line is interpolated between adjacent points
*  `label` can be used to name the entry for given trace, unless `legend=false` has been specified

!!! note
    All plotting functions in `BinderPlots` return an instance of `PlotlyLight.Plot`. These objects can be directly modified and re-displayed. The `show` method creates the graphic for viewing. The `current` function returns the last newly created plot.


### `plot(xs, ys, [zs])` or `plot(pts)`

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

At times it is more convenient to generate pairs of points. In the above example, `g` returns ``(x,y)`` pairs. Tuples and other non-vector containers of points can be plotted directly, as just shown.

The `plot(xs, ys)` function simply connects the points
``(x_1,y_1), (x_2,y_2), \dots``  sequentially with lines in a dot-to-dot manner (the `lineshape` argument can modify this). If values in `y` are non finite, then a break in the dot-to-dot graph is made.

Use `plot(xs, ys, zs)` for line plots in 3 dimensions, which is illustrated in a different section.


*If* one or more `x` or `y` (or `z`) is a matrix, then each *column* will be treated as specifying a trace. In this case, most keyword arguments will be cycled over including the magic arguments. For example:

```@example lite
m, n = 10, 3
x = 1:m
y = rand(m, n)
plot(x, y; label=("one","two","three"), linecolor=(:red, :green, :blue))

to_documenter(current())           # hide
```

!!! note
    It is a bit subtle, but a vector of vectors is treated as holding multiple series; whereas a vector of tuples (or other containers) is treated as a collection of points.

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

!!! note "Not encouraged"
    The `Plots.jl` convenience signature is `plot(f::Function, g::Function, a, b)`. This is supported but with a warning indicating it is best to pass a tuple of functions, as in `plot((f,g), a, b)`.

### `plot(::Array{<:Plot,N})` or `plot(::Plot...)`

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

plot([p1 p2; p3 p4])   # lost labels are a bug; only shows 1 plot in docs

to_documenter(current())           # hide
```

The keyword arguments defined within this package are processed; the rest passed onto the data configuration of Plotly. The bar plot required a specification of the layout configuration.

!!! note "seriestype"
    The `seriestype` argument refers to a plotly `type` and `mode` which could be specified directly. For example, `plot(x,y; type="scatter", mode="markers+lines", ...)` would produce a scatter plot along with lines connecting the points.
This task can be done by either combining  `plot` with `scatter!` (introduced next) *or* passing `seriestype=[:lines, :scatter]`.

### `scatter(xs, ys, [zs])` or `scatter(pts)`

Save for a few methods, the `plot` method represents the data with type `line` which instructs `Plotly` to connect points with lines.

Related to `plot` and `plot!` are `scatter` and `scatter!`; which render just the points, without connecting the dots.


The following `Plots.jl` marker attributes are supported:

* `markershape` to set the shape
* `markersize` to set the marker size
* `markercolor` to adjust the color; `markeralpha` for its transparency level

A specification like `marker=(:diamond, 20, :blue, 0.75)` will set the four attributes above with matching by type. (The set of marker shapes is extensive, but this package does not allow the aliases used by `Plots.jl`. Eg, `:d` for `:diamond` or `:hex` for `:hexagon`.)


### Text and arrows

The `annotate!`, `quiver!`, `arrow` and `arrow!` functions are used to add text and/or arrows to a graphic.

The `annotate!` function takes a a tuple of `(x,y,txt)` points or vectors of each and places text at the `x-y` coordinate. Text attributes can be adjusted.

The `quiver!` function plots arrows with optional text labels. Due to the underlying use of `Plotly`, `quiver` is restricted to 2 dimensions. The arguments to quiver are tail position(s) in `x` and `y` and arrow lengths, passed to `quiver` as `dx` and `dy`. The optional `txt` argument can be used to label the anchors.

The `BinderPlots.arrow!` function is not from `Plots.jl`. It provides a different interface to arrow drawing than `quiver`. For `BinderPlots.arrow!` the tail and vectors are passed in as vectors. (so for a single arrow from `p=[1,2]` with direction `v=[3,1]` one call would be `arrow!(p, v)` (as compared with `quiver([1],[2], quiver=([3],[1]))`). The latter more efficient for many arrows.

The `BinderPlots.arrows!` function borrows the `Makie.jl` interface to specify an arrow (basically `arrows!(x,y,u,v)` is `quiver!(x,y,quiver=(u,v))`.


The following `Plots.jl` text attributes are supported:

* `color`
* `family`
* `pointsize`
* `rotation`

For labels and annotations, the call `text(str, args...)` can be used to specify font properties. For example `text("label", :red, 20)` specifies the color and text size for the string when used to label a graphic. The `font` function takes the `args...` and returns a `Font` object, which allow various text attributes to be customized.

### Shapes

The `Shape` constructor can be used to specify a polygon, as with `Shape(xs, ys)`. There are a few built-in shapes available by specifying symbol (e.g. `Shape(:diamond)` or `Shape(:unitsquare)`.

These `Shape` instances can be manipulated by `translate`, `rotate`, `scale`, `shear`, and their mutating versions. As well there is `invert!` and `center!`.

These need to be qualified, or can be imported with this command:

```{julia}
import BinderPlots: translate, translate!, rotate, rotate!, scale, scale!, shear, shear!, invert!, center!
```


The following create regions which can be filled.  Shapes have an interior and exterior boundary. The exterior line has attributes that can be adjusted with `linecolor`, `linewidth`, and `linestyle`.

The following `Plots.jl` fill attributes are supported:

* `fillcolor` a color, use `rgb` to specify a color with alpha level, e.g. `rgb(:green, 0.25)` (this is like `Plots.plot_color`, but more general as `rgb` also takes RGB values in the range `0` to `225`.

* `fillrange` one of `:none`, `:tozerox`, `:tonextx`, `:tozeroy` (or `0`), `:tonexty`, `:toself`, `:tonext`. The default for `Shape` instances is `:toself`.

Use `stroke` to specify attributes for the enclosing polygonal line.

!!! note
    Unlike `Plots.jl` `Shape` instances can not be used directly as marker shapes.

Other plotting commands that create 2d-regions are:

* `rect!(x0, x1, y0, y1)` draws a rectangle between `(x0, y0)` and `(x1, y1)`.
* `hspan!(ys, YS; xmin=0.0, xmax=1.0)` draws horizontal rectangle(s) with bottom and top vertices specified by `ys` and `YS`. (A different calling style than `Plots.jl`.)
* `vspan!(xs, XS; ymin=0.0, ymax=1.0)` draws vertical rectangle(s) with left and right vertices specified by `xs` and `XS`.
* `circle!(x0, x1, y0, y1)` draws a "circular" shape in the rectangle given by `(x0, y0)` and `(x1, y1)`.
* `poly!(points; kwargs...)` where points is a container of ``(x,y)`` or ``(x,y,z)`` coordinates. Alternate to `Shape`.
* `band!(lower, upper, args...; kwargs...)` draws a ribbon or band between `lower` and `upper`. These are either containers of `(x,y)` points or functions, in which case `args...` is read as `a, b, n = 251` to specify a range of values to plot over. The function can be scalar valued or parameterizations of a space curve in ``2`` or ``3`` dimensions. The `ribbon` argument of `Plots` is not supported.

There are just mutating versions of the above.

In addition, there are a few, simple, non-polygonal shapes, including lines:

* `hline!(y; xmin=0.0, xmax=1.0)` draws a horizontal line at elevation `y` across the computed axis, or adjusted via `xmin` and `xmax`.  The `extrema` function computes the axis sizes. If `y` is a container, multiple lines are drawn.
* `vline(x; ymin=0.0, ymax=1.0)`  draws a vertical line at  `x` across the computed axis, or adjusted via `ymin` and `ymax`. The `extrema` function computes the axis sizes. If `x` is a container, multiple lines are drawn.
* `abline!(intercept, slope)` for drawing lines `a + bx` in the current frame.

(There are also `Shape(:hline)` and `Shape(:vline)` that can be used, though typically would require some translation and scaling.)

----


For example, this shows how one could visualize the points chosen in a plot, showcasing both `plot` and `scatter!` in addition to a few other plotting commands:

```@example lite
f(x) = x^2 * (108 - 2x^2)/4x
x, y = BinderPlots.unzip(f, 0, sqrt(108/2))
plot(x, y; legend=false)
scatter!(x, y, markersize=10)

quiver!([2,4.3,6],[10,50,10], ["sparse","concentrated","sparse"],
        quiver=([-1,0,1/2],[10,15,5]))

# add rectangles to emphasize plot regions
y0, y1 = extrema(current()).y  # get extent in `y` direction
rect!(0, 2.5, y0, y1, fillcolor="#d3d3d3", fillalpha=0.2)
rect!(2.5, 6, y0, y1, linecolor="black", fill=("orange", 0.2))
x1 = last(x)
rect!(6, x1, y0, y1, fillcolor=rgb(150,150,150), opacity=0.2)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

The values returned by `BinderPlots.unzip(f, a, b)` are not uniformly chosen, rather where there is more curvature there is more sampling. For illustration purposes, this is emphasized in a few ways: using `quiver!` to add labeled arrows and `rect!` to add rectangular shapes with transparent filling.

As seen in this overblown example, there are other methods besides `plot` for other useful tasks. These include:

* `scatter!` is used to plot points using markers.

* `quiver!` is used to add arrows to a plot. These can optionally have their tails labeled, so this method can be repurposed to add annotations.  The `quiver` command allows for text rotation. Also `arrow` and `arrows` for different interfaces for drawing arrows. The `annotate!` function is used to add annotations at a given point. There are keyword arguments to adjust the text size, color, font-family, etc.

* `rect!` is used to make a rectangle. There are also `hspan!` and `vspan!`. For lines, there are `hline!` and `vline!` to draw horizontal or vertical lines across the extent of the plotting region. There is also `abline!` to draw lines specified in intercept-slope form across the extent of the plotting region. Other regions can be draws. For example, `circle!` to draw a circle, and, more generally, `poly` can be used to draw a polygonal region.


For another example, shapes can be used to create error bars. For example, suppose at a pair of points, error bars with width ``\sigma`` are to be drawn:

```@example lite
import BinderPlots: translate, scale
xs = 1:5
ys = [1,3,2,4,5]
sigmas = 1 ./ (1:5)

scatter(xs, ys, markersize=5)

vl = Shape(:vline)
errors = [translate(scale(vl, 1, σ), x, y) for (σ, x,y) in zip(sigmas, xs, ys)]
plot!(errors; fill=(stroke(2),) )

to_documenter(current())           # hide
```

To adjust the width of the bar, we pass the value through `stroke`. Error bars can be added with the series type `:xerror`, as with `plot!(xs, ys; seriestype=[:xerror], xerror=(1 ./ (1:5), ))`.

## Attributes

Attributes of a plot are modified through keyword arguments. The `Plots.jl` interface allows many aliases and has magic argument. No attempt to cover all of these is made.

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
|`fillrange`        | shapes                | how much to fill |
|`fill`             | shapes                | set with magic fill arguments |
|`color`			| `annotate!` | set with color argument of `text`  |
|`family`			| `annotate!` | set with string (font family) |
|`pointsize`		| `annotate!` | set with integer |
|`rotation`        	| `annotate!` | set with angle, degrees, real  |
|`center`		   	| new `3`d plots | set with tuple, see [controls](https://plotly.com/python/3d-camera-controls/) |
|`up`				| new `3`d plots | set with tuple, see [controls](https://plotly.com/python/3d-camera-controls/) |
|`eye`				| new `3`d plots | set with tuple, see [controls](https://plotly.com/python/3d-camera-controls/) |

As seen in the example there are *many* ways to specify a color. These can be by name (as a symbol or as a string),  using HEX colors (as strings), using `rgb`. (The `rgb` function, unlike the standard `Colors.RGB`, uses values in `0` to `255` to specify the values and also can take a fourth argument for an alpha value, which is useful for filling with opacity.)

Some exported names are used to adjust a plot after construction:

* `title!`, `xlabel!`, `ylabel!`, `zlabel!`: to adjust title; ``x``-axis label; ``y``-axis label
* `xlims!`, `ylims!`, `zlims!`: to adjust limits of viewing window
* `xticks!`, `yticks!`, `zticks!`: to adjust axis ticks
* `xaxis!`, `yaxis!`, `zaxis!`: to adjust the axis properties

!!! note "Subject to change"
    There are some names for keyword arguments that should be changed.

### "Magic" arguments

The designer of `Plots.jl` cleverly recognized that many argument types come in similar groups. For example, lines, markers, and filling all have a color and an alpha transparency level. Each may have a different style or shape. Each may have a different scale. Moreover, scales are described by integers, styles described by symbols or strings, colors by symbols or strings -- if not a more specific type --  and transparencies by a number in $(0,1)$. As `Julia` can readily dispatch on value types, an expression like `(:red, 0.25, 12)` can be  parsed to identify a color, an alpha level and a scale. From here, it was a smart move to use keywords to associate these values with different attribute groups.

The `Plots.jl` design leverages data types to "magically" fill in keyword arguments. Much of this is implemented within `BinderPlots`, as described next.

#### Series arguments

The special keyword arguments `line`, `marker`, and `fill` are iterated over to fill in keyword arguments. For example, passing `line=(5, (:red, :blue), 0.25, :dash)` will specify: Draw the line for any odd number series with `linewidth=5`; color `rgb(:red, 0.25)`; and line style `:dash`. Even numbered series (when present) will have color `rgb(:blue, 0.25)` and the modified line width and style, as the values are recycled when there are multiple series specified.

The container passed to `line` has the following mappings:

* symbols and strings are matched against the possible linestyles, then the possible lineshapes; if there is no match, then the value is assumed to specify a color
* a number in `(0,1)` indicates a transparency level
* an integer specifies the scale for line width
* `rgb` values are passed to the `linecolor` attribute
* a `Stroke` object, produced by `stroke`, can alternatively be used to specify these values


The container passed to `marker` has the following mappings:

* symbols and strings are matched against known marker shapes; if there is no match then the value is assumed to specify a color
* scale, color, and transparency are as for `line`

The container passed to `fill` has the following mappings:

* symbols and strings are matched against fill styles; if there is no match then the value is assumed to specify a color
* a number in `(0,1)` indicates a transparency level
* a `0` sets fill style = `:tozeroy`. (Other integers are not available, as in `Plots.jl`)
* a `true` indicates the fill style should be `:toself`
* `Stroke` objects, produced by `stroke`, adjust the properties of the line

#### Other uses of magic arguments

The `font` function (which can be called directly or indirectly through `text` or `annotate!`) has the following magic arguments defined:

* strings are assumed to indicate font families
* symbols are checked for alignment (e.g., `:top`, `:bottom`, etc.); if no match, they are assumed to be a color specification.
* integers specify point sizes
* non integers (e.g. `pi/4`) indicate rotation

The `legend` argument can be a boolean or a container. When a container the values are magically transformed with:

* symbols are checked for correspondence with a legend position; if the symbol is `:reverse`, otherwise the symbol is assumed to be a color specification.
* tuples indicate the placement position
* `Font` instances, as produced by `font`, indicate the font in the legend
* Boolean values indicate whether to show or hide the legend

The `[xyz]axis!` function arguments have:

* Symbols are checked for scale indicators `(:log, :linear, :log2m :log10, :flip, :invert, :inverted)`
* strings and `Text` values are applied to the axis label.
* tuples are assumed to indicate a range if length 2, otherwise a collection of tick placements.
* `Font` values apply to the tick fonts
* Boolean values indicate if the grid should be shown for that axis



## Example

This example is from the section on "Input Data" from the `Plots.jl` documentation. It use shapes and other objects to draw a Batman scene. We recreate it here to illustrate some small but significant differences between `Plots.jl` and `BinderPlots`. The comments with superscripts are where differences are needed:

```@example lite
using BinderPlots
import BinderPlots: translate, stroke, BezierCurve #¹

const Plots = BinderPlots
RGB(a,b,c) = rgb(round.(Int, 255 .* (a,b,c))...) #²
const plot_color = rgb

function make_batman()
    p = [(0, 0), (0.5, 0.2), (1, 0), (1, 2),  (0.3, 1.2), (0.2, 2), (0, 1.7)]
    s = [(0.2, 1), (0.4, 1), (2, 0), (0.5, -0.6), (0, 0), (0, -0.15)]
    m = [(p[i] .+ p[i + 1]) ./ 2 .+ s[i] for i in 1:length(p) - 1]

    pts = similar(m, 0)
    for (i, mi) in enumerate(m)
        append!(
            pts,
            map(BezierCurve([p[i], m[i], p[i + 1]]), range(0, 1, length = 30))
        )
    end
    x, y = Plots.unzip(Tuple.(pts))
    Shape(vcat(x, -reverse(x)), vcat(y, reverse(y)))
end

# background and limits
plt = plot(
    bg = :black,
    xlim = (0.1, 0.9),
    ylim = (0.2, 1.5),
    framestyle = :none,
    size = (400, 400),
    legend = false,
)

xaxis!(plt; showticklabels = false, showgrid = false, zeroline = false) #³
yaxis!(plt; showticklabels = false, showgrid = false, zeroline = false) #³



# create an ellipse in the sky
pts = Plots.partialcircle(0, 2π, 100, 0.1)
x, y = Plots.unzip(pts)
x = 1.5x .+ 0.7
y .+= 1.3
pts = collect(zip(x, y))

# beam
beam = Shape([(0.3, 0.0), pts[95], pts[50], (0.3, 0.0)])
plot!(beam, fillcolor = plot_color(:yellow, 0.3))

# spotlight
# plot!(Shape(x, y), c = :yellow)  #⁴ no seriescolor argument
plot!(Shape(x, y), fc = :yellow)

# buildings
rect(w, h, x, y) = Shape(x .+ [0, w, w, 0, 0], y .+ [0, 0, h, h, 0])
gray(pct) = RGB(pct, pct, pct)
function windowrange(dim, denom)
    range(0, 1, length = max(3, round(Int, dim/denom)))[2:end - 1]
end

for k in 1:50
    local w, h, x, y = 0.1rand() + 0.05, 0.8rand() + 0.3, rand(), 0.0
    shape = rect(w, h, x, y)
    graypct = 0.3rand() + 0.3
    plot!(shape, fc = gray(graypct))  #⁴

    # windows
    I = windowrange(w, 0.015)
    J = windowrange(h, 0.04)
    local pts = vec([(Float64(x + w * i), Float64(y + h * j)) for i in I, j in J])

    windowcolors = Symbol[rand() < 0.2 ? :yellow : :black for i in 1:length(pts)]
    local xs, ys = BinderPlots.unzip(pts)
    scatter!(xs', ys', marker = (stroke(0), :square, windowcolors)) #⁵


end
plt

batman = Plots.scale(make_batman(), 0.07, 0.07, (0, 0))
batman = translate(batman, 0.7, 1.23)
plot!(batman, fillcolor = :black)

to_documenter(current())           # hide
```

To remark on the differences:

1) The `translate` and `scale` methods for `Shape` instances and the `BezierCurve` constructor (lifted directly for `Plots.jl`) are not exported.

2) the use of `RGB` from `Colors.jl` is not supported in `PlotlyLight` and hence `BinderPlots`. The `rgb` function is a replacement which also replaces the `plot_color` function used above to add an alpha transparency to a color specified by a symbol.

3) The illustrated use of `xaxis!` and `yaxis!` is needed to make a blank canvas. There is also an unexported `blank_canvas` function to avoid this detail.

4) There is no support for the `seriescolor` argument (with the `c` alias). Rather the fill color is needed to be specified in this line.

5) The `Plots.jl` interface allows individual points in a scatter plot to have colors specified, so `scatter!(pts, ...)` works, where the values specified to `marker` are recycled. However, this is not the case with
the `BinderPlots` interface which specifies these colors at the series level. In the above, taking the adjoint of the `x`- and `y`-values creates an abstract matrix, and then each column is taken as specifying a different series. Alternatively, two series could be used to paint the windows black or yellow. For example:

```
inds = [rand() < 0.2 for i in 1:length(pts)]
scatter!(BinderPlots.Series(pts[inds], pts[.!inds]), marker=(stroke(0), :square, (:yellow,:black)))
```

Also, the shape `:square` is used, not `:rect`, as in the original, for this is not a supported shape in `Plotly`.

## Currently unsupported

The last example highlighted a few differences between `Plots.jl` and less featureful `BinderPlots.jl`. In addition to a less relaxed method for data specification, a few other important differences are summarized in the following (with order given by failing examples from the `examples.jl` file):

* Some markers are not supported, and if passed as a magic argument will be identified as a color (e.g., `:hex`,`:d`, `:rect`, ...)

* Several shorthands are not defined (e.g. `histogram`, `histogram2d`, `bar`, `OHLC`, `pie`, `boxplot`, `violin`, `spy`, `portfoliocomposition`, `areaplot`, `curves`)

The `seriestype` might be defined. If not, defining a method for `SeriesType`, like `SeriesType(::Val{:histogram}) = (:histogram, :histogram)` where the return lists a `type` and a `mode` value for `plotly`, may work.

* The `@layout` macro is not supported

The only grid layout is to put the plots into an array, one plot per cell. For side-by-side plots, `plot(p1, p2, ...)` is supported.

A PR would be most welcome.

* Shapes can not be used as custom  markers

`Plots.jl` allows custom shapes as markers. This is not supported, though can be mimicked, as in the following:

```@example lite
s = Shape(:star6)
BinderPlots.scale!(s, 1/20) # shape is roughly unit circle size
xs, ys = rand(50), rand(50)

BinderPlots.blank_canvas(xlims=(0,1), ylims=(0,1),
    aspect_ratio=:equal)
plot!([BinderPlots.translate(s, x, y) for (x,y) in zip(xs,ys)],
             fill=(:yellow, clamp.(rand(50), 0.5, 1), BinderPlots.stroke(:black)),
			 bg=:black)


to_documenter(current())           # hide
```

* There is no `@df` macro, no `group` argument

* The `projection` keyword is not supported for polar maps

* `PlotsMeasures` are not supported

* Animations are not supported

* magic grid arguments are not supported

* The `ribbon` argument is not supported

The `band` function may be a substitute

* The `lens` feature is not supported

* The `default` function is not supported

* linked axes are not supported

* `Mesh3d` support is lacking

* `seriestype` is slightly different

In `Plots.jl` it can modify how a line is drawn, use `linestyle` for that instead.

* guides are not supported

* flipping of axes is note supported

* `hspan!` and `vspan!` have different calling styles; there are no `hspan` or `vspan` methods

* There are no annotations at discrete locations, only at points

* `proj_type` is not supported; `camera` is idiosyncratic

* Bezier curves are a bit more cumbersome than calling `curves`

The `curves` function might be replicated by:

```@example lite
function curves(x, y; kwargs...)
   BC = BinderPlots.BezierCurve(tuple.(x,y))
   plot(t -> BC(t), 0, 1; kwargs...)
   scatter!(BC.control_points, marker=(12, 0.75))
end
curves(1:4, [1,1,2,4]; title="Bezier Curve")

to_documenter(current())           # hide
```

* There is no hatching for fill style

* Shared axes (`twinx`) are not supported

* legend positioning is different
