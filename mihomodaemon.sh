#!/bin/bash
ip="www.google.com"
while true;
do
min=600
max=1200
random_number=$((RANDOM % (max - min + 1) + min))
sleep $random_number
if pidof "mihomo" >/dev/null; then
    echo "mihome is running" >/dev/null 2>&1
    result=`curl -I -o /dev/null -s -w %{http_code} $ip`
    if [[ $result != 200 ]];then
	echo "world is offline!" >/dev/null 2>&1 
    	/etc/script/ipCloudflare/custonIPlocate.sh &
    	break
    fi
else
    echo "mihome restart" >/dev/null 2>&1
    screen -S x -X screen /usr/bin/mihomo -d /usr/local/clash &
fi
done
