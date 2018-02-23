# Check smartcash is running every 5 minutes instead of 1 minute
(crontab -l | sed -e 's/*\/1 \* \* \* \*/*\/5 \* \* \* \*/g') | crontab -

# Check if upgrade is available every day instead of every 2 hours
(crontab -l | sed -e 's/*\/120 \* \*/0 0 \*\/1/g') | crontab -

# Add a cronjob to start smartcash after reboot
if ! crontab -l | grep "@reboot smartcashd"; then
  (crontab -l ; echo "@reboot smartcashd") | crontab -
fi

# Update the makerun.sh and upgrade.sh shell scripts
cd ~/smartnode
wget https://raw.githubusercontent.com/SmartCash/smartnode/master/makerun.sh -O makerun.sh
wget https://raw.githubusercontent.com/SmartCash/smartnode/master/upgrade.sh -O upgrade.sh

# Run upgrade.sh to upgrade to the latest version: v1.1.1
./upgrade.sh
