#!/usr/bin/env -S bash

#set -euo pipefail
#cd ${0%/*}

if [ $# -lt 2 ]
then
    echo "Usage: $0 /path/to/url/file /path/to/output/file"
    echo ""
    echo "url example: http://127.0.0.1:9001"
    exit 0
fi

url_list_file="$1"
output_file="$2"
base_path="/actuator"

[ -f "${output_file}" ] || touch "${output_file}"
printf "\033[033m%s\033[0m exec start.\n" "$0"

while read url
do
    res_code=$(curl -s -L --connect-timeout 5 "${url}${base_path}" -o /dev/null -w "%{response_code}")
    [ "200" == "${res_code}" ] && echo "${url}" | tee -a "${output_file}"
done < "${url_list_file}"

printf "\033[032m%s\033[0m exec finish.\n" "$0"
