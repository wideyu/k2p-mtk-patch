# k2p-mtk-patch

## 0x00 《失控玩家》（Free Guy）经典台词
>Code, yeah.
>'Cause it's not just zeros and ones, it's hidden messages.
>
>I like to think of myself, actually, as not a code writer, but an author.
>
>I just use zeros and ones instead of words 'cause words will let you down.
>
>But zeros and ones, never. Zeros and ones are as cool as shit.

## 0x01 K2P-mtk-官改2.0D
当年P2P领的K2P-mtk/A1 刷了官改2.0D 后，一直稳定用到2022。居家防疫期间，试了手动启用tr0jan 正常运作，于是用Github Action + bash shell scripts + tr0jan bin 做个patch版。

[k2p] 最全的斐讯官改和第三方的固件下载地址！
https://www.right.com.cn/forum/forum.php?mod=viewthread&tid=636766

```bash
[ -f k2p_mtk_v20d_breed.bin ] || {
  curl --no-progress-meter -vO http://45.11.26.12/K2P/k2p_mtk_v20d_breed.rar
  apt install unrar
  unrar e k2p_mtk_v20d_breed.rar
}
```

## 0x02 解包工具，修改fw.sh
```bash
[ -f fw.sh ] || {
	curl -L -o k2p-fw-master.zip https://github.com/JimLee1996/K2P-FW/archive/master.zip
	unzip -oj k2p-fw-master.zip K2P-FW-master/fw.sh K2P-FW-master/bin/mksquashfs4 K2P-FW-master/bin/padjffs2 K2P-FW-master/bin/unsquashfs4
}
[ -f fw_patch.sh ] || {
	cp fw.sh fw_patch.sh
	sed -i '/^dd if=${FILE_NAME} of=kernel.bin bs=1 ibs=1 count=$offset1$/c\\#dd if=${FILE_NAME} of=kernel.bin bs=1 ibs=1 count=$offset1' fw_patch.sh
	sed -i '/^\#dd if=${FILE_NAME} of=kernel.bin bs=1 ibs=1 count=$size1 skip=$offset0$/c\dd if=${FILE_NAME} of=kernel.bin bs=1 ibs=1 count=$size1 skip=$offset0' fw_patch.sh
}
```

## 0x03 trojan mips bin
>在 Padavan 上使用 trojan
>
><https://ambeta.github.io/post/zai-padavan-shang-shi-yong-trojan/>
```bash
[ -f trojan ] || {
	curl -L -o trojan https://github.com/hanwckf/Trojan-pdv-build/releases/download/v20220216/trojan-mips1004kec-static
	chmod +x trojan
}
[ -f cacert.pem ] || {
	curl -L -o cacert.pem https://curl.haxx.se/ca/cacert.pem	
}
```

## 0x04 监测脚本
/etc/root/trojan_monitor.sh，kill掉1234端口的程序，启动trojan监听1234端口
```bash
[ -f trojan_monitor.sh ] || {
	cat <<'EOF' > trojan_monitor.sh
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
EOF
	chmod +x trojan_monitor.sh
}
```

## 0x05 配置文件
/etc/trojan_config.json
```json
{
    "run_type": "nat",
    "local_addr": "0.0.0.0",
    "local_port": 1234,
    "remote_addr": "remote.com",
    "remote_port": 443,
    "password": [
        "password"
    ],
    "log_level": 2,
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
```

## 0x06 生成刷机文件，发布Release
选择删除了最大size的frpc，生成的刷机文件发布到Github Release
```bash
./fw_patch.sh -e k2p_mtk_v20d_breed.bin
sudo rm -f squashfs-root/usr/bin/frpc
sudo cp -f cacert.pem squashfs-root/etc/
sudo cp -f trojan squashfs-root/usr/bin/
sudo cp -f trojan_config.json squashfs-root/etc/
sudo cp -f trojan_monitor.sh squashfs-root/root/
./fw_patch.sh -c k2p_mtk_v20d_patch.bin
```
刷机方法1:
```bash
mtd -r write k2p_mtk_v20d_patch.bin firmware
```
刷机方法2:
k2p_mtk_v20d_patch_15M.bin 可以在Web管理网页恢复固件
