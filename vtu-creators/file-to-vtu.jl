"""
Creates .vtu files out of IPART files. Output files are named 'IPART.<date_time>.vtu'

ARGS
---
1   data_out directory path
2   Output directory

INPUTS
---
1       First frame #
2       Last frame #
3       # of cores
4       Skip nodes?
4.1     Stride?
4.1.1   Use 1/# of the nodes
4.2     Constant node spacing?
4.2.1   New spacing
5       Maximum # of nodes
6       Scale down x, y, s and h by this # (L_char)

nodes
1   x
2   y
3   s
4   h
5   node type

fields
---
1   rho
2   u
3   v
4   voticity
5   T
6   p'
7   hrr
8   Y1
9   Y2
10  etc.

.vtu
---
All the above!
"""

## ADD SCALING FOR NODE POSITIONS TO REFLECT L_CHAR

println("starting Julia and modules")

using Dates, Printf, Random, Dates

include(joinpath(@__DIR__, "vtu-strings.jl"))

println("Starting script")

arg_data_dir = ARGS[1]
arg_out_dir = ARGS[2]

if !isdir(arg_data_dir)
    println(arg_data_dir)
    printstyled("arg_data_dir is not a directory, exiting.\n", color = :red)
    exit()
elseif !isdir(arg_out_dir)
    println(arg_out_dir)
    printstyled("arg_out_dir is not a directory, exiting.\n", color = :red)
    exit()
end

arg_frame_start = -1
arg_frame_end = -1
arg_cores = -1

arg_skip = false
arg_stride = false
arg_stride_n = -1
arg_spacing = false
arg_spacing_s = -1
arg_max_nodes = -1
arg_L_char = 1.0


if isinteractive()
    printstyled("First frame #\n", color = :blue)
    temp_str = readline()
    arg_frame_start = parse(Int64, temp_str)

    printstyled("Second frame #\n", color = :blue)
    temp_str = readline()
    arg_frame_end = parse(Int64, temp_str)
        
    printstyled("# of cores\n", color = :blue)
    temp_str = readline()
    arg_cores = parse(Int64, temp_str)
    
    printstyled("Skip nodes?\n", color = :blue)
    temp_str = readline()
    arg_skip = parse(Bool, temp_str)
    
    if arg_skip
        printstyled("Stride?\n", color = :blue)
        temp_str = readline()
        arg_stride = parse(Bool, temp_str)
        
        if arg_stride
            printstyled("Use 1/# of the nodes\n", color = :blue)
            temp_str = readline()
            arg_stride_n = parse(Int64, temp_str)
        end
        
        printstyled("Constant node spacing?\n", color = :blue)
        temp_str = readline()
        arg_spacing = parse(Bool, temp_str)

        if arg_spacing && !arg_stride
            printstyled("New spacing\n", color = :blue)
            temp_str = readline()
            arg_spacing_s = parse(Float64, temp_str)
        end
        if !arg_spacing && !arg_stride
            printstyled("No skipping used, exiting.\n", color = :red)
            exit()
        end
    end

    printstyled("Maximum # of nodes (-1 for no maximum)\n", color = :blue)
    temp_str = readline()
    arg_max_nodes = parse(Int64, temp_str)

    printstyled("Scale down x, y, s and h by this # (L_char, 1 for no scaling)\n", color = :blue)
    temp_str = readline()
    arg_L_char = parse(Float64, temp_str)
else
    printstyled("Not run in interactive mode, exiting.\n", color = :red)
    exit()
end

printstyled(string("arg_fields_dir:      ", arg_data_dir, "\n"), color = :yellow)
printstyled(string("arg_out_dir:         ", arg_out_dir, "\n"), color = :yellow)

printstyled(string("arg_frame_start:     ", arg_frame_start, "\n"), color = :yellow)
printstyled(string("arg_frame_end:       ", arg_frame_end, "\n"), color = :yellow)
printstyled(string("arg_cores:           ", arg_cores, "\n"), color = :yellow)

printstyled(string("arg_skip:            ", arg_skip, "\n"), color = :yellow)
printstyled(string("arg_stride:          ", arg_stride, "\n"), color = :yellow)
printstyled(string("arg_stride_n:        ", arg_stride_n, "\n"), color = :yellow)
printstyled(string("arg_spacing:         ", arg_spacing, "\n"), color = :yellow)
printstyled(string("arg_spacing_s:       ", arg_spacing_s, "\n"), color = :yellow)
printstyled(string("arg_max_nodes:       ", arg_max_nodes, "\n"), color = :yellow)
printstyled(string("arg_L_char:          ", arg_L_char, "\n"), color = :yellow)


println("Reading nodes files")

core_nodes_path(i_core) = joinpath(arg_data_dir, string("nodes_", 10000 + i_core))

node_set = Vector{Float64}[]
for i_core in 0:(arg_cores - 1)       # Be sure we're going in order
    open(core_nodes_path(i_core), "r") do in_file
        for (i_line, line) in enumerate(eachline(in_file))
            # Store each field as a float even though node types are ints
            line_vals = tryparse.(Float64, split(line))
            if i_line == 1
                continue
            elseif length(node_set) == arg_max_nodes
                break
            end
            line_vals[1:4] *= arg_L_char
            push!(node_set, line_vals)
        end
    end
end

println("We have a total of ", length(node_set), " nodes")

t1 = Dates.now()

nodes_x1 = minimum(node -> node[1], node_set)
nodes_x2 = maximum(node -> node[1], node_set)
nodes_y1 = minimum(node -> node[2], node_set)
nodes_y2 = maximum(node -> node[2], node_set)

i_bin(x) = Int64(floor((x - nodes_x1) / arg_spacing_s)) + 1
j_bin(y) = Int64(floor((y - nodes_y1) / arg_spacing_s)) + 1

node_bins = [false for j in 1:j_bin(nodes_y2), i in 1:i_bin(nodes_x2)]

function skip_line(i_node, node)
    skip = false
    x = node[1]
    y = node[2]
    if arg_stride
        skip = i_node % arg_stride_n != 0 && arg_stride_n > 1
    elseif arg_spacing
        skip = true
        node_i_bin = i_bin(x)
        node_j_bin = j_bin(y)
        if !node_bins[node_j_bin, node_i_bin]
            skip = false
            node_bins[node_j_bin, node_i_bin] = true
        end
    end

    return skip
end

# Create an array of the nodes which are included in the vtu file
# Shuffle it so we don't get a processor bias
node_indices_shuffled = shuffle(axes(node_set, 1))
node_indices_inverse_shuffled = sortperm(node_indices_shuffled)
node_indices_included = Int64[]
for i_node in node_indices_shuffled
    node = node_set[i_node]
    if skip_line(i_node, node)
        push!(node_indices_included, -1)
    else
        push!(node_indices_included, i_node)
    end
end

permute!(node_indices_included, node_indices_inverse_shuffled)
filter!(i_node -> i_node != -1, node_indices_included)

t2 = Dates.now()
println("Sorting took ", t2 - t1)


println("and we are writing ", length(node_indices_included), " of them")


function write_vtu_data_array(out_file, type, name, node_write_f; n_components = 1)
    write(out_file, vtu_start_data_array(type, name; n_components = n_components))
    for i_node in node_indices_included      # Only write those nodes which have been included
        write(out_file, string(node_write_f(i_node)))     # Having no whitespace saves ~60% on storage space
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
end

function write_vtu_point_data(out_file, field_set, core_set)
    write(out_file, vtu_start_point_data)
    
    write_vtu_data_array(out_file, "Float32", "s", i_node -> string(Float32(node_set[i_node][3])))
    write_vtu_data_array(out_file, "Int32", "Node Type", i_node -> string(Int32(node_set[i_node][5])))
    write_vtu_data_array(out_file, "Float32", "Coordinates",
                         i_node -> string(Float32(node_set[i_node][1]), "\t", Float32(node_set[i_node][2]), "\t", 0.0)
                         ; n_components = 3)

    write_vtu_data_array(out_file, "Float32", "Density", i_node -> string(Float32(field_set[i_node][1])))
    write_vtu_data_array(out_file, "Float32", "Velocity", i_node -> string(Float32(field_set[i_node][2]), "\t", Float32(field_set[i_node][3]), "\t", 0.0); n_components = 3)
    write_vtu_data_array(out_file, "Float32", "Vorticity", i_node -> string(Float32(field_set[i_node][4])))
    write_vtu_data_array(out_file, "Float32", "Temperature", i_node -> string(Float32(field_set[i_node][5])))
    write_vtu_data_array(out_file, "Float32", "Pressure", i_node -> string(Float32(field_set[i_node][6])))
    write_vtu_data_array(out_file, "Float32", "Heat Release Rate", i_node -> string(Float32(field_set[i_node][7])))
    for i_Y in 1:(length(field_set[1]) - 7)
        write_vtu_data_array(out_file, "Float32", string("Y", i_Y), i_node -> string(Float32(field_set[i_node][i_Y + 7])))
    end

    write_vtu_data_array(out_file, "Float32", "Processor", i_node -> string(Float32(core_set[i_node])))

    write(out_file, vtu_end_point_data)
end

function write_vtu_points(out_file)
    write(out_file, vtu_start_points)

    write_vtu_data_array(out_file, "Float32", "", i_node -> string(Float32(node_set[i_node][1]), "\t", Float32(node_set[i_node][2]), "\t", 0.0); n_components = 3)
    
    write(out_file, vtu_end_points)
end

function write_vtu_cells(out_file)
    write(out_file, vtu_start_cells)
    
    i_counter = -1
    write_vtu_data_array(out_file, "Int32", "connectivity", i_node -> begin
        i_counter += 1
        return string(i_counter)
    end)
    i_counter = 0
    write_vtu_data_array(out_file, "Int32", "offsets", i_node -> begin
        i_counter += 1
        return string(i_counter)
    end)
    write_vtu_data_array(out_file, "Int32", "types", i_node -> string(1))

    write(out_file, vtu_end_cells)
end

for i_frame in arg_frame_start:arg_frame_end
    core_fields_path(i_core, i_frame) = joinpath(arg_data_dir, string("fields_", 10000 + i_core, "_", i_frame))

    # Read in fields files
    field_set = Vector{Float64}[]
    core_set = Int64[]
    for i_core in 0:(arg_cores - 1)       # Be sure we're going in order
        if !isfile(core_fields_path(i_core, i_frame))
            println(core_fields_path(i_core, i_frame))
            printstyled("Not a file, exiting.\n", color = :red)
        end

        open(core_fields_path(i_core, i_frame), "r") do in_file
            for (i_line, line) in enumerate(eachline(in_file))
                # Store each field as a float even though node types are ints
                line_vals = tryparse.(Float64, split(line))
                if i_line <= 5
                    continue
                elseif length(field_set) == arg_max_nodes
                    break
                end
                push!(field_set, line_vals)
                push!(core_set, i_core)
            end
        end
    end

    # Output to vtu file
    out_file_name = @sprintf "%04i" i_frame - 1
    out_file_name = string("ben_LAYER", out_file_name, ".vtu")
    out_file_path = joinpath(arg_out_dir, out_file_name)
    println("Writing nodes to ", out_file_path," file")
    open(out_file_path, "w") do out_file
        # Beginning stuff
        write(out_file, vtu_start)
        write(out_file, vtu_start_piece(length(node_indices_included)))

        # Main stuff
        write_vtu_points(out_file)
        write_vtu_point_data(out_file, field_set, core_set)
        write_vtu_cells(out_file)

        # End stuff
        write(out_file, vtu_end_piece)
        write(out_file, vtu_end)
    end
end

exit()