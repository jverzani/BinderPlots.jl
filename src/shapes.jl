# Plots for making polygons
## use Shape
## lots of this lifted from Plots.jl (components.jl)
## in Plots several pre-defined shapes

# Some shape types
# :square, :circle, :diamond, :star
function Shape(s::Symbol, args...)
    Shape(Val(s), args...)
end
Base.extrema(s::Shape) = (x=extrema(s.x), y=extrema(s.y))

Shape(::Val{:unitsquare}, args...) = Shape([0,1,1,0],[0,0,1,1])

# unit circle shapes
function Shape(::Val{:ngon}, n, offset=0, args...)
    θs = range(offset*pi + 0, offset*pi + 2pi, n+1)
    Shape(sin.(θs), cos.(θs))
end
partialcircle(start_θ, end_θ, n = 20, r = 1) =
    [(r * cos(u), r * sin(u)) for u in range(start_θ, stop = end_θ, length = n)]
Shape(::Val{:circle}, args...)   = Shape(Val(:ngon), 100)
Shape(::Val{:triangle}, args...) = Shape(Val(:ngon),3)
Shape(::Val{:diamond}, args...) = Shape(Val(:ngon),4)
Shape(::Val{:rect}, args...) = Shape(Val(:ngon),4,1/4)
Shape(::Val{:pentagon}, args...) = Shape(Val(:ngon),5)
Shape(::Val{:hexagon}, args...)  = Shape(Val(:ngon),5)
Shape(::Val{:heptogon}, args...) = Shape(Val(:ngon),7)
Shape(::Val{:octagon}, args...)  = Shape(Val(:ngon),8)

Shape(::Val{:hline}) = Shape([-1,1],[0,0])
Shape(::Val{:vline}) = Shape([0,0], [-1,1])

function Shape(::Val{:star}, n=5, r = 1/4, args...)
    θs = range(0, 2pi, 2n+1)
    xs = zeros(Float64, 2n)
    ys = zeros(Float64, 2n)
    for i ∈ 1:n
        j = 2i
        ys[j-1], xs[j-1] = sincos(θs[j-1])
        ys[j], xs[j] = r .* sincos(θs[j])
    end
    s = Shape(xs, ys)
    k = mod(n, 4)
    # stand up straight
    k == 1 && rotate!(s,  pi / (2n))
    k == 2 && rotate!(s,  pi / n)
    k == 3 && rotate!(s, -pi / (2n))
    s
end
Shape(::Val{:star4}, args...) = Shape(Val(:star), 4)
Shape(::Val{:star5}, args...) = Shape(Val(:star), 5)
Shape(::Val{:star6}, args...) = Shape(Val(:star), 6)
Shape(::Val{:star7}, args...) = Shape(Val(:star), 7)
Shape(::Val{:star8}, args...) = Shape(Val(:star), 8)

function Shape(::Val{:rounded_square}, k=5, args...) # maybe for text bubbles?
    ts = range(0, pi/2,21)
    xs,ys = (cos.(ts).^(1/k)), (sin.(ts).^(1/k))
    return Shape(vcat(xs, -reverse(xs), -xs, reverse(xs)),
                 vcat(ys, reverse(ys), -ys, -reverse(ys)))
end

## ---- transformations

"""
    scale(s::Shape, x, y=x)
    scale!(s::Shape, x, y=x)

Scale in x and y direction
"""
scale(s::Shape, x, y = x, c = center(s)) =  scale!(copy(s), x, y, c)
function scale!(s::Shape, x, y=x,c=center(s))
    sx, sy = s.x, s.y
    cx, cy = c
    for i in eachindex(sx)
        sx[i] = (sx[i] - cx) * x + cx
        sy[i] = (sy[i] - cy) * y + cy
    end
    s
end

"""
    rotate(s::Shape, θ, c=center(s))
    rotate!(s::Shape, θ, c=center(s))

Rotate shape about its center ccw by angle θ
"""
rotate(s::Shape, θ, c=center(s)) = rotate!(copy(s), θ, c)
function rotate!(s::Shape, θ, c=center(s))
    (;x, y) = s
    for i in eachindex(x)
        xi = rotate_x(x[i], y[i], θ, c...)
        yi = rotate_y(x[i], y[i], θ, c...)
        x[i], y[i] = xi, yi
    end
    s
end
rotate_x(x,y,θ,cx,cy) = ((x - cx) * cos(θ) - (y - cy) * sin(θ) + cx)
rotate_y(x,y,θ,cx,cy) = ((y - cy) * cos(θ) + (x - cx) * sin(θ) + cy)

"""
    translate(s::Shape, x, y=x)
    translate!(s::Shape, x, y=x)

Shift shape over by x, up by y
"""
translate(s::Shape, x, y=x) = translate!(copy(s), x, y)
function translate!(s::Shape, x, y=x)
    s.x .+= x
    s.y .+= y
    s
end

function invert!(s::Shape, axis::Symbol)
    (; x, y) = s
    axis == :xy && return invert!(invert!(s,:x),:y)
    axis == :x && (y .*= -1)
    axis == :y && (x .*= -1)
    s
end
shear(s::Shape, k) = shear!(copy(s), k)
function shear!(s::Shape, k)
    (;x, y) = s
    x .+= (k .* y)
    s
end

# uses the centroid calculation from https://en.wikipedia.org/wiki/Centroid#Centroid_of_polygon (cf. Plots.jl)
"return the centroid of a Shape"
function center(s::Shape)
    (; x, y) = s
    n = length(x)
    A, Cx, Cy = 0, 0, 0
    for i in 1:n
        ip1 = i == n ? 1 : i + 1
        A += x[i] * y[ip1] - x[ip1] * y[i]
    end
    A *= 0.5
    for i in 1:n
        ip1 = i == n ? 1 : i + 1
        m = (x[i] * y[ip1] - x[ip1] * y[i])
        Cx += (x[i] + x[ip1]) * m
        Cy += (y[i] + y[ip1]) * m
    end
    iszero(A) ? (Cx, Cy) : (Cx / 6A, Cy / 6A)
end

function center!(s::Shape)
    a,b = center(s)
    translate!(s, -a, -b)
end


## ---- render shapes
# Shape ignores line properties not given in `stroke`
function plot!(t::Val{:scatter}, m::Val{:lines}, p::Plot, x::Shape,
               y::Nothing, z::Nothing;
               line=nothing,
               linewidth=nothing, linecolor=nothing, linestyle=nothing,
               fillstyle=nothing,
               kwargs...)
    xs, ys = x.x, x.y
    if (first(xs) != last(xs)) || (first(ys) != last(ys))
        push!(xs, first(xs))
        push!(ys, first(ys))
    end

    fillstyle = something(fillstyle, :toself)

    plot!(t, m, p, xs, ys; fillstyle, kwargs...)
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

# ribbon tuple -> two sided, else ...
# ribbon has strokewidth 0 by default; use stroke to change
# Ribbon is **not** the same a Plots.jl
# * called with a seriestype
# * when multiple seriestypes, the arguments may get mixed up
# * not called with multiple series
# XXX ribbon(x,y,r1,r2?)

#SeriesType(::Val{:ribbon}) =  (:scatter, :ribbon)
#function plot!(t::Val{:scatter}, m::Val{:ribbon}, p::Plot, x, y, z::Nothing;
SeriesType(::Val{:ribbon}) =  (:ribbon, :ribbon)
function plot!(t::Val{:ribbon}, m::Val{:ribbon}, p::Plot, x, y, z::Nothing;
               ribbon=nothing,

               fill = nothing,
               kwargs...)

    # make shape(s); plot shape(s)
    T,S = float(eltype(x)), float(eltype(y))
    ss = Shape{T,S}[]
    xs, ysu, ysl = T[], S[], S[]
    inshape = true
    ru,rl = (first(ribbon), last(ribbon))
    ruc = Recycler(ru)
    rlc = Recycler(rl)
    for (i,(xi,yi)) ∈ enumerate(zip(x,y))
        if inshape
            if isfinite(yi)
                push!(xs,  xi)
                push!(ysu, yi + ruc[i])
                push!(ysl, yi - rlc[i])
            else
                S = Shape(vcat(xs, reverse(xs)), vcat(ysl, reverse(ysu)))
                push!(ss, S)
                empty!(xs); empty!(ysu); empty!(ysl)
                inshape = false
            end
        else
            if isfinite(yi)
                push!(xs,  xi)
                push!(ysu, yi + ruc[i])
                push!(ysl, yi - rlc[i])
                inshape = true
            end
        end
    end
    if inshape
        S = Shape(vcat(xs, reverse(xs)), vcat(ysl, reverse(ysu)))
        push!(ss, S)
    end

    for S ∈ ss
        # dispatch so magic arguments go through
        plot!(Val(:scatter), Val(:lines), p, S, nothing, nothing;
              linewidth=0, fill,
              kwargs...)
    end

    p
end

# xerror and yerror are seriestypes, not just arguments
# must call
SeriesType(::Val{:xerror}) =  (:xerror, :xerror)
SeriesType(::Val{:yerror}) =  (:yerror, :yerror)
function plot!(t::Val{:xerror}, m::Val{:xerror}, p::Plot, x, y, z::Nothing;
               xerror = nothing,
               kwargs...)
    isnothing(xerror) && return p # do nothing
    σ = xerror                    # could make two sided...
    S = Shape(:vline)
    ss = typeof(S)[]
    for (σi, xi,yi) ∈ zip(Recycler(xerror), x,y)
        !isfinite(yi) && continue
        push!(ss, translate(scale(S, 1, σi), xi, yi))
    end
    for S ∈ ss
        plot!(Val(:scatter), Val(:lines), p, S, nothing, nothing;
              kwargs...)
    end

    p
end
function plot!(t::Val{:yerror}, m::Val{:yerror}, p::Plot, x, y, z::Nothing;
               yerror = nothing,
               kwargs...)

    isnothing(yerror) && return p # do nothing
    S = Shape(:hline)
    ss = typeof(S)[]
    for (σi, xi,yi) ∈ zip(Recycler(yerror), x,y)
        !isfinite(yi) && continue
        push!(ss, translate(scale(S, σi, 1), xi, yi))
    end

    for S ∈ ss
        plot!(Val(:scatter), Val(:lines), p, S, nothing, nothing;
              kwargs...)
    end

    p
end
