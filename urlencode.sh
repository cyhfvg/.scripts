#!/usr/bin/env -S bash

:<<!
auth: @cyhfvg https://github.com/cyhfvg
date: 2022/12/04

require: python3 or python2 or php

urlencode / urldecode
!

if [ $# -lt 1 ]; then
    echo "Usage: cat input.txt | $0 -d"
    echo "or Usage: cat input.txt | $0 -e"
    exit 0
fi

if [ "$1" = "-d" ]; then
    mode="DECODE"
elif [ "$1" = "-e" ]; then
    mode="ENCODE"
else
    echo "mode should be '-d' / '-e'."
    exit 1
fi

content=$(cat)
content=$(echo "${content}" | sed -e 's#\\#\\\\#g' -e "s#'#\\\\'#g" -e 's#"#\\"#g')

if which python3 &>/dev/null; then
    if [ $mode = "DECODE" ]; then
        python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus('${content}'))"
        exit 0
    elif [ $mode = "ENCODE" ]; then
        python3 -c "import sys, urllib.parse as ul; print(ul.quote_plus('${content}'))"
        exit 0
    fi
elif which python2 &>/dev/null; then
    if [ $mode = "DECODE" ]; then
        python2 -c "import sys, urllib as ul; print ul.unquote_plus('${content}')"
        exit 0
    elif [ $mode = "ENCODE" ]; then
        python2 -c "import sys, urllib as ul; print ul.quote_plus('${content}')"
        exit 0
    fi
elif which php &>/dev/null; then
    if [ $mode = "DECODE" ]; then
        echo $content | php -R 'echo urldecode($argn)."\n";'
        exit 0
    elif [ $mode = "ENCODE" ]; then
        echo $content | php -R 'echo urlencode($argn)."\n";'
        exit 0
    fi
fi
