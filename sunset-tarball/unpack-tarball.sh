# Unpack a tarball at argument 1 into a folder, argument 2
arg_fpath_tarball=$1
arg_fdir_extracted=$2

mkdir -p $arg_fdir_extracted
tar -xzvf $arg_fpath_tarball -C $arg_fdir_extracted

