## ----
## plot has many different interfaces for dispatch
##


## ---


"""
    plot(x, y, [z]; [linecolor], [linewidth], [legend], kwargs...)
    plot(f::Function, a, [b]; kwargs...)
    plot(pts; kwargs...)

Create a line plot.

Returns a `Plot` instance from [PlotlyLight](https://github.com/JuliaComputing/PlotlyLight.jl)

* `x`,`y` points to plot. NaN values in `y` break the line. Can be specified through a container, `pts` of ``(x,y)`` or ``(x,y,z)`` values.
* `a`, `b`: the interval to plot a function over can be given by two numbers or if just `a` then by `extrema(a)`.
* `linecolor`: color of line
* `linewidth`: width of line
* `label` in legend

Other keyword arguments include `size=(width=X, height=Y)`, `xlims` and `ylims`, `legend`, `aspect_ratio`.

Provides an interface like `Plots.plot` for plotting a function `f` using `PlotlyLight`. This just scratches the surface, but `PlotlyLight` allows full access to the underlying `JavaScript` [library](https://plotly.com/javascript/) library.

The provided "`Plots`-like" functions are [`plot`](@ref), [`plot!`](@ref), [`scatter!`](@ref), `scatter`, [`annotate!`](@ref),  [`title!`](@ref), [`xlims!`](@ref) and [`ylims!`](@ref).

# Example

```
p = plot(sin, 0, 2pi; legend=false)
plot!(cos)
# add points
x0 = [pi/4, 5pi/4]
scatter!(x0, sin.(x0), markersize=10)
# add text
annotate!(tuple(zip(x0, sin.(x0), ("A", "B"))...), halign="left", pointsize=12)
title!("Sine and cosine and where they intersect in [0,2π]")
# adjust limits
ylims!((-3/2, 3/2))
# add shape
y0, y1 = extrema(p).y
[rect!(xᵢ-0.1, xᵢ+0.1, y0, y1, fillcolor="gray", opacity=0.2) for xᵢ ∈ x0]
# display plot
p
```

!!! note "Warning"
    You may need to run the first plot cell twice to see an image.
"""
function plot(x, y, zs...; kwargs...)
    p, kwargs = _new_plot(; kwargs...)
    plot!(p, x, y, zs...; kwargs...)
    p
end

function plot(f::Function, a::Real, b::Real;
              line = nothing,
              kwargs...)
    @nospecialize
    p, kwargs = _new_plot(;kwargs...)
    plot!(p, f, a, b; line, kwargs...)
    p
end

# ab is some interval specification via `extrema`
function plot(f::Function, ab; kwargs...)
    @nospecialize
    plot(f, extrema(ab)...; kwargs...)
end
# default
function plot(f::Function; kwargs...)
    @nospecialize
    plot(f, -5, 5; kwargs...)
end

# makie style
plot(pts; kwargs...) = plot(unzip(pts)...; kwargs...)

"""
    plot!([p::Plot], x, y; kwargs...)
    plot!([p::Plot], f, a, [b]; kwargs...)
    plot!([p::Plot], f; kwargs...)

Used to add a new tract to an existing plot. Like `Plots.plot!`. See [`plot`](@ref) for argument details.
"""
function plot!(p::Plot, x, y;
               line = nothing,
               fill = nothing,
               label = nothing,
               kwargs...)
    # fussiness to handle NaNs in `y` values
    y′ = [isfinite(yᵢ) ? yᵢ : nothing for yᵢ ∈ y]
    kwargs = _layout_attrs!(p; kwargs...)
    cfg = _push_line_trace!(p, x, y′; label, kwargs...)
    _line_magic!(cfg, line)
    _fill_magic!(cfg, fill)
    p
end

# every column is a series
function plot!(p::Plot, x, y::Matrix;
               kwargs...)
    ks = Recycler(kwargs)
    for (j,yⱼ) ∈ enumerate(eachcol(y))
        plot!(p, x, yⱼ; ks[j]...)
    end

    p
end


plot!(pts; kwargs...) = plot!(current_plot[], pts; kwargs...)
plot!(p::Plot, pts; kwargs...) = plot!(p, unzip(pts)...; kwargs...)

# pass through to Javascript; like Plot...
plot!(; kwargs...) = plot!(current_plot[]; kwargs...)
function plot!(p::Plot; layout::Union{Nothing, Config}=nothing,
               config::Union{Nothing, Config}=nothing,
               kwargs...)
    !isnothing(layout) && merge!(p.layout, layout)
    !isnothing(config) && merge!(p.config, config)
    kwargs = _layout_attrs!(p; kwargs...)
    d = Config(kwargs...)
    !isempty(d) && push!(p.data, d)
    p
end

# XXX not clean what is line=... and what is data
function _push_line_trace!(p, x, y;
                           mode="lines",
                           fill=nothing,
                           label = nothing, kwargs...
                           )
    c = Config(; x, y, mode=mode)
    _merge!(c; name=label, fill)
    kws = _linestyle!(c.line; kwargs...)
    _merge!(c; kws...)
    push!(p.data, c)
    c
end

plot!(x, y, z; kwargs...) = plot!(current_plot[], x, y, z; kwargs...)
function plot!(p::Plot, x, y, z;
               label = nothing,
               center=nothing, up=nothing, eye=nothing,
               kwargs...)

    # XXX handle NaNs...
    c = Config(;x,y,z,type="scatter3d", mode="lines")
    _merge!(c; name=label)
    _camera_position!(p.layout.scene.camera; center, up, eye)
    kws = _linestyle!(c.line; kwargs...)
    _merge!(c; kws...)
    push!(p.data, c)
    p
end


function plot!(p::Plot, f::Function, a, b; kwargs...)
    @nospecialize
    x, y = unzip(f, a, b)
    plot!(p, x, y; kwargs...)
end

function plot!(p::Plot, f::Function, ab; kwargs...)
    @nospecialize
    plot!(p, f, extrema(ab)...; kwargs...)
end

function plot!(p::Plot, f::Function; kwargs...)
    @nospecialize
    m, M = extrema(p).x
    m < M || throw(ArgumentError("Can't identify interval to plot over"))
    plot!(p, f, m, M; kwargs...)
end

plot!(x, y; kwargs...) =  plot!(current_plot[], x, y; kwargs...)
function plot!(f::Function, args...; kwargs...)
    @nospecialize
    plot!(current_plot[], f, args...; kwargs...)
end


# convenience to make multiple plots by passing in vector
# using plot! allows line customizations...
plot(fs::Vector{<:Function}; kwargs...) = plot(fs, -5,5; kwargs...)
plot(fs::Vector{<:Function}, ab; kwargs...) = plot(fs, extrema(ab)...; kwargs...)
function plot(fs::Vector{<:Function}, a, b;
              kwargs...)
    u, vs... = fs
    kws = Recycler(kwargs)
    p = plot(u, a, b; kws[1]...)
    for (j,v) ∈ enumerate(vs)
        plot!(p, v; kws[j+1]...)
    end
    p
end

# 2-3
"""
    plot((f,g), a, b; kwargs...)
    plot!([p::Plot], (f,g), a, b; kwargs...)

Make parametric plot from tuple of functions, `f` and `g`.
"""
function plot(uv::NTuple{N,Function}, a, b=nothing; kwargs...) where {N}
    2 <= N <= 3 || throw(ArgumentError("2 or 3 functions only"))
    p, kwargs = _new_plot(; kwargs...)
    plot!(p, uv, a, b; kwargs...)
end

# Plots interface is 2/3 functions, not a tuple.
plot(u::Function, v::Function, w::Function, args...; kwargs...) =
    plot((u,v, w), args...; kwargs...)

plot(u::Function, v::Function, args...; kwargs...) =
    plot((u,v), args...; kwargs...)

plot!(uv::Tuple{Function, Function}, a, b=nothing; kwargs...) =
    plot!(current_plot[], us, a, b; kwargs...)

function plot!(p::Plot, uv::NTuple{N,Function}, a, b=nothing; kwargs...) where {N}
    2 <= N <= 3 || throw(ArgumentError("2 or 3 functions only"))

    # which points to use?
    if isnothing(b)
        t = range(extrema(a)...; length=251)
    else
        t = range(a, b; length=251)
    end

    plot!(p, (fᵢ.(t) for fᵢ ∈ uv)...; kwargs...)
end



## --- This is `plot` from PlotlyLight
# No default, see below
#plot(; kw...) = plot(get(kw, :type, :scatter); kw...)

Base.propertynames(::typeof(plot)) = sort!(collect(keys(PlotlyLight.schema.traces)))
Base.getproperty(::typeof(plot), x::Symbol) = (; kw...) -> plot(x; kw...)

function plot(trace::Symbol; kw...)
    PlotlyLight.check_attributes(trace; kw...)
    plot(; type=trace, kw...)
end

"""
    plot(; layout::Config?, config::Config?, kwargs...)

Pass keyword arguments through `Config` and onto `PlotlyLight.Plot`.
"""
function plot(; layout::Union{Nothing, Config}=nothing,
              config::Union{Nothing, Config}=nothing,
              size=(width=nothing, height=nothing),
              xlims=nothing, ylims=nothing,
              legend=nothing,
              aspect_ratio = nothing,
              kwargs...)
    p, kwargs = _new_plot(;size, xlims, ylims, legend, aspect_ratio, kwargs...)
    plot!(p; layout, config, kwargs...)
    p
end


## ------

# This is the identifier of the type of visualization for this series. Choose from [:none, :line, :path, :steppre, :stepmid, :steppost, :sticks, :scatter, :heatmap, :hexbin, :barbins, :barhist, :histogram, :scatterbins, :scatterhist, :stepbins, :stephist, :bins2d, :histogram2d, :histogram3d, :density, :bar, :hline, :vline, :contour, :pie, :shape, :image, :path3d, :scatter3d, :surface, :wireframe, :contour3d, :volume, :mesh3d] or any series recipes which are defined.


SeriesType(x::Symbol) = SeriesType(Val(x))
SeriesType(::Val{:lines}) =  (:scatter, :line)
SeriesType(::Val{:path3d}) = (:scatter3d, :line)
SeriesType(::Val{:scatter}) = (:scatter, :markers)
SeriesType(::Val{:contour}) = (:surface, :contour)
SeriesType(::Val{:surface}) = (:surface, :surface)




## plt
function plt(args...; kwargs...)
    p, kws = _new_plot(; kwargs...)
    plt!(args...; kwargs...)
end

plt!(args...; kwargs...) = plt!(current_plot[], args...; kwargs...)

# XXX dispatch on type and mode
# no xyz for surface type, say
function plt!(p::Plot, x=nothing, y=nothing, z=nothing;
              seriestype::Symbol=:lines,
              kwargs...)
    kws = _make_magic(; kwargs...) # XXX move if you want to be able to recycle
    kws = _layout_styles!(p;  kws...)
    type, mode =  SeriesType(seriestype)
    plt!(Val(type), p, x, y, z; mode, kws...)
end

# scatter type (to dispatch on mode)
function plt!(::Val{:scatter}, p::Plot, x=nothing, y=nothing, z=nothing;
              mode::Symbol=:lines,
              kwargs...)
    KWs = Recycler(kwargs)
    for (i, xyzₛ) ∈ enumerate(xyz(x,y,z))
        _plt(Val(:scatter), Val(mode), p, xyzₛ...; KWs[i]...)
    end
    p
end

# utils
_replace_infinite(f::Function) = f
_replace_infinite(::Nothing) = nothing
_replace_infinite(y) = [isfinite(yᵢ) ? yᵢ : nothing for yᵢ ∈ y]

# make recipes here
# x,y one
_valtype(::Val{T}) where {T} = T

# generic one
function _plt(::Val{:scatter}, m::Val{T}, p::Plot, x, y, z=nothing; kwargs...) where {T}
    mode = _valtype(m)
    c = Config(;
               x=_replace_infinite(x),
               y=_replace_infinite(y),
               z=_replace_infinite(z),
               mode=mode)
    c.type = isnothing(z) ? "scatter" : "scatter3d" # XXX not general?
    kws = _trace_styles!(c; kwargs...)
    _merge!(c; kws...)

    push!(p.data, c)
    nothing
end

function _plt(t::Val{:scatter}, m::Val{T}, p::Plot, f::Function, y, z; kwargs...) where {T}
    a,b = isnothing(z) ? extrema(y) : (y,z)
    _plt(t, m, p, unzip(f, a, b)...; kwargs...)
end

# scatter shorthand
function sctter(args...; kwargs...)
    p, kws = _new_plot(; kwargs...)
    sctter!(args...; kwargs...)
end
sctter!(args...; kwargs...) = plt!(args...; seriestype=:scatter, kwargs...)
export sctter,sctter!


export plt, plt!

# xyziterator
struct XYZ{X,Y,Z}
    x::X
    y::Y
    z::Z
    n::Integer
end

# how many traces does the data represent
# when there can be more than one
ntraces(x) =  last(size(x))
ntraces(::Nothing) = 0
ntraces(::Tuple) = 1
ntraces(::AbstractVector) = 1
ntraces(x::AbstractVector{T}) where {T <: Function} = length(x)
ntraces(::Function) = 1
ntraces(::Number) = 1

# use Tables.
_eachcol(x::Matrix) = [x[:,i] for i in 1:size(x)[2]]
_eachcol(x::Vector) = (x,)
_eachcol(x::Vector{T}) where {T <: Function} = x
_eachcol(x::Tuple) = (x,)
_eachcol(x::AbstractRange) = (x,)
_eachcol(::Nothing) = nothing
_eachcol(x) = (x,)

# make a reccyler for x,y,z values
function xyz(x,y=nothing,z=nothing)
    ns = ntraces.((x,y,z))
    allequal(filter(>(1), ns)) || throw(ArgumentError("mismatched dimensions"))
    n = maximum(ns)
    XYZ(Recycler(_eachcol(x)),
        Recycler(_eachcol(y)),
        Recycler(_eachcol(z)), n)
end

function Base.iterate(xyz::XYZ, state=nothing)
    n = xyz.n
    i = isnothing(state) ? 1 : state
    iszero(n) && return nothing
    i > n && return nothing
    return((x=xyz.x[i], y=xyz.y[i], z=xyz.z[i]), i+1)
end




# styles
# turn magic into keyword arguments
_set(d, key, value) = (d[key] = value)
_set(d, key, ::Nothing) = d
function _make_magic(;
                     line = nothing,
                     marker = nothing,
                     fill = nothing,
                     kwargs...)
    d = Dict{Symbol, Any}()

    for a ∈ something(line, tuple())
        if isa(a, Symbol)
            if a ∈ _linestyles
                _set(d, :linestyle, a)
            else
                _set(d, :linecolor, a)
            end
        end
        if isa(a, Number)
            isa(a, Integer) && _set(d, :linewidth, a)
            0 < a < 1 && _set(d, :opacity, a)
        end
    end

    for a ∈ something(marker, tuple())
        if isa(a, Symbol)
            if a ∈ _marker_shapes
                _set(d, :markershape, replace(string(a), "_" => "-"))
            else
                _set(d, :markercolor, a)
            end
        end
        if isa(a, Number)
            if isa(a, Integer)
                @show a
                _set(d, :markersize, a)
            else
                _set(d, :opacity, a)
            end
        end
    end

    ## axis has x,y,z

    for a ∈ something(fill, tuple())
        # XXX
    end

    # covert back
    kws = merge(Dict(kwargs...), d)
    nt = NamedTuple(kws)
    Base.Pairs(nt, keys(nt))

end

function _trace_styles!(c; label=nothing,  kwargs...)
    c.name = label
    kws = _linestyle!(c.line; kwargs...)
    kws = _fillstyle!(c.fill; kws...)
    kws = _markerstyle!(c.marker; kws...)
    kws
end

# XXX this needs work
function _layout_styles!(p;
                         size=nothing, xlims=nothing, ylims=nothing,
                         xticks=nothing, yticks=nothing, zticks=nothing,
                         xlabel=nothing, ylabel=nothing, zlabel=nothing,
                         xscale=nothing, yscale=nothing, zscale=nothing,
                         legend=nothing,
                         aspect_ratio=nothing,
                         kwargs...)
        # size is specified through a keyed object
    size!(p, size)
    xlims!(p, xlims)
    ylims!(p, ylims)

    # ticks
    xticks!(p, xticks)
    yticks!(p, yticks)
    zticks!(p, zticks)

    # labels
    xlabel!(p, xlabel)
    ylabel!(p, ylabel)
    zlabel!(p, zlabel)

    # scale
    xscale!(p, xscale)
    yscale!(p, yscale)
    zscale!(p, zscale)

    # layout
    legend!(p, legend)
    aspect_ratio == :equal && (p.layout.yaxis.scaleanchor="x")

    kwargs
end
