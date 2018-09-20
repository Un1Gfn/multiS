#!/bin/bash

source getparam.sh


echo 'Installing required packages...'
apt update
apt upgrade
apt install \
shadowsocks-libev \
tmux \
tree \
vim \

# (shellcheck) SC2087: Quote 'EOF' to make here document expansions happen on the server side rather than on the client.
# But we need both types of expansions thus we don't quote EOF
ssh root@"$1" /bin/bash <<EOF

echo 'Set time zone to Asia/Shanghai...'
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo 'Gen /etc/adjtime...'
hwclock --systohc

echo '/etc/locale.gen: Uncomment {en_US,zh_CN,ja_jP}.* ...'
sed -i '/en_US/s/^#//g' /etc/locale.gen
sed -i '/zh_CN/s/^#//g' /etc/locale.gen
sed -i '/ja_jP/s/^#//g' /etc/locale.gen

echo 'Invoke locale-gen...'
locale-gen

echo '/etc/locale.conf: Set $LANG ...'
echo 'LANG=en_US.UTF-8' >/etc/locale.conf

echo 'Gen hostname file...'
HOSTNAME=$2
echo \$HOSTNAME >/etc/hostname

echo '/etc/hosts: Add matching entries...'
cat >/etc/hosts <<EOHOSTS
127.0.0.1 localhost
::1   localhost
127.0.1.1 \$HOSTNAME.localdomain \$HOSTNAME
EOHOSTS



echo "Enable and start services..."
systemctl enable lighttpd.service
systemctl start lighttpd.service

echo 'Cleanup...'
pacman -Scc --noconfirm

EOF

echo -n 'Reboot?...'; read -r
ssh root@"$1" systemctl reboot
exit 0

################################################################################

# [22:42:48] Starting 'vscode-linux-x64-min'...
# [22:43:41] Downloading extension: ms-vscode.node-debug2@1.25.6 ...
# [22:43:45] Downloading extension: ms-vscode.node-debug@1.25.4 ...
# events.js:183
#       throw er; // Unhandled 'error' event
#       ^

# Error: EMFILE: too many open files, open '/home/bob/aur/code/src/vscode/extensions/html-language-features/server/node_modules/lodash/toLength.js'

# *** NOTE: If the build failed due to running out of file handles (EMFILE),                                                            
# *** you will need to raise your max open file limit.
# *** This can be done by:
# *** 1) Set a higher 'nofile' limit (at least 10000) in either
# ***    /etc/systemd/system.conf.d/limits.conf (for systemd systems)                                                                   
# ***    /etc/security/limits.conf (for non-systemd systems)
# *** 2) Reboot (or log out and back in)
# *** 3) Run 'ulimit -n' and ensure the value set above is shown before                                                                 
# ***    re-attempting to build this package.

# tar cf - code/ | pv -s $(du -sb code/ | awk '{print $1}') | xz > code.tar.xz

# ssh root@$1 /bin/bash <<EOF

# ACCOUNT=$(pwgen --no-numerals --no-capitalize 5 1)
# echo "Add wheel user '$ACCOUNT'..."
# useradd $ACCOUNT -m
# echo "$ACCOUNT:1" |chpasswd
# usermod --append --groups wheel $ACCOUNT

# echo "Allow wheel sudo..."
# sed -i '/%wheel ALL=(ALL) ALL/s/^#//g' /etc/sudoers # This is already tested

# echo "Unlimited 'EMFILE'('nofile'/file handles/max open files limit)..."
# sed -i 's/#DefaultLimitNOFILE=/DefaultLimitNOFILE=10000/g' /etc/systemd/system.conf
# sed -i 's/#DefaultLimitNOFILE=/DefaultLimitNOFILE=10000/g' /etc/systemd/user.conf
# EOF

# # Swap
# fallocate -l 8192M /swapfile
# chmod 600 /swapfile
# mkswap /swapfile
# swapon /swapfile

# # Deswap
# swapoff -a
# rm -f /swapfile

################################################################################
