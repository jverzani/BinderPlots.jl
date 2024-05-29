# 3 dimensional graphs

The initial graphics of calculus involve the ``x-y`` plane but eventually the visualizations require a ``z`` direction. This is because functions ``f:R \rightarrow R`` are graphed in ``x-y`` values, but functions such as ``f:R^2 \rightarrow R`` or ``f:R \rightarrow R^3`` naturally use the third dimension.



## Parametric line plots (space curves)

Parametric line plots show the graph of ``f:R \rightarrow R^3`` by a plot linking the points ``(x(t), y(t), z(t))``.

Parametric plots can be easily created by using a tuple of functions, as in:

```@example lite
using BinderPlots # load package if not loaded
using PlotlyDocumenter # hide

version = BinderPlots.PlotlyLight.plotly.version # hide
PlotlyDocumenter.change_default_plotly_version(version) # hide
nothing # hide
```


```@example lite
plot((sin, cos, x -> x), 0, 4pi)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

(The use of tuples to pair functions is idiosyncratic; the `Plots.jl` style of passing functions for the first 3 (or 2) positional arguments is also supported.)

As with 2-dimensional lines, the arguments `linecolor`, `linewidth`, `linestyle`, and `lineshape` from `Plots` are available.

Using a single function returning a point may be more natural for some usages. Below we use `BinderPlots.unzip` to take a container of points into 3 containers for the coordinates, `x`, `y`, `z` to pass to `plot(x,y,z)` (this could also be just `plot(r.(ts))`. but that interface is not available in `Plots.jl`):

```@example lite
r(t) = (sin(t), cos(t), t)
rp(t) = (cos(t), -sin(t), 1)

ts = range(0, 4pi, length=251)
plot(BinderPlots.unzip(r.(ts))...; legend=false)
ts = range(0, 4pi, length=10)
BinderPlots.arrow!(r.(ts), rp.(ts))

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

In the above we used `arrow!`, with a collection of tails and vectors, to indicate the tangent direction. The `arrow!` function hacks together an arrow, as there is no underlying 3-dimensional arrow in `Plotly`.

!!! note "arrow!"
    The cones used for the arrow heads are not always scaled properly.

## Visualizing ``f:R^2 \rightarrow R``

Functions of the two variables which return a single, scalar value can be visualized in different ways. Using ``3`` dimensions one can use the ``x-y`` plane to denote the inputs and the ``z`` axis the value forming a surface. In ``2`` dimensions the value can be represented a few ways: using colors, as with heatmaps, or using a line to show ``(x,y)`` values with the same ``z`` value, as with contour maps.

Contour, heatmaps, and surface plots can be produced by `contour`, `heatmap`, and `surface`. Some examples here use the [`peaks`](https://www.mathworks.com/help/matlab/ref/peaks.html) function of MATLAB:

```@example lite
function peaks(x,y)
    z = 3 * (1-x)^2 * exp(-(x^2) - (y+1)^2)
    z = z - 10 * (x/5 - x^3 - y^5) * exp(-x^2-y^2)
    z = z - 1/3 * exp(-(x+1)^2 - y^2)
end
```

A contour graph can be made by specifying a grid of points through a selection of ``x`` and ``y`` values (utilizing `range`, as below, is one such way) and the function (of two variables) in a direct manner:

```@example lite
xs = range(-3, 3, length=100)
ys = range(-2, 2, length=100)
contour(xs, ys, peaks)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

### Contour graphs

The contour lines are automatically selected. Passing a range to the `levels` argument allows a user choice. Contour plots can be filled with colors. Passing `fill=true` is all it takes (or calling with `contourf`):

```@example lite
contour(xs, ys, peaks; levels=-3:3, fill=true, colorscale="Picnic")

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

The levels argument can be a range (something with a `step` method, like `-3:3`) or a single number.



The `linewidth` argument can adjust the width of the contour lines.
The `contour_labels` argument indicates if the contours should be labeled. The `colorbar` argument indicates if the colorbar scale should be drawn. (The `Plotly` counterpoint is `showscale`.)

The `Plots.jl` argument `fill` is used to indicate if the space between the contours should be colored to give more indication of the gradient.

The `Plotly` argument `colorscale` can be one several scales including `"YlOrRd"`, `"YlGnBu"`, `"RdBu"`, `"Portland"`, `"Picnic"`, `"Jet"`, `"Hot"`, `"Greys"`, `"Greens"`, `"Bluered"`, `"Electric"`, `"Earth"`, `"Blackbody"`, `"Viridis"`, and `"Cividis"`.


### Heatmaps

A heatmap uses color variation, not contour lines, to indicate the differences in ``z`` values. As with `contour`, the `colorscale` argument is passed to `Plotly`:

```@example lite
heatmap(xs, ys, peaks; colorscale="Hot")

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

### Implicitly defined functions

The equation ``f(x,y) = 0`` for a fixed ``x`` may have many ``y`` values for a solution. However, *locally* for most points and nice functions ``f`` there is an *implicitly* defined function ``y(x)``. This is useful, say if a tangent line is sought. The `plot_implicit` function can be used to show implicitly defined function given by ``f(x,y)=0``. It is basically a contour plot with only a ``0`` level.

The implementation only asks for a range of ``x`` and ``y`` values to search over. It chooses the number of intermediate points. The ranges are specified through the arguments `xlims` and `ylims` with defaults yielding the region ``[-5,5] \times [-5,5]``.

For example:

```@example lite
plot_implicit(peaks; xlims=(-3,3), ylims=(-3,3))


delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```


### Surface plots

By surface plot we mean a representation of a ``2`` dimensional structure within ``3`` dimensions, as can be visualised.

There are two primary ways of generating these:

* A bivariate, scalar function $f: R^2 \rightarrow R$ can be visualized with the ``x-y`` plane showing the inputs and the ``z`` axis the values.
* A parametric description with some function $F(u,v) = \langle X(u,v), Y(u,v), Z(u,v) \rangle$.

We illustrate each:

The `peaks` function can be viewed as easily as the following using `surface`, where like `contour`, the `xs` and `ys` show where on the `x` and `y` axis to sample:


```@example lite
xs = range(-3, 3, length=100)
ys = range(-2, 2, length=100)

surface(xs, ys, peaks)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

Attributes are easily adjusted:

```@example lite
surface(xs, ys, peaks; zcontour=true, showscale=false)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```


Parametric surfaces can be produced as follows, where, in this usage, `BinderPlots.unzip` creates ``3`` matrices to pass to `surface`:

```@example lite
r1, r2 = 2, 1/2
r(u,v) = ((r1 + r2*cos(v))*cos(u), (r1 + r2*cos(v))*sin(u), r2*sin(v))
us = vs = range(0, 2pi, length=25)

p = surface(BinderPlots.unzip(us, vs, r)...;
	aspect_ratio=:equal, showscale=false)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```


There isn't much support for arguments from the `Plots.jl` implementation, save:

* `aspect_ratio = :equal` sets the underlying aspect ratio to be equal.

Many `Plotly` arguments are quite useful:

* `zcontour=true` will add a contour graph showing the levels
* `opacity` makes it easy to set the transparency of the rendered object
* `eye`, `center`, and `up` can adjust the camera positioning.
* `showscale=false` can be specified to avoid the drawing of a color scale.


This last example shows how to plot a surface and two planes along with their intersections with the surface emphasized. The latter uses the `Contours` package. One plane has the form ``ax + by + cz = d`` which for non-zero `c` has `z(x,y)` solvable and is visualized through `surface`. The intersection of the surface and the plane is the ``0``-level contour of the function ``f(x,y) - z(x,y)``.

The other plane has ``c=0``, so is plotted differently. That plane is [described](https://community.plotly.com/t/slicing-3d-surface-plot-along-a-user-selected-axis/40771/6) as lying in the direction of the vectors ``[a,b,0]`` and ``[0,0,1]`` and going through the point ``[x_0, y_0, 0]``. This gives ``b(x-x_0) - a(y-y_0) = 0``. We plot this parametrically. The intersecion can be found by projecting the line in the ``x-y`` plane onto the surface.

```@example lite
f(x, y) = 4 - x^2 - y^2

xs = ys = range(-2, 2, length=100)
surface(xs, ys, f; legend=false, showscale=false)

# plane of the from a*x + b*y + c*z = d, c != 0
a,b,c,d = 1,1,1,2.5
z(x,y) = (d - a*x - b*y) / c
surface!(xs, ys, z, opacity=0.25, showscale=false)

# One way to plot intersection numerically
import Contour
cs = Contour.contours(xs, ys, ((x,y) -> f(x,y) - z(x,y)).(xs', ys), [0])
for cl ∈ Contour.levels(cs)
    for line in Contour.lines(cl)
        xₛ, yₛ = Contour.coordinates(line) # coordinates of this line segment
        plot!(xₛ, yₛ, z.(xₛ, yₛ), linecolor="black", linewidth=10)
    end
end

# plane parallel to [a,b,0], [0,0,1] and through [x0,y0,0]
a,b = 1, 1
x0, y0 = 0, 0 # origin

zs = range(-4, 4, length=100) # or extrema(z.(xs', ys))
Xs = ((x,z) -> x).(xs', zs)
Zs = ((x,z) -> z).(xs', zs)

c, d = 0, b*x0 - a * y0
plane(x,z) = (d + a*x - c*z) / b
Ys = plane.(xs', zs)
surface!(Xs, Ys, Zs, opacity=0.25, showscale=false)

g(t) = (b*t -d)/a # line in x-y plane
xxs = xs
yys = g.(xxs)
zzs = f.(xxs, yys)
plot!(xxs, yys, zzs, linewidth=10, linecolor="black")

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```
