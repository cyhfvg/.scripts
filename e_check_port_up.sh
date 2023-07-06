#!/usr/bin/env bash

if [ $# -lt 2 ]
then
    echo "Usage: ${0} 127.0.0.1 4444"
    exit 1
fi

ip="${1}"
port="${2}"



if nc -z -w 3 -n "${ip}" "${port}" &>/dev/null;
then
    printf "${ip} \033[33m${port}\033[0m \033[32mOPENED\033[0m\n"
else
    printf "${ip} \033[33m${port}\033[0m \033[31mCLOSED\033[0m\n"
fi
