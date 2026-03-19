#!/bin/bash

input="titik-penting.txt"
output="posisipusaka.txt"
first_lat=""
first_long=""

awk '
BEGIN {
    FS=","
}

first_lat=="" && first_long=="" {
    first_lat = $3
    first_long = $4
}

first_lat!=$3 && first_long!=$4 {
    second_lat = $3
    second_long = $4
}

END {
    out = "'"$output"'"
    print "Koordinat pusat:" > out
    print (first_lat+second_lat)/2 "," (first_long+second_long)/2 > out
}' "$input"

cat "$output"
