#!/bin/bash
# checkdaemon.sh
# Make sure the daemon is not stuck.
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * ~/boldnode/checkdaemon.sh

previousBlock=$(cat ~/boldnode/blockcount)
currentBlock=$(bold-cli getblockcount)

bold-cli getblockcount > ~/boldnode/blockcount

if [ "$previousBlock" == "$currentBlock" ]; then
  cd ~/bold/src;
  ./bold-cli stop;
  sleep 10;
  ./boldd -daemon;
fi
