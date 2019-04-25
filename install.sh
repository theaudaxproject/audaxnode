#!/bin/bash
# install.sh
# Installs Bold masternode on Ubuntu 16.04 LTS x64

if [ "$(whoami)" != "root" ]; then
  echo "Script must be run as user: root"
  exit -1
fi

while true; do
 if [ -d ~/.bold ]; then
   printf "~/.bold/ already exists! The installer will delete this folder. Continue anyway?(Y/n)"
   read REPLY
   if [ ${REPLY} == "Y" ]; then
      pID=$(pidof boldd)
      if [ ${pID} ]; then
          kill ${pID}      
          rm -rf ~/.bold/
          if [ -d ~/bold ]; then
              rm -rf ~/bold/
          else
              echo ""
          fi    
          break
      else
          echo "No instance of bold running"
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
echo "Welcome to the BOLD Masternode installer. WARNING: This script will reboot the server when it's finished."
printf "Press Ctrl+C to cancel or Enter to continue: "
read IGNORE

cd
# Changing the SSH Port to a custom number is a good security measure against DDOS attacks
printf "Custom SSH Port(Enter to ignore): "
read VARIABLE
_sshPortNumber=${VARIABLE:-22}

# Get a new privatekey by going to console >> debug and typing bold genkey
printf "Bold Masternode GenKey: "
read _nodePrivateKey

# The RPC node will only accept connections from your localhost
_rpcUserName=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12 ; echo '')

# Choose a random and secure password for the RPC
_rpcPassword=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')

# Get the IP address of your vps which will be hosting the bold
_nodeIpAddress=$(ip route get 1 | awk '{print $NF;exit}')

# Set the connection port
_p2pport=':18200'

# Check for swap file - if none, create one
if free | awk '/^Swap:/ {exit !$2}'; then
    echo ""
else
    fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && cp /etc/fstab /etc/fstab.bak && echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
fi

# Make a new directory for bold daemon
mkdir ~/.bold/
touch ~/.bold/bold.conf

# Change the directory to ~/.bold
cd ~/.bold/

# Create the initial bold.conf file
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
" > bold.conf
cd

# Install boldd
set -e
git clone https://github.com/theboldproject/BOLD bold
cd bold
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
./boldd -daemon
cd

# Create a directory for bold's cronjobs
if [ -d ~/boldnode ]; then
    rm -r ~/boldnode
fi
mkdir boldnode

# Change the directory to ~/boldnode/
cd ~/boldnode/

# Download the appropriate scripts
wget https://raw.githubusercontent.com/theboldproject/boldnode/master/makerun.sh
wget https://raw.githubusercontent.com/theboldproject/boldnode/master/checkdaemon.sh
wget https://raw.githubusercontent.com/theboldproject/boldnode/master/clearlog.sh

# Create a cronjob for making sure boldd runs after reboot
if ! crontab -l | grep "@reboot boldd"; then
  (crontab -l ; echo "@reboot boldd") | crontab -
fi

# Create a cronjob for making sure boldd is always running
if ! crontab -l | grep "~/boldnode/makerun.sh"; then
  (crontab -l ; echo "*/5 * * * * ~/boldnode/makerun.sh") | crontab -
fi

# Create a cronjob for making sure the daemon is never stuck
if ! crontab -l | grep "~/boldnode/checkdaemon.sh"; then
  (crontab -l ; echo "*/30 * * * * ~/boldnode/checkdaemon.sh") | crontab -
fi

# Create a cronjob for clearing the log file
if ! crontab -l | grep "~/boldnode/clearlog.sh"; then
  (crontab -l ; echo "0 0 */2 * * ~/boldnode/clearlog.sh") | crontab -
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

# Create aliases for commonly use bold-cli commands to ~/.bash_alises
if [ -e ~/.bash_aliases ]
then
    if grep -q "getinfo" ~/.bash_aliases
        then
        echo "Aliases already exist, will not add..."
    else
	echo "Adding aliases for common bold-cli commands to ~/.bash_aliases"
        echo "
alias getinfo='bold-cli getinfo'
alias nodestatus='bold-cli getmasternodestatus'
alias syncstatus='bold-cli mnsync status'
alias restartnode='bold-cli stop && sleep 5 && boldd -daemon'
        " > ~/.bash_aliases
        echo "     getinfo for 'bold-cli getinfo'"
        echo "     nodestatus for 'bold-cli getmasternodestatus'"
        echo "     syncstatus for 'bold-cli mnsync status'"
        echo "     restartnode for 'bold-cli stop && sleep 5 && boldd -daemon'"
        echo "     Please log out/in for these changes to take effect"
    fi

else
    echo "Adding aliases for common bold-cli commands to ~/.bash_aliases"
    echo "
alias getinfo='bold-cli getinfo'
alias nodestatus='bold-cli getmasternodestatus'
alias syncstatus='bold-cli mnsync status'
alias restartnode='bold-cli stop && sleep 5 && boldd -daemon'
    " > ~/.bash_aliases
    echo "     getinfo for 'bold-cli getinfo'"
    echo "     nodestatus for 'bold-cli getmasternodestatus'"
    echo "     syncstatus for 'bold-cli mnsync status'"
    echo "     restartnode for 'bold-cli stop && sleep 5 && boldd -daemon'"
    echo "     Please log out/in for these changes to take effect"
fi

# Reboot the server
echo "Rebooting server"
reboot
