using BinderPlots
import BinderPlots: unzip, translate
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
    annotate!(p, ((3/2, 1/2, text("A", pointsize=20)),))

    @test isa(p, Plot)

    xs = ys = range(0, 5, length=6)
    f(x,y) = sin(x)*sin(y)
    contour(xs, ys, f)
    heatmap(xs, ys, f)
    surface(xs, ys, f)
    r(x,y) = (x, x*y, y)
    surface(unzip(xs, ys, r)...)

    c1,c2 = rgb(10,10,10,1), rgb(200,200,200,1)
    plot(rand(5,10); linecolor=range(c1, c2, 10))

    nothing

end

@testset "Magic" begin
    col = rgb(10,20,30,0.5)
    plot(1:5, rand(5), xticks=((1:5, string.(1:5))))
    plot(1:5, rand(5), line=(:dot, 10, 0.5, col))
    scatter(1:5, rand(5), marker=(:diamond, 10, 0.5,:red))
    f = font(:red, 20)
    title!(text("title", f))
end

@testset "shapes" begin
    # Shape is of a polygon
    square = Shape([(0, 0), (1, 0), (1, 1), (0, 1)])
    usquare = Shape(:unitsquare) # test names
    @test square.x == usquare.x  #
    @test BinderPlots.rotate(square, 2pi).x ≈ square.x  # test rotation
    @test BinderPlots.center(square) == (1/2, 1/2)      # test center
    @test BinderPlots.center(BinderPlots.translate(square, 1, 2)) == (1 + 1/2, 2 + 1/2)  # test translate


    # Other shapes are definitely idiosyncratic
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


# test of every column is series
@testset "number of series" begin
    nseries(p::Plot=current()) = length(p.data)

    # plot(x,y,z)
    xs = 1:4
    ys = [4,2,3,1]
    zs = [1,3,5,7]
    M = [1 2; 3 4; 5 6;7 8]
    a, b = 0, 2pi
    fs = [sin, cos]
    gs = [sin, cos, exp]

    # use x/y/z to indicate calling pattern below

    # matrix// each column a series against 1:size(M,1)
    plot(M)
    @test nseries() == size(M,2)

    # vector/vector/
    plot(xs, ys)
    @test nseries() == 1

    # vector/vector/vector
    plot(xs, ys, zs)
    @test nseries() == 1

    # vector/matrix/ -- each column a series
    plot(xs,M)
    @test nseries() == size(M, 2)

    # vector/matrix/matrix -- each column a series
    plot(xs,M,M)
    @test nseries() == size(M, 2)

    # matrix/matrix/ -- each column paired off
    plot(M, M)
    @test nseries() == size(M, 2)

    # matrix/matrix/matrx -- each column paired off
    plot(M,M,M)
    @test nseries() == size(M, 2)

    #/Function/[scalar]/[scalar]
    plot(first(fs), a, b)
    @test nseries() == 1

    plot(first(fs), (a, b))
    @test nseries() == 1

    # vector//
    # Plots.jl will plot as a 1-column matrix so plot(1:n, v)
    # vector{<:Real}//
    @test nseries(plot(xs)) == 1

    # /Vector{<:Function/[scalar]/[scalar] isa Vector{<:Function}
    plot(fs, a, b) # no plot(v) w/o plot(v,a,b) or plot(v, (a,b))
    @test nseries() == length(fs)

    n = nseries()
    plot!(fs)
    @test nseries() ==  n + length(fs)

    plot(gs, a, b) # no plot(v) w/o plot(v,a,b) or plot(v, (a,b))
    @test nseries() == length(gs)

    n = nseries()
    plot!(gs)
    @test nseries() ==  n + length(gs)


    # Vector{<:Shape}// plots each shape
    s = Shape(:star, 5)
    ss = [translate(s, k, k) for k in 0:5]
    plot(ss)
    @test nseries() == length(ss)

    ##
    # tuple(f,g)// parametric plot like above, `plot` needs a,b or (a,b)
    plot(tuple(fs...), a, b)
    @test nseries() == 1

    plot(tuple(gs...), a, b)
    @test nseries() == 1

    # cf. https://docs.juliaplots.org/latest/input_data/
    # we don't bother with being so forgiving here
    x1, x2 = [1, 0],  [2, 3]    # vectors
    y1, y2 = [4, 5],  [6, 7]    # vectors
    m1, m2 = [x1 y1], [x2 y2]   # 2x2 matrices


    # array of matrices -> 4 series, plots each matrix column, x assumed to be integer count
    @test_throws ArgumentError nseries(plot([m1, m2])) == 4
    # array of array of arrays -> 4 series, plots each individual array, x assumed to be integer count
    @test_throws MethodError nseries(plot([[x1,y1], [x2,y2]])) == 4
    # array of tuples of arrays -> 2 series, plots each tuple as new series
    @test_throws MethodError nseries(plot([(x1,y1), (x2,y2)]) ) == 2

end
