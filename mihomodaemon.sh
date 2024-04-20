#!/bin/bash
while true;
do
sleep 30
name=`pidof mihomo`
if [[ $name == "" ]]; then
    /usr/bin/tmux new-session -d -s cfip -n cf
    /usr/bin/tmux send-keys -t cfip:cf "/usr/bin/mihomo -d /usr/local/clash" C-m
fi
done
