"""
Creates `init_flame.in` files from a selected `sunset-flames:oned` branch run. This stitches
the flame files for each mpi process into a single init_flame file.

Script args:
1   input data_out dir
2   output init_flame dir
3   contains hrr information?
4   (optional) Output file name. Defaults to `init_flame.in`.
"""

using Dates, Printf
using SunsetFileIO

arg_data_dir = ARGS[1]
arg_out_dir = ARGS[2]
arg_has_hrr = parse(Bool, ARGS[3])
arg_out_name = length(ARGS) < 4 ? "init_flame.in" : ARGS[4]

if !isdir(arg_out_dir)
    throw(ArgumentError("Output directory not found"))
elseif isfile(joinpath(arg_out_dir, arg_out_name))
    nice_dt = replace(string(Dates.now()), ":" => "-")
    arg_out_name = string(arg_out_name, ".", nice_dt)
end


(arg_D, arg_Y, arg_n_cores, arg_i_frame) = ask_file_type("flame")

node_set = read_flames_file(arg_data_dir, arg_D, arg_Y, arg_n_cores, arg_i_frame; has_hrr = arg_has_hrr)

# Post-process flame file
bad_fields = setdiff(node_set.fields, init_flame_fields(arg_D, arg_Y))
for field in bad_fields
    remove_field!(node_set, field.name)
end    

# node_set["x"] = node_set["x"] .+ 0.010
# dx = node_set[2, "x"] - node_set[1, "x"]
# while node_set[length(node_set), "x"] < 1.0e-2
#     new_row = node_set.set[end, :]'
#     new_row[1, 1] = node_set[length(node_set), "x"] + dx
#     node_set.set = vcat(node_set.set, new_row)
# end

# Write out node_set to init_flame.in file
println("Writing ", length(node_set), " nodes to file: ", joinpath(arg_out_dir, arg_out_name))

# Converts from flame usual 'e' based scientific notation to Fortran's weird 'd' based one
sprintf(val :: Float64) = begin
    str = @sprintf "%.7e" val
    replace(str, "e" => "d")
end

open(joinpath(arg_out_dir, arg_out_name), "w") do out_file
    write(out_file, string(length(node_set)))
    write(out_file, "\n")
    for i_node in axes(node_set.set, 1)
        write(out_file, join(sprintf.(node_set.set[i_node, :]), " \t"))
        write(out_file, "\n")
    end
end

printstyled("\nEnd of script. \n"; color = :green)
exit()
