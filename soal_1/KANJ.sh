BEGIN {
	soal = ARGV[2]
	delete ARGV[2]
	FS=","
}

soal == "a" && NR>1 {
	penumpang++
}

soal == "b" && NR>1 {
	gerbong[$4]
}

soal == "c" && NR>1 {
	if($2>max){
		max=$2
		oldest=$1
	}
}

soal == "d" && NR>1 {
	total_umur+=$2
	penumpang++
	average=int((total_umur/penumpang)+0.5)
}

soal == "e" && NR>1 {
	if($3=="Business"){
		business++
	}
}

END {
	if(soal == "a"){
		print "Jumlah seluruh penumpang KANJ adalah", penumpang, "orang"
	}
	else if(soal == "b"){
		print "Jumlah gerbong penumpang KANJ adalah", length(gerbong)
	}
	else if(soal == "c"){
		print oldest, "adalah penumpang kereta tertua dengan usia", max, "tahun"
	}
	else if(soal == "d"){
		print "Rata-rata usia penumpang adalah", average, "tahun"
	}
	else if(soal == "e"){
		print "Jumlah penumpang business class ada", business, "orang"
	}
	else{
		print "Soal tidak dikenali. Gunakan a, b, c, d, atau e"
		print "Contoh penggunaan: awk -f file.sh data.csv a"
	}
}
