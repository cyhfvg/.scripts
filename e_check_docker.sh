#!/usr/bin/env -S bash +e

if [ $# -lt 2 ]
then
    echo "Usage: $0 /path/to/docker-ip.txt /path/to/output_dir"
    exit 0
fi

ip_file="$1"
output_dir="$2"

if [ ! -f "${ip_file}" ]; then
    echo "${ip_file} should be existed."
    exit 1
fi

if [ ! -e "${output_dir}" ]; then
    mkdir -p "${output_dir}"
elif [ ! -d "${output_dir}" ]; then
    echo "${output_dir} should be a directory."
    exit 1
fi
output_dir=$(realpath "${output_dir}")

port="2375"
for ip in $(cat "${ip_file}"); do
    if echo "${ip}" | grep -sq -iP "^\d+\.\d+\.\d+\.\d+$" ; then
        echo ">>>>>"
        echo -e "${ip}"

        output_file="${output_dir}/${ip}.txt"

        exec_cmd=$(echo -n "curl -X GET -sk http://${ip}:${port}/containers/json")
        echo $exec_cmd | xargs -I target -t bash -c 'target' | tee -a "${output_file}"
        exec_cmd=$(echo -n "curl -X GET -sk http://${ip}:${port}/images/json")
        echo $exec_cmd | xargs -I target -t bash -c 'target' | tee -a "${output_file}"

        echo -e "<<<<<\n"
    fi
done
