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

    # layout
    legend!(p, legend)
    aspect_ratio == :equal && (p.layout.yaxis.scaleanchor="x")

    p
end


# plot attributes

"""
    title!([p::Plot], txt)
    xlabel!([p::Plot], txt)
    ylable!([p::Plot], txt)
    zlabel!([p::Plot], txt)

Set plot title.
"""
function title!(p::Plot, txt)
    p.layout.title = txt
    p
end
title!(txt) = title!(current_plot[], txt)

xlabel!(p::Plot, txt) = (p.layout.xaxis.title=txt;p)
xlabel!(txt) = xlabel!(current_plot[], txt)

ylabel!(p::Plot, txt) = (p.layout.yaxis.title=txt;p)
ylabel!(txt) = ylabel!(current_plot[], txt)

zlabel!(p::Plot, txt) = (p.layout.zaxis.title=txt;p)
zlabel!(txt) = zlabel!(current_plot[], txt)

# ticks is values not (values, labels), as with Plots; use ticklabels for that
xticks!(p::Plot, ticks=nothing; ticklabels=nothing, showticklabels=nothing ) =
    xaxis!(;ticks, ticklabels, showticklabels)
xticks!(p::Plot, ::Nothing; kwargs...) = p
xticks!(ticks; kwargs...) = xticks!(current_plot[], ticks; kwargs...)

yticks!(p::Plot, ticks=nothing; ticklabels=nothing, showticklabels=nothing ) =
    yaxis!(;ticks, ticklabels, showticklabels)
yticks!(p::Plot, ::Nothing; kwargs...) = p
yticks!(ticks; kwargs...) = yticks!(current_plot[], ticks; kwargs...)

zticks!(p::Plot, ticks=nothing; ticklabels=nothing, showticklabels=nothing ) =
    zaxis!(;ticks, ticklabels, showticklabels)
zticks!(p::Plot, ::Nothing; kwargs...) = p
zticks!(ticks; kwargs...) = zticks!(current_plot[], ticks; kwargs...)


"""
    xaxis!([p::Plot]; kwargs...)
    yaxis!([p::Plot]; kwargs...)
    zaxis!([p::Plot]; kwargs...)

Adjust ticks on chart.
* ticks: a container or range
* ticklabels: optional labels (same length as `ticks`)
* showticklabels::Bool
"""
xaxis!(p::Plot; kwargs...) = (_axisstyle!(p.layout.xaxis; kwargs...); p)
xaxis!(;kwargs...) = xaxis!(current_plot[]; kwargs...)
yaxis!(p::Plot; kwargs...) = (_axisstyle!(p.layout.yaxis; kwargs...); p)
yaxis!(;kwargs...) = yaxis!(current_plot[]; kwargs...)
zaxis!(p::Plot; kwargs...) = (_axisstyle!(p.layout.zaxis; kwargs...); p)
zaxis!(;kwargs...) = zaxis!(current_plot[]; kwargs...)

# https://plotly.com/javascript/tick-formatting/ .. more to do
# Configure ticks and other axis properties
# to label ticks pass in values for ticks and matching length ticktext
function _axisstyle!(cfg;
                     ticks=nothing,
                     tickvals = nothing,
                     ticklabels=nothing, ticktext=ticklabels,
                     showticklabels=nothing,
                     autotick=nothing,
                     showaxis=nothing, showgrid=showaxis,
                     zeroline=nothing,
                     kwargs...)

    if isnothing(tickvals)
        if !isnothing(ticks)
            tickvals = isa(ticks, AbstractRange) ? collect(ticks) : ticks
        end
    end
    _merge!(cfg; tickvals, ticktext, showticklabels, autotick, showgrid, zeroline)

    kwargs
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

function _markerstyle!(cfg::Config; # .marker
                       shape = nothing, markershape = shape,
                       ms=nothing, markersize  = ms,
                       mc=nothing, markercolor = mc,
                       kwargs...)
    _merge!(cfg; symbol=markershape, size=markersize, color=markercolor)
    kwargs
end

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
