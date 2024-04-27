module BinderPlotsSimpleExpressionsExt

import SimpleExpressions: SymbolicEquation
import BinderPlots: plot!, Plot

# plot method for equations
function plot!(t::Val{:scatter}, p::Plot,
               f::SymbolicEquation, y, z;
               seriestype::Symbol=:lines,
               kwargs...)
    plot!(p, [f.lhs, f.rhs], y, z; seriestype, kwargs...)
end

end
