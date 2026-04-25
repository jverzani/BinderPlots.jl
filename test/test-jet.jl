using JET
using BinderPlots
using LinearAlgebra

@testset "JET" begin
    JET.test_package(BinderPlots, ignored_modules=(AnyFrameModule(Base),
                                                   AnyFrameModule(BinderPlots.ColorTypes),
                                                   AnyFrameModule(BinderPlots.Colors),
                                                   AnyFrameModule(LinearAlgebra)))
end
