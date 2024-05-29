module BinderPlotsSymPyCoreExt

import SymPyCore: lambdify, Sym
import BinderPlots: plot!, Plot

# plot method for equations
function plot!(t::Val{:scatter}, p::Plot,
               f::Sym, y, z;
               seriestype::Symbol=:lines,
               kwargs...)
    plot!(t, p, lambdify(f), y, z; seriestype, kwargs...)
end

end
