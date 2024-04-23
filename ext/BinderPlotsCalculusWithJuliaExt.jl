module BinderPlotsCalculusWithJuliaExt

import CalculusWithJulia
import CalculusWithJulia:
    plotif,
    plot_parametric, plot_parametric!,
    plot_polar, plot_polar!,
    plot_implicit_surface,
    implicit_plot, implicit_plot!,
    newton_vis, newton_plot!,
    riemann_plot, riemann_plot!

using BinderPlots

# plotif
function CalculusWithJulia.plotif(f, g, a::Real, b::Real; kwargs...)
    title = "Plot of f colored when g ≥ 0"
    h = x -> g(x) ≥ 0 ? f(x) : NaN
    BinderPlots.plot([f, h], a, b; title, kwargs...)
end



# plot_parametric
function plot_parametric(ab, r::Function; kwargs...)
    p, kwargs = BinderPlots._new_plot(; kwargs...)
    plot_parametric!(p, ab, r; kwargs...)
end

plot_parametric!(ab, r::Function; kwargs...) = plot_parametric!(current(), ab, r; kwargs...)
function plot_parametric!(p::BinderPlots.Plot, ab, r::Function; kwargs...)
    ts = range(extrema(ab)..., 251)
    xyzₛ = BinderPlots.unzip(r.(ts))
    BinderPlots.plot!(xyzₛ...; kwargs...)
end



# plot_polar
function plot_polar(ab, r::Function; kwargs...)
    p, kwargs = BinderPlots._new_plot(; kwargs...)
    plot_polar!(p, ab, r; kwargs...)
end

plot_polar!(ab, r::Function; kwargs...) = plot_polar!(current(), ab, r; kwargs...)
plot_polar!(p::BinderPlots.Plot, ab, r::Function; kwargs...) =
    plot_parametric!(p, ab, t -> (r(t)*cos(t), r(t)*sin(t)); kwargs...)


# implicit_plot
CalculusWithJulia.implicit_plot(args...;kwargs...) =
    BinderPlots.plot_implicit(args...; kwargs...)

CalculusWithJulia.implicit_plot!(args...;kwargs...) =
    BinderPlots.plot_implicit!(args...; kwargs...)


# plot_implicit_surface
Contour = CalculusWithJulia.Contour
function plot_implicit_surface(F, c=0;
                       xlim=(-5,5), ylim=xlim, zlim=xlim,
                       nlevels=25,         # number of levels in a direction
                       slices=Dict(:z => :blue), # Dict(:x => :color, :y=>:color, :z=>:color)
                       kwargs...          # passed to initial `plot` call
                       )

    _linspace(rng, n=150) = range(extrema(rng)..., n)

    X1, Y1, Z1 = _linspace(xlim), _linspace(ylim), _linspace(zlim)

    p = BinderPlots.plot(;legend=false,kwargs...)

    if :x ∈ keys(slices)
        for x in _linspace(xlim, nlevels)
            local X1 = [F(x,y,z) for y in Y1, z in Z1]
            cnt = Contour.contours(Y1,Z1,X1, [c])
            for line in Contour.lines(Contour.levels(cnt)[1])
                ys, zs = Contour.coordinates(line) # coordinates of this line segment
                BinderPlots.plot!(p, x .+ 0 * ys, ys, zs, linecolor=slices[:x])
          end
        end
    end

    if :y ∈ keys(slices)
        for y in _linspace(ylim, nlevels)
            local Y1 = [F(x,y,z) for x in X1, z in Z1]
            cnt = Contour.contours(Z1,X1,Y1, [c])
            for line in Contour.lines(Contour.levels(cnt)[1])
                xs, zs = Contour.coordinates(line) # coordinates of this line segment
                BinderPlots.plot!(p, xs, y .+ 0 * xs, zs, linecolor=slices[:y])
            end
        end
    end

    if :z ∈ keys(slices)
        for z in _linspace(zlim, nlevels)
            local Z1 = [F(x, y, z) for x in X1, y in Y1]
            cnt = Contour.contours(X1, Y1, Z1, [c])
            for line in Contour.lines(Contour.levels(cnt)[1])
                xs, ys = Contour.coordinates(line) # coordinates of this line segment
                BinderPlots.plot!(p, xs, ys, z .+ 0 * xs, linecolor=slices[:z])
            end
        end
    end


    p
end

## ----

## simple visualizations; should include from somewhere
# don't like should just provide ! method
function newton_vis(f, x0, a=Inf,b=-Inf; steps=5, kwargs...)
    xs = Float64[x0]
    for i in 1:steps
        push!(xs, xs[end] - f(xs[end]) / f'(xs[end]))
    end

    m,M = extrema(xs)
    m = min(m, a)
    M = max(M, b)

    p = plot(f, m, M; linewidth=3, legend=false, kwargs...)
    plot!(p, zero)
    for i in 1:steps
        plot!(p, [xs[i],xs[i],xs[i+1]], [0,f(xs[i]), 0])
        scatter!(p, xs[i:i],[0])
    end
    scatter!(p, [xs[steps+1]], [0])
    p
end

subscript(i) = string.(collect("₀₁₂₃₄₅₆₇₈₉"))[i+1]
function newton_plot!(f, x0; steps=5, annotate_steps::Int=0,
                     fill=nothing,kwargs...)
    xs, ys = Float64[x0], [0.0]
    for i in 1:steps
        xᵢ = xs[end]
        xᵢ₊₁ = xᵢ - f(xᵢ)/f'(xᵢ)
        append!(xs, [xᵢ, xᵢ₊₁]), append!(ys, [f(xᵢ), 0])
    end
    plot!(xs, ys; fill, kwargs...)

    scatter!(xs[1:1], ys[1:1]; marker=(:diamond, 10))
    pts = xs[3:2:end]
    scatter!(pts, zero.(pts); marker=(:circle, 8))

    if annotate_steps > 0
        anns = [(x,0,text("x"*subscript(i-1),18,:bottom)) for
                (i,x) ∈ enumerate(xs[1:2:2annotate_steps])]
        annotate!(anns)
    end
    current()
end


function riemann_plot(f, a, b, n; method="right", fill=nothing, kwargs...)
    plot(f, a, b; legend=false, kwargs...)
    riemann_plot!(f, a, b, n; method, fill, kwargs...)
end

# riemann_plot!(sin, 0, pi/2, 2; method="simpsons", fill=(:green, 0.25, 0))
function riemann_plot!(f, a, b, n; method="right",
                      linecolor=:black, fill=nothing, kwargs...)
    if method == "right"
        shape = (l, r, f) -> begin
            Δ = r - l
            Shape(l .+ [0, Δ, Δ, 0, 0], [0, 0, f(r), f(r), 0])
        end
    elseif method == "left"
        shape = (l, r, f) -> begin
            Δ = r - l
            Shape(l .+ [0, Δ, Δ, 0, 0], [0, 0, f(l), f(l), 0])
        end
    elseif method == "trapezoid"
        shape = (l, r, f) -> begin
            Δ = r - l
            Shape(l .+ [0, Δ, Δ, 0, 0], [0, 0, f(r), f(l), 0])
        end
    elseif method == "simpsons"
        shape = (l, r, f) -> begin
            Δ = r - l
            a, b, m = l, r, l + (r-l)/2
            parabola = x -> begin
                tot =  f(a) * (x-m) * (x-b) / (a-m) / (a-b)
                tot += f(m) * (x-a) * (x-b) / (m-a) / (m-b)
                tot += f(b) * (x-a) * (x-m) / (b-a) / (b-m)
                tot
            end
            xs = range(0, Δ, 3)
            Shape(l .+ vcat(reverse(xs), xs, Δ),
                  vcat(zero.(xs), parabola.(l .+ xs), 0))
        end
    end
    xs = range(a, b, n + 1)
    ls, rs = Base.Iterators.take(xs, n), Base.Iterators.rest(xs, 1)
    for (l, r) ∈ zip(ls, rs)
        plot!(shape(l, r, f); linecolor, fill, kwargs...)
    end
    current()
end


end
