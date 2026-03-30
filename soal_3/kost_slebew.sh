#!/bin/bash

DATA_FILE="$(dirname "$0")/data/penghuni.csv"
ERASE_HISTORY="$(dirname "$0")/sampah/history_hapus.csv"
FINAN_REPORT="$(dirname "$0")/rekap/laporan_bulanan.txt"
INVOICE_LOG="$(dirname "$0")/log/tagihan.log"

mkdir -p "$(dirname "$DATA_FILE")"
mkdir -p "$(dirname "$ERASE_HISTORY")"
mkdir -p "$(dirname "$FINAN_REPORT")"
mkdir -p "$(dirname "$INVOICE_LOG")"

if [ ! -f "$DATA_FILE" ]; then
    touch "$DATA_FILE"
fi
if [ ! -s "$DATA_FILE" ]; then
    echo "Nama,Kamar,Harga Sewa,Tanggal Masuk,Status Awal" >  "$DATA_FILE"
fi

if [ ! -f "$ERASE_HISTORY" ]; then
    touch "$ERASE_HISTORY"
fi
if [ ! -s "$ERASE_HISTORY" ]; then
    echo "Nama,Kamar,Harga Sewa,Tanggal Masuk,Status Awal,Tanggal Hapus" >  "$ERASE_HISTORY"
fi

touch "$FINAN_REPORT"
touch "$INVOICE_LOG"

tambah_penghuni() {
    echo ""
    echo "======================================================"
    echo "		    TAMBAH PENGHUNI			"
    echo "======================================================"
    read -p "Masukkan Nama: " nama

    read -p "Masukkan Kamar: " kamar

    read -p "Masukkan Harga Sewa: " hargaSewa
	if [[ $hargaSewa < 0 ]]; then
	echo "Input harga sewa tidak boleh negatif!"
	return
	fi

    read -p "Masukkan Tanggal Masuk (YYYY-MM-DD): " tanggalMasuk
    if [[ ! "$tanggalMasuk" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
	echo "Input tanggal harus sesuai format: YYYY-MM-DD !"
	return
    fi
    today=$(date +%Y-%m-%d)
    if [[ "$tanggalMasuk" > "$today" ]]; then
	echo "Tanggal masuk tidak boleh melebihi hari ini!"
	return
    fi

    read -p "Masukkan Status Awal (Aktif/Menunggak): " statusAwal

    if awk -F',' -v k="$kamar" 'NR>1 && $2==k {exit 1}' "$DATA_FILE"; then
	echo "$nama,$kamar,$hargaSewa,$tanggalMasuk,$statusAwal" >> $DATA_FILE
    	echo ""
    	echo "Penghuni \"$nama\" berhasil ditambahkan ke Kamar $kamar dengan status $statusAwal"
	echo ""
	read -p "Tekan [ENTER] untuk kembali ke menu..."
    else
	echo "Kamar $kamar sudah ada penghuninya"
	return
    fi
}

hapus_penghuni() {
    echo ""
    echo "======================================================"
    echo "		     HAPUS PENGHUNI			"
    echo "======================================================"
    read -p "Masukkan nama penghuni yang ingin dihapus: " nama

    data=$(awk -F',' -v n="$nama" 'NR>1 && tolower($1)==tolower(n) {print $0}' "$DATA_FILE")

    if [ -z "$data" ]; then
	echo "Penghuni dengan nama \"$nama\" tidak ditemukan"
	return
    fi

    tanggal_hapus=$(date +%Y-%m-%d)

    echo "$data,$tanggal_hapus" >> "$ERASE_HISTORY"

    awk -F',' -v n="$nama" 'NR==1 {print $0} NR>1 && tolower($1)!=tolower(n) {print $0}' "$DATA_FILE" > temp.csv
    mv temp.csv "$DATA_FILE"
    echo ""
    echo "Data penghuni \"$nama\" berhasil diarsipkan ke $ERASE_HISTORY dan dihapus dari sistem."
    echo ""
    read -p "Tekan [ENTER] untuk kembali ke menu..."
}

daftar_penghuni() {
    echo ""
    echo "========================================================================================"
    echo "	       		        DAFTAR PENGHUNI KOST SLEBEW			          "
    echo "========================================================================================"

    awk -F',' 'NR==1 {
	printf "%-4s | %-20s | %-5s | %-20s | %-13s | %-10s\n", "No", $1, $2, $3, $4, $5
	printf "%-4s-+-%-20s-+-%-5s-+-%-20s-+-%-13s-+-%-10s\n", "----", "--------------------", "-----", "--------------------", "-------------", "-----------"
	next
    }
    NR>1 {
	printf "%-4s | %-20s | %-5s | Rp%-18s | %-13s | %-10s\n", NR-1, $1, $2, $3, $4, $5
	total++
	if ($5 == "Aktif") aktif++
	if ($5 == "Menunggak") nunggak++
    }
    END {
	printf "----------------------------------------------------------------------------------------\n"
	printf " Total penghuni: %d	| Aktif: %d	| Menunggak: %d\n", total, aktif, nunggak
	printf "========================================================================================\n"
    }' "$DATA_FILE"
    echo ""
    read -p "Tekan [ENTER] untuk kembali ke menu..."
}

update_status() {
    echo ""
    echo "======================================================"
    echo "		     UPDATE STATUS			"
    echo "======================================================"
    read -p "Masukkan Nama Penghuni: " nama
    read -p "Masukkan Status Baru (Aktif/Menunggak): " statusBaru

    awk -F',' -v nama="$nama" -v inputStatus="$statusBaru" '
    BEGIN {OFS=","}
    NR==1 {print; next}
    {
	lower = tolower(inputStatus)
	newStatus = toupper(substr(lower,1,1)) substr(lower,2)

	if (tolower($1) == tolower(nama)) {
	    $5 = newStatus
	    print $0
	    updated = 1
	} else {
	    print $0
	}
    }
    END {
	if (updated){
	    exit 0
	} else {
	    exit 1
	}
    }' "$DATA_FILE" > temp.csv

    if [ $? -eq 0 ]; then
	mv temp.csv "$DATA_FILE"
	echo "Status $nama berhasil diubah menjadi: $statusBaru"
    else
	rm temp.csv
	echo "Penghuni dengan nama \"$nama\" tidak ditemukan."
    fi

    read -p "Tekan [ENTER] untuk kembali ke menu..."
}

laporan_keuangan(){
    awk -F',' -v totalPemasukan=0 -v totalTunggakan=0 '
    (NR>1 && $5=="Aktif") {
	totalPemasukan+=$3
	kamarTerisi++
    }
    (NR>1 && $5=="Menunggak") {
	totalTunggakan+=$3
	daftarTunggak[$1]=$1
	kamarTerisi++
    }
    END {
	print ""
	print "======================================================"
	print "              LAPORAN KEUANGAN SLEBEW                 "
	print "======================================================"
	print " Total pemasukan (Aktif): Rp",totalPemasukan
	print " Total tunggakan	: Rp",totalTunggakan
	print " Jumlah kamar terisi	Rp:",kamarTerisi
	print "------------------------------------------------------"
	print " Daftar penghuni menunggak:"
	if (length(daftarTunggak) == 0){
	    print "  Tidak ada tunggakan.\n"
	} else {
	    for (nama in daftarTunggak) {
		print "   -", daftarTunggak[nama]
	    }
	    print "\n"
	}
    }' "$DATA_FILE" > "$FINAN_REPORT"

    cat "$FINAN_REPORT"
    echo "Laporan berhasil disimpan ke \"$FINAN_REPORT\""
    echo ""
    read -p "Tekan [ENTER] untuk kembali ke menu..."
}

kelola_cron() {
    while true; do
	echo ""
	echo "=========================================================="
	echo "			  MENU CRON SLEBEW			"
	echo "=========================================================="
	echo " 1. Lihat Cron Job Aktif					"
	echo " 2. Daftarkan Cron Job Pengingat				"
	echo " 3. Hapus Cron Job Pengingat				"
	echo " 4. Kembali ke Menu Utama					"
	echo "=========================================================="
	read -p "Pilih [1-4]: " cronOption

	case $cronOption in
	    1)	echo ""
		echo "--------------Daftar Cron Job Pengingat Tagihan--------------"
		crontab -l | grep "kost_slebew.sh --check-tagihan"
		echo ""
		read -p "Tekan [ENTER] untuk kembali ke menu..."
		;;
	    2)	echo ""
		read -p "Masukkan Jam (0-23): " cronHour
		read -p "Masukkan Menit (0-59): " cronMinutes
		crontab -l | grep -v "kost_slebew.sh --check-tagihan" > newCron.tmp
		echo "$cronMinutes $cronHour * * * $(pwd)/kost_slebew.sh --check-tagihan" >> newCron.tmp
		crontab newCron.tmp
		echo ""
		echo "Jadwal reminder telah ditambahkan pada setiap hari pukul $cronHour:$cronMinutes"
		rm newCron.tmp
		echo ""
		read -p "Tekan [ENTER] untuk kembali ke menu..."
		;;
	    3)	echo ""
		crontab -l | grep -v "kost_slebew.sh --check-tagihan" > myCron.tmp
		crontab myCron.tmp
		rm myCron.tmp
		echo "Cron job pengingat tagihan berhasil dihapus."
		echo ""
		read -p "Tekan [ENTER] untuk kembali ke menu..."
		;;
	    4)	echo ""
		echo "Keluar dari Cron Job Menu..."
		break
		;;
	    *)	echo ""
		echo "Pilihan invalid."
		;;
	esac
    done
}

if [[ "$1" = "--check-tagihan" ]]; then
    awk -F',' '
    NR>1 && $5=="Menunggak" {
	cmd="date +\"[%Y-%m-%d %H:%M:%S]\""
	cmd | getline timestamp
	close(cmd)
	printf "%s TAGIHAN: %s (Kamar %s) - Menunggak Rp%s\n", timestamp, $1, $2, $3
    }' "$DATA_FILE" > log/tagihan.log
    exit 0
fi

menu() {
    while true; do
        echo ""
        echo " _  __          _     _____ _      _			"
        echo "| |/ /___  ___ | |_  / ____| |    | |			"
        echo "| ' // _ \/ __|| __| | (___| | ___| |__  _____      __	"
        echo "| . \ (_) \__ \| |_   \___ \ |/ _ \ '_ \/ _ \ \ /\ / /	"
        echo "|_|\_\___/|___/ \__|  ____)  |  __/ |_) | __/\ V  V /	"
        echo "                     |_____/_|\___|_.__/\___| \_/\_/	"
        echo ""
        echo "=========================================================="
        echo "               SISTEM MANAJEMEN KOST SLEBEW		"
        echo "=========================================================="
        echo " ID | OPTION						"
        echo "----------------------------------------------------------"
        echo "  1 | Tambah Penghuni Baru				"
        echo "  2 | Hapus Penghuni					"
	echo "  3 | Tampilkan Daftar Penghuni				"
	echo "  4 | Update Status Penghuni				"
	echo "  5 | Cetak Laporan Keuangan				"
	echo "  6 | Kelola Cron (Pengingat Tagihan)			"
	echo "  7 | Exit Program					"
	echo "=========================================================="
	read -p "Enter option [1-7]: " option

	case $option in
	    1) tambah_penghuni ;;
	    2) hapus_penghuni ;;
	    3) daftar_penghuni ;;
	    4) update_status ;;
	    5) laporan_keuangan ;;
	    6) kelola_cron ;;
	    7) echo ""; echo "Slebewww... keluar dari program..."; break;;
	    *) echo "Pilihan invalid." ;;
	esac
    done
}

menu
