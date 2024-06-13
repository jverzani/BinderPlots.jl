#=
# Faceting

WIP. This is really hacky and likely won't improve.

### single variables

```
plot(df.bill_depth_mm, df.bill_length_mm; facet = df.species,
     seriestype = :scatter,
     marker = (10, (:red, :blue, :green), (:star, :circle, :square)))
```

### two variables

```
plot(df.bill_depth_mm, df.bill_length_mm;
     facet = (df.species, df.island),
     seriestype = :scatter,
     marker = (10, (:red, :blue, :green), (:star, :circle, :square)))
```

### two variables with grouping

```
plot(df.bill_depth_mm, df.bill_length_mm;
     facet = (df.species, df.island),
     group = df.sex,
     seriestype = :scatter,
     marker = (10, (:red, :blue, :green), (:star, :circle, :square)))
```
=#

# use _facet to dispatch to one or two variables
function _facet(x=nothing, y=nothing, z=nothing;
                facet=nothing,
                group=nothing,
                kwargs...)
    if isa(facet, Tuple)
        n = length(facet)
        n > 1 && return _facet_grid(x, y, z; facet1=facet[1], facet2=facet[2],
                                    group,
                                    kwargs...)
        facet = first(facet)
    end
    _facet_row(x, y, z; facet, group,
               kwargs...)
end

_levels_fnt = Config(weight="bold", size=20, color=:gray)

function _facet_row(x=nothing, y=nothing, z=nothing;
                    facet=nothing, group,
                    xlabel=nothing, ylabel=nothing,
                    kwargs...)
    ks = nothing
    x, ks = make_cells(x, facet, ks)
    y, ks = make_cells(y, facet, ks)
    z, ks = make_cells(z, facet, ks)
    group, ks = make_cells(group, facet, ks)

    nc = length(ks)
    layout = Config(grid=Config(rows=1, columns=nc, pattern="coupled"))
    ps = Vector{Plot}(undef, nc)

    for (i, kᵢ) ∈ enumerate(sort(ks))
        cnt = i == 1 ? "" : string(i)
        cnt₋ = i <= 2 ? "" : string(i-1)

        x′,y′,z′ = _get.((x,y,z), kᵢ)
        g = _get(group, kᵢ)
        g = isnothing(g) ? g :  isempty(g) ? nothing : g

        pᵢ = plot(x′,y′,z′;
                  group = g,
                  showlegend=legend && !isnothing(group) && axis_ctr <= 2,
                  xaxis = "x"*cnt,
                  yaxis = "y"*cnt,
                  kwargs...)

        layout["xaxis"*cnt] = Config(matches="x"*cnt₋,
                                     title=Config(text=xlabel))
        layout["yaxis"*cnt] = Config(matches="y"*cnt₋,
                                     title=Config(text=ylabel))

        ps[i] =  pᵢ
    end

    # add annotations for levels of facet variables
    annotations = Config[]
    for (i, kᵢ) ∈ enumerate(sort(ks))
        c = Config(
            xref="paper", yref="paper",
            x=(2i-1)/(2*nc), y=1,
            xanchor="right", yanchor="bottom",
            text=kᵢ, font=_levels_fnt,
            showarrow=false)
        push!(annotations, c)
    end
    layout.annotations = annotations

    p = plot(ps...)

    p.layout = layout

    p


end

function _facet_grid(x=nothing, y=nothing, z=nothing;
                     facet1=facet[1], facet2=facet[2], # column, row
                     group = nothing, legend=true,
                     xlabel=nothing, ylabel=nothing,
                     kwargs...)

    ks1 = ks2 = nothing
    x, ks1, ks2 = make_cells(x, facet1, facet2, ks1, ks2)
    y, ks1, ks2 = make_cells(y, facet1, facet2, ks1, ks2)
    z, ks1, ks2 = make_cells(z, facet1, facet2, ks1, ks2)
    group, ks1, ks2 = make_cells(group, facet1, facet2, ks1, ks2)

    nc, nr = length(ks1), length(ks2)
    layout = Config(grid = Config(rows=nr, columns=nc,
                                  pattern="independent"))

    ps = Matrix{Plot}(undef, nc, nr)

    axis_ctr = 1

    for (i, k₁) ∈ enumerate(sort(ks1; rev=true)) # row
        for (j, k₂) ∈ enumerate(sort(ks2))       # column
            axis_cnt = axis_ctr == 1 ? "" : string(axis_ctr)
            axis_cnt₋ = axis_ctr <= 2 ? "" : string(axis_ctr-1)
            axis_ctr += 1

            x′,y′,z′ = _get.((x,y,z), k₁, k₂)
            g = _get(group, k₁, k₂)
            g = isnothing(g) ? g :  isempty(g) ? nothing : g
            ps[i,j] = plot(x′, y′, z′;
                           group = g,
                           showlegend=legend && !isnothing(group) && axis_ctr <= 2,
                           xaxis = "x"*axis_cnt,
                           yaxis = "y"*axis_cnt,
                           kwargs...)

            layout["xaxis"*axis_cnt] = Config(matches="x"*axis_cnt₋,
                                              title=Config(text=xlabel))

            layout["yaxis"*axis_cnt] = Config(matches="y"*axis_cnt₋,
                                              title=Config(text=ylabel))
        end
    end

    # add annotations for levels of facet variables
    annotations = Config[]
    for (i, kᵢ) ∈ enumerate(sort(ks1; rev=true))
        c = Config(
            xref="paper", yref="paper",
            x=(2i-1)/(2*nc), y=1,
            xanchor="right", yanchor="bottom",
            text=kᵢ, font=_levels_fnt,
            showarrow=false)
        push!(annotations, c)
    end
    for (i, kᵢ) ∈ enumerate(sort(ks2; rev=true)) # also reverse for paper
        c = Config(
            xref="paper", yref="paper",
            x=1, y=(2i-1)/(2*nr),
            xanchor="left", yanchor="top",
            text=kᵢ, font=_levels_fnt,
            showarrow=false)
        push!(annotations, c)
    end

    layout.annotations = annotations

    p = plot(ps...)

    p.layout = layout

    p

end

# utils
_get(x,i) = isnothing(x) ? x : get(x, i, Float64[])
_get(x,i,j) = isnothing(x) ? x : get(x[i], j, Float64[])

export make_cells
function make_cells(x, g, ks)
    isnothing(x) && return (x, ks)
    xx = SplitApplyCombine.group(g, x)
    x = collect(xx)
    ks = something(ks, collect(string.(keys(xx))))
    xx, ks
end

function make_cells(x, g₁, g₂, ks₁, ks₂)
    isnothing(x) && return (x, ks₁, ks₂)
    xx = SplitApplyCombine.group(g₁, collect(zip(x,g₂)))
    xxx = map(u -> SplitApplyCombine.group(last.(u), first.(u)), xx)
    ks₁ = something(ks₁, collect(string.(keys(xx))))
    ks₂ = something(ks₂, collect(string.(keys(xxx[first(keys(xxx))]))))
    xxx, ks₁, ks₂
end
