#!/usr/bin/env -S bash +e

if [ $# -lt 1 ]
then
    echo "Usage: $0 127.0.0.1"
    echo "or"
    echo "Usage: $0 127.0.0.1 2181"
    exit 0
fi

ip=$1
[ $# -eq 2 ] && port="${2}" || port="2181"

printf "\033[43m%s\033[0m\n" "${ip}"
for cmd in stat ruok reqs envi dump ; do
    # echo -e "\n\$ echo ${cmd} | nc ${ip} ${port}\n"
    # echo ${cmd} | nc ${ip} ${port}

    exec_cmd=$(echo -n "echo ${cmd} | nc -w3 ${ip} ${port}")

    echo ""
    echo $exec_cmd | xargs -I target -t bash -c 'target'
    echo ""
done
echo -e "\n==========\n"
