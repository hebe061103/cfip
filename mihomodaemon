#!/bin/bash
while true;
do
sleep 30
name=`pidof mihomo`
if [[ $name == "" ]]; then
   /usr/bin/killall -9 tmux
   /usr/bin/tmux new-session -d -s cf -n cfw
   /usr/bin/tmux send-keys -t cf:cfw "mihomo" C-m
fi
done
