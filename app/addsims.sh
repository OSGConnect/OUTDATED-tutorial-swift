#! /bin/bash

while read f1 ; do
  read -u 3 f2 
  if [ _$f1 = _ ]; then f1=0; fi
  if [ _$f2 = _ ]; then f2=0; fi
  echo $(($f1+$f2)) 
done <$1 3<$2
