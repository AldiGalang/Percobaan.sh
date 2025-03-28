#!/bin/bash

echo -e "\n🔄 Updating system..."
sudo apt update && sudo apt upgrade -y -o Dpkg::Options::="--force-confold"
sudo apt-get update && sudo apt-get upgrade -y -o Dpkg::Options::="--force-confold"
echo -e "✅ System updated!\n"

echo -e "🔧 Installing essential tools..."
sudo apt install -y pciutils lsof curl nvtop btop jq screen sudo
echo -e "✅ Tools installed... "

echo -e "🚀 Installing CUDA Toolkit..."
wget -q --show-progress https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-8
echo -e "✅ CUDA Toolkit installed!\n"

echo -e "🛑 Stopping existing GaiaNet node (if running)..."
sudo lsof -t -i:8101 | xargs sudo kill -9 2>/dev/null
echo -e "✅ GaiaNet stopped!\n"

echo -e "🗑️ Removing old GaiaNet installation..."
rm -rf $HOME/gaianet
curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/uninstall.sh' | bash
echo -e "✅ Old GaiaNet removed!\n"

echo -e "📥 Installing GaiaNet..."
mkdir -p $HOME/gaianet
curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash -s -- --ggmlcuda 12
source $HOME/.bashrc
echo -e "✅ GaiaNet installed!\n"

echo -e "📥 Downloading configuration file..."
wget -q -O "$HOME/gaianet/config.json" https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen-2.5-coder-7b-instruct_rustlang/config.json
echo -e "✅ Configuration file downloaded!\n"

echo -e "🛠️ Updating configuration..."
CONFIG_FILE="$HOME/gaianet/config.json"
jq '.chat = "https://huggingface.co/gaianet/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-3B-Instruct-Q5_K_M.gguf"' "$CONFIG_FILE" > tmp.$$.json && mv tmp.$$.json "$CONFIG_FILE"
jq '.chat_name = "Qwen2.5-Coder-3B-Instruct"' "$CONFIG_FILE" > tmp.$$.json && mv tmp.$$.json "$CONFIG_FILE"
echo -e "✅ Configuration updated!\n"

echo -e "🔍 Checking configuration..."
grep '"chat":' $HOME/gaianet/config.json
grep '"chat_name":' $HOME/gaianet/config.json
echo -e "✅ Configuration check complete!\n"

echo -e "⚙️ Setting up GaiaNet..."
gaianet config --port 8101
gaianet init
echo -e "✅ GaiaNet setup complete!\n"

echo -e "🚀 Starting GaiaNet..."
gaianet start
echo -e "✅ GaiaNet is now running!\n"

echo -e "📊 Displaying node info..."
gaianet info
echo -e "🎉 Installation complete! Your GaiaNet node is live! 🚀\n"
