"""
Creates `init_flame.in` files from a selected `sunset_code:oned` branch run.

Output fields are:
1   x
2   y
3   u
4   v
5   w
6   ro
7   roE
8   T
9   p
10  Y1
11  Y2 
etc
"""

using Dates, Printf

println("Parsing args")

arg_flame_file_path = ARGS[1]
arg_out_dir = ARGS[2]
arg_out_name = "init_flame.in"

if !isfile(arg_flame_file_path)
    throw(ArgumentError("Flame file not found at location given"))
elseif basename(arg_flame_file_path)[1:5] != "flame"
    throw(ArgumentError("File given not a flame file"))
end

if !isdir(arg_out_dir)
    throw(ArgumentError("Output directory not found"))
elseif isfile(joinpath(arg_out_dir, arg_out_name))
    arg_out_name = string(arg_out_name, ".", Dates.now())
end

println("Reading from flame file: ", arg_flame_file_path)
data_all = Vector{Float64}[]
line_length = -1
for line in eachline(arg_flame_file_path)
    line_strings = filter(str -> str != "", split(line, " "))
    line_vals = tryparse.(Float64, line_strings)
    # println(length(line_vals), " \t", line_vals)
    if length(line_vals) != line_length && line_length != -1
        throw(ArgumentError("Line length varying, inconsistent file data"))
    elseif line_length == -1
        global line_length = length(line_vals)
    end
    push!(data_all, line_vals)
end

println("Writing to file: ", joinpath(arg_out_dir, arg_out_name))

sprintf(val :: Float64) = begin
    str = @sprintf "%.7e" val
    replace(str, "e" => "d")
end

open(joinpath(arg_out_dir, arg_out_name), "w") do out_file
    write(out_file, string(length(data_all)))
    write(out_file, "\n")
    for line_vals in data_all
        write(out_file, join(sprintf.(line_vals), " \t"))
        write(out_file, "\n")
    end
end

printstyled("\nEnd of script. \n"; color = :green)

# print("Press any key to exit.\n")
# readline()
# exit()