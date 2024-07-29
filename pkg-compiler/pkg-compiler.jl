"""
ARGUMENTS:
ARGS[1]       package #1 str
ARGS[2]       package #2 str
ARGS[...]     ...
"""

packages = ARGS

if length(packages) == 0
    throw(ArgumentError("At least one package name required"))
end
# Julia will also throw if any of the packages are not in the project

println("Packages to compile are ", packages)

using PackageCompiler

file_out_path = joinpath(@__DIR__, "sysimages")
file_out_name = string(join(packages, "_"), ".so")
file_out_full = joinpath(file_out_path, file_out_name)

println("Writing sysimage to ", file_out_full)
create_sysimage(
    packages,
    sysimage_path = file_out_full,
    include_transitive_dependencies = false,
)

printstyled("\nEnd of compilation\n", color = :green)

