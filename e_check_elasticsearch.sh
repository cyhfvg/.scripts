#!/usr/bin/env bash

if [ $# -lt 1 ]
then
    echo "$0 127.0.0.1"
    echo "or"
    echo "$0 127.0.0.1 9200"
    exit 0
fi

ip="${1}"
[ $# -eq 2 ] && port="${2}" || port="9200"

result=""
for url_path in $(cat ${HOME}/.scripts/0-wordlists/elasticsearch-path.lst)
do
    curl -m2 -skL "http://${ip}:${port}${url_path}" -o /dev/null -w "%{url}\t%{http_code}\n"
    sleep 0.1s
done
