#!/usr/bin/env -S bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 /path/to/smb-ip.txt /path/to/output_dir"
    echo ""
    echo "{smb-ip.txt} name should be like {suzhou.XXX.txt}"
    echo ""
    echo "Example: $0 ~/zgz-pen/22-12-12-vrp/smb_list/sheng-gong-si.smb.lst /tmp/shang-gong-si/smb-msf-result"
    exit 0
fi

ip_file="$1"
output_dir="$2"

if [ ! -f "${ip_file}" ]; then
    echo "${ip_file} should be existed."
    exit 1
fi
address=$(basename "${ip_file}")
address=${address%%.*}

if [ ! -e "${output_dir}" ]; then
    mkdir -p "${output_dir}"
elif [ ! -d "${output_dir}" ]; then
    echo "${output_dir} should be a directory."
    exit 1
fi
output_dir=$(realpath "${output_dir}")

msf_rc=""
while read ip; do
    output_file="${output_dir}/${ip}.txt"
    echo "${address}  ${ip}  ${output_file}"
    if echo "${ip}" | grep -sq -iP "^\d+\.\d+\.\d+\.\d+$" ; then
        msf_rc="${msf_rc}spool ${output_file};  set rhosts ${ip}; options; exploit; spool off;"
    fi
done < "${ip_file}"

if [ -n "${msf_rc}" ]; then
    msf_rc="use auxiliary/scanner/smb/smb_ms17_010;${msf_rc}exit"
    msfconsole -q -x "${msf_rc}"
fi
