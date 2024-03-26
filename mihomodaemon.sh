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
    echo "mihome is stop restart" >/dev/null 2>&1
    screen_name="x"				# 要建立的screen名字
    /usr/sbin/screen -dmS $screen_name
    /usr/sbin/screen -x -S $screen_name -p 0 -X stuff "/usr/bin/mihomo -d /usr/local/clash"	# 进行执行
    /usr/sbin/screen -x -S $screen_name -p 0 -X stuff $'\n'
fi
done
