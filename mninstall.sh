#!/bin/bash
# mninstall.sh
# Installs Audax masternode on Ubuntu 16.04 LTS x64

installAudax () {
    echo "Installing Audax..."
    cd
    curl -Lo audax-1.0.1-x86_64-linux-gnu.tar.gz $audaxlink
    tar -xzf audax-1.0.1-x86_64-linux-gnu.tar.gz
    sudo mv audax-1.0.1 audax
    cd
    mkdir -p /home/$curruser/.audax
    
    sudo sh -c "echo 'rpcuser=$rpcuser
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
    ' > /home/$curruser/.audax/audax.conf"
	
   sudo sh -c "echo '[Unit]
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
   ' > /etc/systemd/system/audaxd.service"	
   
   # Create a directory for Audax's's cronjobs
   cd
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

   # Give execute permission to the cron scripts
   chmod 0700 ./makerun.sh
   chmod 0700 ./checkdaemon.sh
   chmod 0700 ./clearlog.sh
   
   
   cd
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
       alias getinfo='~/audax/bin/audax-cli getinfo'
       alias nodestatus='~/audax/bin/audax-cli getmasternodestatus'
       alias syncstatus='~/audax/bin/audax-cli mnsync status'
       alias restartnode='~/audax/bin/audax-cli stop && sleep 5 && ~/audax/bin/audaxd -daemon'
       " > ~/.bash_aliases
       echo "     getinfo for '~/audax/bin/audax-cli getinfo'"
       echo "     nodestatus for '~/audax/bin/audax-cli getmasternodestatus'"
       echo "     syncstatus for '~/audax/bin/audax-cli mnsync status'"
       echo "     restartnode for '~/audax/bin/audax-cli stop && sleep 5 && ~/audax/bin/audaxd -daemon'"
       echo "     Please log out/in for these changes to take effect"
   fi
   
   # Reboot the server
   echo "Masternode installation complete. This server will now be rebooted. If you set the SSH Port to something other than the default 22, ensure to configure your SSH client accordingly."
   sleep 4s
   reboot

   
}

# Setup
# Warning that the script will reboot the server
echo "Welcome to the AUDAX Masternode installer. WARNING: This script will reboot the server when it's finished."
printf "Press Ctrl+C to cancel or Enter to continue: "
read IGNORE

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

cd
# Changing the SSH Port to a custom number is a good security measure against DDOS attacks
printf "Custom SSH Port(Enter to ignore): "
read VARIABLE
_sshPortNumber=${VARIABLE:-22}

# Get a new privatekey by going to console >> debug and typing audax genkey
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
# sudo systemctl start audaxd
# sudo systemctl enable audaxd
# systemctl daemon-reload

# echo ""
# echo "Masternode install complete."
