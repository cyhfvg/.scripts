#!/usr/bin/env bash

# searchsploit -x 21145

if [ $# -lt 1 ]
then
        echo "Usage: ${0} http://127.0.0.1:4444"
        exit 1
fi

url="${1}"



for uri in "/index.html" "/index.htm" "/index.jsp" "/default.html" "/default.htm" "/default.jsp" "/home.html" "/home.htm" "/home.jsp"; do
    curl -iskL --url "${url}${uri}" -o /dev/null -w "%{url}\t%{http_code}\t%{size_download}\n"
done
