"""
Creates .vtu files out of IPART files. Output files are named 'IPART.<date_time>.vtu'.

Multithreading can be used by adding the switch "-t <# threads>" when running Julia

ARGS
---
1   data_out directory path
2   Output directory (usually the paraview_files directory)
3   (Optional) LAYER file name prefix. Defaults to "".
"""


using Printf, Base.Threads
using SunsetFileIO


printstyled(string("Started with ", nthreads(), " thread", nthreads() > 1 ? "s" : "", ".\n"); color = :green)
if nthreads() == 1
    printstyled("Start with more than one thread using `julia -i "; color = :green)
    printstyled("-t <# threads>"; color = :white, bold = true)
    printstyled(" -- ...`.\n"; color = :green)
end
println()

arg_data_dir = ARGS[1]
arg_out_dir = ARGS[2]
arg_out_name_prefix = length(ARGS) > 2 ? ARGS[3] : ""

if !isdir(arg_data_dir)
    println(arg_data_dir)
    printstyled("arg_data_dir is not a directory, exiting.\n", color = :red)
    exit()
elseif !isdir(arg_out_dir)
    println(arg_out_dir)
    printstyled("arg_out_dir is not a directory, exiting.\n", color = :red)
    exit()
end

(arg_D, arg_Y, arg_n_cores, (arg_frame_start, arg_frame_end)) = ask_file_type("many fields")
arg_keep_check_f_and_args = ask_skip()
(arg_L_char, ) = ask_scale()
(arg_do_reflect, arg_reflect_p1, arg_reflect_p2) = ask_reflect()
println()

println("Reading nodes files")
node_set = read_nodes_files(arg_data_dir, arg_D, arg_n_cores)
println("We have a total of ", length(node_set), " nodes")

scale!(node_set, arg_L_char)

node_indices = get_shuffle_keep_indices(node_set, arg_keep_check_f_and_args...)
keep_indices!(node_set, node_indices)

if arg_do_reflect
    node_set_reflected = copy_node_set(node_set)
    reflect!(node_set_reflected, arg_reflect_p1, arg_reflect_p2)
    node_set = join_node_sets(node_set, node_set_reflected)
end

println("and we are writing ", length(node_set), " of them")


framepool = arg_frame_start:arg_frame_end
@threads for t in 1:nthreads()
    t_framepool = filter(i_frame -> (i_frame + t - 1) % nthreads() == 0, framepool)
    for i_frame in t_framepool
        field_set = read_fields_files(arg_data_dir, arg_D, arg_Y, arg_n_cores, i_frame)
        keep_indices!(field_set, node_indices)

        if arg_do_reflect
            field_set_reflected = copy_node_set(field_set)
            reflect!(field_set_reflected, arg_reflect_p1, arg_reflect_p2)
            field_set = join_node_sets(field_set, field_set_reflected)    
        end

        full_set = stitch_node_sets(node_set, field_set)

        # Output to vtu file
        out_file_name = @sprintf "%04i" i_frame - 1
        out_file_name = string(arg_out_name_prefix, "LAYER", out_file_name, ".vtu")
        out_file_path = joinpath(arg_out_dir, out_file_name)
        println("thread = ", threadid(), "\tframe = ", i_frame, "\tWriting nodes to ", out_file_path)
        open_and_write_vtu(out_file_path, full_set)
    end
end


exit()