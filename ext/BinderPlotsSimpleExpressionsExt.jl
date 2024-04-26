module BinderPlotsSimpleExpressionsExt

using BinderPlots
import SimpleExpressions

# plot method for equations
function BinderPlots.plot!(t::Val{:scatter}, p::BinderPlots.Plot,
               f::SimpleExpressions.SymbolicEquation, y, z;
               seriestype::Symbol=:lines,
               kwargs...)
    plot!(p, [f.lhs, f.rhs], y, z; seriestype, kwargs...)
end

end
