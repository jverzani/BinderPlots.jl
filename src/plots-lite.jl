## --- plotting

## utils
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
                   windowsize=nothing, size=windowsize, # named tuple (width=, height=)
                   xlim=nothing, xlims=xlim,
                   ylim=nothing, ylims=ylim,
                   xticks=nothing, yticks=nothing,zticks=nothing,
                   xlabel=nothing, ylabel=nothing,zlabel=nothing,
                   xscale=nothing, yscale=nothing,zscale=nothing,
                   legend = nothing,
                   aspect_ratio=nothing,
                   kwargs...)

    p = Plot(Config[],
             Config(), # layout
             Config(responsive=true) ) # config
    current_plot[] = p

    if first_plot[]
        first_plot[] = false
    end

    kwargs = _layout_attrs!(p;
                            size, xlims, ylims,
                            xticks, yticks, zticks,
                            xlabel, ylabel, zlabel,
                            xscale, yscale, zscale,
                            legend,
                            aspect_ratio,
                            kwargs...)

    p, kwargs
end


function _layout_attrs!(p;
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


"""
    xaxis!([p::Plot]; kwargs...)
    yaxis!([p::Plot]; kwargs...)
    zaxis!([p::Plot]; kwargs...)

Adjust properties of an axis on a chart using `Plotly` keywords.

* `ticks`, `ticktext`, `ticklen`, `tickwidth`, `tickcolor`, `tickfont`, `showticklabels`
* `showgrid`, `gridcolor`, `gridwidth`
* `zeroline`, `zerolinecolor`, `zerolinewidth`
"""
xaxis!(p::Plot; kwargs...) = (xyzaxis!(p.layout.xaxis; kwargs...); p)
xaxis!(p::Plot, args...) = _axis_magic!(p.layout.xaxis, args...)
xaxis!(;kwargs...) = xaxis!(current_plot[]; kwargs...)
xaxis!(args...) = xaxis!(current_plot[], args...)

yaxis!(p::Plot; kwargs...) = (xyzaxis!(p.layout.yaxis; kwargs...); p)
yaxis!(p::Plot, args...) = _axis_magic!(p.layout.yaxis, args...)
yaxis!(;kwargs...) = yaxis!(current_plot[]; kwargs...)
yaxis!(args...) = yaxis!(current_plot[], args...)

zaxis!(p::Plot; kwargs...) = (xyzaxis!(p.layout.zaxis; kwargs...);p)
zaxis!(p::Plot, args...) = _axis_magic!(p.layout.zaxis, args...)
zaxis!(;kwargs...) = zaxis!(current_plot[]; kwargs...)
zaxis!(args...) = zaxis!(current_plot[], args...)

xyzaxis!(cfg; kwargs...) = _axisstyle!(cfg; kwargs...)
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

# match args to axis property
# https://docs.juliaplots.org/latest/attributes/#magic-arguments
function _axis_magic!(cfg, args...)
    for a ∈ args
        if isa(a, Font)
            _fontstyle!(cfg.tickfont, a)
            cfg.tickangle = a.rotation
        elseif a ∈ (:log, :linear)
            cfg.type = a
        elseif a ∈ (:flip, :invert, :inverted)
            cfg.autorange = "reversed"
        elseif (isa(a, Tuple) || isa(a, AbstractVector))
            if length(a) == 2
                cfg.range = a
            else
                x₁ = first(a)
                if isa(x₁, Number)
                    cfg.tickvals = collect(a)
                else
                    cfg.ticktext = collect(a)
                end
            end
        elseif isa(a, Bool)
            cfg.showgrid = a
        end
    end
    cfg
end


"`legend!([p::Plot], legend::Bool)` hide/show legend"
legend!(p::Plot, legend=nothing) = !isnothing(legend) && (p.layout.showlegend = legend)
legend!(val::Bool) = legend!(current_plot[], val)

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

# linecolor - color
# linewidth - integer
# linestyle: solic, dot, dashdot, ...
# lineshape: linear, hv, vh, hvh, vhv, spline
function _linestyle!(cfg::Config;
                     lc=nothing, linecolor = lc, # string, symbol, RGB?
                     lw=nothing, width=lw, linewidth = width, # pixels
                     style=nothing, ls=style, linestyle = ls, # solid, dot, dashdot,
                     lineshape = nothing,
                     kwargs...)

    _merge!(cfg; color=linecolor, width=linewidth, dash=linestyle,
            shape=lineshape)
    kwargs
end

# magic
_linestyles = (:dash, :dashdot, :dot, :sold, :auto)
_line_magic!(cfg, line::Nothing) = nothing
function _line_magic!(cfg, line)
    for a ∈ line
        if isa(a, Symbol)
            if a ∈ _linestyles
                cfg.line.dash = a
            else
                cfg.line.color = a
            end
        end
        if isa(a, Number)
            isa(a, Integer) && (cfg.line.width=a)
            0 < a < 1 && (cfg.opacity = a)
        end
    end
end

## ---

function _markerstyle!(cfg::Config; # .marker
                       shape = nothing, markershape = shape,
                       ms=nothing, markersize  = ms,
                       mc=nothing, markercolor = mc,
                       kwargs...)
    _merge!(cfg; symbol=markershape, size=markersize, color=markercolor)
    kwargs
end

# magic arguments
# use :nm_attribute not nm-attribute
_marker_shapes = (:circle, :circle_open, :circle_dot, :circle_open_dot, :square, :square_open, :square_dot, :square_open_dot, :diamond, :diamond_open, :diamond_dot, :diamond_open_dot, :cross, :cross_open, :cross_dot, :cross_open_dot, :x, :x_open, :x_dot, :x_open_dot, :triangle_up, :triangle_up_open, :triangle_up_dot, :triangle_up_open_dot, :triangle_down, :triangle_down_open, :triangle_down_dot, :triangle_down_open_dot, :triangle_left, :triangle_left_open, :triangle_left_dot, :triangle_left_open_dot, :triangle_right, :triangle_right_open, :triangle_right_dot, :triangle_right_open_dot, :triangle_ne, :triangle_ne_open, :triangle_ne_dot, :triangle_ne_open_dot, :triangle_se, :triangle_se_open, :triangle_se_dot, :triangle_se_open_dot, :triangle_sw, :triangle_sw_open, :triangle_sw_dot, :triangle_sw_open_dot, :triangle_nw, :triangle_nw_open, :triangle_nw_dot, :triangle_nw_open_dot, :pentagon, :pentagon_open, :pentagon_dot, :pentagon_open_dot, :hexagon, :hexagon_open, :hexagon_dot, :hexagon_open_dot, :hexagon2, :hexagon2_open, :hexagon2_dot, :hexagon2_open_dot, :octagon, :octagon_open, :octagon_dot, :octagon_open_dot, :star, :star_open, :star_dot, :star_open_dot, :hexagram, :hexagram_open, :hexagram_dot, :hexagram_open_dot, :star_triangle_up, :star_triangle_up_open, :star_triangle_up_dot, :star_triangle_up_open_dot, :star_triangle_down, :star_triangle_down_open, :star_triangle_down_dot, :star_triangle_down_open_dot, :star_square, :star_square_open, :star_square_dot, :star_square_open_dot, :star_diamond, :star_diamond_open, :star_diamond_dot, :star_diamond_open_dot, :diamond_tall, :diamond_tall_open, :diamond_tall_dot, :diamond_tall_open_dot, :diamond_wide, :diamond_wide_open, :diamond_wide_dot, :diamond_wide_open_dot, :hourglass, :hourglass_open, :bowtie, :bowtie_open, :circle_cross, :circle_cross_open, :circle_x, :circle_x_open, :square_cross, :square_cross_open, :square_x, :square_x_open, :diamond_cross, :diamond_cross_open, :diamond_x, :diamond_x_open, :cross_thin, :cross_thin_open, :x_thin, :x_thin_open, :asterisk, :asterisk_open, :hash, :hash_open, :hash_dot, :hash_open_dot, :y_up, :y_up_open, :y_down, :y_down_open, :y_left, :y_left_open, :y_right, :y_right_open, :line_ew, :line_ew_open, :line_ns, :line_ns_open, :line_ne, :line_ne_open, :line_nw, :line_nw_open, :arrow_up, :arrow_up_open, :arrow_down, :arrow_down_open, :arrow_left, :arrow_left_open, :arrow_right, :arrow_right_open, :arrow_bar_up, :arrow_bar_up_open, :arrow_bar_down, :arrow_bar_down_open, :arrow_bar_left, :arrow_bar_left_open, :arrow_bar_right, :arrow_bar_right_open, :arrow, :arrow_open, :arrow_wide, :arrow_wide_open)

function _marker_magic!(cfg, marker)
    for a ∈ marker # a tuple
        if isa(a, Symbol)
            if a ∈ _marker_shapes
                cfg.symbol = replace(string(a), "_" => "-")
            else
                cfg.color = a
            end
        end
        if isa(a, Number)
            if isa(a, Integer)
                cfg.size = a
            else
                0 ≤ a ≤ 1  && (cfg.opacity = a)
            end
        end
        ## XXX Add Stroke properties?
    end
end
_marker_magic!(cfg, ::Nothing) = nothing

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
        # string is family
        isa(a, AbstractString) && (family = a)
        # pointsize or rotation
        if isa(a, Real)
            if isa(a, Integer)
                pointsize = a
            else
                rotation = a
            end
        end
        # symbol is color or alignment
        if isa(a, Symbol)
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

## ---
# for filled shapes
# XXX test this! clean up code calling style! functions (kwargs)
# XXX image
function _fillstyle!(cfg::Config;
                     fc=nothing, fillcolor = fc, # string, symbol, RGB?
                     fillalpha=nothing, opacity = fillalpha,
                     kwargs...)
    _merge!(cfg; fillcolor=fillcolor, opacity)
    kwargs
end


# XXX not yet integrated
# range, color, alpha
function _fill_magic!(cfg, fill)
end
_fill_magic!(cfg, ::Nothing) = nothing

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
                          center,
                          up,
                          eye, kwargs...)
    _merge!(camera; center)
    _merge!(camera; up)
    _merge!(camera; eye)
    kwargs
end
