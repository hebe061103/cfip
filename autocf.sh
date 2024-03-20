#!/bin/bash
# better-cloudflare-ip

function bettercloudflareip(){
speed=$[$bandwidth*1024]
starttime=$(date +%s)
cloudflaretest
endtime=$(date +%s)
unset temp
if [ "$ips" == "ipv4" ]
then
	if [ $tls == 1 ]
	then
		temp=($(curl --resolve $domain:443:$anycast --retry 1 -s https://$domain/cdn-cgi/trace --connect-timeout 2 --max-time 3))
	else
		temp=($(curl -x $anycast:80 --retry 1 -s http://$domain/cdn-cgi/trace --connect-timeout 2 --max-time 3))
	fi
else
	if [ $tls == 1 ]
	then
		temp=($(curl --resolve $domain:443:$anycast --retry 1 -s https://$domain/cdn-cgi/trace --connect-timeout 2 --max-time 3))
	else
		temp=($(curl -x [$anycast]:80 --retry 1 -s http://$domain/cdn-cgi/trace --connect-timeout 2 --max-time 3))
	fi
fi
if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | grep colo= | wc -l) == 0 ]
then
	publicip=获取超时
	colo=获取超时
else
	publicip=$(echo ${temp[@]} | sed -e 's/ /\n/g' | grep ip= | cut -f 2- -d'=')
	colo=$(grep -w "($(echo ${temp[@]} | sed -e 's/ /\n/g' | grep colo= | cut -f 2- -d'='))" colo.txt | awk -F"-" '{print $1}')
fi
}

function rtthttps(){
avgms=0
n=1
for ip in `cat rtt/$1.txt`
do
	while true
	do
		if [ $n -le 3 ]
		then
			rsp=$(curl --resolve $domain:443:$ip https://$domain/cdn-cgi/trace -o /dev/null -s --connect-timeout 1 --max-time 3 -w %{time_connect}_%{http_code})
			if [ $(echo $rsp | awk -F_ '{print $2}') != 200 ]
			then
				avgms=0
				n=1
				break
			else
				avgms=$[$(echo $rsp | awk -F_ '{printf ("%d\n",$1*1000000)}')+$avgms]
				n=$[$n+1]
			fi
		else
			avgms=$[$avgms/3000]
			if [ $avgms -lt 10 ]
			then
				echo 00$avgms $ip >> rtt/$1.log
			elif [ $avgms -ge 10 ] && [ $avgms -lt 100 ]
			then
				echo 0$avgms $ip >> rtt/$1.log
			else
				echo $avgms $ip >> rtt/$1.log
			fi
			avgms=0
			n=1
			break
		fi
	done
done
rm -rf rtt/$1.txt
}

function rtthttp(){
avgms=0
n=1
for ip in `cat rtt/$1.txt`
do
	while true
	do
		if [ $n -le 3 ]
		then
			if [ $(echo $ip | grep : | wc -l) == 0 ]
			then
				rsp=$(curl -x $ip:80 http://$domain/cdn-cgi/trace -o /dev/null -s --connect-timeout 1 --max-time 3 -w %{time_connect}_%{http_code})
			else
				rsp=$(curl -x [$ip]:80 http://$domain/cdn-cgi/trace -o /dev/null -s --connect-timeout 1 --max-time 3 -w %{time_connect}_%{http_code})
			fi
			if [ $(echo $rsp | awk -F_ '{print $2}') != 200 ]
			then
				avgms=0
				n=1
				break
			else
				avgms=$[$(echo $rsp | awk -F_ '{printf ("%d\n",$1*1000000)}')+$avgms]
				n=$[$n+1]
			fi
		else
			avgms=$[$avgms/3000]
			if [ $avgms -lt 10 ]
			then
				echo 00$avgms $ip >> rtt/$1.log
			elif [ $avgms -ge 10 ] && [ $avgms -lt 100 ]
			then
				echo 0$avgms $ip >> rtt/$1.log
			else
				echo $avgms $ip >> rtt/$1.log
			fi
			avgms=0
			n=1
			break
		fi
	done
done
rm -rf rtt/$1.txt
}

function speedtesthttps(){
rm -rf log.txt speed.txt
curl --resolve $domain:443:$1 https://$domain/$file -o /dev/null --connect-timeout 1 --max-time 10 > log.txt 2>&1
cat log.txt | tr '\r' '\n' | awk '{print $NF}' | sed '1,3d;$d' | grep -v 'k\|M' >> speed.txt
for i in `cat log.txt | tr '\r' '\n' | awk '{print $NF}' | sed '1,3d;$d' | grep k | sed 's/k//g'`
do
	k=$i
	k=$[$k*1024]
	echo $k >> speed.txt
done
for i in `cat log.txt | tr '\r' '\n' | awk '{print $NF}' | sed '1,3d;$d' | grep M | sed 's/M//g'`
do
	i=$(echo | awk '{print '$i'*10 }')
	M=$i
	M=$[$M*1024*1024/10]
	echo $M >> speed.txt
done
max=0
for i in `cat speed.txt`
do
	if [ $i -ge $max ]
	then
		max=$i
	fi
done
rm -rf log.txt speed.txt
echo $max
}

function speedtesthttp(){
rm -rf log.txt speed.txt
if [ $(echo $1 | grep : | wc -l) == 0 ]
then
	curl -x $1:80 http://$domain/$file -o /dev/null --connect-timeout 1 --max-time 10 > log.txt 2>&1
else
	curl -x [$1]:80 http://$domain/$file -o /dev/null --connect-timeout 1 --max-time 10 > log.txt 2>&1
fi
cat log.txt | tr '\r' '\n' | awk '{print $NF}' | sed '1,3d;$d' | grep -v 'k\|M' >> speed.txt
for i in `cat log.txt | tr '\r' '\n' | awk '{print $NF}' | sed '1,3d;$d' | grep k | sed 's/k//g'`
do
	k=$i
	k=$[$k*1024]
	echo $k >> speed.txt
done
for i in `cat log.txt | tr '\r' '\n' | awk '{print $NF}' | sed '1,3d;$d' | grep M | sed 's/M//g'`
do
	i=$(echo | awk '{print '$i'*10 }')
	M=$i
	M=$[$M*1024*1024/10]
	echo $M >> speed.txt
done
max=0
for i in `cat speed.txt`
do
	if [ $i -ge $max ]
	then
		max=$i
	fi
done
rm -rf log.txt speed.txt
echo $max
}

function cloudflaretest(){
while true
do
	while true
	do
		rm -rf rtt rtt.txt log.txt speed.txt
		mkdir rtt
		echo "正在生成 $ips"
		unset temp
		if [ "$ips" == "ipv4" ]
		then
			n=0
			iplist=100
			while true
			do
				for i in `awk 'BEGIN{srand()} {print rand()"\t"$0}' $filename | sort -n | awk '{print $2} NR=='$iplist' {exit}' | awk -F\. '{print $1"."$2"."$3}'`
				do
					temp[$n]=$(echo $i.$(($RANDOM%256)))
					n=$[$n+1]
				done
				if [ $n -ge $iplist ]
				then
					break
				fi
			done
			while true
			do
				if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
				then
					break
				else
					for i in `awk 'BEGIN{srand()} {print rand()"\t"$0}' $filename | sort -n | awk '{print $2} NR=='$[$iplist-$(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l)]' {exit}' | awk -F\. '{print $1"."$2"."$3}'`
					do
						temp[$n]=$(echo $i.$(($RANDOM%256)))
						n=$[$n+1]
					done
				fi
			done
		else
			n=0
			iplist=100
			while true
			do
				for i in `awk 'BEGIN{srand()} {print rand()"\t"$0}' $filename | sort -n | awk '{print $2} NR=='$iplist' {exit}' | awk -F: '{print $1":"$2":"$3}'`
				do
					temp[$n]=$(echo $i:$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))))
					n=$[$n+1]
				done
				if [ $n -ge $iplist ]
				then
					break
				fi
			done
			while true
			do
				if [ $(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]
				then
					break
				else
					for i in `awk 'BEGIN{srand()} {print rand()"\t"$0}' $filename | sort -n | awk '{print $2} NR=='$[$iplist-$(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l)]' {exit}' | awk -F: '{print $1":"$2":"$3}'`
					do
						temp[$n]=$(echo $i:$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))):$(printf '%x\n' $(($RANDOM*2+$RANDOM%2))))
						n=$[$n+1]
					done
				fi
			done
		fi
		ipnum=$(echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u | wc -l)
		if [ $tasknum == 0 ]
		then
			tasknum=1
		fi
		if [ $ipnum -lt $tasknum ]
		then
			tasknum=$ipnum
		fi
		n=1
		for i in `echo ${temp[@]} | sed -e 's/ /\n/g' | sort -u`
		do
			echo $i>>rtt/$n.txt
			if [ $n == $tasknum ]
			then
				n=1
			else
				n=$[$n+1]
			fi
		done
		n=1
		while true
		do
			if [ $tls == 1 ]
			then
				rtthttps $n &
			else
				rtthttp $n &
			fi
			if [ $n == $tasknum ]
			then
				break
			else
				n=$[$n+1]
			fi
		done
		while true
		do
			n=$(ls rtt | grep txt | wc -l)
			if [ $n -ne 0 ]
			then
				echo "$(date +'%H:%M:%S') 等待RTT测试结束,剩余进程数 $n"
			else
				echo "$(date +'%H:%M:%S') RTT测试完成"
				break
			fi
			sleep 1
		done
		n=$(ls rtt | grep log | wc -l)
		if [ $n == 0 ]
		then
			echo "当前所有IP都存在RTT丢包"
			echo "继续新的RTT测试"
		else
			cat rtt/*.log > rtt.txt
			echo "待测速的IP地址"
			cat rtt.txt | sort | awk '{print $2" 往返延迟 "$1" 毫秒"}'
			for i in `cat rtt.txt | sort | awk '{print $1"_"$2}'`
			do
				avgms=$(echo $i | awk -F_ '{print $1}')
				ip=$(echo $i | awk -F_ '{print $2}')
				echo "正在测试 $ip"
				if [ $tls == 1 ]
				then
					max=$(speedtesthttps $ip)
				else
					max=$(speedtesthttp $ip)
				fi
				max=$[$max/1024]
				echo "$ip:速度$max KB/s ,系统要求速度为:$speed KB/s"
				if [ $max -gt $speed ]
				then
					let ipcfnum++
					anycast=$ip
					echo "$ip:峰值速度$ipcfnum $max KB/s" |tee -a cfiplist
					if [ $ipcfnum -eq 5 ]
					then
						status=1
						ipcfnum=0
						rm -rf rtt rtt.txt
						break
					fi
				fi
			done
			if [[ $status -eq 1 ]]
			then
				break
			fi
		fi
	done
		break
done
}
#模板文件路径
parm_path=$(cd `dirname $0`; pwd)
killall -9 mihomo
cd $parm_path
echo "" > cfiplist
url=$(sed -n '1p' url.txt)
domain=$(echo $url | cut -f 1 -d'/')
file=$(echo $url | cut -f 2- -d'/')
bandwidth=5  #设置带宽
tasknum=10   #设置多线程
ips=ipv4    #设置类型
filename=ips-v4.txt
tls=0    #是否使用https
rm -rf rtt rtt.txt log.txt speed.txt
clear
echo "缓存已经清空"
while (true)
do
linenum=$(wc -l cfiplist | awk '{print $1}')
if [  $linenum -lt 5 ];then
	bettercloudflareip
else
	sed -i '/./,/^$/!d' cfiplist
	break
fi
done
#----------------------------------------------------------------------------------------------
#开始整理config.yaml配置文件并提取代理合并入文件
echo --$date-- "开始整理配置文件并提取代理" |tee -a /tmp/cf.log
cp $parm_path/formwork /tmp/newconfig
for filename in $(ls cfiplist)
do
  while read line
  do
  let l++
  uuid=`sed -n "$l p" uuid`
  work=`sed -n "$l p" workhost`
  if echo $line | grep "峰值速度";then
  a=${line%:*}
  b=${line#*:}
  line="- {name: $b, server: $a, port: 80, type: vless, $uuid, tls: false, network: ws, ws-opts: {path: '"/?ed=2048"', headers: {$work}}}"
  sed -i '/以上为代理地址请插入/i\'"  $line"'' /tmp/newconfig
  sed -i '/以上为节点选择组的自动选择代理请插入/i\'"      - $b"'' /tmp/newconfig
  sed -i '/以上为自动选择组下面的代理地址请插入/i\'"      - $b"'' /tmp/newconfig
  sed -i '/以上为轮询组下面的代理地址请插入/i\'"      - $b"'' /tmp/newconfig
  sed -i '/以上为散列组下面的代理地址请插入/i\'"      - $b"'' /tmp/newconfig
  fi
  done < $filename
done
echo --$date-- "代理提取完成并成功生成配置文件" |tee -a /tmp/cf.log
mv /tmp/newconfig /tmp/config_cl.yaml
echo --$date-- "配置文件以生成到:/tmp/config_cl.yaml,更新完成!" |tee -a /tmp/cf.log
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "------------------------重启CLASH-----------------------------" |tee -a /tmp/cf.log
rm /usr/local/clash/config.yaml
cp /tmp/config_cl.yaml  /usr/local/clash/config.yaml
/usr/bin/mihomo -d /usr/local/clash &
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "------------------------重启CLASH完成-------------------------" |tee -a /tmp/cf.log
#执行github同步脚本
echo --$date-- "------------------------正在生成v2ray地址-------------------------" |tee -a /tmp/cf.log
$parm_path/Create_v2ray
echo --$date-- "------------------------等待代理服务稳定-------------------------" |tee -a /tmp/cf.log
sleep 5
$parm_path/Creategithubfile
#清除日志内容
a=$(grep -c "" /tmp/cf.log)
if [ $a -gt 100 ]; then
    rm /tmp/cf.log
fi
