"""
    annotate!([p::Plot], x, y, txt; [color], [family], [pointsize], [halign], [valign])
    annotate!([p::Plot], anns::Tuple;  kwargs...)

Add annotations to plot.

* x, y, txt: text to add at (x,y)
* color: text color
* family: font family
* pointsize: text size
* halign: one of "top", "bottom"
* valign: one of "left", "right"
* rotation: angle to rotate

The `x`, `y`, `txt` values can be specified as 3 iterables or tuple of tuples.
"""
function annotate!(p::Plot, x, y, txt;
                   kwargs...)

    # txt maybe string or 'text' objects
    # convert string to text object then ...
    tfs = [text(tᵢ) for tᵢ ∈ txt]
    _txt = [t.str for t in tfs]
    family = [t.font.family for t in tfs]
    pointsize = [t.font.pointsize for t in tfs]
    textposition = [_align(t.font.valign, t.font.halign) for t in tfs]
    rotation = [t.font.rotation for t in tfs]
    color = [t.font.color for t in tfs]

    cfg = Config(; x, y, z=nothing, text=_txt, mode="text", type="scatter", textposition)
    _textstyle!(cfg.textfont; color, family, pointsize, rotation, kwargs...)

    push!(p.data, cfg)
    p
end

annotate!(x, y, txt; kwargs...) = annotate!(current_plot[], x, y, txt; kwargs...)
annotate!(anns::Tuple; kwargs...) = annotate!(current_plot[], anns; kwargs...)
annotate!(anns::Vector; kwargs...) = annotate!(current_plot[], anns; kwargs...)

annotate!(p::Plot, anns::Tuple; kwargs...) = annotate!(p, collect(anns)...; kwargs...)

# use magic to create `text` objects
function annotate!(p::Plot, anns::Vector; kwargs...)
    x = [a[1] for a in anns]
    y = [a[2] for a in anns]
    txt = [text(a[3:end]...) for a in anns]
    annotate!(p, x, y, txt; kwargs...)
end


## ----

# arrow from u to u + du with optional text at tail
function _arrow(u,du,txt=nothing;
                arrowhead=nothing,
                arrowwidth=nothing,
                arrowcolor=nothing,
                showarrow=nothing,
                kwargs...)
    cfg = Config()
    ax, ay = u
    x, y = u .+ du
    xref = axref = "x"
    yref = ayref = "y"
    str, font = isa(txt,TextFont) ? (txt.str, txt.font) : (txt, nothing)
    textangle = isnothing(font) ? nothing : font.rotation
    _merge!(cfg; x, y, ax, ay,
            text=str,
            xref,yref, axref, ayref,
            arrowhead, arrowwidth, arrowcolor, showarrow,
            textangle,
            kwargs...)
    _fontstyle!(cfg.font, font)
    cfg
end
