#!/bin/bash
# checkdaemon.sh
# Make sure the daemon is not stuck.
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * ~/audaxnode/checkdaemon.sh

previousBlock=$(cat ~/audaxnode/blockcount)
currentBlock=$(audax-cli getblockcount)

audax-cli getblockcount > ~/audaxnode/blockcount

if [ "$previousBlock" == "$currentBlock" ]; then
  cd ~/audax/src;
  ./audax-cli stop;
  sleep 10;
  ./audaxd -daemon;
fi
