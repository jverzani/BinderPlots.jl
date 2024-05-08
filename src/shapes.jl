# Plots for making polygons
## use Shape
## lots of this lifted from Plots.jl (components.jl)
## in Plots several pre-defined shapes

# Some shape types
# :square, :circle, :diamond, :star
function Shape(s::Symbol, args...)
    Shape(Val(s), args...)
end

Shape(::Val{:unitsquare}, args...) = Shape([0,1,1,0],[0,0,1,1])

# unit circle shapes
function Shape(::Val{:ngon}, n, offset=0, args...)
    θs = range(offset*pi + 0, offset*pi + 2pi, n+1)
    Shape(sin.(θs), cos.(θs))
end
partialcircle(start_θ, end_θ, n = 20, r = 1) =
    [(r * cos(u), r * sin(u)) for u in range(start_θ, stop = end_θ, length = n)]
Shape(::Val{:circle}, args...)   = Shape(Val(:ngon), 100)
Shape(::Val{:triangle}, args...) = Shape(Val(:ngon),3)
Shape(::Val{:diamond}, args...) = Shape(Val(:ngon),4)
Shape(::Val{:rect}, args...) = Shape(Val(:ngon),4,1/4)
Shape(::Val{:pentagon}, args...) = Shape(Val(:ngon),5)
Shape(::Val{:hexagon}, args...)  = Shape(Val(:ngon),5)
Shape(::Val{:heptogon}, args...) = Shape(Val(:ngon),7)
Shape(::Val{:octogon}, args...)  = Shape(Val(:ngon),8)

Shape(::Val{:hline}) = Shape([-1,1],[0,0])
Shape(::Val{:vline}) = Shape([0,0], [-1,1])

function Shape(::Val{:star}, n=5, r = 1/4, args...)
    θs = range(0, 2pi, 2n+1)
    xs = zeros(Float64, 2n)
    ys = zeros(Float64, 2n)
    for i ∈ 1:n
        j = 2i
        ys[j-1], xs[j-1] = sincos(θs[j-1])
        ys[j], xs[j] = r .* sincos(θs[j])
    end
    s = Shape(xs, ys)
    k = mod(n, 4)
    # stand up straight
    k == 1 && rotate!(s,  pi / (2n))
    k == 2 && rotate!(s,  pi / n)
    k == 3 && rotate!(s, -pi / (2n))
    s
end
Shape(::Val{:star4}, args...) = Shape(Val(:star), 4)
Shape(::Val{:star5}, args...) = Shape(Val(:star), 5)
Shape(::Val{:star6}, args...) = Shape(Val(:star), 6)
Shape(::Val{:star7}, args...) = Shape(Val(:star), 7)
Shape(::Val{:star8}, args...) = Shape(Val(:star), 8)



"""
    scale(s::Shape, x, y=x)
    scale!(s::Shape, x, y=x)

Scale in x and y direction
"""
scale(s::Shape, x, y = x, c = center(s)) =  scale!(copy(s), x, y, c)
function scale!(s::Shape, x, y=x,c=center(s))
    sx, sy = s.x, s.y
    cx, cy = c
    for i in eachindex(sx)
        sx[i] = (sx[i] - cx) * x + cx
        sy[i] = (sy[i] - cy) * y + cy
    end
    s
end

"""
    rotate(s::Shape, θ, c=center(s))
    rotate!(s::Shape, θ, c=center(s))

Rotate shape about its center ccw by angle θ
"""
rotate(s::Shape, θ, c=center(s)) = rotate!(copy(s), θ, c)
function rotate!(s::Shape, θ, c=center(s))
    (;x, y) = s
    for i in eachindex(x)
        xi = rotate_x(x[i], y[i], θ, c...)
        yi = rotate_y(x[i], y[i], θ, c...)
        x[i], y[i] = xi, yi
    end
    s
end
rotate_x(x,y,θ,cx,cy) = ((x - cx) * cos(θ) - (y - cy) * sin(θ) + cx)
rotate_y(x,y,θ,cx,cy) = ((y - cy) * cos(θ) + (x - cx) * sin(θ) + cy)

"""
    translate(s::Shape, x, y=x)
    translate!(s::Shape, x, y=x)

Shift shape over by x, up by y
"""
translate(s::Shape, x, y=x) = translate!(copy(s), x, y)
function translate!(s::Shape, x, y=x)
    s.x .+= x
    s.y .+= y
    s
end

function invert!(s::Shape, axis::Symbol)
    (; x, y) = s
    axis == :xy && return invert!(invert!(s,:x),:y)
    axis == :x && (y .*= -1)
    axis == :y && (x .*= -1)
    s
end
shear(s::Shape, k) = shear!(copy(s), k)
function shear!(s::Shape, k)
    (;x, y) = s
    x .+= (k .* y)
    s
end

# uses the centroid calculation from https://en.wikipedia.org/wiki/Centroid#Centroid_of_polygon (cf. Plots.jl)
"return the centroid of a Shape"
function center(s::Shape)
    (; x, y) = s
    n = length(x)
    A, Cx, Cy = 0, 0, 0
    for i in 1:n
        ip1 = i == n ? 1 : i + 1
        A += x[i] * y[ip1] - x[ip1] * y[i]
    end
    A *= 0.5
    for i in 1:n
        ip1 = i == n ? 1 : i + 1
        m = (x[i] * y[ip1] - x[ip1] * y[i])
        Cx += (x[i] + x[ip1]) * m
        Cy += (y[i] + y[ip1]) * m
    end
    Cx / 6A, Cy / 6A
end

function center!(s::Shape)
    a,b = center(s)
    translate!(s, -a, -b)
end

# shapes in Plotly use `layout` not `data`
# generalize shapes (line, rect, circle, ...)
# fillcolor
# line.color
function _shape(type, x0, x1, y0, y1;
                kwargs...)



    c = Config(; type, x0, x1, y0, y1)
    kws = _make_magic(;kwargs...)
    kws = _linestyle!(c.line; kws...)
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
hline!(0:.1:1, linecolor=:blue, opacity=0.75)
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

A current plot must be made to add to, as the extent of the lines is taken from that.
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

# Example

```
rect!(p, 2,3,-1,1; linecolor=:gray, fillcolor=:red, opacity=0.2)
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
    hspan!([p::Plot], ys, YS; xmin=0.0, ymin=1.0, kwargs...)

Draw horizontal rectanglular rectangle from `ys` to `YS`. By default extends over `x` range of plot `p`, though using `xmin` or `xmax` can adjust that. These are values in `[0,1]` and are interpreted relative to the range returned by `extrema(p).x`.
"""
hspan!(ys,YS; kwargs...) = hspan!(current_plot[], ys, YS; kwargs...)
function hspan!(p::Plot, ys, YS; xmin=0.0, xmax=1.0, kwargs...)
    a, b = extrema(p).x
    Δ = b - a

    xxyy = _identity(a .+ Δ .* xmin, a .+ Δ .* xmax, ys, Ys)
    KWs = Recycler(kwargs)
    for (i, yᵢ) ∈ enumerate(y)
        _add_shape!(p, _shape("rect",xxyy[i]...;
                              mode="Line", KWs[i]...))
    end

    p
end

"""
    vspan!([p::Plot], xs, XS; ymin=0.0, ymin=1.0, kwargs...)

Draw vertical rectanglular rectangle from `xs` to `XS`. By default extends over `y` range of plot `p`, though using `ymin` or `ymax` can adjust that. These are values in `[0,1]` and are interpreted relative to the range returned by `extrema(p).y`.

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
    for (i, yᵢ) ∈ enumerate(y)
        _add_shape!(p, _shape("rect",xxyy[i]...;
                              mode="Line", KWs[i]...))
    end

    p
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
    kws = _linestyle!(cfg.line; kwargs...)
    kws = _fillstyle!(cfg; kws...)
    _merge!(cfg; kws...)
    push!(p.data, cfg)
    p
end

"""
    circle([p::Plot], x0, x1, y0, y1; kwargs...)

Draw circle shape bounded in `[x0, x1] × [y0,y1]`. (Will adjust to non-equal sized boundary.)
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
    l1 = Config(;x,y)
    _linestyle!(l1.line; kwargs...)

    x,y = unzip(upper)
    fill = "tonexty"
    l2 = Config(;x, y, fill)
    kws = _linestyle!(l2.line; kwargs...)
    kws = _fillstyle!(l2; kws...)
    _merge!(l2; kws...)

    append!(p.data, (l1, l2))
    p
end


# image
"""
    image!([p::Plot], img_url; [x],[y],[sizex],[sizey], kwargs...)

Plot image, by url, onto background of plot.

* `x`,`y`,`sizex`, `sizey` specify extent via `[x, x+sizex] × [y-sizey, y]`.
* pass `sizing="stretch"` to fill space.
* other arguments cf. [plotly examples](https://plotly.com/javascript/images/).

# Example
```
img = "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Julia_Programming_Language_Logo.svg/320px-Julia_Programming_Language_Logo.svg.png"
plot(;xlims=(0,1), ylims=(0,1), legend=false);
image!(img; sizing="stretch")
plot!(x -> x^2; linewidth=10, linecolor=:black)
```
"""
image!(img; kwargs...) = image!(current_plot[], img; kwargs...)
function image!(p::Plot, img;
                x=nothing,
                y=nothing,
                sizex = nothing,
                sizey = nothing,
                kwargs...)
    isempty(p.layout.images) && (p.layout.images = Config[])

    ex = extrema(p)
    x0,x1 = ex.x
    y0,y1 = ex.y
    x = isnothing(x) ? x0 : x
    y = isnothing(y) ? y1 : y
    sizex = isnothing(sizex) ? x1 - x : sizex
    sizey = isnothing(sizey) ? y - y0 : sizey
    image = Config(;source=img, x, y, sizex, sizey,
                   xref="x", yref="y",
                   layer="below")
    _merge!(image; kwargs...)
    push!(p.layout.images, image)
    p
end
