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
SeriesType(::Val{:path3d}) = (:scatter, :lines)

function plot!(::Val{:scatter}, p::Plot, x=nothing, y=nothing, z=nothing;
               seriestype::Symbol=:lines,
               kwargs...)
    _,mode = SeriesType(seriestype)
    KWs = Recycler(kwargs)
    for (i, xyzₛ) ∈ enumerate(xyz(x,y,z))
        kws = _make_magic(; KWs[i]...)
        plot!(Val(:scatter), Val(Symbol(mode)), p, xyzₛ...; kws...)
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
    kws = _trace_styles!(c; kwargs...)
    _merge!(c; kws...)

    push!(p.data, c)
    nothing
end

# plot matrix by padding ut
function plot!(t::Val{:scatter}, p::Plot,
               x::AbstractMatrix, ::Nothing, ::Nothing; kwargs...)
    m, n = size(x)
    plot!(t, p, 1:m, x, nothing; kwargs...)
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

##
function plot!(t::Val{:scatter}, p::Plot,
               f::Function, g::Function, a, b; kwargs...)
    @show :hi
end



# Recipe for pts style
# different from Plots which fill in 1:m for values
function plot!(t::Val{:scatter}, m::Val{M}, p::Plot, x, y::Nothing, z::Nothing; kwargs...) where {M}
    plot!(t, m, p, unzip(x)...; kwargs...)
end
