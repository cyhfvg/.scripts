#!/usr/bin/env -S bash

if [ $# -eq 0 ];then
    echo "Usage: $0 /path/to/grep/file"
    echo "or"
    echo "Usage: $0 /path/to/grep/dir"
    exit 0
elif [ $# -eq 1 ];then
    grep --color=always -H -aiRP "\[\+\]" "$1"
    exit 0
fi
