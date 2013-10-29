#!/bin/bash

dev=$1

#disk=mpathap3

if [[ -z "$dev" ]]; then
  echo "error: wrong input value"
  exit 1
fi

iostats=`iostat -xN |egrep -o "^${dev}[[:space:]]+.*"`

if [ -z "$iostats" ]; then
    echo "error: device not found (${dev})"
    exit 3
fi

iostats_lines=`wc -l <<< "$iostats"`

if [ $iostats_lines -ne 1 ]; then
    echo "error: wrong output value (${iostats_lines})"
    exit 2
fi

echo $iostats

exit 0

