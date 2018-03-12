#!/bin/bash -i

path_usr=/usr/local/share/zdl
path_tmp=.zdl_tmp
secs=$(date +%s)

touch $secs-test-binding
read -e -t 1 -n 1 binding_in_loop
rm $secs-test-binding

echo "$binding_in_loop" > "$path_tmp"/binding-in-loop
