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

vtu_start = """
<?xml version="1.0"?>

<VTKFile type= "UnstructuredGrid"  version= "0.1"  byte_order= "BigEndian">
<UnstructuredGrid>
"""
vtu_end = """
</UnstructuredGrid>
</VTKFile>
"""
vtu_start_piece(n_nodes) = """
<Piece NumberOfPoints="$n_nodes" NumberOfCells="$n_nodes">
"""
vtu_end_piece = """
</Piece>
"""
vtu_start_points = """
<Points>
"""
vtu_end_points = """
</Points>
"""
vtu_start_point_data() = """
<PointData>
"""
vtu_end_point_data = """
</PointData>
"""
vtu_start_data_array(type; name = "", n_components = 1) = """
<DataArray type="$type" $(name == "" ? "" : "Name=\"$name\" ")$(n_components == 1 ? "" : string("NumberOfComponents=\"", n_components, "\" "))format="ascii">
"""

vtu_end_data_array = """
</DataArray>
"""
vtu_start_cells = """
<Cells>
"""
vtu_end_cells = """
</Cells>
"""

out_file_path = joinpath(dirname(arg_node_file), "IPART.$(Dates.now()).vtu")
open(out_file_path, "w") do out_file
    # Beginning stuff
    write(out_file, vtu_start)
    write(out_file, vtu_start_piece(length(node_set)))

    # Write node locations
    write(out_file, vtu_start_points)
    write(out_file, vtu_start_data_array("Float32"; n_components = 3))
    for node in node_set
        write(out_file, string(Float32(node[1]), "\t", Float32(node[2]), "\t", 0.0))
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
    write(out_file, vtu_end_points)
    
    ## Write node resolutions
    write(out_file, vtu_start_point_data())
    write(out_file, vtu_start_data_array("Float32"; name = "s"))
    for node in node_set
        write(out_file, string(Float32(node[6])))
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
    
    ## Write node types
    write(out_file, vtu_start_data_array("Int32"; name = "node_type"))
    for node in node_set
        write(out_file, string(Int32(node[3])))
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
    write(out_file, vtu_end_point_data)

    # Write Cells element
    write(out_file, vtu_start_cells)
    
    ## Connectivity
    write(out_file, vtu_start_data_array("Int32"; name = "connectivity"))
    for i_node in axes(node_set, 1)
        write(out_file, string(i_node - 1))
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
    
    ## Offsets
    write(out_file, vtu_start_data_array("Int32"; name = "offsets"))
    for i_node in axes(node_set, 1)
        write(out_file, string(i_node))
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)

    ## Types
    write(out_file, vtu_start_data_array("Int32"; name = "types"))
    for i_node in axes(node_set, 1)
        write(out_file, string(1))
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
    write(out_file, vtu_end_cells)
    
    # End stuff
    write(out_file, vtu_end_piece)
    write(out_file, vtu_end)

end
