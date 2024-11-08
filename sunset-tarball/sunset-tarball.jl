"""
sunset-tarball program, rewritten in Julia (because bash is hard to use and Julia is wayyyy simpler).

Navigate to the root directory of your sunset-flames directory and run this program to create a tarball
containing that directory and everything in it. Creates two tarballs: one containing everything and another
only containing the contents needed to run that simulation from the beginning.

ARGS
---
1   The name part of the tarball file name
2   (optional) Directory to place tarballs into. Defaults to `sunset_storage_directory` environment variable.
"""

using Dates

arg_storage_name = ARGS[1]
arg_storage_dir = length(ARGS) > 1 ? ARGS[2] : ENV["sunset_storage_dir"]

if !isdir(arg_storage_dir)
    printstyled("Storage directory does not exist, making it now"; color = :purple)
    run(`mkdir -p $arg_storage_dir`)
end

script_dir = @__DIR__

current_dir = splitdir(pwd())[2]

df = DateFormat("yyyy-mm-dd_HHMM")
dt = Dates.format(now(), df)

storage_path = joinpath(arg_storage_dir, "sunset_NO-DATA_$(arg_storage_name)_$(dt).tar.gz")
run(`tar --exclude-from=$(joinpath(script_dir, ".tar-excludes")) -zcvf $storage_path "../$(current_dir)/."`)

storage_path = joinpath(arg_storage_dir, "sunset_$(arg_storage_name)_$(dt).tar.gz")
run(`tar -zcvf $storage_path "../$(current_dir)/."`)
