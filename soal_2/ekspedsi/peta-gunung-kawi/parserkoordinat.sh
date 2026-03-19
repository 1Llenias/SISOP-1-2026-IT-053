#!/bin/bash

input="gsxtrack.json"
output="titik-penting.txt"

awk '
BEGIN {
    FS=":"
    id_i=0
    site_i=0
    lat_i=0
    lon_i=0
}

/"id"/ {
    gsub(/[",]/,"",$2)		# ganti koma & petik jadi kosong
    id[id_i++] = trim($2)	# masukin ke array + bikin fungsi buat ngilangin spasi sama tab
}

/"site_name"/ {
    gsub(/[",]/,"",$2)
    site[site_i++] = trim($2)
}

/"latitude"/ {
    gsub(/[",]/,"",$2)
    lat[lat_i++] = trim($2)
}

/"longitude"/ {
    gsub(/[",]/,"",$2)
    long[lon_i++] = trim($2)
}

function trim(x) {		#fungsi ngilangin spasi sama tab
    sub(/^[ \t]+/, "", x)
    sub(/[ \t]+$/, "", x)
    return x
}

END {
    out = "'"$output"'"
    for (i = 0; i < site_i; i++) {
        print id[i] "," site[i] "," lat[i] "," long[i] > out
    }
}
' "$input"

echo "Titik ditemukan, cek di $output"
