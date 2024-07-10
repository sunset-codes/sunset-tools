"""
Creates .vtu files out of IPART files. Output files are named 'IPART.<date_time>.vtu'

ARGS
---
1   data_out directory path
2   Output directory

INPUTS
---
1   First frame #
2   Last frame #
3   # of cores
4   Use every # data nodes
5   Maximum # of nodes

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

using Dates, Printf

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
arg_every_n_nodes = -1
arg_max_nodes = -1

if isinteractive()
    printstyled("First frame #?\n", color = :blue)
    temp_str = readline()
    arg_frame_start = parse(Int64, temp_str)

    printstyled("Second frame #?\n", color = :blue)
    temp_str = readline()
    arg_frame_end = parse(Int64, temp_str)
        
    printstyled("# of cores?\n", color = :blue)
    temp_str = readline()
    arg_cores = parse(Int64, temp_str)
    
    printstyled("Use every # data nodes?\n", color = :blue)
    temp_str = readline()
    arg_every_n_nodes = parse(Int64, temp_str)
    
    printstyled("Maximum # of nodes?\n", color = :blue)
    temp_str = readline()
    arg_max_nodes = parse(Int64, temp_str)
else
    printstyled("Not run in interactive mode, exiting.\n", color = :red)
    exit()
end

printstyled(string("arg_fields_dir:      ", arg_data_dir, "\n"), color = :yellow)
printstyled(string("arg_out_dir:         ", arg_out_dir, "\n"), color = :yellow)

printstyled(string("arg_frame_start:     ", arg_frame_start, "\n"), color = :yellow)
printstyled(string("arg_frame_end:       ", arg_frame_end, "\n"), color = :yellow)
printstyled(string("arg_cores:           ", arg_cores, "\n"), color = :yellow)
printstyled(string("arg_every_n_nodes:   ", arg_every_n_nodes, "\n"), color = :yellow)
printstyled(string("arg_max_nodes:       ", arg_max_nodes, "\n"), color = :yellow)


skip_line(line_skip, i_line) = (i_line - line_skip) % arg_every_n_nodes != 0 && arg_every_n_nodes > 1

println("Reading nodes files")

core_nodes_path(i_core) = joinpath(arg_data_dir, string("nodes_", 10000 + i_core))

node_set = Vector{Float64}[]
for i_core in 0:(arg_cores - 1)       # Be sure we're going in order
    open(core_nodes_path(i_core), "r") do in_file
        for (i_line, line) in enumerate(eachline(in_file))
            # Store each field as a float even though node types are ints
            line_vals = tryparse.(Float64, split(line))
            if i_line == 1 || skip_line(1, i_line)
                continue
            elseif length(node_set) == arg_max_nodes
                break
            end
            push!(node_set, line_vals)
        end
    end
end

println("We have a total of ", length(node_set), " nodes")



function write_vtu_data_array(out_file, type, name, node_write_f; n_components = 1, )
    write(out_file, vtu_start_data_array(type, name; n_components = n_components))
    for i_node in axes(node_set, 1)
        write(out_file, string("                    ", node_write_f(i_node)))     # Needs 5 tabs (20 spaces) to align
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
end

function write_vtu_point_data(out_file, field_set)
    write(out_file, vtu_start_point_data)
    
    write_vtu_data_array(out_file, "Float32", "s", i_node -> string(Float32(node_set[i_node][3])))
    write_vtu_data_array(out_file, "Int32", "Node Type", i_node -> string(Int32(node_set[i_node][5])))
    write_vtu_data_array(out_file, "Float32", "Coordinates", i_node -> string(Float32(node_set[i_node][1]), "\t", Float32(node_set[i_node][2]), "\t", 0.0); n_components = 3)

    write_vtu_data_array(out_file, "Float32", "Density", i_node -> string(Float32(field_set[i_node][1])))
    write_vtu_data_array(out_file, "Float32", "Velocity", i_node -> string(Float32(field_set[i_node][2]), "\t", Float32(field_set[i_node][3]), "\t", 0.0); n_components = 3)
    write_vtu_data_array(out_file, "Float32", "Vorticity", i_node -> string(Float32(field_set[i_node][4])))
    write_vtu_data_array(out_file, "Float32", "Temperature", i_node -> string(Float32(field_set[i_node][5])))
    write_vtu_data_array(out_file, "Float32", "Pressure", i_node -> string(Float32(field_set[i_node][6])))
    write_vtu_data_array(out_file, "Float32", "Heat Release Rate", i_node -> string(Float32(field_set[i_node][7])))
    for i_Y in 1:(length(field_set[1]) - 7)
        write_vtu_data_array(out_file, "Float32", string("Y", i_Y), i_node -> string(Float32(field_set[i_node][i_Y + 7])))
    end

    write(out_file, vtu_end_point_data)
end

function write_vtu_points(out_file)
    write(out_file, vtu_start_points)

    write_vtu_data_array(out_file, "Float32", "", i_node -> string(Float32(node_set[i_node][1]), "\t", Float32(node_set[i_node][2]), "\t", 0.0); n_components = 3)
    
    write(out_file, vtu_end_points)
end

function write_vtu_cells(out_file)
    write(out_file, vtu_start_cells)
    
    write_vtu_data_array(out_file, "Int32", "connectivity", i_node -> string(i_node - 1))
    write_vtu_data_array(out_file, "Int32", "offsets", i_node -> string(i_node))
    write_vtu_data_array(out_file, "Int32", "types", i_node -> string(1))

    write(out_file, vtu_end_cells)
    
end

for i_frame in arg_frame_start:arg_frame_end
    core_fields_path(i_core, i_frame) = joinpath(arg_data_dir, string("fields_", 10000 + i_core, "_", i_frame))

    field_set = Vector{Float64}[]
    for i_core in 0:(arg_cores - 1)       # Be sure we're going in order
        if !isfile(core_fields_path(i_core, i_frame))
            println(core_fields_path(i_core, i_frame))
            printstyled("Not a file, exiting.\n", color = :red)
        end

        open(core_fields_path(i_core, i_frame), "r") do in_file
            for (i_line, line) in enumerate(eachline(in_file))
                # Store each field as a float even though node types are ints
                line_vals = tryparse.(Float64, split(line))
                if i_line <= 5 || skip_line(5, i_line)
                    continue
                elseif length(field_set) == arg_max_nodes
                    break
                end
                push!(field_set, line_vals)
            end
        end
    end

    out_file_name = @sprintf "%04i" i_frame - 1
    out_file_name = string("ben_LAYER", out_file_name, ".vtu")
    out_file_path = joinpath(arg_out_dir, out_file_name)
    println("Writing nodes to ", out_file_path," file")
    open(out_file_path, "w") do out_file
        # Beginning stuff
        write(out_file, vtu_start)
        write(out_file, vtu_start_piece(length(node_set)))

        # Main stuff
        write_vtu_points(out_file)
        write_vtu_point_data(out_file, field_set)
        write_vtu_cells(out_file)

        # End stuff
        write(out_file, vtu_end_piece)
        write(out_file, vtu_end)
    end
end

exit()