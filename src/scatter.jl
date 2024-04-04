"""
    scatter(x, y, [z]; [markershape], [markercolor], [markersize], kwargs...)
    scatter(pts; kwargs...)
    scatter!([p::Plot], x, y, [z]; kwargs...)
    scatter!([p::Plot], pts; kwargs...)

Place point on a plot.
* `markershape`: shape, e.g. "diamond" or "diamond-open"
* `markercolor`: color e.g. "red"
* `markersize`:  size, as an integer
"""
function scatter!(p::Plot, x, y; marker=nothing, kwargs...)

    # skip NaN or Inf
    keep_x = findall(isfinite, x)
    keep_y = findall(isfinite, y)
    idx = intersect(keep_x, keep_y)

    cfg = Config(;x=x[idx], y=y[idx], mode="markers", type="scatter")
    _marker_magic!(cfg.marker, marker)
    kws = _markerstyle!(cfg.marker; kwargs...)
    _merge!(cfg; kws...)
    push!(p.data, cfg)

    p
end

function scatter!(p::Plot, x, y::Matrix; kwargs...)
    kw = Recycler(kwargs)
    for (j, yⱼ) ∈ enumerate(eachcol(y))
        scatter!(p, x, yⱼ; kw[j]...)
    end
end


function scatter!(p::Plot, x, y, z;
                  marker=nothing,
                  legend=nothing,
                  kwargs...)

    kwargs = _layout_attrs!(p; kwargs...)
    # skip NaN or Inf
    keep_x = findall(isfinite, x)
    keep_y = findall(isfinite, y)
    keep_z = findall(isfinite, z)
    idx = intersect(keep_x, keep_y, keep_z)

    cfg = Config(;x=x[idx], y=y[idx], z=z[idx],
                 mode="markers", type="scatter3d")
    _marker_magic!(cfg.marker, marker)
    kws = _markerstyle!(cfg.marker; kwargs...)
    _merge!(cfg; kws...)
    push!(p.data, cfg)

    p
end

scatter!(x, y; kwargs...) = scatter!(current_plot[], x, y; kwargs...)

"`scatter(x, y; kwargs...)` see [`scatter!`](@ref)"
function scatter(x, y, zs...; kwargs...)
    p, kwargs = _new_plot(; kwargs...)
    scatter!(p, x, y, zs...; kwargs...)
    p
end

scatter(pts; kwargs...) = scatter(unzip(pts)...; kwargs...)
scatter!(pts; kwargs...) = scatter!(current_plot[], pts; kwargs...)
scatter!(p::Plot, pts; kwargs...) = scatter!(p, unzip(pts)...; kwargs...)



## zcolor argument
