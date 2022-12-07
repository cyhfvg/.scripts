#!/usr/bin/env -S bash

:<<!
auth: @cyhfvg https://github.com/cyhfvg
date: 2022/12/08

require: netstat, grep

easy netstat with grep.
!

cd "${0%/*}" || exit

debug_mode=0
all_ports=""
netstat="netstat -panto"
while [ -n "$1" ]; do
    case "$1" in
        -h | --help)
            printf "usage:\n"
            printf "example: \033[33m%s\033[0m\n" "$0"
            printf "example: \033[33m%s\033[0m\n" "$0 80 443"
            printf "example: \033[33m%s\033[0m\n" "$0 80,443 4444"
            printf "example: \033[33m%s\033[0m\n" "$0 :80 :443"
            printf "example: \033[33m%s\033[0m\n" "$0 127.0.0.1"
            printf "example: \033[33m%s\033[0m\n" "$0 -4 9001"
            printf "example: \033[33m%s\033[0m\n" "$0 -6 9001"
            exit 0
            ;;
        -d | --debug)
            debug_mode=1
            ;;
        -4 | --tcp4)
            netstat="${netstat} -4"
            ;;
        -6 | --tcp6)
            netstat="${netstat} -6"
            ;;
        *)
            if echo "$1" | grep -sq -iP "[^0-9,:.]" ; then
                echo "param should be numberic port like 4444 or 80,443 ...";
                exit 1
            fi
            all_ports="${all_ports},$1"
            ;;
    esac
    shift
done

[ -z "${all_ports}" ] && (${netstat} ; exit)

# delete head/tail [,.] chars
all_ports=$(echo "${all_ports}" | sed -e 's/^[,.]\+//; s/[,.]\+$//')
# add head '('    and tail ')'
all_ports=$(echo "${all_ports}" | sed -e 's#^#(#' -e 's#$#)#')
# replace multi [.,] to single char
all_ports=$(echo "${all_ports}" | sed -e 's#,\+#)|(#g' -e 's#\.\+#.#g')
# remove '.' magci
all_ports=${all_ports//./\\.}

[ $debug_mode -eq 1 ] && echo "${all_ports}"

${netstat} 2>/dev/null | grep --color -iP "${all_ports}"
