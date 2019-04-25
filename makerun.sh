#!/bin/bash
# makerun.sh
# Make sure boldd is always running.
# Add the following to the crontab (i.e. crontab -e)
# */5 * * * * ~/boldnode/makerun.sh

if ps -A | grep boldd > /dev/null
then
  exit
else
 cd ~/bold/src;
 ./boldd -daemon &
fi
