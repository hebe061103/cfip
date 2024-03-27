#!/bin/bash
while true;
do
sleep 30
if pidof "mihomo" >/dev/null; then
    echo "mihome is running" >/dev/null 2>&1
else
    echo "mihome is stop restart" >/dev/null 2>&1
    /usr/bin/mihomo -d /usr/local/clash &
fi
done
