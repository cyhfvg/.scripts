#!/usr/bin/env -S bash +e

if [ $# -lt 1 ]
then
    echo "Usage: $0 /path/to/redis-ip.txt"
    echo "default port 6379"
    echo "result: TIME OUT / FAILURE / SUCCESS"
    exit 0
fi

ip_file="$1"

if [ ! -f "${ip_file}" ]; then
    echo "${ip_file} should be existed."
    exit 1
fi

port="6379"
for ip in $(cat "${ip_file}"); do
    if echo "${ip}" | grep -sq -iP "^\d+\.\d+\.\d+\.\d+$" ; then
        echo -ne "${ip}\t"

        content=$(echo "set bbed9acf1a41 abc" | nc -w2 -nv "${ip}" "${port}" 2>&1);

        if echo -n ${content} |grep -q -iP "(timed out)|(Connection refused)";
        then
            printf "\033[31m%s\033[0m\n" "TIME OUT";
        elif echo -n ${content} |grep -q -iP "Authentication required";
        then
            printf "\033[31m%s\033[0m Authentication required\n" "FAILURE";
        else
            printf "\033[32m%s\033[0m unAuth\n" "SUCCESS";
        fi

    fi
done
