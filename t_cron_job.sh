#!/usr/bin/env -S bash -e -x

# variables {{{1

# 1 => run; 0 => do not run
run_flag=1

# job time: 00:00 ~ 06:00
rule_start_time="00:00:00"
rule_end_time="06:00:00"

log_file="./.log/cron.log"
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
#    log "addressA scan port start"
#    masscan -e eth0 -p1-65535 --max-rate 5000 -iL ./23-04-24-vrp/0-fscan-dir/adA.ip.txt -oG ./23-04-24-vrp/0-fscan-dir/adA.scan.0419.masscan
#    log "addressA scan port end"
#fi
