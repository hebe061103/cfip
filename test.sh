#!/bin/bash
address_locate="Hong Kong"
colo="Hong Kong,Asia Pacific"
iplocate=$(echo "$colo" | grep "${address_locate}")
if [[ "$iplocate" != "" ]]
then
    echo "IP所属位置在:${iplocate%,*}"
else
	echo "IP所属位置在:$locate 非指定地址选择丢弃."
fi
