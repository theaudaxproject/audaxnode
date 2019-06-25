#!/bin/bash
# install.sh
# Installs Audax masternode on Ubuntu 16.04 LTS x64

if [ "$(whoami)" != "root" ]; then
  echo "Script must be run as user: root"
  exit -1
fi

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

# Warning that the script will reboot the server
echo "Welcome to the AUDAX Masternode installer. WARNING: This script will reboot the server when it's finished."
printf "Press Ctrl+C to cancel or Enter to continue: "
read IGNORE

cd
# Changing the SSH Port to a custom number is a good security measure against DDOS attacks
printf "Custom SSH Port(Enter to ignore): "
read VARIABLE
_sshPortNumber=${VARIABLE:-22}

# Get a new privatekey by going to console >> debug and typing audax genkey
printf "Audax Masternode GenKey: "
read _nodePrivateKey

# The RPC node will only accept connections from your localhost
_rpcUserName=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12 ; echo '')

# Choose a random and secure password for the RPC
_rpcPassword=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')

# Get the IP address of your vps which will be hosting the audax
_nodeIpAddress=$(ip route get 1 | awk '{print $NF;exit}')

# Set the connection port
_p2pport=':18200'

# Check for swap file - if none, create one
if free | awk '/^Swap:/ {exit !$2}'; then
    echo ""
else
    fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && cp /etc/fstab /etc/fstab.bak && echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
fi

# Make a new directory for audax daemon
mkdir ~/.audax/
touch ~/.audax/audax.conf

# Change the directory to ~/.audax
cd ~/.audax/

# Create the initial audax.conf file
echo "rpcuser=${_rpcUserName}
rpcpassword=${_rpcPassword}
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=64
masternode=1
externalip=${_nodeIpAddress}
bind=${_nodeIpAddress}
masternodeaddr=${_nodeIpAddress}${_p2pport}
masternodeprivkey=${_nodePrivateKey}
" > audax.conf
cd

# Install audaxd
set -e
git clone https://github.com/theaudaxproject/audax
cd audax
apt-get update -y && apt-get upgrade -y
apt-get install automake -y
add-apt-repository ppa:bitcoin/bitcoin -y
apt-get update -y
apt-get install build-essential libtool autotools-dev autoconf pkg-config libssl-dev libevent-dev libboost-all-dev  libprotobuf-dev protobuf-compiler  libdb4.8-dev libdb4.8++-dev -y
./autogen.sh
./configure
make
make install
cd src
./audaxd -daemon
cd

# Create a directory for Audax's's cronjobs
if [ -d ~/audaxnode ]; then
    rm -r ~/audaxnode
fi
mkdir audaxnode

# Change the directory to ~/audaxnode/
cd ~/audaxnode/

# Download the appropriate scripts
wget https://raw.githubusercontent.com/theaudaxproject/audaxnode/master/makerun.sh
wget https://raw.githubusercontent.com/theaudaxproject/audaxnode/master/checkdaemon.sh
wget https://raw.githubusercontent.com/theaudaxproject/audaxnode/master/clearlog.sh

# Create a cronjob for making sure audaxd is always running
if ! crontab -l | grep "~/audaxnode/makerun.sh"; then
  (crontab -l ; echo "*/2 * * * * ~/audaxnode/makerun.sh") | crontab -
fi

# Create a cronjob for making sure the daemon is never stuck
if ! crontab -l | grep "~/audaxnode/checkdaemon.sh"; then
  (crontab -l ; echo "*/30 * * * * ~/audaxnode/checkdaemon.sh") | crontab -
fi

# Create a cronjob for clearing the log file
if ! crontab -l | grep "~/audaxnode/clearlog.sh"; then
  (crontab -l ; echo "0 0 */2 * * ~/audaxnode/clearlog.sh") | crontab -
fi

# Create a cronjob for making sure audaxd runs after reboot
if ! crontab -l | grep -q "reboot audaxd"; then
  (crontab -l ; echo "@reboot sleep 12 && ~/audax/audaxd -daemon") | crontab -
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
ufw allow 18200
ufw allow "$_sshPortNumber"/tcp
ufw limit "$_sshPortNumber"/tcp
ufw logging on
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

# Create aliases for commonly use audax-cli commands to ~/.bash_alises
if [ -e ~/.bash_aliases ]
then
    if grep -q "getinfo" ~/.bash_aliases
        then
        echo "Aliases already exist, will not add..."
    else
	echo "Adding aliases for common audax-cli commands to ~/.bash_aliases"
        echo "
alias getinfo='audax-cli getinfo'
alias nodestatus='audax-cli getmasternodestatus'
alias syncstatus='audax-cli mnsync status'
alias restartnode='audax-cli stop && sleep 5 && audaxd -daemon'
        " > ~/.bash_aliases
        echo "     getinfo for 'audax-cli getinfo'"
        echo "     nodestatus for 'audax-cli getmasternodestatus'"
        echo "     syncstatus for 'audax-cli mnsync status'"
        echo "     restartnode for 'audax-cli stop && sleep 5 && audaxd -daemon'"
        echo "     Please log out/in for these changes to take effect"
    fi

else
    echo "Adding aliases for common audax-cli commands to ~/.bash_aliases"
    echo "
alias getinfo='audax-cli getinfo'
alias nodestatus='audax-cli getmasternodestatus'
alias syncstatus='audax-cli mnsync status'
alias restartnode='audax-cli stop && sleep 5 && audaxd -daemon'
    " > ~/.bash_aliases
    echo "     getinfo for 'audax-cli getinfo'"
    echo "     nodestatus for 'audax-cli getmasternodestatus'"
    echo "     syncstatus for 'audax-cli mnsync status'"
    echo "     restartnode for 'audax-cli stop && sleep 5 && audaxd -daemon'"
    echo "     Please log out/in for these changes to take effect"
fi

# Reboot the server
echo "Rebooting server"
reboot
