#!/bin/sh
# modify by wideyu at gmail

sudo apt-get update
sudo apt-get -y install unrar unzip zip binwalk

[ -f k2p_mtk_v20d_breed.bin ] || {
	curl -L -o k2p_mtk_v20d_breed.rar http://45.11.26.12/K2P/k2p_mtk_v20d_breed.rar
	unrar e k2p_mtk_v20d_breed.rar
}

[ -f fw.sh ] || {
	curl -L -o k2p-fw-master.zip https://github.com/JimLee1996/K2P-FW/archive/master.zip
	unzip -oj k2p-fw-master.zip K2P-FW-master/fw.sh K2P-FW-master/bin/mksquashfs4 K2P-FW-master/bin/padjffs2 K2P-FW-master/bin/unsquashfs4
}

[ -f fw_patch.sh ] || {
	cp fw.sh fw_patch.sh
	sed -i "s/HuangYingNing/wideyu/g" fw_patch.sh
	sed -i "s/'\/bin\//'\//g" fw_patch.sh
	sed -i "s/awk .*/awk \'{print \$1}\'\`/g" fw_patch.sh
	sed -i '/^dd if=${FILE_NAME} of=kernel.bin bs=1 ibs=1 count=$offset1$/c\\#dd if=${FILE_NAME} of=kernel.bin bs=1 ibs=1 count=$offset1' fw_patch.sh
	sed -i '/^\#dd if=${FILE_NAME} of=kernel.bin bs=1 ibs=1 count=$size1 skip=$offset0$/c\dd if=${FILE_NAME} of=kernel.bin bs=1 ibs=1 count=$size1 skip=$offset0' fw_patch.sh
}

[ -f trojan ] || {
	curl -L -o trojan https://github.com/hanwckf/Trojan-pdv-build/releases/download/v20220216/trojan-mips1004kec-static
	chmod +x trojan
}

[ -f cacert.pem ] || {
	curl -L -o cacert.pem https://curl.haxx.se/ca/cacert.pem	
}

[ -f trojan_monitor.sh ] || {
	cat <<'EOF' > trojan_monitor.sh
#!/bin/sh 

pname=\$(netstat -nlp | grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\:1234" | awk '{print \$7}')
if echo "\$pname" | grep -q trojan ; then
	pid=\$pname
else
	pid=\$(echo "\$pname" | sed -e "s/\/.*//g")
	logger -t \$0 "Start trojan ..."
	kill -9 \$pid
	killall -q -9 ssr-monitor
	export SSL_CERT_FILE=/etc/cacert.pem
	/usr/bin/trojan -c /etc/trojan_config.json 2>&1 | logger -t "trojan" &
fi
EOF
	chmod +x trojan_monitor.sh
}

[ -f trojan_config.json ] || {
	cat <<'EOF' > trojan_config.json
{
    "run_type": "nat",
    "local_addr": "0.0.0.0",
    "local_port": 1234,
    "remote_addr": "remote.com",
    "remote_port": 443,
    "password": [
        "password"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF
}

./fw_patch.sh -e k2p_mtk_v20d_breed.bin
sudo rm -f squashfs-root/usr/bin/frpc
sudo cp -f cacert.pem squashfs-root/etc/
sudo cp -f trojan squashfs-root/usr/bin/
sudo cp -f trojan_config.json squashfs-root/etc/
sudo cp -f trojan_monitor.sh squashfs-root/root/
./fw_patch.sh -c k2p_mtk_v20d_patch.bin
dd if=/dev/zero bs=1 count=$(expr 16121856 - $(wc -c k2p_mtk_v20d_patch.bin | awk '{print $1}')) | LC_CTYPE=C tr '\0' '\377' | cat k2p_mtk_v20d_patch.bin - > k2p_mtk_v20d_patch_15M.bin
zip -j -9 k2p_mtk_v20d_patch.zip k2p_mtk_v20d_patch.bin
zip -j -9 k2p_mtk_v20d_patch_15M.zip k2p_mtk_v20d_patch_15M.bin
