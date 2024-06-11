"""
Arguments:
ARGS[1] = IPART file path
ARGS[2] = number of lines to skip at the start of IPART
ARGS[3] = plot finite difference nodes?
ARGS[4] = (optional) maximum number of nodes to read from IPART file 
ARGS[5] = (optional) show legend?

IPART fields:
1     x
2     y
3     node type
4     n.x
5     n.y
6     s (AKA dxp)
"""

println("starting Julia and modules")

using Plots

using LaTeXStrings

pyplot()

println("starting script")

arg_node_file = ARGS[1]
arg_line_skip = -1
arg_plot_fd_nodes = true
arg_max_nodes = -1
arg_show_legend = true

if length(ARGS) < 3
    printnln("ERROR: NOT ENOUGH ARGUMENTS")
    exit()
else
    arg_node_file = ARGS[1]
    arg_line_skip = tryparse(Int64, ARGS[2])
    arg_plot_fd_nodes = tryparse(Bool, ARGS[3])
    if length(ARGS) == 4
        arg_max_nodes = tryparse(Int64, ARGS[4])
        println("max nodes set as: ", arg_max_nodes)
    elseif length(ARGS) >= 5
        arg_max_nodes = tryparse(Int64, ARGS[4])
        println("max nodes set as: ", arg_max_nodes)
        arg_show_legend = tryparse(Bool, ARGS[5])
        println(arg_show_legend ? "" : "not ", "showing node legend")
    end
end

println("parsing node file: ", arg_node_file)

node_set = Vector{Float64}[]

open(arg_node_file) do f
    for (i_line, line) in enumerate(eachline(f))
        # Store each field as a float even though node types are ints
        line_vals = tryparse.(Float64, split(line))
        if i_line <= arg_line_skip || length(line_vals) == 0
            continue
        elseif length(node_set) == arg_max_nodes
            break
        end
        push!(node_set, line_vals)
    end
end

println("inserting extra finite difference nodes")

if arg_plot_fd_nodes
    for node in node_set
        if node[3] in [999.0, -1.0]
            continue
        end

        push!(node_set,
            [node[1] + 1 * node[4] * node[6], node[2] + 1 * node[5] * node[6], -1.0, 0.0, 0.0, node[6]],
            [node[1] + 2 * node[4] * node[6], node[2] + 2 * node[5] * node[6], -1.0, 0.0, 0.0, node[6]],
            [node[1] + 3 * node[4] * node[6], node[2] + 3 * node[5] * node[6], -1.0, 0.0, 0.0, node[6]],
            [node[1] + 4 * node[4] * node[6], node[2] + 4 * node[5] * node[6], -1.0, 0.0, 0.0, node[6]],
        )
    end
end

println("getting node colours")

boundary_types = Dict(
    999.0 => (:grey, "Unstructured Nodes"),
    1.0   => (:blue, "Non-reflecting Inflow"),
    2.0   => (:red, "Non-reflecting Outflow"),
    -1.0  => (:orange, "Finite Difference Nodes"),
)
# Get n vectors, one for nodes of each type
node_type_sets = [
    filter(n -> n[3] == node_type, node_set)
    for (node_type, _) in boundary_types
]

println("plotting ", length(node_set)," nodes")

x_min = minimum(n -> n[1], node_set)
x_max = maximum(n -> n[1], node_set)
y_min = minimum(n -> n[2], node_set)
y_max = maximum(n -> n[2], node_set)
x_size = x_max - x_min
y_size = y_max - y_min
frame_margin = 0.2 * max(x_size, y_size)
x_limits = (x_min - frame_margin, x_max + frame_margin)
y_limits = (y_min - frame_margin, y_max + frame_margin)

node_plot = scatter(
    aspect_ratio = :equal, legend = arg_show_legend,
    xlimits = x_limits, ylimits = y_limits, xlabel = L"x", ylabel = L"y",
    size = (1000, 750)
)
for node_type_set in node_type_sets
    if length(node_type_set) == 0
        continue
    end

    boundary_type = boundary_types[node_type_set[1][3]]
    marker_colour = boundary_type[1]
    label = boundary_type[2]
    nodes_xy = [(node[1], node[2]) for node in node_type_set]
    scatter!(
        node_plot,
        nodes_xy,
        markercolor = marker_colour,
        markerstrokewidth = 0.2, label = label,
    )
end

display(node_plot)

println("press Enter to close Julia and the plot")
readline()
exit()
