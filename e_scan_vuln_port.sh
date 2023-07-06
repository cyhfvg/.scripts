#!/usr/bin/env bash

if [ $# -lt 2 ]
then
    echo "Usage: $0 /path/to/ip-list-file /path/to/output.gnmap"
    exit 0
fi

ports="139,445,21,22,135,111,8009,389,636,2375,2181,9200,9300,2049"

ip_list_file="$1"
output_gnmap_file="$2"

nmap -p "${ports}" -sT -iL "${ip_list_file}" -oG "${output_gnmap_file}" &>/dev/null
