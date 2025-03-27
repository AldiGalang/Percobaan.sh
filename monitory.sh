#!/bin/bash

# Fungsi untuk mengecek penggunaan GPU
check_gpu_utilization() {
    utilization=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    echo $utilization
}

# Variabel
check_interval=5  # Interval pemeriksaan (detik)
inactivity_threshold=120  # Ambang batas ketidakaktifan (detik)
inactivity_duration=0  # Waktu tidak aktif saat ini

while true; do
    gpu_util=$(check_gpu_utilization)
    if [ "$gpu_util" -eq 0 ]; then
        inactivity_duration=$((inactivity_duration + check_interval))
        echo "$inactivity_duration"
        if [ "$inactivity_duration" -ge "$inactivity_threshold" ]; then
            # GPU tidak aktif lebih dari ambang batas
            echo "GPU telah tidak aktif selama lebih dari 2 menit."
            echo "Restarting Gaia node..."
            gaianet stop
            gaianet start
            gaianet info
            echo "Gaia node telah direstart."
            inactivity_duration=0  # Reset durasi ketidakaktifan
        fi
    else
        inactivity_duration=0  # Reset jika GPU aktif kembali
    fi
    sleep $check_interval
done
