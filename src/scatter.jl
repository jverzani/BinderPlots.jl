SeriesType(::Val{:scatter}) = (:scatter, :markers)

"""
    scatter(x, y, [z]; [markershape], [markercolor], [markersize], kwargs...)
    scatter(pts; kwargs...)
    scatter!([p::Plot], x, y, [z]; kwargs...)
    scatter!([p::Plot], pts; kwargs...)

Place points on a plot.
* `markershape`: shape, e.g. "diamond" or "diamond-open"
* `markercolor`: color e.g. "red", or :blue, or "rgba(255, 0, 0, 0.5)" (a string,a sit passes JavaScript command to plotly.
* `markersize`:  size, as an integer

The `marker` keyword has some magic arguments.
"""
scatter(args...; kwargs...) = plot(args...; seriestype=:scatter, kwargs...)

"""
    scatter!([p::Plot], x, y, [z]; kwargs...)
    scatter!([p::Plot], pts; kwargs...)

Add points to a plot.
* `markershape`: shape, e.g. "diamond" or "diamond-open"
* `markercolor`: color e.g. "red"
* `markersize`:  size, as an integer
"""
scatter!(args...; kwargs...) = plot!(args...; seriestype=:scatter, kwargs...)
