function _facet(x=nothing, y=nothing, z=nothing; facet=nothing, kwargs...)
    if isa(facet, Tuple)
        n = length(facet)
        n > 1 && return _facet_grid(x, y, z; facet1=facet[1], facet2=facet[2],
                                    kwargs...)
        facet = first(facet)
    end
    # assume 1
    ks = nothing
    x, ks = make_cells(x, facet, ks)
    y, ks = make_cells(y, facet, ks)
    z, ks = make_cells(z, facet, ks)

    nc = length(ks)
    ps = Vector{Plot}(undef, nc)
    layout = Config(grid=Config(rows=1, columns=nc, pattern="coupled"))
    fnt = Config(weight="bold")

    for (i, kᵢ) ∈ enumerate(sort(ks))
        cnt = i == 1 ? "" : string(i)
        cnt₋ = i <= 2 ? "" : string(i-1)

        pᵢ = plot(_get.((x,y,z), kᵢ)...;
                       xaxis = "x"*cnt,
                       yaxis = "y"*cnt,
                       kwargs...)

        layout["xaxis"*cnt] = Config(matches="x"*cnt₋,
                                     title=Config(text=kᵢ, font=fnt))
        layout["yaxis"*cnt] = Config(matches="y"*cnt₋)

        ps[i] =  pᵢ
    end

    p = plot(ps...)

    p.layout = layout

    p


end

function _facet_grid(x=nothing, y=nothing, z=nothing;
                     facet1=facet[1], facet2=facet[2],
                     kwargs...)

    ks1 = ks2 = nothing
    x, ks1, ks2 = make_cells(x, facet1, facet2, ks1, ks2)
    y, ks1, ks2 = make_cells(y, facet1, facet2, ks1, ks2)
    z, ks1, ks2 = make_cells(z, facet1, facet2, ks1, ks2)

    nc, nr = length(ks1), length(ks2)
    layout = Config(grid = Config(rows=nr, columns=nc, pattern="independent"))

    ps = Matrix{Plot}(undef, nc, nr)
    axis_ctr = 1
    axis_cnt = 0
    fnt = Config(weight="bold")

    for (j, k₁) ∈ enumerate(sort(ks1; rev=true))
        for (i, k₂) ∈ enumerate(sort(ks2))

            axis_cnt = axis_ctr == 1 ? "" : string(axis_ctr)
            axis_cnt₋ = axis_ctr <= 2 ? "" : string(axis_ctr-1)
            axis_ctr += 1

            ps[i,j] = plot(_get.((x,y,z), k₁, k₂)...;
                           xaxis = "x"*axis_cnt,
                           yaxis = "y"*axis_cnt,
                           kwargs...)

            layout["xaxis"*axis_cnt] = Config(matches="x"*axis_cnt₋,
                                              title=Config(text=k₂, font=fnt))

            layout["yaxis"*axis_cnt] = Config(matches="y"*axis_cnt₋,
                                              title=Config(text=k₁, font=fnt))
        end
    end

    p = plot(ps...)

    p.layout = layout

    p


end

# utils
_get(x,i) = isnothing(x) ? x : x[i]
_get(x,i,j) = isnothing(x) ? x : x[i][j]

function make_cells(x, g, ks)
    isnothing(x) && return (x, ks)
    xx = SplitApplyCombine.group(g, x)
    x = collect(xx)
    ks = something(ks, collect(string.(keys(xx))))
    xx, ks
end

function make_cells(x, g₁, g₂, ks₁, ks₂)
    isnothing(x) && return (x, ks₁, ks₂)
    xx = SplitApplyCombine.group(g₁, zip(x,g₂))
    xxx = map(u -> SplitApplyCombine.group(last.(u), first.(u)), xx)
    ks₁ = something(ks₁, collect(string.(keys(xx))))
    ks₂ = something(ks₂, collect(string.(keys(xxx[first(keys(xxx))]))))
    xxx, ks₁, ks₂
end
