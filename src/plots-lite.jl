# This is the identifier of the type of visualization for this series. Choose from [:none, :line, :path, :steppre, :stepmid, :steppost, :sticks, :scatter, :heatmap, :hexbin, :barbins, :barhist, :histogram, :scatterbins, :scatterhist, :stepbins, :stephist, :bins2d, :histogram2d, :histogram3d, :density, :bar, :hline, :vline, :contour, :pie, :shape, :image, :path3d, :scatter3d, :surface, :wireframe, :contour3d, :volume, :mesh3d] or any series recipes which are defined.

"""
    SeriesType(x::Symbol)

Return a type and mode for `plotly` based on a Plots.jl series type.
"""
SeriesType(x::Symbol) = SeriesType(Val(x))

SeriesType(::Val{:mesh3d}) = (:mesh3d, :mesh3d)

"""
    plot(x, y, [z]; kwargs...)
    plot(f::Function, a, [b]; kwargs...)
    plot(pts; kwargs...)
    plot(x,[y],[z]; seriestype::Symbol=:lines, kwargs...)

Create a plot, defaulting to a line plot.

Returns a `Plot` instance from [PlotlyLight](https://github.com/JuliaComputing/PlotlyLight.jl)

For lines:

* `x`,`y`,[`z`] points to plot. NaN values break the line. Can be specified through a container, `pts` of ``(x,y)`` or ``(x,y,z)`` values.
* `a`, `b`: the interval to plot a function over can be given by two numbers or if just `a` then by `extrema(a)`.
* `label` in legend
* `linecolor`: color of line
* `linewidth`: width of line

The `line` argument allows for magic arguments.



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
annotate!(tuple(zip(x0, sin.(x0), (text("A",:top), text("B",:top)))...), halign="left", pointsize=12)
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
function plot(args...; facet=nothing, kwargs...)
    !isnothing(facet) && return _facet(args...; facet, kwargs...)
    p, kws = _new_plot(; kwargs...) # new_plot adjust Config aspects
    plot!(p, args...; kwargs...)
end

"""
    plot!([p::Plot], x, y; kwargs...)
    plot!([p::Plot], f, a, [b]; kwargs...)
    plot!([p::Plot], f; kwargs...)

Used to add a new trace to an existing plot. Like `Plots.plot!`. See [`plot`](@ref) for argument details.
"""
plot!(args...; kwargs...) = plot!(current_plot[], args...; kwargs...)
plot!(::Plot, args...; kwargs...) = throw(ArgumentError("No plot method defined"))

# XXX dispatch on type and mode
# no xyz for surface type, say
function plot!(p::Plot, x=nothing, y=nothing, z=nothing;
               seriestype= :lines,
               kwargs...)
    kws = _layout_styles!(p;  kwargs...) # adjust layout



    types = isa(seriestype, Symbol) ? (seriestype,) : tuple(seriestype...)
    for seriestype in types
        type, mode =  SeriesType(seriestype)
        plot!(Val(type), p, x, y, z; seriestype, kws...)
    end
    p
end


# basic dispatch to type, then type/mode
function plot!(t::Val{T}, p::Plot, x=nothing, y=nothing, z=nothing;
               seriestype::Symbol=:lines,
               kwargs...) where {T}
    _, mode = SeriesType(seriestype)
    kws = _make_magic(; kwargs...)
    plot!(t, Val(mode), p, x, y, z; kws...)
end

# generic usage
function plot!(t::Val{T}, m::Val{M}, p::Plot, x=nothing, y=nothing, z=nothing;
               kwargs...) where {T,M}
    type, mode = _valtype(t), _valtype(m)
    # adjust trace properties here
    c = Config(;x,y,z, type, mode)
    kws = _trace_styles!(c; kwargs...)
    _merge!(c; kws...)
    push!(p.data, c)
    p
end

# create a blank canvas with a given size, etc.
# alternatively just `plot(; axis=([], false))`, as with Plots.
function blank_canvas(;
                      xlim=nothing, xlims=xlim,
                      ylim=nothing, ylims=ylim,
                      aspect_ratio=:equal,
                      border=:none, legend=false,
                      kwargs...)

    p = plot(; xlims, ylims,
             aspect_ratio,
             border, legend,
             kwargs...)

    xaxis!(p; showticklabels = false, showgrid = false, zeroline = false) #³
    yaxis!(p; showticklabels = false, showgrid = false, zeroline = false) #³

    p

end

## ----

##  keep track of current figure/whether a figure has been plottted
const current_plot = Ref{Plot}() # store current plot
const first_plot = Ref{Bool}(true) # for first plot warning

"""
    current()

Get current figure. A `Plot` object of `PlotlyLight`; `UndefRefError` if none.

Not typically needed, as it is implicit in most mutating calls, though may be convenient if those happen within a loop.

"""
current() = current_plot[]

# make a new plot by calling `PlotlyLight.Plot`
# doesn't consume
function _new_plot(;
                   windowsize=nothing, size=windowsize, # named tuple (width=, height=),
                   axis = nothing,
                   kwargs...)

    p = Plot(Config[],
             Config(), # layout
             Config(responsive=true) ) # config
    current_plot[] = p

    if first_plot[]
        first_plot[] = false
    end

    size!(p, size)
    if !isnothing(axis)
        for ax ∈ (:xaxis, :yaxis, :zaxis)
            _axis_magic!(p.layout[ax], axis...)
        end
    end
    p, kwargs
end

#=
processing pipeline
A plot(...) call for a line plot does:

* `_new_plot` adjusts windowsize
* `_layout_styles` processes layout arguments
* loop over `seriestype` value(s)
* kwargs are recycled
* data is split into series (if necessary)
* magic arguments are processed to adjust kwargs
* `_series_styles` are processed
* `trace_styles!` are processed mapping kwargs -> attribute names
* data pushed to `p.data`


=#

# plot attributes

"""
    title!([p::Plot], txt)
    xlabel!([p::Plot], txt)
    ylabel!([p::Plot], txt)
    zlabel!([p::Plot], txt)

Set plot title.

* `txt`: either a string or a string with font information produced by [`text`](@ref).

# Example

```
f = font(20, :red, :left, :bottom, 45.0)

p = plot(sin, 0, 2pi)
title!(p, text("Plot", f))
xlabel!(p, text("sine function", f))
xticks!(p, 0:pi:2pi, ticklabels = ["0", "π", "2π"], tickfont=f)
annotate!(p, [(pi, 0, text("Zero", f))])
quiver!(p, [pi],[1/2], [text("zero",f)], quiver=([0],[-1/2]))
```
"""
title!(p::Plot, ::Nothing) = nothing
function title!(p::Plot, txt)
    p.layout.title = txt
    p
end
function title!(p::Plot, txt::TextFont)
    p.layout.title.text = txt.str
    _fontstyle!(p.layout.title.font, txt.font)
    p
end

title!(txt) = title!(current_plot[], txt)

"""
    xlabel!([p::Plot], txt::Union{String, TextFont})
    ylabel!([p::Plot], txt::Union{String, TextFont})
    zlabel!([p::Plot], txt::Union{String, TextFont})

Set axis label. Use a `text` object to specify font information.
"""
xlabel!(p::Plot, ::Nothing) = nothing
function xlabel!(p::Plot, txt; kwargs...)
    _labelstyle!(p.layout.xaxis, txt; kwargs...)
    p
end
xlabel!(txt) = xlabel!(current_plot[], txt)

ylabel!(p::Plot, ::Nothing) = nothing
function ylabel!(p::Plot, txt; kwargs...)
    _labelstyle!(p.layout.yaxis, txt; kwargs...)
    p
end
ylabel!(txt) = ylabel!(current_plot[], txt)

zlabel!(p::Plot, ::Nothing) = nothing
function zlabel!(p::Plot, txt; kwargs...)
    _labelstyle!(p.layout.zaxis, txt; kwargs...)
    p
end
zlabel!(txt) = zlabel!(current_plot[], txt)

function _labelstyle!(cfg, txt=nothing;
                      titlefont=nothing, # ::Font?
                      kwargs...)
    cfg.title.text = txt
    _fontstyle!(cfg.title.font, titlefont)
    kwargs
end

_labelstyle!(cfg, txt::TextFont; kwargs...) =
    _labelstyle!(cfg, txt.str;  titlefont=txt.font)


# ticks is values not (values, labels), as with Plots; use ticklabels for that
"""
    xticks!([p::Plot], ticks; [ticklabels], [tickfont], kwargs...)
    yticks!([p::Plot], ticks; [ticklabels], [tickfont], kwargs...)
    zticks!([p::Plot], ticks; [ticklabels], [tickfont], kwargs...)

Set ticks. Optionally add labels using a matching length container. Passing a `Font` object to `tickfont` will set the font.,

* `ticks:` a range of collection of tick positions
* `ticklabels`: if given, a matching length collection of strings
* `tickfont`: a `Font` instance to adjust font of all specified ticks.
* `kwargs...`: passed to `[xyz]axis!` method.

"""
xticks!(p::Plot, ::Nothing; kwargs...) = p
xticks!(p::Plot, ticks; kwargs...) = xaxis!(p; ticks, kwargs...)
xticks!(p::Plot, ticks, ticklabels;
        tickfont=nothing, kwargs... ) =
    xaxis!(;ticks, ticklabels, tickfont, kwargs...)
xticks!(ticks; kwargs...) = xticks!(current_plot[], ticks; kwargs...)
xticks!(ticks, ticklabels; kwargs...) =
    xticks!(current_plot[], ticks, ticklabels; kwargs...)

yticks!(p::Plot, ::Nothing; kwargs...) = p
yticks!(p::Plot, ticks; kwargs...) = xaxis!(p; ticks, kwargs...)
yticks!(p::Plot, ticks, ticklabels;
        tickfont=nothing, kwargs... ) =
    xaxis!(;ticks, ticklabels, tickfont, kwargs...)
yticks!(ticks; kwargs...) = yticks!(current_plot[], ticks; kwargs...)
yticks!(ticks, ticklabels; kwargs...) =
    yticks!(current_plot[], ticks, ticklabels; kwargs...)

zticks!(p::Plot, ::Nothing; kwargs...) = p
zticks!(p::Plot, ticks; kwargs...) = xaxis!(p; ticks, kwargs...)
zticks!(p::Plot, ticks, ticklabels;
        tickfont=nothing, kwargs... ) =
    xaxis!(;ticks, ticklabels, tickfont, kwargs...)
zticks!(ticks; kwargs...) = zticks!(current_plot[], ticks; kwargs...)
zticks!(ticks, ticklabels; kwargs...) =
    zticks!(current_plot[], ticks, ticklabels; kwargs...)


xscale!(p, ::Nothing) = nothing
xscale!(p, scale) = _scale!(p.layout.xaxis, scale)
yscale!(p, ::Nothing) = nothing
yscale!(p, scale) = _scale!(p.layout.yaxis, scale)
zscale!(p, ::Nothing) = nothing
zscale!(p, scale) = _scale!(p.layout.zaxis, scale)

# only :log10
function _scale!(cfg, scale)
    if scale ∈ (:ln, :log, :log10, :log2)
        cfg.type = :log
        cfg.autorange=true
    else
        @warn "Scale :$scale is not supported"
    end
end

# XXX mix magic and positional...
"""
    xaxis!([p::Plot]; kwargs...)
    yaxis!([p::Plot]; kwargs...)
    zaxis!([p::Plot]; kwargs...)

Adjust properties of an axis on a chart using `Plotly` keywords.

* `ticks`, `ticktext`, `ticklen`, `tickwidth`, `tickcolor`, `tickfont`, `showticklabels`
* `showgrid`, `gridcolor`, `gridwidth`
* `zeroline`, `zerolinecolor`, `zerolinewidth`
"""
xaxis!(p::Plot, args...; kwargs...) = (_xyzaxis!(p.layout.xaxis, args...; kwargs...); p)
#xaxis!(p::Plot, args...) = (_axis_magic!(p.layout.xaxis, args...); p)
xaxis!(args...;kwargs...) = xaxis!(current_plot[], args...; kwargs...)
#xaxis!(args...) = xaxis!(current_plot[], args...)

yaxis!(p::Plot, args...; kwargs...) = (_xyzaxis!(p.layout.yaxis, args...; kwargs...); p)
#yaxis!(p::Plot, args...) = (_axis_magic!(p.layout.yaxis, args...); p)
yaxis!(args...;kwargs...) = yaxis!(current_plot[], args...; kwargs...)
#yaxis!(args...) = yaxis!(current_plot[], args...)

zaxis!(p::Plot, args...; kwargs...) = (_xyzaxis!(p.layout.zaxis, args...; kwargs...);p)
#zaxis!(p::Plot, args...) = (_axis_magic!(p.layout.zaxis, args...); p)
zaxis!(args...;kwargs...) = zaxis!(current_plot[], args...; kwargs...)
#zaxis!(args...) = zaxis!(current_plot[], args...)

xyzaxis!(cfg; kwargs...) = _axisstyle!(cfg; kwargs...)
function _xyzaxis!(cfg, args...; kwargs...)
    _axis_magic!(cfg, args...);
    kws = xyzaxis!(cfg; kwargs...)
    kws
end

# https://plotly.com/javascript/tick-formatting/ .. more to do
# Configure ticks and other axis properties
# to label ticks pass in values for ticks and matching length ticktext
function _axisstyle!(cfg;
                     ticks=nothing, tickvals = ticks,
                     ticklabels=nothing, ticktext=ticklabels,
                     ticklen=nothing,
                     tickwidth=nothing,
                     tickcolor=nothing,
                     tickfont=nothing,
                     showticklabels=nothing,
                     autotick=nothing,
                     #
                     type = nothing, # "log"
                     #
                     showaxis=nothing, showgrid=showaxis,
                     #
                     mirror=nothing,
                     gridcolor=nothing,
                     gridwidth=nothing,
                     #
                     zeroline=nothing,
                     zerolinecolor=nothing,
                     zerolinewidth=nothing,
                     #
                     kwargs...)

    # process ticks first
    # range -- use one style
    # 2-tuple (can specify vals/labels)
    if !isnothing(tickvals)
        if isa(tickvals, AbstractRange)
            tick0, dtick, nticks =
                first(tickvals), step(tickvals),length(tickvals)
            _merge!(cfg; tick0, dtick, nticks, ticktext)
        else
            if isa(tickvals, Tuple) &&
                length(tickvals) == 2 &&
                !isa(first(tickvals), Number)
                # vals/labels
                _merge!(cfg;
                        tickvals = collect(first(tickvals)),
                        ticktext = last(tickvals))

            else
                _merge!(cfg; tickvals, ticktext)
            end
        end
    end

    _merge!(cfg; showticklabels, autotick,
            ticklen, tickwidth, tickcolor,
            type,
            showgrid, mirror,
            gridcolor, gridwidth,
            zeroline,zerolinecolor, zerolinewidth

            )

    if !isnothing(tickfont)
        _fontstyle!(cfg.tickfont, tickfont)
        cfg.tickangle = tickfont.rotation
    end

    kwargs
end


"`legend!([p::Plot], legend::Bool)` hide/show legend"
legend!(p::Plot, ::Nothing) = nothing
legend!(p::Plot, legend::Bool) = (p.layout.showlegend = legend)
legend!(p::Plot, legend::Tuple) = _legend_magic!(p, legend)
legend!(p::Plot, args...) = legend!(args)
legend!(legend::Bool) = legend!(current_plot[], legend)
legend!(args...) = legend!(current_plot[], args...)

"`size!([p::Plot]; [width], [height])` specify size of plot figure"
function size!(p::Plot; width=nothing, height=nothing)
    !isnothing(width) && (p.layout.width=width)
    !isnothing(height) && (p.layout.height=height)
    p
end
size!(;width=nothing, height=nothing) = size!(current_plot[]; width, height)

size!(s) = size!(current_plot[], size)
size!(p::Plot, ::Nothing) = p
function size!(p::Plot, s)
    width = get(s, :width, nothing)
    height = get(s, :height, nothing)
    size!(p; width, height)
end
size!(p::Plot, s::Tuple{Int64, Int64}) = size!(p; width=first(s), height=last(s))


"`xlims!(p, lims)` set `x` limits of plot"
function xlims!(p::Plot, lims)
    p.layout.xaxis.range = lims
    p
end
xlims!(p::Plot, ::Nothing) = p
xlims!(lims) = xlims!(current_plot[], lims)
xlims!(a::Real, b::Real) = xlims!(current_plot[], (a,b))
xlims!(p::Plot, a::Real, b::Real) = xlims!(p, (a,b))

"`ylims!(p, lims)` set `y` limits of plot"
function ylims!(p::Plot, lims)
    p.layout.yaxis.range = lims
    p
end
ylims!(p::Plot, ::Nothing) = p
ylims!(lims) = ylims!(current_plot[], lims)
ylims!(a::Real, b::Real) = ylims!(current_plot[], (a,b))
ylims!(p::Plot, a::Real, b::Real) = ylims!(p, (a,b))

"`zlims!(p, lims)` set `z` limits of plot"
function zlims!(p::Plot, lims)
    p.layout.xaxis.range = lims
    p
end
zlims!(p::Plot, ::Nothing) = p
zlims!(lims) = zlims!(current_plot[], lims)
zlims!(a::Real, b::Real) = zlims!(current_plot[], (a,b))
zlims!(p::Plot, a::Real, b::Real) = zlims!(p, (a,b))

"`scrollzoom!([p], x::Bool)` turn on/off scrolling to zoom"
scroll_zoom!(p::Plot,x::Bool) = p.config.scrollZoom = x
scroll_zoom!(x::Bool) = scroll_zoom!(current_plot[], x)

## ---- configuration
# These gather specific values for lines, marker and text style
# match Plots stroke
struct Stroke
    width
    color
    alpha
    style
end
Recycler(x::Stroke) = Recycler((x,))

"""
    stroke(args...; alpha=nothing)

Specify line attributes. Returns a `Stroke` instance.

This function can be used to specify the attributes of the polygonal line in a shape or other uses of lines.
"""
function stroke(args...; alpha = nothing)
    width = nothing # use plotly defaults not Plots.jl
    color = nothing
    style = nothing

    for arg in args
        T = typeof(arg)

        # if arg in _allStyles
        if  arg ∈ _linestyles
            style = arg
        elseif T <: _RGB
            color = arg
        elseif T <: RGB || T <: RGBA
            color = rgb(arg)
        elseif T <: Symbol || T <: AbstractString
            color = arg
        elseif 0 < arg < 1
            alpha = arg
        elseif isa(arg, Real)
            width = arg
        else
            @warn "Unused stroke arg: $arg ($(typeof(arg)))"
        end
    end

    Stroke(width, color, alpha, style)
end

# https://docs.juliaplots.org/latest/attributes/#magic-arguments
"""
    font(args...)

(This is from Plots.jl)

Create a Font from a list of features. Values may be specified either as
arguments (which are distinguished by type/value) or as keyword arguments.

# Arguments

- `family`: AbstractString. "serif" or "sans-serif" or "monospace"
- `pointsize`: Integer. Size of font in points
- `halign`: Symbol. Horizontal alignment (:hcenter, :left, or :right)
- `valign`: Symbol. Vertical alignment (:vcenter, :top, or :bottom)
- `rotation`: Real. Angle of rotation for text in degrees (use a non-integer type). (Works with ticks and annotations.)
- `color`
# Examples
```julia-repl
julia> font(8)
julia> font(family="serif", halign=:center, rotation=45.0)
```
"""
font(f::Font; kwargs...) = f
function font(args...;
              family="sans-serif",
              pointsize = 14,
              halign = nothing,
              valign = nothing,
              rotation = 0,
              color = "black"
              )

    for a ∈ args
        T = typeof(a)
        # string is family
        T <: AbstractString && (family = a)
        # pointsize or rotation
        if T <: Real
            if T <: Integer
                pointsize = a
            else
                rotation = a
            end
        end
        # symbol is color or alignment
        if T <: Symbol
            if a ∈ (:top, :bottom,:center)
                valign = a
            elseif a ∈ (:left, :right)
                halign = a
            else
                color=a
            end
        end
    end

    Font(family, pointsize, halign, valign, rotation, color)
end

_fontstyle!(cfg, Nothing) = nothing
function _fontstyle!(cfg, f::Font)
    (;family, pointsize, halign, valign, rotation, color) = f
    _merge!(cfg; family, color,
            textangle=rotation,
            size=pointsize,textposition=_align(halign, valign))
end

_align(::Nothing, x::Symbol) = string(x)
_align(x::Symbol, ::Nothing) = string(x)
_align(::Nothing, ::Nothing) = ""
_align(x::Symbol, y::Symbol) = join((string(x), string(y)), " ")

## ----

# linecolor - color
# linealpha - float
# linewidth - integer
# linestyle: solic, dot, dashdot, ...
# lineshape: linear, hv, vh, hvh, vhv, spline; or keys of _lineshapes
function _linestyle!(c::Config;
                     lc=nothing, linecolor = lc, # string, symbol, RGB?
                     linealpha=nothing,
                     lw=nothing, width=lw, linewidth = width, # pixels
                     style=nothing, ls=style, linestyle = ls, # solid, dot, dashdot,
                     lineshape = nothing,
                     kwargs...)

    cfg = c.line # pass in config object, not line part

    shape = isnothing(lineshape) ? nothing :
        lineshape ∈ keys(_lineshapes) ? _lineshapes[lineshape] : lineshape

    color = linecolor

    if !isnothing(linealpha)
        if !isnothing(color)
            color = rgb(linecolor, linealpha)
        else
            _merge!(c; opacity=linealpha) # opacity is not line, but c
        end
    end

    _merge!(cfg; color=color, width=linewidth, dash=linestyle, shape)

    kwargs
end

# [:path :steppre :steppost :sticks :scatter]

## ---

function _markerstyle!(cfg::Config; # .marker
                       shape = nothing, markershape = shape,
                       ms=nothing, markersize  = ms,
                       mc=nothing, markercolor = mc,
                       malpha=nothing, markeralpha = malpha,
                       # no marker opacity; pass `rgba(r,g,b,α)` to color
                       #ma=nothing, markeralpha=ma,opacity=markeralpha,
                       kwargs...)
    if !isnothing(markeralpha)
        if !isnothing(markercolor)
            markercolor = rgb(markercolor, markeralpha)
        else
            _merge!(cfg; opacity=markeralpha)
        end
    end

    _merge!(cfg;
            symbol=markershape,
            size=markersize,
            color=markercolor)
    kwargs
end

# magic arguments
## ---
function _textstyle!(cfg::Config;
                     family    = nothing,
                     pointsize = nothing,
                     halign    = nothing,
                     valign    = nothing,
                     rotation  = nothing,
                     color     = nothing,
                     kwargs...)
    # https://plotly.com/javascript/reference/layout/annotations/
    _merge!(cfg, # textftont
            color=color,
            family=family,
            size=pointsize,
            align=halign,  # one of "left","center","right"
            valign=valign, # one of "top", "middle", "bottom"
            textangle=rotation)
    kwargs
end


function _shapestyle!(cfg; kwargs...)
    _merge!(cfg, Config(kwargs...))
end

## ---
# for filled shapes
function _fillstyle!(cfg::Config;
                     fc=nothing, fillcolor = fc, # string, symbol, RGB?
                     fillalpha =  nothing,
                     fillrange=nothing, fill=fillrange,
                     kwargs...)
    if !isnothing(fillcolor)
        fillcolor = rgb(fillcolor, fillalpha)
    end
    _merge!(cfg; fill, fillcolor)
    kwargs
end



## ----

# The camera position and direction is determined by three vectors: up, center, eye.
#
# Their coordinates refer to the 3-d domain, i.e., (0, 0, 0) is always the center of the domain, no matter data values.
#
# The eye vector determines the position of the camera. The default is $(x=1.25, y=1.25, z=1.25)$.
#
# The up vector determines the up direction on the page. The default is $(x=0, y=0, z=1)$, that is, the z-axis points up.
#
#  The projection of the center point lies at the center of the view. By default it is $(x=0, y=0, z=0)$. [https://plotly.com/python/3d-camera-controls/]
#
function _camera_position!(camera::Config;
                          center=nothing,
                          up=nothing,
                           eye=nothing,
                           kwargs...)
    _merge!(camera; center)
    _merge!(camera; up)
    _merge!(camera; eye)
    kwargs
end

_camera_styles!(p::Plot; kwargs...) = _camera_position!(p.layout.scene.camera; kwargs...)

function _aspect_ratio!(p::Plot; aspect_ratio=:nothing, kwargs...)
    if aspect_ratio == :equal
        p.layout.scene.aspectmode = "data"
        p.layout.scene.aspectratio = Config(x=1, y=1, z=1)
    end
    kwargs
end

function _zcontour_style!(p::Plot; zcontour=nothing, kwargs...)
    if !isnothing(zcontour) && zcontour
        p.data[end].contours.z = Config(show=true, usecolormap=true,
                                        project=Config(;z=true))
    end
    kwargs
end

function _3d_styles!(p;
                     kwargs...)
    # layout
    kws = _aspect_ratio!(p; kwargs...)
    kws = _camera_styles!(p; kws...)
    # trace
    kws = _zcontour_style!(p; kws...)

    kws
end



# act directly on config ...
_expand_color(::Nothing) = nothing
_expand_color(x::Symbol) = (x,)
_expand_color(x::AbstractString) = (x,)
_expand_color(x::T) where {T <: Union{ContinuousColorGradient, CategoricalColorGradient}}= (x,)
_expand_color(x) = x


function _series_styles(cfg;
                        c=nothing, color=c, seriescolor=color,
                        alpha = nothing, opacity=alpha, seriesalpha=opacity,
                        kwargs...)
    kws = kwargs
    if !isnothing(seriescolor)
        kws = (kws..., linecolor=seriescolor,
               markercolor=seriescolor) #not fillcolor
    end
    if !isnothing(seriesalpha)
        kws = (kws..., linealpha=seriesalpha,
               markeralpha=seriesalpha,
               fillalpha = seriesalpha)
    end
    kws
end

function _trace_styles!(c; label=nothing,
                        opacity = nothing,
                        kwargs...)
    if !isnothing(label)
        c.name = string(label)
    else
        c.showlegend=false
    end
    c.opacity = opacity
    kws = _linestyle!(c; kwargs...)
    kws = _fillstyle!(c; kws...)
    kws = _markerstyle!(c.marker; kws...)
    kws
end

# XXX this needs work
function _layout_styles!(p;
                         xlims=nothing, ylims=nothing,
                         xticks=nothing, yticks=nothing, zticks=nothing,
                         title=nothing,
                         xlabel=nothing, ylabel=nothing, zlabel=nothing,
                         xscale=nothing, yscale=nothing, zscale=nothing,
                         xaxis=nothing, yaxis=nothing, zaxis=nothing,
                         background_color=nothing, background=background_color,bg=background_color, plot_bgcolor=bg,
                         framestyle=nothing, border=framestyle,
                         legend=nothing,

                         kwargs...)
    # size is specified through a keyed object
    xlims!(p, xlims)
    ylims!(p, ylims)

    # ticks
    xticks!(p, xticks)
    yticks!(p, yticks)
    zticks!(p, zticks)

    # labels
    title!(p, title)
    xlabel!(p, xlabel)
    ylabel!(p, ylabel)
    zlabel!(p, zlabel)

    # scale
    xscale!(p, xscale)
    yscale!(p, yscale)
    zscale!(p, zscale)

    # axis
    isa(xaxis, Tuple) ? xaxis!(p, xaxis...) : xaxis!(p, xaxis)
    isa(yaxis, Tuple) ? yaxis!(p, yaxis...) : yaxis!(p, yaxis)
    isa(zaxis, Tuple) ? zaxis!(p, zaxis...) : zaxis!(p, zaxis)


    # layout
    legend!(p, legend)

    # attributes
    if !isnothing(plot_bgcolor)
        p.layout.plot_bgcolor = plot_bgcolor
    end
    p.layout.border = border

    # don't consume
    haskey(kwargs, :aspect_ratio) &&
        kwargs[:aspect_ratio] == :equal && (p.layout.yaxis.scaleanchor="x")

    kwargs
end

struct MagicRecycler{T}
    t::T
    n::Int
end
MagicRecycler(o) = MagicRecycler(map(Recycler, o), 0)
MagicRecycler(o::Real) = MagicRecycler((o,), 0) # annoying special case
MagicRecycler(o::Symbol) = MagicRecycler((o,), 0) # annoying special case
MagicRecycler(o::String) = MagicRecycler((o,), 0) # annoying special case

function Base.getindex(R::MagicRecycler, i::Int)
    getindex.(R.t, i)
end

# recycle magic so that all is well in the world
# bypass Config(...)
KWRecycler(::Val{T}, o) where {T} = Recycler(o) # default
KWRecycler(::Val{:line}, o::Config) =  Recycler(o)
KWRecycler(::Val{:line}, o) = MagicRecycler(o)
KWRecycler(::Val{:marker}, o::Config) =  Recycler(o)
KWRecycler(::Val{:marker}, o) =  MagicRecycler(o)
KWRecycler(::Val{:fill}, o::Config) =  Recycler(o)
KWRecycler(::Val{:fill}, o) = MagicRecycler(o)
