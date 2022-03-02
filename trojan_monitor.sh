#!/bin/sh 

pname=$(netstat -nlp | grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\:1234" | awk '{print $7}')
[ (echo "$pname" | grep -q trojan) ] || {
	pid=$(echo "$pname" | sed -e "s/\/.*//g")
	logger -t $0 "Start trojan ..."
	kill -9 $pid
	killall -q -9 ssr-monitor
	export SSL_CERT_FILE=/etc/cacert.pem
	/usr/bin/trojan -c /etc/trojan_config.json 2>&1 | logger -t "trojan" &
}
