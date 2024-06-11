#!/bin/bash
storage_name=$1

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

current_dir=${PWD##*/}              # to assign to a variable
current_dir=${current_dir:-/}       # to correct for the case where PWD=/

storage_dir="$HOME/Documents/work/sunset-storage/"
YYYY=$(date +"%Y")
MM=$(date +"%m")
DD=$(date +"%d")
HH=$(date +"%H")
mm=$(date +"%M")

storage_path="$storage_dir""sunset_$YYYY-$MM-$DD""_$HH$mm""_$storage_name.tar.gz"

tar --exclude="*.git*" -zcvf $storage_path "../$current_dir/"

storage_path="$storage_dir""sunset_$YYYY-$MM-$DD""_$HH$mm""_NO-DATA_$storage_name.tar.gz"

tar --exclude-from="$script_dir/.tar-excludes" -zcvf $storage_path "../$current_dir/"
