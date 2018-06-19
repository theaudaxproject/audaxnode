# Change the directory to ~/heliumnode
cd ~/heliumnode

# Download the new cronjob
wget https://raw.githubusercontent.com/cryptotronxyz/heliumnode/master/clearlog.sh 

# Create a cronjob for clearing the log file
if ! crontab -l | grep "~/heliumnode/clearlog.sh"; then
  (crontab -l ; echo "0 0 */2 * * ~/heliumnode/clearlog.sh") | crontab -
fi

# Give execute permission to the cron script
chmod 0700 ./clearlog.sh

./clearlog.sh
