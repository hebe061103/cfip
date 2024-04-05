#!/bin/bash
while true;
do
sleep 30
name=`pidof mihomo`
if [[ $name == "" ]]; then
   /usr/bin/mihomo -d /usr/local/clash &
fi
done

