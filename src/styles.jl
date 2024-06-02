## --- Styles
## PlotlyLight styles

_linestyles = (:dash, :dashdot, :dashdotdot, :dot, :solid, :auto)

_lineshapes = (path=:linear, spline=:spline,
               steppre=:vh, steppost=:hv)

_fillstyles = (:none,
               :tozerox, :tonextx,
               :tozeroy, :tonexty,
               :toself,  :tonext)

# use :nm_attribute not nm-attribute
_marker_shapes = (:circle, :circle_open, :circle_dot, :circle_open_dot, :square, :square_open, :square_dot, :square_open_dot, :diamond, :diamond_open, :diamond_dot, :diamond_open_dot, :cross, :cross_open, :cross_dot, :cross_open_dot, :x, :x_open, :x_dot, :x_open_dot, :triangle_up, :triangle_up_open, :triangle_up_dot, :triangle_up_open_dot, :triangle_down, :triangle_down_open, :triangle_down_dot, :triangle_down_open_dot, :triangle_left, :triangle_left_open, :triangle_left_dot, :triangle_left_open_dot, :triangle_right, :triangle_right_open, :triangle_right_dot, :triangle_right_open_dot, :triangle_ne, :triangle_ne_open, :triangle_ne_dot, :triangle_ne_open_dot, :triangle_se, :triangle_se_open, :triangle_se_dot, :triangle_se_open_dot, :triangle_sw, :triangle_sw_open, :triangle_sw_dot, :triangle_sw_open_dot, :triangle_nw, :triangle_nw_open, :triangle_nw_dot, :triangle_nw_open_dot, :pentagon, :pentagon_open, :pentagon_dot, :pentagon_open_dot, :hexagon, :hexagon_open, :hexagon_dot, :hexagon_open_dot, :hexagon2, :hexagon2_open, :hexagon2_dot, :hexagon2_open_dot, :octagon, :octagon_open, :octagon_dot, :octagon_open_dot, :star, :star_open, :star_dot, :star_open_dot, :hexagram, :hexagram_open, :hexagram_dot, :hexagram_open_dot, :star_triangle_up, :star_triangle_up_open, :star_triangle_up_dot, :star_triangle_up_open_dot, :star_triangle_down, :star_triangle_down_open, :star_triangle_down_dot, :star_triangle_down_open_dot, :star_square, :star_square_open, :star_square_dot, :star_square_open_dot, :star_diamond, :star_diamond_open, :star_diamond_dot, :star_diamond_open_dot, :diamond_tall, :diamond_tall_open, :diamond_tall_dot, :diamond_tall_open_dot, :diamond_wide, :diamond_wide_open, :diamond_wide_dot, :diamond_wide_open_dot, :hourglass, :hourglass_open, :bowtie, :bowtie_open, :circle_cross, :circle_cross_open, :circle_x, :circle_x_open, :square_cross, :square_cross_open, :square_x, :square_x_open, :diamond_cross, :diamond_cross_open, :diamond_x, :diamond_x_open, :cross_thin, :cross_thin_open, :x_thin, :x_thin_open, :asterisk, :asterisk_open, :hash, :hash_open, :hash_dot, :hash_open_dot, :y_up, :y_up_open, :y_down, :y_down_open, :y_left, :y_left_open, :y_right, :y_right_open, :line_ew, :line_ew_open, :line_ns, :line_ns_open, :line_ne, :line_ne_open, :line_nw, :line_nw_open, :arrow_up, :arrow_up_open, :arrow_down, :arrow_down_open, :arrow_left, :arrow_left_open, :arrow_right, :arrow_right_open, :arrow_bar_up, :arrow_bar_up_open, :arrow_bar_down, :arrow_bar_down_open, :arrow_bar_left, :arrow_bar_left_open, :arrow_bar_right, :arrow_bar_right_open, :arrow, :arrow_open, :arrow_wide, :arrow_wide_open,
                )
_legend_positions =
    (topleft=(0,1), top=(1/2,1), topright=(1,1),
     left=(0,1/2),  inside=(1/2,1/2), right=(1,1/2),
     bottomleft=(0,0), bottom=(1/2,0), bottomright=(1,0))

_color_scales = (:YlOrRd, :YlGnBu, :RdBu,
                 :Portland, :Picnic, :Jet, :Hot,
                 :Greys, :Greens, :Bluered,
                 :Electric, :Earth, :Blackbody)
