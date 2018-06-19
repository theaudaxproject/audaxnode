# New security measures using ufw
_sshPortNumber=$(grep "^[#]\{0,1\}[ ]\{0,1\}Port [0-9]\{2,\}" /etc/ssh/sshd_config | awk '{print $2}')
apt install ufw -y
ufw disable
ufw allow 9009
ufw allow "$_sshPortNumber"/tcp
ufw limit "$_sshPortNumber"/tcp
ufw logging on
ufw default deny incoming
ufw default allow outgoing
ufw --force enable
