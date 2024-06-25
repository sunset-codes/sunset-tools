#!/bin/bash
# Argument 1    Name of tarball (excluding common name, date and file extension)

storage_name=$1

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

current_dir=${PWD##*/}              # to assign to a variable
current_dir=${current_dir:-/}       # to correct for the case where PWD=/

storage_dir="$sunset_storage_dir"

YYYY=$(date +"%Y")
MM=$(date +"%m")
DD=$(date +"%d")
HH=$(date +"%H")
mm=$(date +"%M")

dt="$YYYY-$MM-$DD""_$HH$mm"

# Skeleton tarball with none of the data inside, just:
# The code used (source, executables, object files)
# Node discretisation
# Control parameters
# Docs
storage_path="${storage_dir}sunset_${dt}_NO-DATA_${storage_name}.tar.gz"
tar --exclude-from="${script_dir}/.tar-excludes" -zcvf $storage_path "../${current_dir}/"

# Full tarball containing everything
storage_path="${storage_dir}sunset_${dt}_${storage_name}.tar.gz"
tar --exclude="*.git*" -zcvf $storage_path "../${current_dir}/"
