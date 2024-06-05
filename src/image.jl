# image
"""
    image!([p::Plot], img_url; [x],[y],[sizex],[sizey], kwargs...)

Plot image, by url, onto background of plot.

* `x`,`y`,`sizex`, `sizey` specify extent via `[x, x+sizex] × [y-sizey, y]`.
* pass `sizing="stretch"` to fill space.
* other arguments cf. [plotly examples](https://plotly.com/javascript/images/).

# Example
```
img = "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Julia_Programming_Language_Logo.svg/320px-Julia_Programming_Language_Logo.svg.png"
plot(;xlims=(0,1), ylims=(0,1), legend=false);
image!(img; sizing="stretch")
plot!(x -> x^2; linewidth=10, linecolor=:black)
```
"""
image!(img; kwargs...) = image!(current_plot[], img; kwargs...)
function image!(p::Plot, img;
                x=nothing,
                y=nothing,
                sizex = nothing,
                sizey = nothing,
                kwargs...)
    isempty(p.layout.images) && (p.layout.images = Config[])

    ex = extrema(p)
    x0,x1 = ex.x
    y0,y1 = ex.y
    x = isnothing(x) ? x0 : x
    y = isnothing(y) ? y1 : y
    sizex = isnothing(sizex) ? x1 - x : sizex
    sizey = isnothing(sizey) ? y - y0 : sizey
    image = Config(;source=img, x, y, sizex, sizey,
                   xref="x", yref="y",
                   layer="below")
    _merge!(image; kwargs...)
    push!(p.layout.images, image)
    p
end
