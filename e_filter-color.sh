#!/usr/bin/env -S bash

content=$(cat)

echo "${content}" | col | sed -e 's/22m//g;s/31m//g;s/33m//g;s/34m//g;s/36m//g;s/1m//g;s/0m//g'
