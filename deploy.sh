#!/bin/bash

# o JSONserver
# o UNITserver
# o JSONlocal
# x UNITlocal

test "$(whoami)" != "root" || { echo "No root"; exit 1; }
test $# -eq 2 || { echo '
  $1 <- IP
  $2 <- Hostname
'; exit 1; }

# $JSONDIR
LOCALJSONDIR=/etc/shadowsocks
SERVERJSONDIR=/etc/shadowsocks-libev
SYSTEMCTL="SYSTEMD_COLORS=1 systemctl"
PROMPT="\\033[32m[$(date)]\\033[0m" # man console_codes
SERVERPORT='443'
CIPHER='bf-cfb'
PASSWD=$(pwgen -s 32 1)
TIMEOUT='60'
SERVERPREFIX="$2"_server
LOCALPREFIX="$2"_local
SERVERFILE="$SERVERPREFIX".json
LOCALFILE="$LOCALPREFIX".json
QRFILE="$2".png

# server.JSON
rm -fv "$SERVERFILE"
cat <<EOF >"$SERVERFILE"
{"server_port" : "$SERVERPORT",
"method"       : "$CIPHER",
"password"     : "$PASSWD",
"timeout"      : "$TIMEOUT",
"fast_open"    : false}
EOF

# local.JSON
rm -fv "$LOCALFILE"
cat <<EOF >"$LOCALFILE"
{"server"       : "$1",
"server_port"   : "$SERVERPORT",
"method"        : "$CIPHER",
"password"      : "$PASSWD",
"local_address" : "127.0.0.1",
"local_port"    : "1080",
"timeout"       : "$TIMEOUT",
"fast_open"     : false}
EOF

# server.kill
echo -e "$PROMPT $1 $2 kill..."
ssh root@"$1" /bin/bash <<EOSSH
$SYSTEMCTL disable "shadowsocks-libev-server@*.service"
$SYSTEMCTL stop    "shadowsocks-libev-server@*.service"
echo "running: \$(systemctl list-units | grep -c shadowsocks-libev@)"
rm -rfv "$SERVERJSONDIR"
mkdir -v $SERVERJSONDIR
EOSSH
echo -e "$PROMPT ...finish"

# server.scp
echo -e "$PROMPT $1 $2 scp..."
scp "$SERVERFILE" root@"$1":"$SERVERJSONDIR"/
echo -e "$PROMPT ...finish"

# server.run
echo -e "$PROMPT $1 $2 run..."
ssh root@"$1" /bin/bash <<EOSSH
$SYSTEMCTL start  shadowsocks-libev-server@"$SERVERPREFIX".service
$SYSTEMCTL enable shadowsocks-libev-server@"$SERVERPREFIX".service
$SYSTEMCTL status shadowsocks-libev-server@"$SERVERPREFIX".service
EOSSH
echo -e "$PROMPT ...finish"

# local.kill
echo -e "$PROMPT local kill..."
sudo $SYSTEMCTL disable "shadowsocks-libev@*.service"
sudo $SYSTEMCTL stop    "shadowsocks-libev@*.service"
echo "running: $(systemctl list-units | grep -c shadowsocks-libev@)"
sudo rm -v "$LOCALJSONDIR"/"$LOCALFILE"
sudo cp -v "$LOCALFILE" "$LOCALJSONDIR"/
echo -e "$PROMPT ...finish"

# local.qr
echo -e "$PROMPT QR code..."
rm -v ./"$QRFILE"
SERVERIP="$1"
TAG="$2"
#https://github.com/shadowsocks/shadowsocks/wiki/Generate-QR-Code-for-Android-or-iOS-Clients#generate-via-command-line
#http://www.shadowsocks.org/en/config/quick-guide.html
PLAIN="$CIPHER:$PASSWD@$SERVERIP:$SERVERPORT"
ENCODE=$(echo -n "$PLAIN" | base64 --wrap=0)
URI="ss://$ENCODE#$TAG"
# echo "$PLAIN"
# echo "$ENCODE"
# echo "$URI"
# exit 1
echo -n "$URI" | qr
echo -n "$URI" | qr >"$QRFILE"
echo "Countinue?..."
read -r
clear
echo -e "$PROMPT ...all finished"

# local.qr
# echo -e "$PROMPT QR code..."
# rm -v ./"$QRFILE"
# for i in $(seq 0 $((LEN-1))); do
#   SERVERIP=${IP[$i]}
#   TAG=${ID[$i]}
#   #https://github.com/shadowsocks/shadowsocks/wiki/Generate-QR-Code-for-Android-or-iOS-Clients#generate-via-command-line
#   #http://www.shadowsocks.org/en/config/quick-guide.html
#   # PLAIN=$CIPHER:$PASSWORD@$SERVER:$SERVERPORT
#   PLAIN=$CIPHER:$PASSWD@$SERVERIP:$SERVERPORT
#   echo "$PLAIN"
#   echo -n "ss://"`echo -n $PLAIN | base64 --wrap=0`#$TAG | qr
#   echo -n "ss://"`echo -n $PLAIN | base64 --wrap=0`#$TAG | qr >$SERVERIP#$TAG.png
#   echo "Press Enter for next QR code..."
#   read -r
#   clear
# done
# echo "$(date) Finish."