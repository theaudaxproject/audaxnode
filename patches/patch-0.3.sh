# It turns out that reboots clear the iptables so this patch will make sure the anti-ddos script runs after reboots.

# Give execute permission to ~/smartnode/anti-ddos.sh
chmod 0700 ~/smartnode/anti-ddos.sh

# Create a cronjob to run the anti-ddos script after reboot
if ! crontab -l | grep "@reboot ~/smartnode/anti-ddos.sh"; then
  (crontab -l ; echo "@reboot ~/smartnode/anti-ddos.sh") | crontab -
fi
