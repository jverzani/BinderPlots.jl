## ----- Plotly shapes

# shapes in Plotly use `layout` not `data`
# generalize shapes (line, rect, circle, ...)
# fillcolor
# line.color
function _shape(type, x0, x1, y0, y1;
                kwargs...)



    c = Config(; type, x0, x1, y0, y1)
    kws = _make_magic(;kwargs...)
    kws = _linestyle!(c; kws...)
    kws = _fillstyle!(c; kws...)
    _merge!(c; kws...)
    c
end

function _add_shape!(p::Plot, d)
    if isempty(p.layout.shapes)
        p.layout.shapes = [d]
    else
        push!(p.layout.shapes, d)
    end
    p
end

function _add_shapes!(p::Plot, ps; kwargs...)
    if isa(ps, Config)
        _add_shape!(p, ps; kwargs...)
    else
        for (i, s) ∈ enumerate(ps)
            _add_shape!(p, s)
        end
    end
end

# _identity Broadcast to an iterable
_identity(x0::Real,x1::Real,x2::Real,x3::Real) = ((x0,x1,x2,x3),)
_identity(xs...) = __identity.(xs...)
__identity(xs...) = xs

"""
    vline!(x; ymin=0, ymax=1.0; kwargs...)

Draw vertical line at `x`. By default extends over the current plot range, this can be adjusted by `ymin` and `ymax`, values in `[0,1]`.

The values for `x`, `ymin`, and `ymax` are broadcast.

A current plot must be made to add to, as the extent of the lines is taken from that.

# Example

Add a grid to a plot:

```
p = plot(x -> x^2, 0, 1; aspect_ratio=:equal)
vline!(0:.1:1, linecolor=:red,  opacity=0.25, linewidth=5)
hline!(0:.1:1, line=(:blue, 0.75))
```

"""
vline!(x; kwargs...) = vline!(current_plot[], x; kwargs...)
function vline!(p::Plot, x; ymin = 0.0, ymax = 1.0, kwargs...)
    a, b = extrema(p).y
    Δ = b - a

    xxyy = _identity(x, x, a .+ Δ .* ymin, a .+ Δ .* ymax)

    KWs = Recycler(kwargs)
    for (i, xᵢ) ∈ enumerate(x)
        _add_shape!(p, _shape("line", xxyy[i]...;
                              mode="Line", KWs[i]...))
    end

    p
end

"""
    hline!(y; xmin=0, xmax=1.0; kwargs...)

Draw horizontal line at `y`. By default extends over the current plot range, this can be adjusted by `xmin` and `xmax`, values in `[0,1]`.

The values for `y`, `xmin`, and `xmax` are broadcast.

A current plot must be made to add to, as the extent of the lines is taken from the current plot.
"""
hline!(x; kwargs...) = hline!(current_plot[], x; kwargs...)
function hline!(p::Plot, y; xmin = 0.0, xmax = 1.0, kwargs...)
    a, b = extrema(p).x
    Δ = b - a

    xxyy = _identity(a .+ Δ .* xmin, a .+ Δ .* xmax, y, y)
    KWs = Recycler(kwargs)
    for (i, yᵢ) ∈ enumerate(y)
        _add_shape!(p, _shape("line",xxyy[i]...;
                              mode="Line", KWs[i]...))
    end

    p
end

"""
    abline!([p::Plot], intercept, slope; kwargs...)

Draw line `y = a + bx` over current viewing window, as determined by
`extrema(p)`.
"""
abline!(intercept, slope; kwargs...) = abline!(current_plot[], intercept, slope; kwargs...)
function abline!(p::Plot, intercept, slope;
                  kwargs...)
    xa, xb = extrema(p).x
    ya, yb = extrema(p).y

    _line = (a, b) -> begin
        if iszero(b)
            return (xa, xb, a, a)
        end
        # line is a + bx in region [xa, xb] × [ya, yb]
        l = x -> a + b * x
        x0 = l(xa) >= ya ? xa : (ya - a)/b
        x1 = l(xb) <= yb ? xb : (yb - a)/b
        y0, y1 = extrema((l(x0), l(x1)))
        return (x0, x1, y0, y1)
    end
    KWs = Recycler(kwargs)
    for (i, xxyy) ∈ enumerate(_line.(intercept, slope))
        _add_shape!(p, _shape("line",xxyy...;
                              mode="Line", KWs[i]...))
    end

    p
end



"""
    rect!([p::Plot], x0, x1, y0, y1; kwargs...)

Draw rectangle shape on graphic.

# Example [2, 3] × [-1, 1]

```
rect!(p, 2, 3, -1, 1; linecolor=:gray, fillcolor=:red, opacity=0.2)
```
"""
function rect!(p::Plot, x0, x1, y0, y1; kwargs...)
    KWs = Recycler(kwargs)
    xxyyₛ = _identity(x0, x1, y0, y1)
    for (i, xxyy) ∈ enumerate(xxyyₛ)
        _add_shape!(p, _shape("rect", xxyy...; KWs[i]...))
    end
end
rect!(x0, x1, y0, y1; kwargs...) = rect!(current_plot[], x0, x1, y0, y1; kwargs...)


"""
    hspan!([p::Plot], ys; kwargs...)
    hspan!([p::Plot], ys, YS; xmin=0.0, ymin=1.0, kwargs...)

Draw horizontal rectanglular rectangle from `ys` to `YS`. By default extends over `x` range of plot `p`, though using `xmin` or `xmax` can adjust that. These are values in `[0,1]` and are interpreted relative to the range returned by `extrema(p).x`.

If just `ys` is specified, it is taken as zipped form of (ys, YS). This form is from `Plots.jl` so use this for compatibility.

"""
hspan!(ys,YS; kwargs...) = hspan!(current_plot[], ys, YS; kwargs...)
function hspan!(p::Plot, ys, YS; xmin=0.0, xmax=1.0, kwargs...)
    a, b = extrema(p).x
    Δ = b - a

    xxyy = _identity(a .+ Δ .* xmin, a .+ Δ .* xmax, ys, YS)
    KWs = Recycler(kwargs)
    for (i, yᵢ) ∈ enumerate(ys)
        _add_shape!(p, _shape("rect",xxyy[i]...;
                              mode="Line", KWs[i]...))
    end

    p
end
hspan!(y; kwargs...) = hspan!(current_plot[], y; kwargs...)
function hspan!(p::Plot, y; kwargs...)
    n = length(y)
    vspan!(p, y[1:2:n], y[2:2:n]; kwargs...)
end

"""
    vspan!([p::Plot], xs; kwargs...)
    vspan!([p::Plot], xs, XS; ymin=0.0, ymin=1.0, kwargs...)

Draw vertical rectanglular rectangle from `xs` to `XS`. By default extends over `y` range of plot `p`, though using `ymin` or `ymax` can adjust that. These are values in `[0,1]` and are interpreted relative to the range returned by `extrema(p).y`.

If just `xs` is specified, it is taken as zipped form of `(xs, XS)`. This form is from `Plots.jl` so use this for compatibility.


# Example

```
p = plot(x -> x^2, 0, 1; legend=false)
M = 1 # max of function on `[a,b]`
vspan!(0:.1:0.9, 0.1:0.1:1.0; ymax=[x^2 for x in 0:.1:0.9]/M,
    fillcolor=:red, opacity=.25)
```
"""
vspan!(xs, XS; kwargs...) = vspan!(current_plot[], xs, XS; kwargs...)
function vspan!(p::Plot, xs, XS; ymin=0.0, ymax=1.0, kwargs...)
    a, b = extrema(p).y
    Δ = b - a

    xxyy = _identity(xs, XS, a .+ Δ .* ymin, a .+ Δ .* ymax)
    KWs = Recycler(kwargs)
    for (i, yᵢ) ∈ enumerate(xs)
        _add_shape!(p, _shape("rect",xxyy[i]...;
                              mode="Line", KWs[i]...))
    end

    p
end
# single vector for compat with Plots.jl
vspan!(x; kwargs...) = vspan!(current_plot[], x; kwargs...)
function vspan!(p::Plot, x; kwargs...)
    n = length(x)
    vspan!(p, x[1:2:n], x[2:2:n]; kwargs...)
end

# XXX poly (?https://docs.makie.org/stable/reference/plots/poly/)
"""
    poly(points; kwargs...)
    poly!([p::Plot], points; kwargs...)

Plot polygon described by `points`, a container of `x-y` or `x-y-z` values.
Alternative to creating `Shape` instance.

Example

```
f(r,θ) = (r*cos(θ), r*sin(θ))
poly(f.(repeat([1,2],5), range(0, 2pi-pi/5, length=10)))
```
"""
function poly(points; kwargs...)
    p, kwargs = _new_plot(; kwargs...)
    poly!(p, points; kwargs...)
end
poly!(points; kwargs...) = poly!(current_plot[], points; kwargs...)
function poly!(p::Plot,points;
               color = nothing,
               kwargs...)
    x,y = unzip(points)
    if (first(x) != last(x)) || (first(y) != last(y))
        x, y = collect(x), collect(y)
        push!(x, first(x))
        push!(y, first(y))
    end
    cfg = Config(; x, y, type="line", color=color, fill="toself")
    kws = _linestyle!(cfg; kwargs...)
    kws = _fillstyle!(cfg; kws...)
    _merge!(cfg; kws...)
    push!(p.data, cfg)
    p
end

"""
    circle([p::Plot], x0, x1, y0, y1; kwargs...)

Draw circle shape bounded in `[x0, x1] × [y0, y1]`. (Will adjust to non-equal sized boundary.)
# Example
Use named tuple for `line` for boundary.
```
circle!(p, 2,3,-1,1; line=(color=:gray,), fillcolor=:red, opacity=0.2)
```
"""
function circle!(p::Plot, x0, x1, y0, y1; kwargs...)
    KWs = Recycler(kwargs)
    xxyyₛ = _identity(x0, x1, y0, y1)
    for (i, xxyy) ∈ enumerate(xxyyₛ)
        _add_shape!(p, _shape("circle", xxyy...; KWs[i]...))
    end
    p
end
circle!(x0, x1, y0, y1; kwargs...) =
    circle!(current_plot[], x0, x1, y0, y1; kwargs...)


"""
    band(lower, upper; kwargs...)
    band(lower::Function, upper::Function, a::Real, b::Real,n=251; kwargs...)
    band!([p::Plot],lower, upper; kwargs...)
    band!([p::Plot],lower::Function, upper::Function, a::Real, b::Real,n=251; kwargs...)

Draw band between `lower` and `upper`. These may be specified by functions or by tuples of `x-y-[z]` values.

# Example

Using `(x,y)` points to define the boundaries
```
xs = 1:0.2:10
ys_low = -0.2 .* sin.(xs) .- 0.25
ys_high = 0.2 .* sin.(xs) .+ 0.25

p = plot(;xlims=(0,10), ylims=(-1.5, .5), legend=false)
band!(zip(xs, ys_low), zip(xs, ys_high); fillcolor=:blue)
band!(zip(xs, ys_low .- 1), zip(xs, ys_high .- 1); fillcolor=:red)
```

Or, using functions to define the boundaries

```
band(x -> -0.2 * sin(x) - 0.25, x -> 0.2 * sin(x) + 0.25,
     0, 10;  # a, b, n=251
     fillcolor=:red, legend=false)
```
"""
function band(lower, upper, args...; kwargs...)
    p, kwargs = _new_plot(; kwargs...)
    band!(p, lower, upper, args...; kwargs...)
end
band!(lower::Function, upper::Function, a,b,n=251; kwargs...) =
    band!(current_plot[], lower, upper, a,b,n; kwargs...)
band!(lower, upper; kwargs...) =
    band!(current_plot[], lower, upper; kwargs...)

function band!(p::Plot, lower::Function, upper::Function, a::Real, b::Real, n=251; kwargs...)
    ts = range(a, b, length=n)
    ls = lower.(ts)
    us = upper.(ts)
    n = length(first(ls))
    n == 1 && return band!(p, Val(2), zip(ts, ls), zip(ts, us); kwargs...)
    band!(p, Val(n), ls, us; kwargs...)
end

function band!(p::Plot, lower, upper; kwargs...)
    n = length(first(lower))
    band!(p, Val(n), lower, upper; kwargs...)
end

# method for 2d band
function band!(p::Plot, ::Val{2}, lower, upper;
               kwargs...)

    x,y = unzip(lower)
    x, y = _replace_infinite(x), _replace_infinite(y)
    l1 = Config(;x,y)
    kws = _make_magic(kwargs)
    _linestyle!(l1; kws...)

    x,y = unzip(upper)
    x, y = _replace_infinite(x), _replace_infinite(y)
    fill = "tonexty"
    l2 = Config(;x, y, fill)

    kws = _linestyle!(l2; kws...)
    kws = _fillstyle!(l2; kws...)
    _merge!(l2; kws...)

    append!(p.data, (l1, l2))
    p
end
