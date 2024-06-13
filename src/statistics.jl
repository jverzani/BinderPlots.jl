# this is all it takes to make
# `plot(x; seriestype=:histogram)` plot a histogram

# no grouping
SeriesType(::Val{:histogram2d}) = (:histogram2d, :histogram2d)
# https://plotly.com/javascript/pie-charts/
SeriesType(::Val{:pie}) = (:pie, :pie) # plot(; values = [19, 26, 55], labels=["a","b", "c"], seriestype=:pie)

# use type=:statistics to dispatch for grouping

# https://plotly.com/javascript/histograms/
# cf below for translated examples
SeriesType(::Val{:histogram}) = (:statistics, :histogram)
SeriesType(::Val{:bar}) = (:statistics, :bar) # x categorical, y numeric

# https://plotly.com/javascript/box-plots/
SeriesType(::Val{:boxplot}) = (:statistics, :box)
SeriesType(::Val{:violin}) = (:statistics, :violin)

# handle grouping
function plot!(::Val{:statistics}, p::Plot, x=nothing, y=nothing, z=nothing;
               seriestype::Symbol=:histogram,
               group = nothing,
               label = nothing,
               kwargs...)

    # group
    if !isnothing(group)
        if !isnothing(x)
            xx = SplitApplyCombine.group(group, x)
            x = collect(xx)
            label = something(label, collect(string.(keys(xx))))
        end
        if !isnothing(y)
            yy = SplitApplyCombine.group(group, y)
            y = collect(yy)
            label = something(label, collect(string.(keys(yy))))
        end
        if !isnothing(z)
            zz = SplitApplyCombine.group(group, z)
            z = collect(zz)
            label = something(label, collect(string.(keys(zz))))
        end
    end
    _,mode = SeriesType(seriestype)
    M = Val(Symbol(mode))

    KWs = Recycler(kwargs)
    label = Recycler(label)

    for (i, xyzₛ) ∈ enumerate(xyz(x,y,z))
        plot!(M, M, p, xyzₛ...;
              label = label[i],
              KWs[i]...)
    end
    p
end
