# sunset-tools
Tools to help use @jrcking 's sunset code, most of which are written in Julia.

## Contains
- animate-frames.jl
- init_flame_file-creator.jl
- julia-package-compiler.jl
- plot-nodes.jl
- sunset-tarball.sh

Documentation for each of these are given below. Arguments each script takes are given in the script files.

To run a bash file, do:

```bash
<bash script path> <arguments>
```

To run most julia scripts, do:

```
julia -- <julia script path> <arguments>
```

Sometimes these julia scripts need to be run in interactive mode (pretty much just when you are getting a plot display window to show). To do this, add the `-i` flag:

```
julia -i -- <julia script path> <arguments>
```

## animate-frames.jl
No extra info yet.

## init_flame_file-creator.jl
No extra info yet.

## julia-package-compiler.jl
No extra info yet.

## plot-nodes.jl
This creates a plot, so the `-i` flag is needed.

## sunset-tarball.sh
Must be run at the root of the `sunset_code` directory that you are working in. This script just takes the root directory and everything inside of it and makes a tar file out of that. It could be adapted in the future to just be a julia script which takes the root directory path as an argument. It works fine for now though.

For easiest usage, use the alias:

```bash
alias sunset-tar='~/Documents/work/GitHub/sunset-tools/sunset-tarball/sunset-tarball.sh'
```

