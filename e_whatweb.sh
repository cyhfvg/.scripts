#!/usr/bin/env -S bash +e

# run flag
exec_flag=1
#exec_flag=0


if [ $exec_flag -eq 0 ]
then
    exit 0
fi

if [ $# -lt 2 ]
then
    echo "param is necessary."
    exit 1
fi

# *.url.lst
url_list_dir="$1"
output_dir="$2"

if [ ! -d $url_list_dir ]
then
    exit 1
fi

if [ ! -d $output_dir ]
then
    mkdir -p "${output_dir}"
fi

#/root/zgz-pen/1121-vuln-reprodece/0-fscan-result/url_list
for url_list_file in ${url_list_dir}/*.url.lst; do
    echo $url_list_file
    addr="$(basename -s .url.lst $url_list_file)"
    whatweb -a 1 -t 25 --color=never -i "$url_list_file" &> ${output_dir}/${addr}.url.whatweb
done
