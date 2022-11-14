#!/bin/env bash

:<<!
auth: @cyhfvg https://github.com/cyhfvg
date: 2022/11/14

require: ufw

open/close firewall ports for pen.
!

if [ $# -lt 1 ]
then
    echo -e "Usage: $0 <mode>\n"
    echo "mode: open/close/status"
    echo "eg: $0 status"
    exit 1
fi

add_mode="$1"
if [ "$add_mode" != "open" ] && [ "$add_mode" != "close" ] && [ "$add_mode" != "status" ]
then
    echo "mode is open/close/status"
    exit 1
fi

if [ "$add_mode" = "status" ]
then
    ufw status
    exit
fi

port_list=(21 80 443 139 445 9001 9002 9003 9004 9005 9998 9999)

for port in ${port_list[*]}
do
    #echo ${port}
    if [ "$add_mode" = "open" ]
    then
        paste <(echo -ne "${port}\t\n${port}\t") <(ufw allow ${port});
    elif [ "$add_mode" = "close" ]
    then
        paste <(echo -ne "${port}\t\n${port}\t") <(ufw delete allow ${port});
    fi
done
