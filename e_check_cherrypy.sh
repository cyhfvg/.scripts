#!/usr/bin/env bash

if [ $# -lt 1 ]
then
        echo "Usage: ${0} http://127.0.0.1:9000"
        exit 1
fi

url="${1}"

curl -iskL --url "${url}" | grep --color=always -iP "\w+\.py"
