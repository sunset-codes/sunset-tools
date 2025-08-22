"""
Creates .vtu files out of fields_*** files.

Multithreading can be used by adding the switch "-t <# threads>" when running Julia

ARGS
---
1   fields directory
2   Output directory (usually the paraview_files directory)
3   Do the fields_****** files contain production rate data (after the mass fraction, Y, data)?
4   Do the fields_****** files contain volume data?
5   Do the nodes_****** files contain index data?
6   Do the nodes_****** files contain h_small data?
7   (Optional) LAYER file name prefix. Defaults to "".
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

arg_fields_dir = ARGS[1]
arg_out_dir = ARGS[2]
arg_has_ω = parse(Bool, ARGS[3])
arg_has_vol = parse(Bool, ARGS[4])
arg_has_index = parse(Bool, ARGS[5])
arg_has_h_small = parse(Bool, ARGS[6])
arg_out_name_prefix = length(ARGS) > 6 ? ARGS[7] : ""

if !isdir(arg_fields_dir)
    println(arg_fields_dir)
    printstyled("arg_fields_dir is not a directory, exiting.\n", color = :red)
    exit()
elseif !isdir(arg_out_dir)
    println(arg_out_dir)
    printstyled("arg_out_dir is not a directory, exiting.\n", color = :red)
    exit()
end

(arg_D, arg_Y, arg_n_cores, (arg_frame_start, arg_frame_end)) = ask_file_type("many fields")
arg_keep_check_f_and_args = ask_skip()
(arg_L_char, ) = ask_scale()
# (arg_do_reflect, ) = ask_reflect()
println()

println("Reading nodes files")
node_set = read_nodes_files(arg_fields_dir, arg_D, arg_n_cores; has_index = arg_has_index, has_h_small = arg_has_h_small)
println("We have a total of ", length(node_set), " nodes")

node_indices = get_shuffle_keep_indices(node_set, arg_keep_check_f_and_args...)
keep_indices!(node_set, node_indices)

println("and we are writing ", length(node_set), " of them")


framepool = arg_frame_start:arg_frame_end
@threads for t in 1:nthreads()
    t_framepool = filter(i_frame -> (i_frame + t - 1) % nthreads() == 0, framepool)
    for i_frame in t_framepool
        if !all([isfile(fields_file_path(arg_fields_dir, i_core, i_frame)) for i_core in 0:(arg_n_cores - 1)])
            println("Frame $(i_frame) not found")
            continue
        end
        field_set = read_fields_files(arg_fields_dir, arg_D, arg_Y, arg_n_cores, i_frame; has_ω = arg_has_ω, has_vol = arg_has_vol)
        keep_indices!(field_set, node_indices)
        full_set = stitch_node_sets(node_set, field_set)
        scale!(full_set, arg_L_char)

        # Switch [0, 2π] -> [-π, π]
        # keep_indices!(full_set, findall(>=(0.0), full_set["y"]))
        # SunsetFileIO.translate!(full_set, [0.0, -(0.1 * 3.0 / 2) * arg_L_char])
        # field_set_reflected = copy_node_set(full_set)
        # reflect!(field_set_reflected, [0.0, 0.0], [1.0, 0.0])
        # full_set_reflect = join_node_sets(full_set, field_set_reflected)    

        # Output to vtu file
        out_file_name = @sprintf "%04i" i_frame - 1
        out_file_name = string(arg_out_name_prefix, "LAYER", out_file_name, ".vtu")
        out_file_path = joinpath(arg_out_dir, out_file_name)
        println("thread = ", threadid(), "\tframe = ", i_frame, "\tWriting nodes to ", out_file_path)
        # open_and_write_vtu(out_file_path, full_set_reflect)
        open_and_write_vtu(out_file_path, full_set)
    end
end


exit()