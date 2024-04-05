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
_adjust_matrix(m::Matrix) = collect(eachrow(m))
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
_replace_infinite(y) = [isfinite(yᵢ) ? yᵢ : nothing for yᵢ ∈ y]

# pick out symbol
_valtype(::Val{T}) where {T} = T

# xyziterator
struct XYZ{X,Y,Z}
    x::X
    y::Y
    z::Z
    n::Integer
end

# how many traces does the data represent
# when there can be more than one
ntraces(x) =  last(size(x))
ntraces(::Nothing) = 0
ntraces(::Tuple) = 1
ntraces(::AbstractVector) = 1
ntraces(x::AbstractVector{T}) where {T <: Function} = length(x)
ntraces(::Function) = 1
ntraces(::Number) = 1

# use Tables.
_eachcol(x::Matrix) = [x[:,i] for i in 1:size(x)[2]]
_eachcol(x::Vector) = (x,)
_eachcol(x::Vector{T}) where {T <: Function} = x
_eachcol(x::Tuple) = (x,)
_eachcol(x::AbstractRange) = (x,)
_eachcol(::Nothing) = nothing
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
Recycler(x) =  Recycler(x, length(x))
Recycler(::Nothing) =  Recycler([nothing],1)
Recycler(x::Symbol) = Recycler((x,))
Recycler(x::AbstractString) = Recycler((x,))

function Base.getindex(R::Recycler, i::Int)
    q, r = divrem(i, R.n)
    idx = iszero(r) ? R.n : r
    R.itr[idx]
end


function Recycler(kw::Base.Pairs)
    y = Base.Pairs((;zip(keys(kw), [BinderPlots.Recycler(kw[k]) for k in keys(kw)])...), keys(kw))
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
