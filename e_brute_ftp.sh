#!/usr/bin/env -S bash

if [ $# -lt 2 ]
then
    echo "Usage: $0 /path/to/ftp-ip.txt /path/to/username.lst /path/to/password.lst /path/to/logfile"
    exit 0
fi

ip_file="$1"
user_file="$2"
pass_file="$3"
log_file="$4"

if [ ! -f "${ip_file}" ]; then
    echo "${ip_file} should be existed."
    exit 1
fi

if [ ! -f "${user_file}" ]; then
    echo "${user_file} should be existed."
    exit 1
fi

if [ ! -f "${pass_file}" ]; then
    echo "${pass_file} should be existed."
    exit 1
fi

if [ ! -f "${log_file}" ]; then
    touch "${log_file}"
fi

hydra -v -L "${user_file}" -P "${pass_file}" -M ${ip_file} ftp  | tee -a ${log_file}
