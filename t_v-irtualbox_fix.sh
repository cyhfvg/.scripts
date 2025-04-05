#!/usr/bin/env -S bash

:<<!
auth: @cyhfvg https://github.com/cyhfvg
date: 2025/04/05

virtualbox start problem fix.
!

:<<!
# VirtualBox can't enable the AMD-V extension. Please disable the KVM kernel extension, recompile your kernel and reboot
!

# 检查是否以 root 用户运行
if [[ "$EUID" -ne 0 ]]; then
  echo "本脚本需要 root 权限，请使用 sudo 或以 root 用户身份运行。" >&2
  exit 1
fi

echo "check amd..."
lsmod | grep -i amd


echo "rmmove kvm_amd module"
sudo rmmod kvm_amd

echo "check amd..."
lsmod | grep -i amd
