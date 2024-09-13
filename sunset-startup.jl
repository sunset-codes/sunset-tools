printstyled("Sunset startup file used!\n"; bold = true, color = :red)
printstyled("Startup contains plotting defaults and Measures.jl.\n"; bold = true, color = :yellow)
println()

# using Revise
using Measures

const PLOTS_DEFAULTS_GR = Dict(
    :titlefont => (8, "Computer Modern"),
    :legendfont => (6, "Computer Modern"),
    :guidefont => (8, "Computer Modern"),
    :tickfont => (8, "Computer Modern"),
    :bottommargin => -7mm,
    :leftmargin => -8mm,
    :legend => (0.1, 1.1),              # Legend in gr has coords 0 -> 1 from left/bottom to right/top of frame, anchored on the middle of the legend, so ticks often get covered
)

const PLOTS_DEFAULTS_PYPLOT = Dict(
    :titlefont => (8, "cmr10"),
    :legendfont => (6, "cmr10"),
    :guidefont => (8, "cmr10"),
    :tickfont => (8, "serif"),
    :bottommargin => 0mm,
    :leftmargin => 0mm,
    :legend => (0, 1),              # Legend in pyplot has coords 0 -> 1 from left/bottom to right/top of frame, anchored on the bottom left of the legend
)


plots_defaults(backend_defaults) = Dict(
    # Non-backend specific
    :size => (600, 400),
    :frame => :box,
    :thickness_scaling => 2.0,
    # Backend specific
    backend_defaults...,
)

# Change defaults on the fly using:
# default(; reset = true, plots_defaults(PLOTS_DEFAULTS_GR or PLOTS_DEFAULTS_PYPLOT)...)
const PLOTS_DEFAULTS = plots_defaults(PLOTS_DEFAULTS_GR)


