#!/bin/bash
# checkdaemon.sh
# Make sure the daemon is not stuck.
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * ~/audaxnode/checkdaemon.sh

curruser=$(whoami)

previousBlock=$(cat ~/audaxnode/blockcount)
currentBlock=$(/home/$curruser/audax/bin/audax-cli getblockcount)

/home/$curruser/audax/bin/audax-cli getblockcount > ~/audaxnode/blockcount

if [ "$previousBlock" == "$currentBlock" ]; then
  cd /home/$curruser/audax/bin/;
  ./audax-cli stop;
  sleep 10;
  ./audaxd -daemon;
fi
