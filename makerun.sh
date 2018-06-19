#!/bin/bash
# makerun.sh
# Make sure heliumd is always running.
# Add the following to the crontab (i.e. crontab -e)
# */5 * * * * ~/heliumnode/makerun.sh

if ps -A | grep heliumd > /dev/null
then
  exit
else
 cd ~/helium/src;
 ./heliumd -daemon &
fi
