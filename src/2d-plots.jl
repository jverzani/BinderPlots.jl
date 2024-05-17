##
## Basic 2d plots of f::𝐑² → 𝐑
##
SeriesType(::Val{:contour}) = (:contour, :contour)
SeriesType(::Val{:heatmap}) = (:heatmap, :heatmap)



# types and modes here
ContourTypes = Union{Val{:contour}, Val{:heatmap},
                     Val{:surface}, Val{:wireframe}}


function plot!(t::T, m::M, p::Plot, x, y, z;
               kwargs...) where {T <: ContourTypes, M<:ContourTypes}

    x, y, z = _adjust_matrix.((x,y,z))
    c = Config(; x, y, z, type=_valtype(t))
    push!(p.data, c)

    kws = _bivariate_scalar_styles!(t, m, p; kwargs...)
    kws = _color_magic(; kws...)
    _merge!(c; kws...)

    p

end

function plot!(t::T, m::M, p::Plot, x::AbstractMatrix, y::Nothing, z::Nothing;
               kwargs...) where {T <: ContourTypes, M<:ContourTypes}
    plot!(t, m, p, axes(x,1), axes(x, 2), x; kwargs...)
end


"""
    contour(x, y, z; kwargs...)
    contour!([p::Plot], x, y, z; kwargs...)
    contour(x, y, f::Function; kwargs...)
    contour!(x, y, f::Function; kwargs...)

Create contour map.
"""
function contour(args...; kwargs...)
    p, kws = _new_plot(; kwargs...)
    contour!(p, args...; kwargs...)
end
contour!(args...; kwargs...) = plot!(args...; seriestype=:contour, kwargs...)

# filled
contourf(args...; kwargs...) = contour(args...; fillrange=true, kwargs...)
contourf!(args...; kwargs...) = contour!(args...; fillrange=true, kwargs...)

_bivariate_scalar_styles!(::Val{T}, ::Val{M}, p; kwargs...) where {T,M} = kwargs
function  _bivariate_scalar_styles!(t::Val{:contour}, ::Val{M}, p;
                           levels = nothing, # a number or something w/ step method
                           color = nothing, # magic argument
                           colorbar::Union{Nothing, Bool} = nothing, # show colorbar
                           fillrange::Bool = false,
                           contour_labels::Bool = false,
                           linewidth = nothing,
                           kwargs...) where {M}

    # color --> colorscale A symbol or name (or container)
    # levels
    c = p.data[end]

    !fillrange && (c.contours.coloring = "lines")

    !isnothing(linewidth) && (c.line.width = linewidth)
    !isnothing(colorbar) && (c.showscale = colorbar)

    if !isnothing(levels) # something with a step or single number
        c.autocontour = false
        if hasmethod(step, (typeof(levels),))
            l,r = extrema(levels)
            s = step(levels)
        else
            l = r = first(levels)
            s = 0
        end
        c.contours.start = l
        c.contours.size  = s
        c.contours."end" = r
    end

    ## labels (adjust font? via contours.labelfont
    c.contours.showlabels = contour_labels

    kwargs
end


"""
    heatmap(x, y, z; kwargs...)
    heatmap!([p::Plot], x, y, z; kwargs...)
    heatmap(x, y, f::Function; kwargs...)
    heatmap!(x, y, f::Function; kwargs...)

Create heatmap function of `f`
"""
function heatmap(args...; kwargs...)
    p, kws = _new_plot(; kwargs...)
    heatmap!(p, args...; kwargs...)
end
heatmap!(args...; kwargs...) = plot!(args...; seriestype=:heatmap, kwargs...)

## -----

"""
    plot_implicit(f; xlims=(-5,5), ylims=(-5,5), legend=false, linewidth=2, kwargs...)
    plot_implicit!([p::Plot], f; kwargs...)

For `f(x,y) = ...` plot implicitly defined `y(x)` from `f(x,y(x)) = 0` over range specified by `xlims` and `ylims`.

## Example
```
f(x,y) = x * y - (x^3 + x^2 + x + 1)
plot_implicit(f)
```

(Basically just `contour` plot with `levels=0` and points determined by extrema of `xlims` and `ylims`.)
"""
function plot_implicit(f::Function; kwargs...)
    p, kwargs = _new_plot(; kwargs...)
    plot_implicit!(p, f; kwargs...)
end

plot_implicit!(f::Function; kwargs...) = plot_implicit!(current_plot[], f; kwargs...)
function plot_implicit!(p::Plot, f::Function;
                        xlims=(-5, 5), ylims=(-5, 5),
                        legend=false,
                        linewidth=2,
                        kwargs...)

    xs = range(extrema(xlims)..., length=100)
    ys = range(extrema(ylims)..., length=100)
    zs = f.(xs', ys)
    kws = _color_magic(; kwargs...)
    contour!(p, xs, ys, zs;
             levels=0,  colorbar=legend, linewidth,
             kws...)
end
