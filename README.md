# sunset-tools
Tools to help use the [sunset-flames](https://github.com/sunset-codes/sunset-flames) code. Written primarily in Julia and bash.

## Table of Contents
- [sunset-tools](#sunset-tools)
  - [Table of Contents](#table-of-contents)
  - [Installation + Prerequisites](#installation--prerequisites)
  - [General Instructions](#general-instructions)
  - [`animate-frames.jl`](#animate-framesjl)
    - [Description](#description)
    - [Usage](#usage)
  - [`init_flame_file-creator.jl`](#init_flame_file-creatorjl)
    - [Description](#description-1)
    - [Usage](#usage-1)
  - [`IPART-to-vtu.jl`](#ipart-to-vtujl)
    - [Description](#description-2)
    - [Usage](#usage-2)
  - [`julia-package-compiler.jl`](#julia-package-compilerjl)
    - [Description](#description-3)
    - [Usage](#usage-3)
  - [`node-resolution.jl`](#node-resolutionjl)
    - [Description](#description-4)
    - [Usage](#usage-4)
  - [`plot-nodes.jl`](#plot-nodesjl)
    - [Description](#description-5)
    - [Usage](#usage-5)
  - [`sunset-tarball.sh`](#sunset-tarballsh)
    - [Description](#description-6)
    - [Usage](#usage-6)

## Installation + Prerequisites
- Linux
  - If you're on Windows you can use WSL
- Bash on linux
- Julia 1.10
  - You should probably install this via [juliaup](https://github.com/JuliaLang/juliaup)
- A bunch of Julia packages which are easy to install:
  - `Revise.jl`
  - `Plots.jl`
  - `PyPlot.jl`
  - `VideoIO.jl`
  - `ProgressMeter.jl`
  - `PackageCompiler.jl`
  - `Printf.jl`
  - `Dates.jl`
  - `LaTeXStrings.jl`

Oh and you should probably install [sunset-flames](https://github.com/sunset-codes/sunset-flames), as this repo is just a tool set for that CFD software.

## General Instructions
Documentation for each of these are given below. Arguments each script takes are given in the script files.

To run a bash file, do:

```bash
<bash script path> <arguments>
```

To run most julia scripts, do:

```bash
julia -- <julia script path> <arguments>
```

Sometimes these julia scripts need to be run in interactive mode (pretty much just when you are getting a plot display window to show). To do this, add the `-i` flag:

```bash
julia -i -- <julia script path> <arguments>
```

## `animate-frames.jl`
### Description
Stitches together images into an animation.

### Usage
No extra info yet.

## `init_flame_file-creator.jl`
### Description
Takes the output `data_out/flame...` data from a 1D SUNSET flame simulation and turns it into a `init_flame.in` file.

### Usage
No extra info yet.

## `IPART-to-vtu.jl`
### Description
Takes an IPART file as input from a sunset code and turns it into an xml 'unstructured node set' file that paraview can read.

### Usage
No extra info yet.

## `julia-package-compiler.jl`
### Description
Precompiles Julia packages into their sysimages (`.so` files). They can be used quickly when running Julia scripts with the `-J` flag, e.g.

```bash
julia -J <path to compiled package> -- <julia script path> <arguments>
```

Uses the `PackageCompiler.jl` package to do this.

Note that the usage of these precompiled package sysimages only makes scripts *start faster*. It does not make them run faster overall, just removes the initial precompilation Julia has to do when you use a package for the first time after starting julia (which happens everytime if you're running scripts).

### Usage
No extra info yet.

## `node-resolution.jl`
### Description
An interactive script for finding appropriate resolution parameters before generating a node set.

Currently only case 5 is implemented for a quasi 1D laminar flame.

Results from this script can be verified using the [`plot-nodes.jl`](#plot-nodesjl) script.

### Usage
This script is best used differently to a typical julia script. Instead what we do is enter an interactive julia session (called the REPL) via:

```bash
$ julia
```

and the run the commands:

```julia
julia> using Revise   # Loads the Revise package, which lets us alter and use julia scripts on-the-fly

julia> includet("node_resolution/node_resolution.jl")  # Runs the `node-resolution.jl` julia script

```

Note that this runs the `node-resolution.jl` script, but nothing executes because all of the useful functionality is held in julia functions! To use them we simply run these functions in the REPL, e.g.:

```julia
julia> dxmin = 1 / 500
0.002

julia> sunset_resolution_case_5(-0.5:0.01:0.5, dxmin * 10, dxmin, 0.15, 0.00; b0 = 4.0, b1 = 80.0)
```

Because we are in an interactive environment, not only will this function return a resolution array, it will also plot the resolution (and other relevant values, as used in sunset-flames `source/gen/datclass.f90` script) against x. This plotting is incredibly useful to quickly modify the input parameters (e.g. b0, b1) to find values which best suit our needs.

## `plot-nodes.jl`
### Description
Plots nodes stored in Jack's `IPART` format using the PyPlot backend.

This script is optimized for performance (so it can work on e.g. 100,000 nodes without being the worst thing ever), so should be used in conjunction with a sysimage as described above. In particular, this script uses the `Plots.jl` and `PyPlot.jl` packages. You can use these via:

```bash
# This creates the `Plots_PyPlot.so` sysimage
julia -- <path to this repo>/julia-package-compiler.jl Plots PyPlot

# This uses that sysimage to make the `plot-nodes.jl` script *start faster*
# The key part is the usage of the `-J` flag for `.so` files
# Also notice the `-i` flag is needed to view the plot
julia -i -J <path to repo>/julia-package-compilation/sysimages/Plots_PyPlot.so -- <path to repo>/plot-nodes/plot-nodes.jl <ARGS as listed in plot-nodes.jl>
```

### Usage
This creates a plot, so the `-i` flag is needed.

## `sunset-tarball.sh`
### Description
This script just takes the root directory and everything inside of it and makes a tar file out of that. The tar file is placed in the `sunset-storage` subdirectory. It could be adapted in the future to just be a julia script which takes the root directory path as an argument. It works fine for now though.

### Usage
Must be run at the root of the `sunset_code` directory that you are working in. For easiest usage, use the alias:

```bash
export sunset_storage_dir="<path to sunset-storage dir>"
alias sunset-tar='<path to this repo>/sunset-tarball/sunset-tarball.sh'
```

To unpack the tarball, run the command:

```bash
tar -zxvf <path to tarball>
```

in the location you want the `sunset_code` directory to appear.
