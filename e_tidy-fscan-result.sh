#!/usr/bin/env -S bash +e
#
# date: 2022/11/24

if [ $# -lt 2 ]
then
    echo "Usage: $0 /path/to/fscan-result-dir/ /path/to/output-dir/"
    exit 0
fi

fscan_result_dir="$1"
output_dir="$2"

# check fscan result dir {{{1
if [ ! -d ${fscan_result_dir} ]
then
    echo "fscan result dir should be exist."
    exit 1
fi
# }}}

# check output_dir {{{1
if [ ! -d ${output_dir} ]
then
    echo "${output_dir} dir is not exist."
    exit 1
fi
# }}}

# basic functions {{{1
function zmkdir() {
    [ -d "$1" ] || mkdir "$1"
}
# }}}

for fscan_file in ${fscan_result_dir}/*.txt ; do
    addr="$(basename -s ".txt" $fscan_file)"

    # no icmp {{{1
    no_icmp_dir="${output_dir}/no_icmp"
    zmkdir "${no_icmp_dir}"
    no_icmp_file="${no_icmp_dir}/${addr}.noicmp.txt"
    grep -aivP "^\(icmp\) target [0-9.]+ is alive$" $fscan_file > "${no_icmp_file}"
    # }}}

    # ip port list {{{1
    ip_port_list_dir="${output_dir}/ip_port_list"
    zmkdir "${ip_port_list_dir}"
    ip_port_file="${ip_port_list_dir}/${addr}.ip_port.lst"
    grep -aiP "^[0-9.:]+(?=\sopen)" "${no_icmp_file}" | grep -oP "^[0-9.:]+" | \
        sort | uniq | sort -n -t: -k1,2 > "${ip_port_file}"
    # }}}

    # port list {{{1
    port_list_dir="${output_dir}/port_list"
    zmkdir "${port_list_dir}"
    cut -d: -f2 "${ip_port_file}" | sort | uniq | sort -n > "${port_list_dir}/${addr}.port.lst"
    # }}}

    # url list {{{1
    url_list_dir="${output_dir}/url_list"
    zmkdir "${url_list_dir}"
    grep -aioP "http[s]?:.+?(?=\s)" "${no_icmp_file}" | sort | uniq | sort > "${url_list_dir}/${addr}.url.lst"
    grep -aiP "http[s]?:.+?(?=\s)" "${no_icmp_file}" | grep -aioP "(?<=title.)[^|]+" | sort | uniq | sort > "${url_list_dir}/${addr}.title.lst"
    # }}}

    # dc list {{{1
    dc_list_dir="${output_dir}/dc_list"
    zmkdir "${dc_list_dir}"
    grep -aiP "\s\[\+\]DC\s" "${no_icmp_file}" | sort | uniq | sort > "${dc_list_dir}/${addr}.dc.lst"
    # }}}

    # pcName list {{{1
    computer_list_dir="${output_dir}/computer_list"
    zmkdir "${computer_list_dir}"
    grep -aiP "\[-\>\]" "${no_icmp_file}" | grep -aivP "[0-9.]{7,}" | grep -aioP "(?<=\[-\>\]).+" | sort | uniq | sort > "${computer_list_dir}/${addr}.computer.lst"
    # }}}

    # smb list {{{1
    smb_list_dir="${output_dir}/smb_list"
    zmkdir "${smb_list_dir}"
    grep -P ":139$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${smb_list_dir}/${addr}.smb.139.lst"
    grep -P ":445$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${smb_list_dir}/${addr}.smb.445.lst"
    # }}}

    # ftp list {{{1
    ftp_list_dir="${output_dir}/ftp_list"
    zmkdir "${ftp_list_dir}"
    grep -P ":(21)$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${ftp_list_dir}/${addr}.ftp.lst"
    # }}}

    # rpc list {{{
    rpc_list_dir="${output_dir}/rpc_list"
    zmkdir "${rpc_list_dir}"
    grep -P ":135$" ${ip_port_file} | cut -d: -f1,2 | sort | uniq | sort  -n > "${rpc_list_dir}/${addr}.rpc.135.lst"
    grep -P ":111$" ${ip_port_file} | cut -d: -f1,2 | sort | uniq | sort  -n > "${rpc_list_dir}/${addr}.rpc.111.lst"
    # }}}

    # ajp list {{{
    ajp_list_dir="${output_dir}/ajp_list"
    zmkdir "${ajp_list_dir}"
    grep -P ":(8009)$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${ajp_list_dir}/${addr}.ajp.8009.lst"
    # }}}

    # ldap list {{{
    ldap_list_dir="${output_dir}/ldap_list"
    zmkdir "${ldap_list_dir}"
    grep -P ":((389)|(636))$" ${ip_port_file} | cut -d: -f1,2 | sort | uniq | sort -n > "${ldap_list_dir}/${addr}.ldap.lst"
    # }}}

    # docker list {{{
    docker_list_dir="${output_dir}/docker_list"
    zmkdir "${docker_list_dir}"
    grep -P ":(2375)$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${docker_list_dir}/${addr}.docker.2375.lst"
    # }}}


    # zookeeper list {{{
    zookeeper_list_dir="${output_dir}/zookeeper_list"
    zmkdir "${zookeeper_list_dir}"
    grep -P ":(2181)$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${zookeeper_list_dir}/${addr}.zookeeper.2181.lst"
    # }}}

    # elasticsearch  list {{{
    elasticsearch_list_dir="${output_dir}/elasticsearch_list"
    zmkdir "${elasticsearch_list_dir}"
    grep -P ":9200$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${elasticsearch_list_dir}/${addr}.elasticsearch.9200.lst"
    grep -P ":9300$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${elasticsearch_list_dir}/${addr}.elasticsearch.9300.lst"
    # }}}

    # nfs  list {{{
    nfs_list_dir="${output_dir}/nfs_list"
    zmkdir "${nfs_list_dir}"
    grep -P ":2049$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${nfs_list_dir}/${addr}.nfs.2049.lst"
    # }}}

    # rabbitMQ  list {{{
    rabbitMQ_list_dir="${output_dir}/rabbitMQ_list"
    zmkdir "${rabbitMQ_list_dir}"
    grep -P ":15672$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${rabbitMQ_list_dir}/${addr}.rabbitMQ.15672.lst"
    grep -P ":15692$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${rabbitMQ_list_dir}/${addr}.rabbitMQ.15692.lst"
    grep -P ":25672$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${rabbitMQ_list_dir}/${addr}.rabbitMQ.25672.lst"
    # }}}

    # redis list {{{
    redis_list_dir="${output_dir}/redis_list"
    zmkdir "${redis_list_dir}"
    grep -P ":6379$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${redis_list_dir}/${addr}.redis.6379.lst"
    # }}}

    # rsync list {{{
    rsync_list_dir="${output_dir}/rsync_list"
    zmkdir "${rsync_list_dir}"
    grep -P ":873$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${rsync_list_dir}/${addr}.rsync.873.lst"
    # }}}

    # dockerReg list {{{
    dockerReg_list_dir="${output_dir}/dockerReg_list"
    zmkdir "${dockerReg_list_dir}"
    grep -P ":5000$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${dockerReg_list_dir}/${addr}.dockerReg.5000.lst"
    # }}}

    # kibana list {{{
    kibana_list_dir="${output_dir}/kibana_list"
    zmkdir "${kibana_list_dir}"
    grep -P ":5601$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${kibana_list_dir}/${addr}.kibana.5601.lst"
    # }}}

    # vnc list {{{
    vnc_list_dir="${output_dir}/vnc_list"
    zmkdir "${vnc_list_dir}"
    grep -P ":5900$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${vnc_list_dir}/${addr}.vnc.5900.lst"
    grep -P ":5901$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${vnc_list_dir}/${addr}.vnc.5901.lst"
    # }}}

    # counchdb list {{{
    counchdb_list_dir="${output_dir}/counchdb_list"
    zmkdir "${counchdb_list_dir}"
    grep -P ":5984$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${counchdb_list_dir}/${addr}.counchdb.5984.lst"
    # }}}

    # apache_spark list {{{
    apache_spark_list_dir="${output_dir}/apache_spark_list"
    zmkdir "${apache_spark_list_dir}"
    grep -P ":6066$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${apache_spark_list_dir}/${addr}.apache_spark.6066.lst"
    # }}}

    # weblogic list {{{
    weblogic_list_dir="${output_dir}/weblogic_list"
    zmkdir "${weblogic_list_dir}"
    grep -P ":7001$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${weblogic_list_dir}/${addr}.weblogic.7001.lst"
    # }}}

    # hadoopYARN list {{{
    hadoopYARN_list_dir="${output_dir}/hadoopYARN_list"
    zmkdir "${hadoopYARN_list_dir}"
    grep -P ":8088$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${hadoopYARN_list_dir}/${addr}.hadoopYARN.8088.lst"
    # }}}

    # activeMQ list {{{
    activeMQ_list_dir="${output_dir}/activeMQ_list"
    zmkdir "${activeMQ_list_dir}"
    grep -P ":8161$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${activeMQ_list_dir}/${addr}.activeMQ.8161.lst"
    # }}}

    # jupyter list {{{
    jupyter_list_dir="${output_dir}/jupyter_list"
    zmkdir "${jupyter_list_dir}"
    grep -P ":8888$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${jupyter_list_dir}/${addr}.jupyter.8888.lst"
    # }}}

    # zabbix list {{{
    zabbix_list_dir="${output_dir}/zabbix_list"
    zmkdir "${zabbix_list_dir}"
    grep -P ":10051$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${zabbix_list_dir}/${addr}.zabbix.10051.lst"
    # }}}

    # memcached list {{{
    memcached_list_dir="${output_dir}/memcached_list"
    zmkdir "${memcached_list_dir}"
    grep -P ":11211$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${memcached_list_dir}/${addr}.memcached.11211.lst"
    # }}}

    # mongodb list {{{
    mongodb_list_dir="${output_dir}/mongodb_list"
    zmkdir "${mongodb_list_dir}"
    grep -P ":27017$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${mongodb_list_dir}/${addr}.mongodb.27017.lst"
    # }}}

    # dubbo list {{{
    dubbo_list_dir="${output_dir}/dubbo_list"
    zmkdir "${dubbo_list_dir}"
    grep -P ":28096$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${dubbo_list_dir}/${addr}.dubbo.28096.lst"
    # }}}

    # winrm list {{{
    winrm_list_dir="${output_dir}/winrm_list"
    zmkdir "${winrm_list_dir}"
    grep -P ":5985$" ${ip_port_file} | cut -d: -f1 | sort | uniq | sort -n > "${winrm_list_dir}/${addr}.winrm.5985.lst"
    # }}}
done

echo ""
[ -n "$(cat ${dc_list_dir}/*)" ] && echo "dc has items."
echo ""
[ -n "$(cat ${computer_list_dir}/*)" ] && echo "computer has items."

echo ""
[ -n "$(cat ${smb_list_dir}/*)" ] && echo "smb has items."
[ -n "$(cat ${rpc_list_dir}/*)" ] && echo "rpc has items."
[ -n "$(cat ${ajp_list_dir}/*)" ] && echo "ajp has items."
[ -n "$(cat ${ldap_list_dir}/*)" ] && echo "ldap has items."
[ -n "$(cat ${docker_list_dir}/*)" ] && echo "docker has items."
[ -n "$(cat ${zookeeper_list_dir}/*)" ] && echo "zookeeper has items."
[ -n "$(cat ${elasticsearch_list_dir}/*)" ] && echo "elasticsearch has items."
[ -n "$(cat ${nfs_list_dir}/*)" ] && echo "nfs has items."
[ -n "$(cat ${rabbitMQ_list_dir}/*)" ] && echo "rabbitMQ has items."
[ -n "$(cat ${redis_list_dir}/*)" ] && echo "redis has items."
[ -n "$(cat ${rsync_list_dir}/*)" ] && echo "rsync has items."
[ -n "$(cat ${dockerReg_list_dir}/*)" ] && echo "dockerReg has items."
[ -n "$(cat ${kibana_list_dir}/*)" ] && echo "kibana has items."
[ -n "$(cat ${vnc_list_dir}/*)" ] && echo "vnc has items."
[ -n "$(cat ${counchdb_list_dir}/*)" ] && echo "counchdb has items."
[ -n "$(cat ${apache_spark_list_dir}/*)" ] && echo "apache_spark has items."
[ -n "$(cat ${weblogic_list_dir}/*)" ] && echo "weblogic has items."
[ -n "$(cat ${hadoopYARN_list_dir}/*)" ] && echo "hadoopYARN has items."
[ -n "$(cat ${activeMQ_list_dir}/*)" ] && echo "activeMQ has items."
[ -n "$(cat ${jupyter_list_dir}/*)" ] && echo "jupyter has items."
[ -n "$(cat ${zabbix_list_dir}/*)" ] && echo "zabbix has items."
[ -n "$(cat ${memcached_list_dir}/*)" ] && echo "memcached has items."
[ -n "$(cat ${mongodb_list_dir}/*)" ] && echo "mongodb has items."
[ -n "$(cat ${dubbo_list_dir}/*)" ] && echo "dubbo has items."
[ -n "$(cat ${winrm_list_dir}/*)" ] && echo "winrm has items."
