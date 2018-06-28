#!/bin/bash
# heliumd-install.sh
# Installs heliumd without a masternode on Ubuntu 16.04 LTS x64

if [ "$(whoami)" != "root" ]; then
  echo "Script must be run as user: root"
  exit -1
fi

while true; do
 if [ -d ~/.helium ]; then
   printf "~/.helium/ already exists! The installer will delete this folder. Continue anyway?(Y/n)"
   read REPLY
   if [ ${REPLY} == "Y" ]; then
      pID=$(ps -ef | grep heliumd | awk '{print $2}')
      kill ${pID}      
      rm -rf ~/.helium/
      break
   else
      if [ ${REPLY} == "n" ]; then
        exit
      fi
   fi
 else
   break
 fi
done

# Warning that the script will reboot the server
echo "WARNING: This script will reboot the server when it's finished."
printf "Press Ctrl+C to cancel or Enter to continue: "
read IGNORE

cd
# Changing the SSH Port to a custom number is a good security measure against DDOS attacks
printf "Custom SSH Port(Enter to ignore): "
read VARIABLE
_sshPortNumber=${VARIABLE:-22}

# The RPC node will only accept connections from your localhost
_rpcUserName=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12 ; echo '')

# Choose a random and secure password for the RPC
_rpcPassword=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')

# Get the IP address of your vps which will be hosting the helium
_nodeIpAddress=$(ip route get 1 | awk '{print $NF;exit}')

# Make a new directory for helium daemon
mkdir ~/.helium/
touch ~/.helium/helium.conf

# Change the directory to ~/.helium
cd ~/.helium/

# Create the initial helium.conf file
echo "rpcuser=${_rpcUserName}
rpcpassword=${_rpcPassword}
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=64
externalip=${_nodeIpAddress}
bind=${_nodeIpAddress}
addnode=minkiz.co
" > helium.conf
cd

# Install heliumd
set -e
git clone https://github.com/heliumchain/helium
cd helium
apt-get install automake -y
add-apt-repository ppa:bitcoin/bitcoin -y
apt-get update -y
apt-get install build-essential libtool autotools-dev autoconf pkg-config libssl-dev libevent-dev libboost-all-dev  libprotobuf-dev protobuf-compiler  libdb4.8-dev libdb4.8++-dev -y
./autogen.sh
./configure  --disable-tests
make
make install
cd src
./heliumd -daemon
cd

# Create a directory for helium's cronjobs
if [ -d ~/heliumnode ]; then
    rm -r ~/heliumnode
fi
mkdir heliumnode

# Change the directory to ~/heliumnode/
cd ~/heliumnode/

# Download the appropriate scripts
wget https://raw.githubusercontent.com/cryptotronxyz/heliumnode/master/makerun.sh
wget https://raw.githubusercontent.com/cryptotronxyz/heliumnode/master/checkdaemon.sh
wget https://raw.githubusercontent.com/cryptotronxyz/heliumnode/master/clearlog.sh

# Create a cronjob for making sure heliumd runs after reboot
if ! crontab -l | grep "@reboot ~/helium/src/heliumd -daemon"; then
  (crontab -l ; echo "@reboot ~/helium/src/heliumd -daemon") | crontab -
fi

# Create a cronjob for making sure heliumd is always running
if ! crontab -l | grep "~/heliumnode/makerun.sh"; then
  (crontab -l ; echo "*/5 * * * * ~/heliumnode/makerun.sh") | crontab -
fi

# Create a cronjob for making sure the daemon is never stuck
if ! crontab -l | grep "~/heliumnode/checkdaemon.sh"; then
  (crontab -l ; echo "*/30 * * * * ~/heliumnode/checkdaemon.sh") | crontab -
fi

# Create a cronjob for clearing the log file
if ! crontab -l | grep "~/heliumnode/clearlog.sh"; then
  (crontab -l ; echo "0 0 */2 * * ~/heliumnode/clearlog.sh") | crontab -
fi

# Give execute permission to the cron scripts
chmod 0700 ./makerun.sh
chmod 0700 ./checkdaemon.sh
chmod 0700 ./clearlog.sh

# Change the SSH port
sed -i "s/[#]\{0,1\}[ ]\{0,1\}Port [0-9]\{2,\}/Port ${_sshPortNumber}/g" /etc/ssh/sshd_config

# Firewall security measures
apt install ufw -y
ufw disable
ufw allow 9009
ufw allow "$_sshPortNumber"/tcp
ufw limit "$_sshPortNumber"/tcp
ufw logging on
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

# Reboot the server
reboot
