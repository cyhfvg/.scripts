#!/usr/bin/env -S bash

if [ $# -lt 1 ]
then
    echo "Usage: $0 http://127.0.0.1:10002"
    exit 0
fi

set -euo pipefail
cd ${0%/*}

url=$1
base_path="/actuator"

for p in "/beans" "/dump" "/env" "/health" "/info" "mappings" "/trace" ; do
    exec_cmd='curl -iskL --url '"${url}${base_path}${p}"
    echo ${exec_cmd} | xargs -I target -t bash -c 'target'
    echo -e "\n\n==========\n\n"
done
