#!/bin/bash
ip="www.google.com"
while true;
do
sleep 600
if pidof "mihomo" >/dev/null; then
    echo "mihome is running" >/dev/null 2>&1
    result=`curl -I -o /dev/null -s -w %{http_code} $ip`
    if [[ $result != 200 ]];then
    	echo "google is offline!"
    	/etc/script/ipCloudflare/custonIPlocate.sh &
    	break
    fi
else
    echo "mihome restart" >/dev/null 2>&1
    screen -S x -X screen /usr/bin/mihomo -f /usr/local/clash/config.yaml &
fi
done
