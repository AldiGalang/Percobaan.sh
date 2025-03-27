#!/bin/bash

# 1️⃣ Meminta API Key di awal
read -p "Masukkan API key Anda: " api_key

# Pastikan input tidak kosong
if [[ -z "$api_key" ]]; then
    echo "❌ API key tidak boleh kosong!"
    exit 1
fi

# 2️⃣ Membuat folder & clone repo bot
mkdir -p Gaiabot
cd Gaiabot

echo "Cloning Gaiabot..."
git clone https://github.com/AldiGalang/Gaiabot.git gaiabot-101

echo "$api_key" > gaiabot-101/file_api_keys.txt
echo "✅ API key telah disimpan di gaiabot-101/file_api_keys.txt!"

# 3️⃣ Menjalankan bot dalam screen "gaiabot-101"
sudo apt update && sudo apt install -y screen python3 python3.12-venv

screen -dmS gaiabot-101 bash -c "
    cd gaiabot-101 && 
    python3 -m venv myenv &&
    source myenv/bin/activate &&
    pip install -r requirements.txt &&
    python3 bot.py
"

echo "✅ Bot berjalan di screen 'gaiabot-101' (screen -r gaiabot-101)"

# 4️⃣ Update & upgrade sistem
apt update && apt upgrade -y
apt-get update && apt-get upgrade -y

# 5️⃣ Install dependencies
apt install -y pciutils lsof curl nvtop btop jq screen

# 6️⃣ Install CUDA Toolkit
CUDA_KEYRING="cuda-keyring_1.1-1_all.deb"
wget "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/$CUDA_KEYRING"
dpkg -i $CUDA_KEYRING
apt-get update
apt-get install -y cuda-toolkit-12-8
rm -f $CUDA_KEYRING

# 7️⃣ Konfigurasi folder & port GaiaNet
i=101
home_dir="$HOME/gaia-node-$i"
backup_dir="$HOME/gaia-backup/gaia-node-$i"
gaia_port="8$i"

# 8️⃣ Backup jika folder node sudah ada
if [ -d "$home_dir" ]; then
    echo "$home_dir sudah ada."
    read -p "Backup ke $backup_dir? [y/n] " -n 1 choice
    echo ""

    if [[ $choice =~ ^[Yy]$ ]]; then
        mkdir -p "$backup_dir/gaia-frp"
        cp -n "$home_dir/nodeid.json" "$backup_dir/"
        cp -n "$home_dir/gaia-frp/frpc.toml" "$backup_dir/gaia-frp/"
    else
        echo "Backup dilewati."
    fi
fi

# 9️⃣ Hentikan proses yang menggunakan port Gaia
lsof -t -i:$gaia_port | xargs kill -9

# 🔟 Hapus folder node lama & uninstall GaiaNet
rm -rf "$home_dir"
curl -sSfL "https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/uninstall.sh" | bash

# 1️⃣1️⃣ Buat folder baru & install GaiaNet
mkdir -p "$home_dir"
curl -sSfL "https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh" | bash -s -- --ggmlcuda 12 --base "$home_dir"

# 1️⃣2️⃣ Restore backup jika tersedia
if [ -d "$backup_dir" ]; then
    read -p "Restore dari $backup_dir? [y/n] " -n 1 choice
    echo ""

    if [[ $choice =~ ^[Yy]$ ]]; then
        cp -f "$backup_dir/nodeid.json" "$home_dir/"
        cp -f "$backup_dir/gaia-frp/frpc.toml" "$home_dir/gaia-frp/"
    else
        echo "Restore dilewati."
    fi
fi

# 1️⃣3️⃣ Update konfigurasi GaiaNet
source "$HOME/.bashrc"
gaianet stop

CONFIG_URL="https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen-2.5-coder-7b-instruct_rustlang/config.json"
CONFIG_FILE="$home_dir/config.json"

wget -O "$CONFIG_FILE" "$CONFIG_URL"
jq '.chat = "https://huggingface.co/gaianet/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-3B-Instruct-Q5_K_M.gguf"' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
jq '.chat_name = "Qwen2.5-Coder-3B-Instruct"' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"

grep '"chat":' "$CONFIG_FILE"
grep '"chat_name":' "$CONFIG_FILE"

# 1️⃣4️⃣ Inisialisasi & jalankan GaiaNet
gaianet config --base "$home_dir" --port "$gaia_port"
gaianet init --base "$home_dir"
gaianet start --base "$home_dir"

# 1️⃣5️⃣ Membuat script monitoring GPU
monitor_script="$home_dir/monitor_gpu_activity.sh"

cat <<EOL > "$monitor_script"
#!/bin/bash

# Function to check GPU utilization
check_gpu_utilization() {
    utilization=\$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    echo \$(date) - GPU Utilization: \$utilization% >> "$home_dir/gpu_monitor.log"
    echo \$utilization
}

# Variables
check_interval=5  # Interval antara pengecekan (detik)
inactivity_threshold=120  # Waktu tunggu sebelum restart (detik)
inactivity_duration=0

while true; do
    gpu_util=\$(check_gpu_utilization)
    if [ "\$gpu_util" -eq 0 ]; then
        inactivity_duration=\$((inactivity_duration + check_interval))
        echo "\$inactivity_duration" >> "$home_dir/gpu_monitor.log"
        if [ "\$inactivity_duration" -ge "\$inactivity_threshold" ]; then
            echo "\$(date) - GPU idle terlalu lama, restart GaiaNet." >> "$home_dir/gpu_monitor.log"
            gaianet stop
            gaianet start
            echo "\$(date) - GaiaNet restarted." >> "$home_dir/gpu_monitor.log"
            inactivity_duration=0  # Reset durasi inaktivitas
        fi
    else
        inactivity_duration=0  # Reset jika GPU aktif
    fi
    sleep \$check_interval
done
EOL

# Beri izin eksekusi ke script monitoring
chmod +x "$monitor_script"

# 1️⃣6️⃣ Jalankan monitoring GPU dalam screen
screen -dmS monitor_gpu_activity "$monitor_script"

# 1️⃣7️⃣ Menampilkan informasi GaiaNet di akhir
echo "Gaianet berhasil dijalankan!"
echo "Untuk melihat log GPU: tail -f $home_dir/gpu_monitor.log"
echo "Untuk masuk ke screen monitoring: screen -r monitor_gpu_activity"

# Menampilkan informasi GaiaNet setelah semua proses selesai
gaianet info --base "$home_dir"
