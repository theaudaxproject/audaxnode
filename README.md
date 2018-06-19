# Helium Masternode
### Bash installer for Helium Masternode on Ubuntu 16.04 LTS x64

#### This shell script comes with 3 cronjobs: 
1. Make sure the daemon is always running: `makerun.sh`
2. Make sure the daemon is never stuck: `checkdaemon.sh`
4. Clear the log file every other day: `clearlog.sh`

#### Login to your vps as root, download the install.sh file and then run it:
```
wget https://rawgit.com/cryptotronxyz/heliumnode/master/install.sh
bash ./install.sh
```

#### On the client-side, add the following line to helium.conf:
```
masternode_alias vps-ip:9009 genkey collateral-txhash outputidx
```

#### Run the qt wallet, go to Masternodes tab, choose your node and click the "start alias".

#### Your masternode should be setup now!
