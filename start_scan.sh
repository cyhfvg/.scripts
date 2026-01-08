#!/usr/bin/env bash

dst_output_root_path="${1}"

path_alive_dir="${dst_output_root_path}/01-alive-ip"
path_portscan_dir="${dst_output_root_path}/02-port-scan"
path_scan_fscan_dir="${dst_output_root_path}/03-vuln-scan-fscan"
path_scan_afrog_dir="${dst_output_root_path}/04-vuln-scan-afrog"

today="$(date +%Y%m%d)"
# edit me {{{1
all_ip_file="/c/080-work/ip.txt"
BIN_FSCAN_PATH="/c/020-MYTOOL/010-bin/fscan.exe"
BIN_AFROG_PATH="/c/020-MYTOOL/010-bin/afrog.exe"
SCRIPT_FPING_PATH="/c/020-MYTOOL/021-scripts/t_fping_check_alive.sh"
SCRIPT_RUSTSCAN_PATH="/c/020-MYTOOL/021-scripts/t_rustscan_batch.sh"
SCRIPT_FSCAN_PATH="/c/020-MYTOOL/021-scripts/t_fscan_batch.sh"
SCRIPT_AFROG_PATH="/c/020-MYTOOL/021-scripts/t_afrog_batch.sh"
# }}}

# comman step
mkdir -p "${dst_output_root_path}"
cd "${dst_output_root_path}"

echo "========= START ALIVE SCAN =========="
mkdir -p "${path_alive_dir}"
cd "${path_alive_dir}"
alive_ip_list_file="${path_alive_dir}/$(date +%Y%m%d)-alive-ip-list.txt"
#
bash "${SCRIPT_FPING_PATH}" "${all_ip_file}" "${alive_ip_list_file}" --chunk-size 1024 --jobs 7

# ==============================================
echo "========= START PORT SCAN =========="
mkdir -p "${path_portscan_dir}"
cd "${path_portscan_dir}"
ip_ports_file="${path_portscan_dir}/ip_ports.txt"
#
 bash "${SCRIPT_RUSTSCAN_PATH}" "${alive_ip_list_file}" "${path_portscan_dir}" --ports "1-65535" --chunk-size 256 --jobs 7 --batch-size 4096 --ulimit 16384

# ==============================================
echo "========= START VULN SCAN =========="
#
echo "========= START VULN SCAN: fscan =========="
mkdir -p "${path_scan_fscan_dir}"
cd "${path_scan_fscan_dir}"
fscan_result_file="${path_scan_fscan_dir}/$(date +%Y%m%d)-fscan-result.txt"
#
bash "${SCRIPT_FSCAN_PATH}" -i "${ip_ports_file}" -b "${BIN_FSCAN_PATH}" -P 7 -o "${fscan_result_file}"

# ==============================================
echo "========= START VULN SCAN: afrog =========="
mkdir -p "${path_scan_afrog_dir}"
cd "${path_scan_afrog_dir}"
#
bash "${SCRIPT_AFROG_PATH}" -i "${fscan_result_file}" -a "${BIN_AFROG_PATH}" -o "${path_scan_afrog_dir}" -P 4 -B 50

# ==============================================
echo ""
echo "========= ALL SCAN DONE =========="

