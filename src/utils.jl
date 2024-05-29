# utils and types
function _merge!(c::Config; kwargs...)
    for kv ∈ kwargs
        k,v = kv
        v = isa(v,Pair) ? last(v) : v
        isnothing(v) && continue
        c[k] = v
    end
end
function _merge!(c::Config, d::Config)
    for (k, v) ∈ d
        c[k] = v
    end
end

function _join!(xs, delim="")
    xs′ = filter(!isnothing, xs)
    isempty(xs′) && return nothing
    join(string.(xs′), delim)
end

# helper
_adjust_matrix(m::AbstractMatrix) = collect(eachrow(m))
_adjust_matrix(x::Any) = x

# from some.jl
_something() = nothing
_something(x::Nothing, xs...) = _something(xs...)
_something(x::Any, xs...) = x
# from Missing.jl

_allowmissing(x::AbstractArray{T}) where {T} = convert(AbstractArray{Union{T, Missing}}, x)

## ---
# utils
_replace_infinite(f::Function) = f
_replace_infinite(::Nothing) = nothing
_replace_infinite(::Missing) = nothing
_replace_infinite(y) = [!ismissing(yᵢ) && isfinite(yᵢ) ? yᵢ : nothing for yᵢ ∈ y]

# pick out symbol
_valtype(::Val{T}) where {T} = T

# xyziterator
struct XYZ{X,Y,Z}
    x::X
    y::Y
    z::Z
    n::Integer
end

"""
    Series(xs₁, xs₂, …)

Struct to indicate traces in a series.
Can be used in place of matrix to combine mismatched sizes, e.g.

```
scatter(BinderPlots.Series(1:3, 1:5), markersize=(20,10))
```

Not exported.
"""
struct Series
    ss
    Series(as...) = new(as)
end

# how many traces does the data represent
# when there can be more than one
ntraces(x) =  1
ntraces(::Nothing) = 0
ntraces(::Tuple) = 1
ntraces(x::AbstractMatrix) = last(size(x))
ntraces(::AbstractVector) = 1
ntraces(x::AbstractVector{T}) where {T <: Function} = length(x)
ntraces(::Function) = 1
ntraces(::Number) = 1
ntraces(x::Series) = length(x.ss)
ntraces(x::Vector{Vector{T}}) where {T <: Real} = length(x)

# use Tables.
_eachcol(x::AbstractMatrix) = [x[:,i] for i in 1:size(x)[2]]
_eachcol(x::Vector) = (x,)
_eachcol(x::Vector{T}) where {T <: Function} = x
_eachcol(x::Tuple) = (x,)
_eachcol(x::AbstractRange) = (x,)
_eachcol(x::Series) = x.ss
_eachcol(::Nothing) = nothing
_eachcol(x::Vector{Vector{T}}) where {T<:Real} = [xᵢ for xᵢ ∈ x]
_eachcol(x) = (x,)

# make a reccyler for x,y,z values
function xyz(x,y=nothing,z=nothing)
    ns = ntraces.((x,y,z))
    allequal(filter(>(1), ns)) || throw(ArgumentError("mismatched dimensions"))
    n = maximum(ns)
    XYZ(Recycler(_eachcol(x)),
        Recycler(_eachcol(y)),
        Recycler(_eachcol(z)), n)
end

function Base.iterate(xyz::XYZ, state=nothing)
    n = xyz.n
    i = isnothing(state) ? 1 : state
    iszero(n) && return nothing
    i > n && return nothing
    return((x=xyz.x[i], y=xyz.y[i], z=xyz.z[i]), i+1)
end





## ----
function Base.extrema(p::Plot)
    mx,Mx = (Inf, -Inf)
    my,My = (Inf, -Inf)
    mz,Mz = (Inf, -Inf)
    for d ∈ p.data
        if haskey(d, :x) && !isnothing(d.x)
            a,b = extrema(d.x)
            mx = min(a, mx); Mx = max(b, Mx)
        end
        if haskey(d, :y)  && !isnothing(d.y)
            a,b = extrema(filter(!isnothing, d.y))
            my = min(a, my); My = max(b, My)
        end
        if !haskey(d, :z) && !isnothing(d.z)
            a,b = extrema(filter(!isnothing, d.z))
            mz = min(a, mz); Mz = max(b, Mz)
        end

    end
    x = isempty(p.layout.xaxis.range) ? (mx,Mx) : p.layout.xaxis.range
    y = isempty(p.layout.yaxis.range) ? (my,My) : p.layout.yaxis.range
    z = isempty(p.layout.zaxis.range) ? (mz,Mz) : p.layout.zaxis.range
    (; x, y, z)
end

struct Recycler{T}
    itr::T
    n::Int
end

_ndims(x) = ndims(x)

Recycler(x) =  Recycler(x, length(x))
Recycler(::Nothing) =  Recycler([nothing],1)
Recycler(x::Symbol) = Recycler((x,))
Recycler(x::AbstractString) = Recycler((x,))
Recycler(x::PlotUtils.Colors.RGB) = Recycler((x,))

function Base.iterate(r::BinderPlots.Recycler, state=nothing)
    isnothing(state) && return (r[1],2)
    return (r[state],state+1)
end


function Base.getindex(R::Recycler, i::Int)
    q, r = divrem(i, R.n)
    idx = iszero(r) ? R.n : r
    R.itr[idx]
end


function Recycler(kw::Base.Pairs)
    rs = [KWRecycler(Val(k), kw[k]) for k in keys(kw)]
    y = Base.Pairs((;zip(keys(kw), rs)...), keys(kw))
    Recycler(y, 0)
end

function Base.getindex(R::Recycler{T}, i::Int) where {T <: Base.Pairs}
    ks = keys(R.itr)
    vals = [R.itr[k][i] for k in ks]
    Base.Pairs((; zip(ks, vals)...), ks)
end




## -----
# what is a good heuristic to identify vertical lines?

## -----

include("SplitApplyCombine_invert.jl")

"""
    unzip(v, [vs...])
    unzip(f::Function, a, b)
    unzip(a, b, F::Function)

Reshape data to x,y,[z] mode.

In its basic use, `zip` takes two vectors, pairs them off, and returns an iterator of tuples for each pair. For `unzip` a vector of same-length vectors is "unzipped" to return two (or more) vectors.

The function version applies `f` to a range of points over `(a,b)` and then calls `unzip`. This uses the `adapted_grid` function from `PlotUtils`.

The function version with `F` computes `F(a', b)` and then unzips. This is used with parameterized surface plots

This uses the `invert` function of `SplitApplyCombine`.
"""
unzip(vs) = invert(vs) # use SplitApplyCombine.invert (copied below)
unzip(vs::Base.Iterators.Zip) = vs.is
#unzip(v,vs...) = unzip([v, vs...])
unzip(@nospecialize(r::Function), a, b, n) = unzip(r.(range(a, stop=b, length=n)))
# return (xs, f.(xs)) or (f₁(xs), f₂(xs), ...)
function unzip(f::Function, a, b)
    @nospecialize
    n = length(f(a))
    if n == 1
        return PlotUtils.adapted_grid(f, (a,b))
    else
        xsys = [PlotUtils.adapted_grid(x->f(x)[i], (a,b)) for i ∈ 1:n]
        xs = sort(vcat([xsys[i][1] for i ∈ 1:n]...))
        return unzip(f.(xs))
    end

end
# return matrices for x, y, [z]
unzip(as, bs, F::Function) = unzip(F.(as', bs))



## ====

# hold text and font
struct TextFont{S,F}
    str::S
    font::F
end
Base.string(lab::TextFont) = lab.str
"""
    text(str, args...; kwargs...)
    text(str, f::Font)

Create text with font information to be passed to labeling functions.

* `f::Font`: object produced by [`font`](@ref)
* `args...`, `kwargs...`: passed to `font` to create font information. The positional arguments are matched by type.
"""
text(str, args...; kwargs...) = TextFont(str, font(args...; kwargs...))
text(t::TextFont, args...; kwargs...) = t

struct Font{F,PS,HA,VA,R,C}
    family::F
    pointsize::PS
    halign::HA
    valign::VA
    rotation::R
    color::C
end

## Would like to use Colors.RGB[a] for colors *but*
## it isn't clear how to get this to write correctly
## *without* type piracy, so we make our own little one:

struct _RGB
    r::Float64
    g::Float64
    b::Float64
    α::Float64
end

"""
    rgb(r,g,b,α=1.0)
    rgb(c::Union{RGB, RGBA}) # RGB[A] from Colors.jl
    rgb(::Symbol, α)
    colormap(cname, N; kwargs...)

Specify red, green, blue values between 0 and 255 (as integers). The transparency is specified by the 4th argument, a value in [0.0,1.0].

The range operator can be used with color to produce a sequence, following `Colors.range` for `RGB[A]` values. (It is not lazy, so don't take `length` to be too large.)

The `colormap` function returns a colormap of length 10 using `Colors.colormap`.

"""
function rgb(r::Int, g::Int, b::Int, α=1.0)
    _RGB(r/255, g/255, b/255, clamp(α,0.0,1.0))
end
Recycler(x::_RGB) = Recycler((x,))

function Base.convert(::Type{_RGB}, c::PlotUtils.Colors.RGB)
    (; b,g,r) = c
    _RGB(b,g,r,1.0)
end
function Base.convert(::Type{_RGB}, c::PlotUtils.Colors.RGBA)
    (; b,g,r,alpha) = c
    _RGB(b,g,r,alpha)
end
rgb(c::PlotUtils.Colors.RGB) = convert(_RGB, c)
rgb(c::PlotUtils.Colors.RGBA) = convert(_RGB, c)
rgb(c::Symbol, α=1.0) = _RGB(PlotUtils.Colors.color_names[string(c)]..., α)
rgb(c::Symbol, ::Nothing) = _RGB(PlotUtils.Colors.color_names[string(c)]..., 1.0)
rgb(c::AbstractString, α=1.0) = startswith(c, r"#|rgb") ? c * string(round(Int, 255*α), base=16) : rgb(Symbol(c), α)
rgb(c::AbstractString, ::Nothing) = startswith(c, r"#|rgb") ? c : rgb(Symbol(c), nothing)
rgb(r::_RGB, α=1.0) = _RGB(r.r,r.g,r.b,α)
rgb(r::_RGB, ::Nothing) = r
rgb(::Nothing, ::Any) = nothing

PlotlyLight.StructTypes.StructType(::Type{_RGB}) = PlotlyLight.StructTypes.StringType()
function Base.string(c::_RGB)
    (;r,g,b,α) = c
    "rgba($r,$g,$b,$α)"
end

# make a colormap
function colormap(cname, N=100; kwargs...)
    if !(cname ∈ ("Blues", "Greens", "Grays", "Oranges", "Purples", "Reds", "RdBu"))
        @warn "incorrect colormap name; using RdBu"
        cname = "RdBu"
    end
    cols = PlotUtils.Colors.colormap(cname, N; kwargs...)
    convert.(_RGB, cols)
end

# not *lazy*!!
function Base.range(start::_RGB, stop::_RGB, length::Integer)
    (; r,g,b,α) = start
    c1 = PlotUtils.Colors.RGBA(r,g,b,α)
    (; r,g,b,α) = stop
    c2 = PlotUtils.Colors.RGBA(r,g,b,α)
    [rgb(c) for c ∈ range(c1, c2, length)]
end

"""
    create a BezierCurve for plotting

From Plots.jl
"""
mutable struct BezierCurve{T<:Tuple}
    control_points::Vector{T}
end

function (bc::BezierCurve)(t::Real)
    p = (0.0, 0.0)
    n = length(bc.control_points) - 1
    for i in 0:n
        p = p .+ bc.control_points[i + 1] .* binomial(n, i) .* (1 - t)^(n - i) .* t^i
    end
    p
end



## Define Shape type
## see shape.jl for methods
"""
    Shape(x, y)
    Shape(vertices)

Construct a *polygon* to be plotted.

When plotting shapes, use `stroke` argument to `fill` to adjust bounding
line properties.
"""
struct Shape{X, Y}
    x::AbstractVector{X}
    y::AbstractVector{Y}
    function Shape(x::X,y::Y) where {X, Y}
        length(x) == length(y) || throw(ArgumentError("Need same length objects"))
        x′, y′ = float(x), float(y)
        X′, Y′ = eltype(x′), eltype(y′)
        new{X′,Y′}(x′, y′)
    end
end

function Shape(xy)
    Shape(unzip(xy)...)
end

Base.copy(s::Shape) = Shape(copy(s.x), copy(s.y))
