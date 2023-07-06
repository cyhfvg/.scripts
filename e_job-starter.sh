#!/usr/bin/env -S bash -e -x

# variables {{{1

# 1 => run; 0 => do not run
run_flag=1

# job time: 00:00 ~ 06:00
rule_start_time="00:00:00"
rule_end_time="06:00:00"

log_file="/home/zgz-pen/.log/cron.log"
# }}}

# basic functions {{{1

# yyyy/mm/dd
function checkDateTime() {

    date_today="$1"
    [ "${date_today}" != "$(date +%Y/%m/%d)" ] && return 1

    start_time=$(date -d "${date_today} ${rule_start_time}" +%s)
    end_time=$(date -d "${date_today} ${rule_end_time}" +%s)
    now_time=$(date -d "$(date +'%Y/%m/%d %H:%M:%S')" +%s)

    [ $now_time -lt $start_time ] && return 1
    [ $now_time -gt $end_time ] && return 1

    return 0
}

function log() {
    echo "$(date +'%Y/%m/%d %H:%M:%S') ${1}" | tee -a $log_file
}
# }}}


# main
log "invoke script."

[ $run_flag -eq 0 ] && exit 0

log "start jobs."

#if checkDateTime "2023/04/19" ; then
#    log "zhenjiang scan port start"
#    masscan -e eth0 -p1-65535 --max-rate 5000 -iL /home/zgz-pen/23-04-24-vrp/0-fscan-dir/zj.ip.txt -oG /home/zgz-pen/23-04-24-vrp/0-fscan-dir/zj.scan.0419.masscan
#    log "zhenjiang scan port end"
#fi

#if checkDateTime "2023/04/18" ; then
#    log "zhenjiang check whatweb start"
#    bash /home/zgz-pen/.scripts/z_whatweb.sh /home/zgz-pen/23-04-24-vrp/1-fscan-tidy/url_list/ /home/zgz-pen/23-04-24-vrp/1-fscan-tidy/url_list/0-whatweb
#    log "zhenjiang check whatweb end"
#
#    log "zhenjiang scan port start"
#    masscan -e eth0 -p1-65535 --max-rate 3500 -iL /home/zgz-pen/23-04-24-vrp/0-fscan-dir/zj.ip.txt -oG /home/zgz-pen/23-04-24-vrp/0-fscan-dir/zj.scan.masscan
#    log "zhenjiang scan port end"
#fi

#if checkDateTime "2023/04/14" ; then
#    log "wuxi check whatweb start"
#    bash /home/zgz-pen/.scripts/z_whatweb.sh /home/zgz-pen/23-04-17-vrp/1-fscan-tidy.d/url_list/ /home/zgz-pen/23-04-17-vrp/1-fscan-tidy.d/url_list/0-whatweb
#    log "wuxi check whatweb end"
#
#fi

#if checkDateTime "2023/04/09" ; then
#    log "nanjing check ajp with msf start"
#    for f in /home/zgz-pen/23-04-10-vrp/0-fscan.tidy.d/ajp_list/nanjing.ajp.ip.port.d/*; do /home/zgz-pen/.scripts/z_check_ajp_with_msf.sh "${f}" /home/zgz-pen/23-04-10-vrp/0-fscan.tidy.d/ajp_list/msf-result ; done
#    log "nanjing check ajp with msf end"
#fi

#if checkDateTime "2023/04/08" ; then
#    log "nanjing scan whatweb start"
#    bash /home/zgz-pen/.scripts/z_whatweb.sh /home/zgz-pen/23-04-10-vrp/0-fscan.tidy.d/url_list /home/zgz-pen/23-04-10-vrp/0-fscan.tidy.d/url_list/0-whatweb
#    log "nanjing scan whatweb end"
#
#    log "nanjing check ajp with msf start"
#    for f in /home/zgz-pen/23-04-10-vrp/0-fscan.tidy.d/ajp_list/nanjing.ajp.ip.port.d/*
#    do
#        /home/zgz-pen/.scripts/z_check_ajp_with_msf.sh "${f}" /home/zgz-pen/23-04-10-vrp/0-fscan.tidy.d/ajp_list/msf-result ;
#    done
#    log "nanjing check ajp with msf end"
#fi

#if checkDateTime "2023/04/07" ; then
#    log "nanjing scan whatweb start"
#    bash /home/zgz-pen/.scripts/z_whatweb.sh /home/zgz-pen/23-04-10-vrp/0406.fscan.tidy.d/url_list /home/zgz-pen/23-04-10-vrp/0406.fscan.tidy.d/0-whatweb
#    log "nanjing scan whatweb end"
#fi

#if checkDateTime "2023/04/04" ; then
#    log "nanjing scan whatweb start"
#    bash /root/zgz-pen/.scripts/z_whatweb.sh /root/zgz-pen/23-04-03-vrp/nj-url-dir/ /root/zgz-pen/23-04-03-vrp/0-whatweb
#    log "nanjing scan whatweb end"
#
#    log "nanjing ajp ip scan start"
#    nmap -p- -sSVC -O -oA /root/zgz-pen/23-04-03-vrp/2-ajp-nmap.result/ajp.nmap -iL /root/zgz-pen/23-04-03-vrp/nj-ajp.ip.lst
#    log "nanjing ajp ip scan end"
#fi

#if checkDateTime "2023/03/29" ; then
#    log "shenggongsi scan whatweb start"
#    bash /root/zgz-pen/.scripts/z_whatweb.sh /root/zgz-pen/23-03-27-vrp/url_list /root/zgz-pen/23-03-27-vrp/0-whatweb
#    log "shenggongsi scan whatweb end"
#fi

#if checkDateTime "2023/02/02" ; then
#    event="yangzhou ftp brute"
#    log "${event} start"
#
#
#    msfconsole -r /root/zgz-pen/230130-vuln-reproduce/yangzhou/ftp.brute.rc
#
#
#    log "${event} end"
#
#    # ====================
#
#    event="yangzhou smb brute"
#    log "${event} start"
#
#
#    msfconsole -r /root/zgz-pen/230130-vuln-reproduce/yangzhou/smb.brute.rc
#
#
#    log "${event} end"
#fi

#if checkDateTime "2023/02/01" ; then
#    log "yangzhou scan vuln ports start"
#    bash /root/zgz-pen/.scripts/z_scan_vuln_port.sh /root/zgz-pen/230130-vuln-reproduce/yangzhou/yang_zhou-ip-range.lst /root/zgz-pen/230130-vuln-reproduce/yangzhou/yang_zhou_scan.gnmap
#    log "yangzhou scan vuln ports end"
#fi

## {{{ 2023/01/31 start
#checkDateTime "2023/01/31" && log "nantong scan vuln ports start"
#checkDateTime "2023/01/31" && bash /root/zgz-pen/.scripts/z_scan_vuln_port.sh /root/zgz-pen/230130-vuln-reproduce/nan_tong-ip-range.lst /root/zgz-pen/230130-vuln-reproduce/nan_tong_scan.gnmap
#checkDateTime "2023/01/31" && log "nantong scan vuln ports end"
## 2023/01/31 end }}}

## {{{ 2022/12/30 start
#checkDateTime "2022/12/30" && log "suzhou web : whatweb? start"
#checkDateTime "2022/12/30" && bash /root/zgz-pen/.scripts/z_whatweb.sh /root/zgz-pen/22-12-26-vrp/url_list/ /root/zgz-pen/22-12-26-vrp/whatweb-result
#checkDateTime "2022/12/30" && log "suzhou web : whatweb? end"
#
#checkDateTime "2022/12/30" && log "sheng-gong-si oracle brute start"
#checkDateTime "2022/12/30" && bash /root/zgz-pen/.scripts/t_brute_oracle_with_msf.sh
#checkDateTime "2022/12/30" && log "sheng-gong-si oracle brute end"
#
##checkDateTime "2022/12/30" && log "suzhou ftp brute start"
##checkDateTime "2022/12/30" && hydra -v -L /root/zgz-pen/0-all-info/0-wordlists/username.lst -P /root/zgz-pen/0-all-info/0-wordlists/password.lst -M /root/zgz-pen/22-12-26-vrp/ftp_list/suzhou.ftp.lst ftp | tee -a ${log_file}
##checkDateTime "2022/12/30" && log "suzhou ftp brute end"
## 2022/12/30 end }}}

## {{{ 2022/12/12 start
#checkDateTime "2022/12/13" && log "2022/12/12 sheng-gong-si web : whatweb? start"
#checkDateTime "2022/12/13" && bash /root/zgz-pen/.scripts/z_whatweb.sh /root/zgz-pen/22-12-12-vrp/url_list/ /root/zgz-pen/22-12-12-vrp/whatweb-result
#checkDateTime "2022/12/13" && log "2022/12/12 sheng-gong-si web : whatweb? end"
## 2022/12/12 end }}}

