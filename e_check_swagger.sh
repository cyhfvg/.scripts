#!/usr/bin/env bash

if [ $# -lt 2 ]
then
    echo "$0 127.0.0.1 8080"
    exit 0
fi

ip="${1}"
port="${2}"

for url_path in $(cat ${HOME}/.scripts/0-wordlists/swagger-ui-path.lst)
do
    curl -m2 -iskL "${ip}:${port}${url_path}" -o /dev/null -w "%{url}\t%{http_code}\t%{size_download}\n"
    sleep 0.1s
done
