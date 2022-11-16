#!/usr/bin/env bash -x

:<<!
auth: @cyhfvg https://github.com/cyhfvg
date: 2022/11/16

require: ssr

This script can ban ddos ipv6 address, then restart ssr server automatically.

Some code copy from ssr.sh

===

You can create a cron job to execute this script.

Append this to /etc/crontab for execute every 5 minutes.

*/5 * * * *   root    /bin/bash /root/.scripts/ssr-ban-ipv6-ddos.sh

===

band_ip_file is the file where these have been baned ipv6 address save to.
band_ip_file should be exist.
band_ip_file can be empty.

band_ip_file example:

::ffff:125.46.32.121
::ffff:111.63.22.72

===

ssserver.log error log example:

2022-11-16 03:01:30 ERROR    tcprelay.py:1097 can not parse header when handling connection from ::ffff:111.63.22.72:13745

!

# change me {{{1
band_ip_file='/root/.scripts/baned-ip.lst'
log_file='/usr/local/shadowsocksr/shadowsocks/ssserver.log'
#

CAT='/usr/bin/cat'
GREP='/usr/bin/grep'
SORT='/usr/bin/sort'
UNIQ='/usr/bin/uniq'
UFW='/usr/sbin/ufw'
AWK='/usr/bin/awk'

do_ban=0
execute_flag=1

if [ 0 -eq $execute_flag ]
then
    exit 0
fi

if [ ! -e ${band_ip_file} ]
then
    exit 1
fi
if [ ! -e ${log_file} ]
then
    exit 1
fi

# this function copy from ssr.sh
check_pid(){
    PID=`ps -ef |$GREP -v grep | $GREP server.py |$AWK '{print $2}'`
}


for ip in $($CAT $log_file  | $GREP -aiP "\d{2}:\d{2}:\d{2} ERROR" | $GREP -aioP "(?<=from ).+(?=:\d+)" | $SORT | $UNIQ)
do
    if $GREP -q "${ip}" $band_ip_file
    then
        # echo "${ip}"
    touch $0
    else
        $UFW deny from "${ip}" &>/dev/null
        echo "${ip}" >> $band_ip_file
        do_ban=1
    fi
done

if [ $do_ban -eq 1 ]
then
    check_pid
    [[ ! -z ${PID} ]] && /etc/init.d/ssr stop
    /etc/init.d/ssr start
fi
