# Audax Masternode
### Bash installer for Audax Masternode on Ubuntu 16.04 LTS x64

#### This shell script comes with 3 maintenance cronjobs: 
1. Make sure the daemon is always running: `makerun.sh`
2. Make sure the daemon is never stuck: `checkdaemon.sh`
3. Clear the log file every other day: `clearlog.sh`

#### You will need:
1. Your genkey, generated from your Audax wallet using 'masternode genkey' in the Debug console
2. A custom port for SSH, as firewall will be enabled and only the custom port will be allowed for SSH

#### Login to your vps as root, download the install.sh file and then run it:
```
wget https://raw.githubusercontent.com/theaudaxproject/audaxnode/master/install.sh && bash ./install.sh
```

#### On the client-side, add the following line to audax.conf:
```
masternode_alias vps-ip:18200 genkey collateral-txhash outputidx
```

#### Launch the Audax QT wallet
1. Go to Masternodes tab
2. Choose your node and click the "start alias" button
#### OR
1. From the debug console in your qt wallet
2. Type ```startmasternode alias false mn-alias``` (where mn-alias is the alias or name of your masternode).

#### Your masternode should be setup now!
test
test

#### Usage Tips

Check Masternode status: ```nodestatus```  
Check Masternode Sync status: ```syncstatus```  
Check current block height, wallet version: ```getinfo```  
Restart Masternode: ```restartnode```  


