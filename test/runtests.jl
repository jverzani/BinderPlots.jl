using BinderPlots
using Test

@testset "BinderPlots.jl" begin
    u = sin
    a, b = 0, 2pi
    I = (a,b)

    # plots
    p₁ = plot(u, a, b)
    p₂ = plot(u, I)
    p₃ = scatter([1,2, NaN,4], [1,NaN, 3,4])
    plot([p₁ p₂; p₃ Plot()], legend=false)

    p = plot(u, a, b)
    xlims!(p, (1,2))
    ylims!(p, (0, 1))
    title!(p, "plot of u")
    annotate!(p, ((3/2, 1/2, "A"),), pointsize=20)

    @test isa(p, Plot)

    xs = ys = range(0, 5, length=6)
    f(x,y) = sin(x)*sin(y)
    contour(xs, ys, f)
    heatmap(xs, ys, f)
    surface(xs, ys, f)
    r(x,y) = (x, x*y, y)
    surface(unzip(xs, ys, r)...)

    nothing

end


@testset "shapes" begin
    # shapes are definitely idiosyncratic
    # 2d
    let
        p = plot()
        rect!(-1,1,0,2)
        circle!(-1/2, 1/2, 2, 3)
    end

    # hline and vline require a plot with data (not just a layout)
    let
        p = plot(sin, 0, 2pi)
        hline!.((-1, 1))
        vline!.((0,pi,2pi))
        p
    end

    # 3d
    # star connected mesh
    let
        pts = 5
        Δ = 2pi/pts/2
        a, A = 1, 3
        q = [0,0,0]
        ts = range(0, 2pi, length=pts+1)
        ps = [(A*[cos(t),sin(t),0], a*[cos(t+Δ), sin(t+Δ), 0]) for t in ts]
        xs, ys, zs = unzip(collect(Base.Iterators.flatten(ps)))
        ★(q, xs, ys, zs)
    end

    # ziptie mesh
    let
        r(t) = (sin(t), cos(t), t)
        s(t) = (sin(t+pi), cos(t+pi), t)
        ts = range(0, 4pi, length=100)
        ziptie(unzip(r.(ts))..., unzip(s.(ts))...;
               color="green", opacity=.25, showscale=false)
    end

    # parallelogram
    let
        q,v,w = [0,0,0],[1,0,0],[0,1,0]
        parallelogram(q, v, w)
    end

    # circ3d
    let
        q, n = [0,0,0], [0,0,1]
        circ3d(q, 3, n)
        arrow!(q, n)
    end

    # skirt
    let
        q, v = [0,0,0], [0,1,0]
        f(x,y) = 4 - x^2 - y^2
        skirt(q, v, f)

        r(t) = (t, sin(t), 0)
        ts = range(0, pi, length=50)
        xs, ys, zs = unzip(r.(ts))
        skirt(xs, ys, zs, f)
    end

end
