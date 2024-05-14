##
## Line and scatter plots of
## * (x,y) data
## * f:𝐑 → 𝐑 over [a,b]
##
## Differences from Plots.jl
## (It may not seem like  much, but many of the examples at
## https://github.com/JuliaPlots/Plots.jl/blob/master/src/examples.jl
## expect these to work)
## * plot(y) for data does not work; instead a recipe for plot(pts)
##   is given
## * plot(f, g, a, b) does not work (errors); use plot((f,g), a, b) for
##   parametric plots (or plot(f.(ts), g.(ts)))
## * magic arguments are not vectorized, as they are in Plots
## * markers are not as flexible; there are no markerstrokeXXX things or stroke
##
# scatter type
# this step recycles arguments and x,y,z values
SeriesType(::Val{:lines}) =  (:scatter, :lines)
SeriesType(::Val{:path}) =  (:scatter, :lines) # is this correct?
SeriesType(::Val{:sticks}) =  (:scatter, :sticks)
SeriesType(::Val{:path3d}) = (:scatter, :lines)

function plot!(::Val{:scatter}, p::Plot, x=nothing, y=nothing, z=nothing;
               seriestype::Symbol=:lines,
               kwargs...)
    _,mode = SeriesType(seriestype)
    KWs = Recycler(kwargs)
    for (i, xyzₛ) ∈ enumerate(xyz(x,y,z))
        plot!(Val(:scatter), Val(Symbol(mode)), p, xyzₛ...; KWs[i]...)
    end
    p
end

# scatter/3d type
# generic one
function plot!(::Val{:scatter}, m::Val{T}, p::Plot, x, y, z=nothing; kwargs...) where {T}
    mode = _valtype(m)
    type = isnothing(z) ? "scatter" : "scatter3d" # XXX not general?

    c = Config(;
               x=_replace_infinite(x),
               y=_replace_infinite(y),
               z=_replace_infinite(z),
               type,
               mode=mode)
    kws = _make_magic(; kwargs...)
    kws = _series_styles(c; kws...)
    kws = _trace_styles!(c; kws...)
    _merge!(c; kws...)

    push!(p.data, c)
    nothing
end

# plot vector by adding x
function plot!(t::Val{:scatter}, m::Val{M}, p::Plot, x::AbstractVector{<:Real}, y::Nothing, z::Nothing; kwargs...) where {M}
    plot!(t, m, p, eachindex(x),x; kwargs...)
end


# plot matrix by padding ut
function plot!(t::Val{:scatter}, p::Plot,
               x::AbstractMatrix{<:Real}, ::Nothing, ::Nothing; kwargs...)
    m, n = size(x)
    plot!(t, p, axes(m, 1), x, nothing; kwargs...)
end


# recipe(s) for function f,[a],[b]
# XXX a little lower than desirable
function plot!(t::Val{:scatter}, m::Val{M}, p::Plot,
               f::Function, y, z; kwargs...) where {M}
    plot!(t, m, p, unzip(f, extrema((y,z))...)...; kwargs...)
end

function plot!(t::Val{:scatter}, m::Val{M}, p::Plot,
               f::Function, y, ::Nothing; kwargs...) where {M}
    plot!(t, m, p, f, extrema(y)...; kwargs...)
end

function plot!(t::Val{:scatter}, m::Val{M}, p::Plot,
               f::Function, y::Nothing, ::Nothing; kwargs...) where {M}
    a, b= extrema(p).x
    plot!(t, m, p, unzip(f, a, b)...; kwargs...)
end

## parametric
function plot!(t::Val{:scatter}, m::Val{M}, p::Plot,
               fs::NTuple{N,Function}, y, z; npts::Integer = 251,
               kwargs...) where {M,N}
    2 ≤ N ≤ 3 || throw(ArgumentError("parametric plots needs 2 or 3 functions"))
    ts = range(y,z,length=npts)
    plot!(t, m, p, (f.(ts) for f ∈ fs)...; kwargs...)
end

function plot!(t::Val{:scatter}, m::Val{M}, p::Plot,
               fs::NTuple{N,Function}, y, ::Nothing; kwargs...) where {M,N}
    plot!(t, m, p, fs, extrema(y)...; kwargs...)
end

function plot!(t::Val{:scatter}, m::Val{M}, p::Plot,
               fs::NTuple{N,Function}, ::Nothing, ::Nothing; kwargs...) where {M,N}
    throw(ArgumentError("parametric plots needs 2 or 3 functions"))
end

## # should just error
function plot!(p::Plot,
               f::Function, g::Function, as...; kwargs...)
    @warn "use a tuple, `(f,g)`, to specify a parametric plot"
    plot!(p, (f,g), as...; kwargs...)
end
function plot!(p::Plot,
               f::Function, g::Function, h::Function , as...)
    @warn "use a tuple, `(f,g,h)`, to specify a parametric plot"
    plot!(p, (f,g,h), as...; kwargs...)
end

# sticks
function plot!(t::Val{:scatter}, m::Val{:sticks}, p::Plot, x, y, z::Nothing; kwargs...)
    n, T = length(x), eltype(x)
    xs = Float64[]
    ys = Float64[]
    for (xᵢ, yᵢ) ∈ zip(x,y)
        append!(xs, [xᵢ,xᵢ, NaN])
        append!(ys, [0, yᵢ, yᵢ])
    end
    plot!(t, Val(:lines), p,xs, ys, nothing; kwargs...)
    plot!(t, Val(:markers), p, x, y, nothing; kwargs...)
    p
end

# Shape recipes
function plot!(t::Val{:scatter}, m::Val{:lines}, p::Plot, x::Shape, y::Nothing, z::Nothing; kwargs...)
    xs, ys = x.x, x.y
    if (first(xs) != last(xs)) || (first(ys) != last(ys))
        push!(xs, first(xs))
        push!(ys, first(ys))
    end
    plot!(t, m, p, xs, ys; kwargs...)
end


function plot!(t::Val{:scatter}, p::Plot, x::AbstractVector{<:Shape}, y::Nothing, z::Nothing;
               seriestype::Symbol=:lines,
               kwargs...)

    _,mode = SeriesType(seriestype)
    KWs = Recycler(kwargs)
    for (i, s) ∈ enumerate(x)
        plot!(t, Val(Symbol(mode)),p, s; KWs[i]...)
    end
    p
end

# XXX
function plot!(t::Val{:scatter}, m::Val{M}, p::Plot, x::AbstractVector{T}, y::Nothing, z::Nothing; kwargs...) where {M,T<:Union{Missing,Real}}
    plot!(t, m, p, eachindex(x), x; kwargs...)
end

function plot!(t::Val{:scatter}, m::Val{M}, p::Plot, x::AbstractVector{T}, y::Nothing, z::Nothing; kwargs...) where {M, T <: Complex}
    plot!(t, m, p, real(x), imag(x); kwargs...)
end


# Recipe for pts style
# different from Plots which fill in 1:m for values
function plot!(t::Val{:scatter}, m::Val{M}, p::Plot, x, y::Nothing, z::Nothing; kwargs...) where {M}
    plot!(t, m, p, unzip(x)...; kwargs...)
end
