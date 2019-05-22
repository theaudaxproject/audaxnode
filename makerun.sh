#!/bin/bash
# makerun.sh
# Make sure audaxd is always running.
# Add the following to the crontab (i.e. crontab -e)
# */5 * * * * ~/audaxnode/makerun.sh

if ps -A | grep audaxd > /dev/null
then
  exit
else
 cd ~/audax/src;
 ./audaxd -daemon &
fi
