# handle magic args
#
# modify kwargs...
#
# there are magic keywords: marker, fill, ... XXX
#

# Utils
# turn magic into keyword arguments
_set(d, key, value) = (d[key] = value)
_set(d, key, ::Nothing) = d



## --- Magic

## **Should** modify kwargs...

# match args to axis property
# https://docs.juliaplots.org/latest/attributes/#magic-arguments
# XXX update
function _axis_magic!(cfg, args...)
    for a ∈ args
        if isa(a, Font)
            _fontstyle!(cfg.tickfont, a)
            cfg.tickangle = a.rotation
        elseif a ∈ (:log, :linear)
            cfg.type = a
        elseif a ∈ (:log2, :log10)
            cfg.type = :log
        elseif a ∈ (:flip, :invert, :inverted)
            cfg.autorange = "reversed"
        elseif (isa(a, Tuple) || isa(a, AbstractVector))
            N = length(a)
            if iszero(N)
                @warn "look this up"
            elseif N == 2
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
            cfg.zeroline = a
            cfg.showticklabels=a
        elseif isa(a, AbstractString)
            _labelstyle!(cfg, a)
        elseif isa(a, TextFont)
            _labelstyle!(cfg, a)
        end
    end
    cfg
end

# XXX update
function _legend_magic!(p, legend)

    lyt = p.layout
    leg = p.layout.legend
    for a ∈ legend
        if isa(a, Tuple)
            x, y = a
            leg.x = x; leg.y=y
        elseif isa(a, Font)
            font = leg.font
            font.family = a.family
            font.size = a.pointsize
            font.color = a.color
        elseif isa(a, Bool)
           lyt.showlegend=a
        elseif isa(a, Symbol)
            if haskey(_legend_positions, a)
                x,y = _legend_positions[a]
                leg.x = x; leg.y=y
            elseif a == :reversed
                leg.traceorder = :reversed
            else
                leg.bgcolor = a
            end
        end
    end
    nothing
end


function _color_magic(;
                      seriescolor=nothing, palette=seriescolor, color_palette=palette,
                      kwargs...)
    d = Config()
    for a ∈ something(_expand_color(color_palette), tuple())
        T = typeof(a)
        if T <: AbstractString
            a,T = Symbol(a), Symbol
        end
        if T <: Symbol
            if a ∈ _color_scales
                _set(d, :colorscale, a)
                cfg.colorscale = a
            else
                a = cgrad(a)
                T = typeof(a)
            end
        end

        if T <: ContinuousColorGradient || T <: CategoricalColorGradient
            cols = [[v,rgb(c)] for (v,c) ∈ zip(a.values, a.colors)]
            _set(d, :colorscale, cols)
        end

        if T <: Stroke
            line = Config()
            line.color = rgb(a.color, a.alpha)
            line.width = a.width
            line.style = a.style
            _set(d, :line, line)
        end
    end

    # covert back
    kws = merge(Dict(kwargs...), d)
    nt = NamedTuple(kws)
    Base.Pairs(nt, keys(nt))
end

function _line_magic(; line=nothing, kwargs...)
    isnothing(line) && return kwargs
    d = Config()
    # ---
    linecolor = nothing
    linealpha = nothing
    for a ∈ something(line, tuple())
        T = typeof(a)
        if T <: Stroke
            _set(d, :linewidth, a.width)
            _set(d, :linecolor, rgb(a.color, a.alpha))
            _set(d, :linestyle, a.style)
        elseif T <: Symbol || T <: AbstractString
            a′ = Symbol(a)
            if a′ ∈ _linestyles
                _set(d, :linestyle, a′)
            elseif a′ ∈ keys(_lineshapes)
                _set(d, :lineshape, _lineshapes[a′])
            else
                linecolor = a′
            end
        elseif T <: _RGB
            linecolor = a
            _set(d, :linecolor, a)
        elseif T <: RGB || T <: RGBA
            linecolor = rgb(a)
            _set(d, :linecolor, rgb(a))
        elseif T <:  Number
            T <: Integer && _set(d, :linewidth, a)
            0 < a < 1 && (linealpha = a)
        end
    end
    if !isnothing(linealpha)
        if isa(linecolor, Union{String,Symbol})
            linecolor = rgb(linecolor, linealpha)
        else
            _set(d, :opacity, linealpha)
        end
    end
    _set(d, :linecolor, linecolor)

    # ---
    # covert back
    kws = merge(Dict(kwargs...), d)
    nt = NamedTuple(kws)
    Base.Pairs(nt, keys(nt))

end

function _fill_magic(; fill=nothing, kwargs...)
    isnothing(fill) && return kwargs
    d = Config()
    # ---

    fillcolor = nothing
    fillalpha = nothing
    fillstyle = get(kwargs, :fillstyle, nothing)

    for a ∈ something(fill, tuple())
        T = typeof(a)
        if T <: Symbol || T <: AbstractString
            a′ = Symbol(a)
            if a′ ∈ _fillstyles
                fillstyle = a′
            else
                fillcolor = a′
            end
        elseif T <: _RGB
            fillcolor = a
        elseif T <: Bool
            a && (fillstyle = :toself) # true false
        elseif T <: Real
            if 0 < a < 1
                fillalpha =a
            elseif iszero(a)
                fillstyle = :tozeroy
            elseif isa(a, Integer)
                @warn "Fill to a non-zero y value is not implemented"
            end
        elseif T <: Stroke
            # adjust line properties
            _set(d, :linewidth, a.width)
            _set(d, :linecolor, rgb(a.color, a.alpha))
            _set(d, :linestyle, a.style)
        end
    end
    if isa(fillcolor, Union{String,Symbol}) && !isnothing(fillalpha)
        fillcolor = rgb(fillcolor, fillalpha)
    end
    _set(d, :fillcolor, fillcolor)
    !isnothing(fillcolor) && _set(d, :fill, fillstyle)


    # ---
    # covert back
    kws = merge(Dict(kwargs...), d)
    nt = NamedTuple(kws)
    Base.Pairs(nt, keys(nt))

end

function _marker_magic(; marker=nothing, kwargs...)
    isnothing(marker) && return kwargs
    d = Config()
    # ---
    markercolor = nothing
    markeralpha = nothing
    for a ∈ something(marker, tuple())
        T = typeof(a)
        if T <: Symbol || T <: AbstractString
            a′ = Symbol(a)
            if a′ ∈ _marker_shapes
                _set(d, :markershape, replace(string(a), "_" => "-"))
            else
                markercolor = a′
            end
        elseif T <:  _RGB
            markercolor = a
        elseif T <: RGB || T <: RGBA
            markercolor = rgb(a)
        elseif T <: Number
            if T <: Integer
                _set(d, :markersize, a)
            end
            0 < a < 1 && (markeralpha = a)
        end
    end
    if  !isnothing(markeralpha)
        if isa(markercolor, Union{String,Symbol})
            markercolor = rgb(markercolor, markeralpha)
        else
            _set(d, :opacity, markeralpha)
        end
    end
    _set(d, :markercolor, markercolor)

    # ---
    # covert back
    kws = merge(Dict(kwargs...), d)
    nt = NamedTuple(kws)
    Base.Pairs(nt, keys(nt))

end



# too much heere
function _make_magic(;
                     #line = nothing,
                     #marker = nothing,
                     #fill = nothing,
                     kwargs...)

    d = Config()

    #=
    # fill = ...
    fillcolor = nothing
    fillalpha = nothing
    fillstyle = get(kwargs, :fillstyle, nothing)

    for a ∈ something(fill, tuple())
        T = typeof(a)
        if T <: Symbol || T <: AbstractString
            a′ = Symbol(a)
            if a′ ∈ _fillstyles
                fillstyle = a′
            else
                fillcolor = a′
            end
        elseif T <: _RGB
            fillcolor = a
        elseif T <: Bool
            a && (fillstyle = :toself) # true false
        elseif T <: Real
            if 0 < a < 1
                fillalpha =a
            elseif iszero(a)
                fillstyle = :tozeroy
            elseif isa(a, Integer)
                @warn "Fill to a non-zero y value is not implemented"
            end
        elseif T <: Stroke
            # adjust line properties
            _set(d, :linewidth, a.width)
            _set(d, :linecolor, rgb(a.color, a.alpha))
            _set(d, :linestyle, a.style)
        end
    end
    if isa(fillcolor, Union{String,Symbol}) && !isnothing(fillalpha)
        fillcolor = rgb(fillcolor, fillalpha)
    end
    _set(d, :fillcolor, fillcolor)
    !isnothing(fillcolor) && _set(d, :fill, fillstyle)


    ## line = ...
    linecolor = nothing
    linealpha = nothing
    for a ∈ something(line, tuple())
        T = typeof(a)
        if T <: Stroke
            _set(d, :linewidth, a.width)
            _set(d, :linecolor, rgb(a.color, a.alpha))
            _set(d, :linestyle, a.style)
        elseif T <: Symbol || T <: AbstractString
            a′ = Symbol(a)
            if a′ ∈ _linestyles
                _set(d, :linestyle, a′)
            elseif a′ ∈ keys(_lineshapes)
                _set(d, :lineshape, _lineshapes[a′])
            else
                linecolor = a′
            end
        elseif T <: _RGB
            linecolor = a
            _set(d, :linecolor, a)
        elseif T <: RGB || T <: RGBA
            linecolor = rgb(a)
            _set(d, :linecolor, rgb(a))
        elseif T <:  Number
            T <: Integer && _set(d, :linewidth, a)
            0 < a < 1 && (linealpha = a)
        end
    end
    if !isnothing(linealpha)
        if isa(linecolor, Union{String,Symbol})
            linecolor = rgb(linecolor, linealpha)
        else
            _set(d, :opacity, linealpha)
        end
    end
    _set(d, :linecolor, linecolor)


    ## marker = ...
    markercolor = nothing
    markeralpha = nothing
    for a ∈ something(marker, tuple())
        T = typeof(a)
        if T <: Symbol || T <: AbstractString
            a′ = Symbol(a)
            if a′ ∈ _marker_shapes
                _set(d, :markershape, replace(string(a), "_" => "-"))
            else
                markercolor = a′
            end
        elseif T <:  _RGB
            markercolor = a
        elseif T <: RGB || T <: RGBA
            markercolor = rgb(a)
        elseif T <: Number
            if T <: Integer
                _set(d, :markersize, a)
            end
            0 < a < 1 && (markeralpha = a)
        end
    end
    if  !isnothing(markeralpha)
        if isa(markercolor, Union{String,Symbol})
            markercolor = rgb(markercolor, markeralpha)
        else
            _set(d, :opacity, markeralpha)
        end
    end
    _set(d, :markercolor, markercolor)
    =#

    kws = kwargs
    kws = _line_magic(; kws...)
    kws = _fill_magic(; kws...)
    kws = _marker_magic(; kws...)
    kws = _color_magic(; kws...)

    # covert back
    kws = merge(Dict(kws...), d)
    nt = NamedTuple(kws)
    Base.Pairs(nt, keys(nt))

end
