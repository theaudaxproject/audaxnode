#!/bin/bash
# mninstall.sh
# Installs Audax masternode on Ubuntu 16.04 LTS x64

installAudax () {
    echo "Installing Audax..."
    cd
    curl -Lo audax-1.0.0-x86_64-linux-gnu.tar.gz $audaxlink
    tar -xzf audax-1.0.0-x86_64-linux-gnu.tar.gz
    sudo mv audax-1.0.0 audax
    cd
    mkdir -p /home/$curruser/.audax
    
    cat > sudo /home/$curruser/.audax/audax.conf << EOL
    rpcuser=$rpcuser
    rpcpassword=$rpcpassword
    daemon=1
    rpcallowip=127.0.0.1
    listen=1
    server=1
    logtimestamps=1
    maxconnections=64
    masternode=1
    externalip=${_nodeIpAddress}
    bind=${_nodeIpAddress}
    masternodeaddr=${_nodeIpAddress}${_p2pport}
    masternodeprivkey=${_nodePrivateKey}
EOL
	
    sudo cat > sudo /etc/systemd/system/audaxd.service << EOL
    [Unit]
    Description=audaxd
    After=network.target
    [Service]
    Type=forking
    User=$curruser
    WorkingDirectory=/home/$curruser
    ExecStart=/home/$curruser/audax/bin/audaxd -datadir=/home/$curruser/.audax
    ExecStop=/home/$curruser/audax/bin/audax-cli -datadir=/home/$curruser/.audax stop
    Restart=on-abort
    [Install]
    WantedBy=multi-user.target
EOL
	
   sudo systemctl start audaxd
   sudo systemctl enable audaxd
   echo "Masternode install complete"
}


# Setup
echo "Updating system..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https build-essential cron curl gcc git g++ make sudo vim wget
clear

# check swap
if free | awk '/^Swap:/ {exit !$2}'; then
    echo ""
else
    sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && sudo cp /etc/fstab /etc/fstab.bak && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
fi

# check existing

while true; do
 if [ -d ~/.audax ]; then
   printf "~/.audax/ already exists! The installer will delete this folder. Continue anyway?(Y/n)"
   read REPLY
   if [ ${REPLY} == "Y" ]; then
      pID=$(pidof audaxd)
      if [ ${pID} ]; then
          kill ${pID}      
          rm -rf ~/.audax/
          if [ -d ~/audax ]; then
              rm -rf ~/audax/
          else
              echo ""
          fi    
          break
      else
          echo "No instance of audax running"
      fi  
   else
      if [ ${REPLY} == "n" ]; then
        exit
      fi
   fi
 else
   break
 fi
done

printf "Audax Masternode GenKey: "
read _nodePrivateKey

# Variables
echo "Setting up variables..."
audaxlink=`curl -s https://api.github.com/repos/theaudaxproject/audax/releases/latest | grep browser_download_url | grep 64-linux | cut -d '"' -f 4`
curruser=$(whoami)
rpcuser=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')
rpcpassword=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
_nodeIpAddress=$(ip route get 1 | awk '{print $NF;exit}')
_p2pport=':18200'
sleep 5s
clear

installAudax
