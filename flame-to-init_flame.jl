"""
Creates `init_flame.in` files from a selected `sunset-flames:oned` branch run. This stitches
the flame files for each mpi process into a single init_flame file.

Script args:
1   input data_out dir
2   output init_flame dir
3   (optional) Output file name. Defaults to `init_flame.in`.
"""

using Dates, Printf
using SunsetFileIO

arg_data_dir = ARGS[1]
arg_out_dir = ARGS[2]
arg_out_name = length(ARGS) < 3 ? "init_flame.in" : ARGS[3]

if !isdir(arg_out_dir)
    throw(ArgumentError("Output directory not found"))
elseif isfile(joinpath(arg_out_dir, arg_out_name))
    nice_dt = replace(string(Dates.now()), ":" => "-")
    arg_out_name = string(arg_out_name, ".", nice_dt)
end


(arg_D, arg_Y, arg_n_cores, arg_i_frame) = ask_file_type("flame")

node_set = read_flames_file(arg_data_dir, arg_D, arg_Y, arg_n_cores, arg_i_frame)

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
