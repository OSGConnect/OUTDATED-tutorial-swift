#!/bin/bash -x

output=shift
output=$(cd $(dirname $output); echo $PWD/$(basename $output))     # Full pathname of output file
tmpdir=$( eval mktemp -d $PWD/modis.assemble.XXXX )
bindir=$(cd $(dirname $0); pwd)

# input files are expected to start with hNNvNN. 
# we reverse this to form the final image

while [ $# -gt 0 ]
do
   file=$1
   shift
   h=$( basename $file | cut -c2-3 )
   v=$( basename $file | cut -c5-6 )
   vh=v"$v"h"$h"
   cp $file $tmpdir/$vh.rgb
done

cd $tmpdir
$bindir/montage.pl 5 4 300 300 v*
$bindir/rgb_to_png.py map.rgb 1500 1200 ../map.png

exit 0
