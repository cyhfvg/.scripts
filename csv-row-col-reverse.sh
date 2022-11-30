#!/usr/bin/env -S bash

:<<!
auth: @cyhfvg https://github.com/cyhfvg
date: 2022/11/29

ref: https://stackoverflow.com/questions/45682947/how-to-convert-the-column-to-row-data-using-bash-script-and-create-the-csv-file

reverse csv row and col.

usage: cat test.csv | ./csv-row-col-reverse.sh


raw:

admin,john,nancy
1,2,3
a,b,c

convert:

admin,1,a
john,2,b
nancy,3,c
!

set -euo pipefail
cd ${0%/*}

content=$(cat)

# 按行读取，按列存放，按行输出
echo "${content}" | awk '                                    # awk it is
                    BEGIN {
                        FS=",";OFS=",";start=1               # separators
                    }
                    NR>=start && $0!="" {                    # define start line and remove empties
                        # sub(/\r/,"",$NF)                   # uncomment to remove windows line endings
                        for(i=1;i<=NF;i++) {                 # all cols
                            a[i]=a[i] (NR==start?"":OFS) $i  # gather
                        }
                    }
                    END {                                    # in the end
                        for(j=1;j<i;j++) {                   # all ..
                            print a[j]                       # outputed
                        }
                    }'
