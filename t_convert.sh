#!/usr/bin/env bash

:<<!
auth: @cyhfvg https://github.com/cyhfvg
date: 2024/01/21
dependence: https://github.com/233boy/Xray
install xray node:  bash <(wget -qO- -o- https://github.com/233boy/Xray/raw/main/install.sh)

xray node convert to clash node
!


cd "${0%/*}" || exit

# VAR DEFINE {{{1
VLESS_REALITY='{"name":"NAME","type":"PROTOCOL","server":"ADDRESS","port":PORT,"udp":true,"uuid":"UID","tls":true,"servername":"SNI","flow":"FLOW","network":"P_TYPE","reality-opts":{"public-key":"PBK"},"client-fingerprint":"FP"}'

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NONE='\033[0m'
#}}}


# FUNC {{{1
function usage() {
    printf "usage:\n"
    printf "example: ${YELLOW}%s${NONE}\n" "$0 -n 'vless://XXX?encryption=none&XXX'"
    printf "${YELLOW}%s${NONE} node info\n" "-n,--node"
    printf "${YELLOW}%s${NONE} node info file list, one node per line.\n" "-f,--file"
    echo ""
}

function convert_node() {
    protocol="$(echo -n $1 | grep -ioP '^[^:]+')"
    uid="$(echo -n $1 | grep -ioP "(?<=://)[^@]+")"
    address="$(echo -n $1 | grep -ioP "(?<=@)[^:]+")"
    port="$(echo -n $1 | grep -ioP "(?<=:)[0-9^?]+(?=\?)")"
    PARAM="$(echo -n $1 | cut -d"?" -f2)"
    encryption="$(echo -n ${PARAM} | grep -ioP "(?<=encryption=)[^&^#]+")"
    security="$(echo -n ${PARAM} | grep -ioP "(?<=security=)[^&^#]+")"
    flow="$(echo -n ${PARAM} | grep -ioP "(?<=flow=)[^&^#]+")"
    p_type="$(echo -n ${PARAM} | grep -ioP "(?<=type=)[^&^#]+")"
    sni="$(echo -n ${PARAM} | grep -ioP "(?<=sni=)[^&^#]+")"
    pbk="$(echo -n ${PARAM} | grep -ioP "(?<=pbk=)[^&^#]+")"
    fp="$(echo -n ${PARAM} | grep -ioP "(?<=fp=)[^&^#]+")"
    name="$(echo -n ${PARAM} | grep -ioP "(?<=#)[-.a-zA-Z0-9]+")"
    # echo "${protocol}://${uid}@${address}:${port}?encryption=${encryption}&security=${security}&flow=${flow}&type=${p_type}&sni=${sni}&pbk=${pbk}&fp=${fp}#${name}"
    echo "${VLESS_REALITY}" | sed -e "s#NAME#${name}#" \
        -e "s#PROTOCOL#${protocol}#" \
        -e "s#ADDRESS#${address}#" \
        -e "s#PORT#${port}#" \
        -e "s#UID#${uid}#" \
        -e "s#SNI#${sni}#" \
        -e "s#FLOW#${flow}#" \
        -e "s#P_TYPE#${p_type}#" \
        -e "s#PBK#${pbk}#" \
        -e "s#FP#${fp}#"

}
# }}}


if [ $# -lt 1 ]; then
    usage
fi

NODE=""
FILE=""

while [ -n "$1" ]; do
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        -n | --node)
            shift;
            NODE="$1"
            ;;
        -f | --file)
            shift;
            FILE="${1}"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

if [ -n "${FILE}" ]; then
    for node in $(cat "${FILE}") ; do
        convert_node "${node}"
    done
    exit 0
else
    if [ -n "${NODE}" ]; then
        convert_node "${NODE}"
    fi
fi
