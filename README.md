# sunset-tools
Tools to help use the [sunset-flames](https://github.com/sunset-codes/sunset-flames) code. Written primarily in Julia and bash.

## Table of Contents
- [sunset-tools](#sunset-tools)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [General Instructions](#general-instructions)
  - [`pkg-compiler.jl`](#pkg-compilerjl)
    - [Description](#description)
    - [Usage](#usage)
  - [`sunset-tarball.jl` and `unpack-tarball.sh`](#sunset-tarballjl-and-unpack-tarballsh)
    - [Description](#description-1)
    - [Usage](#usage-1)
  - [`node-resolution.jl`](#node-resolutionjl)
    - [Description](#description-2)
    - [Usage](#usage-2)
  - [Other Scripts](#other-scripts)

## Prerequisites
- Linux
  - If you're on Windows you can use WSL
- Bash on linux
- Julia 1.10
  - You should probably install this via [juliaup](https://github.com/JuliaLang/juliaup)
- A bunch of Julia packages which are easy to install:
  - `Revise.jl`
  - `Plots.jl`
  - `PyPlot.jl`
  - `PackageCompiler.jl`
  - `Dates.jl`
  - All of those which are required by [SunsetFileIO](https://github.com/sunset-codes/SunsetFileIO)

Oh and you should probably install [sunset-flames](https://github.com/sunset-codes/sunset-flames), as this repo is just a tool set for that CFD software.

## General Instructions
Documentation for each of these are given below. Arguments each script takes are given in the script files.

To run a bash file, do:

```bash
<bash script path> <arguments>
```

To run most julia scripts, do:

```bash
julia -e 'include("/path/to/sunset-startup.jl")' -- <julia script path> <arguments>
```

The `-e` flag will run the julia code `include...`, which runs the code in `sunset-startup.jl` before running the script code. This can be skipped if you instead add `include("/path/to/sunset-startup.jl")` to your [`startup.jl` file](https://docs.julialang.org/en/v1/manual/command-line-interface/#Startup-file). From now on I will omit this flag, assuming that you've done this.

Sometimes these julia scripts need to be run in interactive mode (pretty much just when you are getting a plot display window to show). To do this, add the `-i` flag:

```bash
julia -i -- <julia script path> <arguments>
```

## `pkg-compiler.jl`
### Description
Precompiles Julia packages into their sysimages (`.so` files). They can be used quickly when running Julia scripts with the `-J` flag, e.g.

```bash
julia -J sysimages/PackageCompiler.so -- pkg-compiler.jl <arguments>
```

Uses the `PackageCompiler.jl` package to do this.

Note that the usage of these precompiled package sysimages only makes scripts *start faster*. It does not make them run faster overall, just removes the initial hooplah Julia has to do when you use a package for the first time after starting julia (which happens everytime if you're running scripts).

### Usage
No extra info yet.

## `sunset-tarball.jl` and `unpack-tarball.sh`
### Description
Creates two tarballs containing that directory and everything in it: one containing everything and another
only containing the contents needed to run that simulation from the beginning.


### Usage
Must be run at the root of the e.g. `sunset_code` directory that you are working in. For easiest usage, use the alias:

```bash
export sunset_storage_dir="<path to sunset-storage dir>"
alias sunset-tarball='julia -- <path to sunset-tarball.jl>'
```

To extract this tarball at some location, simply run the command

```bash
<path to unpack-tarball.sh> <tarball file> <directory to unpack into>
```

This script effectively just runs the command

```bash
tar -zxvf <path to tarball>
```

in the location you want the `sunset_code` directory to appear.

## `node-resolution.jl`
### Description
An interactive script for finding appropriate resolution parameters before generating a node set.

Currently only case 5 is implemented for a quasi 1D laminar flame.

Results from this script can be verified using `plot-nodes.jl`.

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

## Other Scripts
The rest of these scripts should be relatively self-explanatory, you run them like a usual script (always interactively, so that you as the user can give input without needing to enter it at the command line) and all the rigmarole of using SunsetFileIO yourself should be hidden.

Of course, if you wish SunsetFileIO is designed to be scripted on, so feel free to create your own scripts and add them here.

If you have any questions, feel free to ask!
