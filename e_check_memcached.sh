#!/usr/bin/env bash

if [ $# -lt 1 ]
then
    echo "$0 127.0.0.1"
    echo "or"
    echo "$0 127.0.0.1 11211"
    exit 0
fi

ip="${1}"
[ $# -eq 2 ] && port="${2}" || port="11211"


printf "\033[43m%s\033[0m\n" "${ip}"
for cmd in "stats" "version" "stats slabs" "stats items"
do
    exec_cmd="echo \"${cmd}\" | nc -w3 -nvC \"${ip}\" \"${port}\""
    echo "${exec_cmd}"
    timeout 1s bash -c "${exec_cmd}"
    sleep 0.1s
done
