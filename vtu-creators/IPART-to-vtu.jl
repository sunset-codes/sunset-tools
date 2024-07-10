"""
Creates .vtu files out of IPART files. Output files are named 'IPART.<date_time>.vtu'

ARGS
ARGS[1] .   . IPART file path
ARGS[2] .   . number of lines to skip at the start of IPART
ARGS[3] .   . (optional) maximum number of nodes to read from IPART file 

IPART
1   x
2   y
3   node type
4   n.x
5   n.y
6   s

.vtu
Points  (x, y, z = 0)
s
node type
"""

println("starting Julia and modules")

using Dates

include(joinpath(@__DIR__, "vtu-strings.jl"))


println("Starting script")

arg_node_file = ARGS[1]
arg_line_skip = -1
arg_max_nodes = -1

if length(ARGS) < 2
    println("ERROR: NOT ENOUGH ARGUMENTS")
    exit()
else
    arg_node_file = ARGS[1]
    arg_line_skip = tryparse(Int64, ARGS[2])
    if length(ARGS) >= 3
        arg_max_nodes = tryparse(Int64, ARGS[3])
        println("max nodes set as: ", arg_max_nodes)
    end
end

printstyled(string("arg_node_file:         ", arg_node_file, "\n"), color = :yellow)
printstyled(string("arg_line_skip:         ", arg_line_skip, "\n"), color = :yellow)
printstyled(string("arg_max_nodes:         ", arg_max_nodes, "\n"), color = :yellow)

println("Reading IPART file")

node_set = Vector{Float64}[]
open(arg_node_file, "r") do in_file
    for (i_line, line) in enumerate(eachline(in_file))
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

println("Calculating extra fd node locations")

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


println("Writing nodes to .vtu file")

function write_vtu_data_array(type, name, node_write_f; n_components = 1, )
    write(out_file, vtu_start_data_array(type, name; n_components = n_components))
    for i in axes(node_set, 1)
        write(out_file, node_write_f(node))
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
end

function write_vtu_point_data(out_file, )
    write(out_file, vtu_start_point_data)
    
    write_vtu_data_array("Float32", "s", i_node -> string(Float32(node_set[i][6])))
    write_vtu_data_array("Int32", "node_type", i_node -> string(Float32(node_set[i][3])))
    write_vtu_data_array("Float32", "coords", i_node -> string(Float32(node_set[i][1]), "\t", Float32(node_set[i][2]), "\t", 0.0); n_components = 3)

    write(out_file, vtu_end_point_data)
end

function write_vtu_points(out_file)
    write(out_file, vtu_start_points)

    write_vtu_data_array("Float32", "", i_node -> string(Float32(node_set[i][1]), "\t", Float32(node_set[i][2]), "\t", 0.0); n_components = 3)
    
    write(out_file, vtu_end_points)
end

function write_vtu_cells(out_file)
    write(out_file, vtu_start_cells)
    
    write_vtu_data_array("Int32", "connectivity", i_node -> string(i_node - 1))
    write_vtu_data_array("Int32", "offsets", i_node -> string(i_node))
    write_vtu_data_array("Int32", "types", i_node -> string(1))

    write(out_file, vtu_end_cells)
    
end

out_file_path = joinpath(dirname(arg_node_file), "IPART.$(Dates.now()).vtu")
open(out_file_path, "w") do out_file
    # Beginning stuff
    write(out_file, vtu_start)
    write(out_file, vtu_start_piece(length(node_set)))

    write_vtu_points(out_file)
    write_vtu_point_data(out_file)
    write_vtu_cells(out_file)

    # End stuff
    write(out_file, vtu_end_piece)
    write(out_file, vtu_end)
end
