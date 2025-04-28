"""
Creates IPART files out of nodes files. Output file is named 'IPART.<date_time>'

ARGS
---
1   data_out directory path
"""

using Dates
using SunsetFileIO


arg_data_dir = ARGS[1]
if arg_data_dir[end] == '/' && length(arg_data_dir) != 1
    arg_data_dir = arg_data_dir[1:end - 1]
end
arg_sunset_dir = dirname(arg_data_dir)

(arg_D, arg_n_cores) = ask_file_type("nodes")
printstyled("What scaling WAS used to create the nodes file? "; color = :blue)
(arg_L_char, ) = ask_scale()
# (arg_n_cores_x, arg_n_cores_y, arg_n_cores_z) = ask_node_decomp()


cores_node_sets = NodeSet[]
cores_n_nodes = Int64[]

for i_core in 0:(arg_n_cores - 1)
    node_set = read_nodes_file(arg_data_dir, arg_D, i_core)
    scale!(node_set, 1 / arg_L_char)                            # Scale up(!) node sets
    keep_indices!(node_set, findall(>=(0), node_set["type"]))   # Remove FD nodes
    push!(cores_node_sets, node_set)
    push!(cores_n_nodes, length(node_set))
end


out_file_path = joinpath(arg_sunset_dir, "IPART.$(Dates.now())")
println("Writing to ", out_file_path)
open(out_file_path, "w") do file
    # Write the preamble data


    # Write the nodes data
    for i_core in 0:(arg_n_cores - 1)
        node_set = cores_node_sets[i_core + 1]
        x    = node_set["x"]
        y    = node_set["y"]
        type = node_set["type"]
        n_x  = node_set["n_x"]
        n_y  = node_set["n_y"]
        s    = node_set["s"]
        for i_node in 1:length(node_set)
            write(file, "x \ty \ttype \tn_x \tn_y \ts\n")
        end
    end
end




