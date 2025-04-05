#!/usr/bin/env -S bash

:<<!
auth: @cyhfvg https://github.com/cyhfvg
date: 2025/04/05

easy netstat with grep.
!


:<<!
# sudo apt-get purge bluez-alsa-utils pulseaudio-module-bluetooth ; sudo apt-get install --reinstall libspa-0.2-bluetooth && systemctl reboot     
[ 8.410259] Bluetooth: hci0: command 0xfc05 tx timeout
Bluetooth: hci0: Reading Intel version command failed (-110)
====================================================================

Bluetooth: “no default controller available”, Intel version command failed (-110) after update
[https://forum.manjaro.org/t/bluetooth-no-default-controller-available-intel-version-command-failed-110-after-update/138560]

rmmod btusb btintel
modprobe btusb btintel
!

cd "${0%/*}" || exit

# 检查是否以 root 用户运行
if [[ "$EUID" -ne 0 ]]; then
  echo "本脚本需要 root 权限，请使用 sudo 或以 root 用户身份运行。" >&2
  exit 1
fi

sudo rmmod btusb btintel
echo "rmmove btusb btintel module"

sudo modprobe btusb btintel
echo "readd btusb btintel module"

echo "bluetooth problem should be fixed. Check manually, please."
