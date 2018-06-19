#!/bin/bash
# checkdaemon.sh
# Make sure the daemon is not stuck.
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * ~/heliumnode/checkdaemon.sh

previousBlock=$(cat ~/heliumnode/blockcount)
currentBlock=$(helium-cli getblockcount)

helium-cli getblockcount > ~/heliumnode/blockcount

if [ "$previousBlock" == "$currentBlock" ]; then
  cd ~/helium/src;
  ./helium-cli stop;
  sleep 10;
  ./heliumd -daemon;
fi
