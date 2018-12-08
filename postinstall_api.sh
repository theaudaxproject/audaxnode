#!/bin/bash

if [ -e /root/vpsvaletreboot.txt ]; then
    hname=$(</root/installtemp/vpshostname.info)
    curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$hname"'","message":"Mast$
    rm /root/vpsvaletreboot.txt
    rm -rf /root/installtemp
fi
