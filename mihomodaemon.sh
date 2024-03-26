#!/bin/bash
while true;
do
min=600
max=1200
random_number=$((RANDOM % (max - min + 1) + min))
sleep $random_number
if pidof "mihomo" >/dev/null; then
    echo "mihome is running" >/dev/null 2>&1
else
    echo "mihome is stop restart" >/dev/null 2>&1
    killall -9 screen
    screen_name="x" # 要建立的screen名字
    /usr/sbin/screen -dmS $screen_name
    /usr/sbin/screen -x -S $screen_name -p 0 -X stuff "/usr/bin/mihomo -d /usr/local/clash"
    /usr/sbin/screen -x -S $screen_name -p 0 -X stuff $'\n'
fi
done
