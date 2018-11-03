#!/bin/bash

# Prep
test "$(whoami)" != "root" || { echo "Please do not run me as root"; exit 1; }
test $# -eq 3 || { echo '
  $1 <- ipv6
  $2 <- ipv4
  $3 <- hostname
'; exit 1; }

# global conf
SYSTEMCTL="SYSTEMD_COLORS=1 systemctl"
PROMPT="\\033[32m[$(date)]\\033[0m" # man console_codes
SERVERPORT='443'
# CIPHER='bf-cfb'
# CIPHER='aes-256-gcm'
CIPHER='chacha20-ietf-poly1305'
PASSWD=$(pwgen -s 32 1)
TIMEOUT='60'

# local conf
LOCALJSONDIR=/etc/shadowsocks
LOCALTITLE6="$3"6
LOCALTITLE4="$3"4
LOCALFILE6="$LOCALTITLE6".json
LOCALFILE4="$LOCALTITLE4".json

# server conf
SERVERDIR=/etc/shadowsocks-libev
SERVERTITLE="$3"S
SERVERFILE=$SERVERTITLE.json

# server json
# ss-server(1) INCOMPATIBILITY
rm -fv "$SERVERFILE"
cat <<EOF >"$SERVERFILE"
{"server":["::0","0.0.0.0"],
"server_port" : "$SERVERPORT",
"method"       : "$CIPHER",
"password"     : "$PASSWD",
"timeout"      : "$TIMEOUT",
"fast_open"    : false}
EOF

# local json
rm -fv "$LOCALFILE6"
cat <<EOF >"$LOCALFILE6"
{"server"       : "$1",
"server_port"   : "$SERVERPORT",
"method"        : "$CIPHER",
"password"      : "$PASSWD",
"local_address" : "127.0.0.1",
"local_port"    : "1080",
"timeout"       : "$TIMEOUT",
"fast_open"     : false}
EOF
rm -fv "$LOCALFILE4"
cat <<EOF >"$LOCALFILE4"
{"server"       : "$2",
"server_port"   : "$SERVERPORT",
"method"        : "$CIPHER",
"password"      : "$PASSWD",
"local_address" : "127.0.0.1",
"local_port"    : "1080",
"timeout"       : "$TIMEOUT",
"fast_open"     : false}
EOF

# qr
# https://github.com/shadowsocks/shadowsocks/wiki/Generate-QR-Code-for-Android-or-iOS-Clients#generate-via-command-line
# http://www.shadowsocks.org/en/config/quick-guide.html
echo -e "$PROMPT QR code..."
TAG6="$3"6
TAG4="$3"4
QRPIC6="$3"6.png
QRPIC4="$3"4.png
PLAIN6="$CIPHER:$PASSWD@$1:$SERVERPORT"
PLAIN4="$CIPHER:$PASSWD@$2:$SERVERPORT"
ENCODE6=$(echo -n "$PLAIN6" | base64 --wrap=0)
ENCODE4=$(echo -n "$PLAIN4" | base64 --wrap=0)
URI6="ss://$ENCODE6#$TAG6"
URI4="ss://$ENCODE4#$TAG4"
rm -fv $QRPIC6 $QRPIC4
# 
clear
echo -e "$PLAIN6\n"
echo -e "$ENCODE6\n"
echo -e "$URI6\n"
echo -n "$URI6" | qr
echo -n "$URI6" | qr >$QRPIC6
echo "Countinue?..."; read -r;
# 
clear
echo -e "$PLAIN4\n"
echo -e "$ENCODE4\n"
echo -e "$URI4\n"
echo -n "$URI4" | qr
echo -n "$URI4" | qr >$QRPIC4
echo "Countinue?..."; read -r;
echo -e "$PROMPT ...all finished"

# kill local
echo -e "$PROMPT local kill..."
sudo $SYSTEMCTL disable shadowsocks-libev@"*".service
sudo $SYSTEMCTL stop    shadowsocks-libev@"*".service
echo "running: $(systemctl list-units | grep -c shadowsocks-libev@)"
sudo rm -fv "$LOCALJSONDIR"/"$LOCALFILE6"
sudo rm -fv "$LOCALJSONDIR"/"$LOCALFILE4"
echo -e "$PROMPT ...finish"

# cp local
echo -e "$PROMPT local cp..."
sudo cp -v "$LOCALFILE6" "$LOCALFILE4" "$LOCALJSONDIR"/
echo -e "$PROMPT ...finish"

# kill server
echo -e "$PROMPT $3 $2 $1 kill..."
ssh root@"$1" /bin/bash <<EOSSH
$SYSTEMCTL disable shadowsocks-libev-server@"*".service
$SYSTEMCTL stop    shadowsocks-libev-server@"*".service
echo "running: \$(systemctl list-units | grep -c shadowsocks-libev@)"
rm -rfv "$SERVERDIR"
mkdir -v $SERVERDIR
EOSSH
echo -e "$PROMPT ...finish"

# scp server
# https://askubuntu.com/questions/14409/how-to-make-scp-to-use-ipv6-addresses
echo -e "$PROMPT $3 $2 $1 scp..."
scp "$SERVERFILE" root@\[$1\]:"$SERVERDIR"/
echo -e "$PROMPT ...finish"

# bring up server
echo -e "$PROMPT $3 $2 $1 run..."
ssh root@"$1" /bin/bash <<EOSSH
$SYSTEMCTL start  shadowsocks-libev-server@"$SERVERTITLE".service
$SYSTEMCTL enable shadowsocks-libev-server@"$SERVERTITLE".service
$SYSTEMCTL status shadowsocks-libev-server@"$SERVERTITLE".service
EOSSH
echo -e "$PROMPT ...finish"