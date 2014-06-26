#! /bin/bash

log() {
  printf "Start time: "; /bin/date
  printf "Job is running on node: "; /bin/hostname
  printf "Job running as user: "; /usr/bin/id

  echo "Environment:"
  /bin/env | /bin/sort
}

runtime=${1:-0}
range=${2:-100}
biasfile=${3:-nobias}
scale=${4:-1}
n=${5:-1}

if [ $biasfile = nobias ]; then
  offset=0
else
  read offset <$biasfile
fi

# run for some number of "timesteps"

sleep $runtime

# emit n "simulation results", scaled and biased by the specified argument values

for ((i=0;i<n;i++)); do
  value=$(((($RANDOM)*32768)+$RANDOM))
  echo $(( ($value%range)*scale+offset))
done

# log environmental data

log 1>&2

