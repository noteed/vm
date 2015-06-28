#!/bin/sh
if [ -z "$1" ]; then
  export EDITOR=$0 && sudo -E visudo
else
  echo "horde ALL=(ALL:ALL) NOPASSWD: ALL" >> $1
fi
