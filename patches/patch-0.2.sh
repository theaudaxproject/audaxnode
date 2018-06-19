#Attention: There is an issue with the update.sh cronjob which is kind of good because an update 
# requires a manual start so it's better if you update manually. Only run this patch if you want to update automatically.
# This patch will fix the issue with update.sh cronjob and will then upgrade your node using the ppa.

# Check helium is running every 5 minutes instead of 1 minute
crontab -l | sed 's/.*makerun.sh/\*\/5 \* \* \* \* ~\/heliumnode\/makerun.sh/g' | crontab -

# Check if upgrade is available every two hours
crontab -l | sed 's/.*upgrade.sh/0 *\/2 \* \* \* ~\/heliumnode\/upgrade.sh/g' | crontab -

# Add a cronjob to start helium after reboot
if ! crontab -l | grep "@reboot heliumd"; then
  (crontab -l ; echo "@reboot heliumd") | crontab -
fi

# Update the makerun.sh and upgrade.sh shell scripts
cd ~/heliumnode
wget https://raw.githubusercontent.com/cryptotronxyz/heliumnode/master/makerun.sh -O makerun.sh
wget https://raw.githubusercontent.com/cryptotronxyz/heliumnode/master/upgrade.sh -O upgrade.sh

./upgrade.sh
