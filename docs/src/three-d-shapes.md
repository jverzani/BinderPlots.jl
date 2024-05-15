# Three dimesional shapes

```@example lite
using BinderPlots
using PlotlyDocumenter # hide

version = BinderPlots.PlotlyLight.plotly.version # hide
PlotlyDocumenter.change_default_plotly_version(version) # hide
nothing # hide
```

!!! note "Not `Plots` inspired"
    The three dimensional shapes discussed here are developed without paying attention to any `Plots.jl` interfaces.

Many surfaces are easily described in turns of being the graph of a function ``f:R^2 \rightarrow R`` or in turns of a parameterization ``F(u,v) = \langle X(u,v), Y(u,v), Z(u,v) \rangle``. The `surface` function readily plots such. However, some surfaces can be more easily described otherwise, and `BinderPlots` attempts to provide some interface in a few cases.

Rather than use the `surface` type, the following use the `mesh3d` type which requires a triangularization of the desired surface. Two types of surfaces that are easily triangulated are:

* "star-shaped" surfaces defined by a boundary, described by `xs, ys, zs`, and a point `p` (a vector) with the property that the line segment connecting `p` to a boundary point does not cross any other boundary point. A simple example is a disc with `p` being the origin. The triangulation is easy to visualize, the vertices being the origin and adjacent points on the boundary (which is of course discretized by the data).

* The surface between two space curves defined by selecting $n$ points on each and connecting the points by a line. Paired adjacent points form "rectangles" that are easily triangulated.  This is an example of a [ruled surface](https://en.wikipedia.org/wiki/Ruled_surface) between two space curves. (A star shape is a ruled surface with one of the curves being just a point.)

The underlying functions have the odd names `★` (i.e., `\bigstar[tab]`) and `ziptie`, along with their `!` counterparts.

These are used to provide the following shapes

* `parallelogram)q, u, v)!` which draws the planar region formed by two vectors `u` and `v` anchored at a point `q`.

* `circ3d!(q, r, n)` which draws the disc with origin `q`, radius `r` and normal to a vector `n`

* `skirt!` which forms a surface defined by an underlying path (either the vector `v` anchored at `q` or by values `xs`, `ys`, `zs`) and the paths projection onto the surface of `f(x,y)`

* `band!` is an alternative interface, borrowed from `Makie`, to `ziptie!`


# Intersection of 3 planes

The `parallelogram` function allows planes to easily be described. Contrast the following to an example in the previous section when a plane ``ax + by = d`` was described as a parametric surface in order to graph it with `surface`. Here such planes are described by two orthogonal vectors.

```@example lite
parallelogram( [-1,-1,0], [2,0,0], [0,2,0])
parallelogram!([-1,0,-1], [0,0,2], [2,0,0])
parallelogram!([0,-1,-1], [0,2,0], [0,0,2])

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

The choice of shapes is done to facilitate certain graphics of calculus.

For example, to illustrate the method of finding volumes by slices a figure like the following might be of interest:

```@example lite
f(r, u) = 4 - r
rs = range(0, 4, length=25)
us = range(0, 2pi, length=25)
X(r, u) = r * sin(u)
Y(r, u) = r * cos(u)

surface(X.(rs', us), Y.(rs', us), f.(rs', us), opacity=0.25)

q, n = [0,0,2], [0,0,1]
circ3d!(q, 2, n, opacity=0.5, color="blue")

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

That utilizes `circ3d!` to draw a disc with normal vector in the direction of the ``z`` axis.

Whereas, this next graphic utilizes `skirt!` to highlight the intersection of the plane `x=-1`with surface.

```@example lite
f(x, y) = 1 + cospi(x) + cospi(y)
xs = ys = range(-1, 1, 100)

surface(xs, ys, f; opacity=0.25)

# draw skirt between surface and the line p + t*v
p, v = [-1/2,-1,0], [0, 2, 0]
skirt!(p, v, f; opacity = 0.5, color=:black)

# draw intersection of plane and surface
r(t) = p + t * v
ts = range(0, 1, length=100)
xs, ys, _ = BinderPlots.unzip(r.(ts))
zs = f.(xs, ys)
plot!(xs, ys, zs, linewidth=10)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```


The underlying mesh functions can be of use as well.


# Helix

The `ziptie` function lends itself to drawing an helix (or fusili if you are hungry):

```@example lite
r(t) = (sin(t), cos(t), t)
s(t) = (sin(t+pi), cos(t+pi), t)
ts = range(0, 4pi, length=100)

ziptie(BinderPlots.unzip(r.(ts))..., BinderPlots.unzip(s.(ts))...;
       color="green", opacity=.25, showscale=false)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

This is  a related spiraling ribbon using `band`:

```@example lite
r(t) = (sin(t), cos(t), t)
s(t) = (sin(t)/2, cos(t)/2, t)
ts = range(0, 4pi, length=100)

band(r.(ts), s.(ts);
       color="seafoam", opacity=.25, showscale=false)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```


# Star shapes

This shape is reminiscent of a potato chip, though formed with lines drawn from `[0,0,0]`:


```@example lite
r(t) = (sin(t), 2cos(t), sin(2t))
ts = range(0, 2pi, 100)

★([0,0,0], BinderPlots.unzip(r.(ts))...)
plot!(BinderPlots.unzip(r.(ts))..., linewidth=10)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```
