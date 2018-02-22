# Check smartcash is running every 5 minutes instead of 1 minute
(crontab -l | sed -e 's/*\/1 \*/*\/5 \*/g') | crontab -

# Add a cronjob to start smartcash after reboot
if ! crontab -l | grep "@reboot smartcashd"; then
  (crontab -l ; echo "@reboot smartcashd") | crontab -
fi

# Update makerun.sh and upgrade.sh script
cd ~/smartnode
wget https://raw.githubusercontent.com/SmartCash/smartnode/master/makerun.sh -O makerun.sh
wget https://raw.githubusercontent.com/SmartCash/smartnode/master/upgrade.sh -O upgrade.sh
