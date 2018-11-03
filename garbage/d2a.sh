#!/dev/null
# Copy to term, manually, one-by-one

apt update
# apt upgrade

apt install tmux

tmux

wget https://raw.githubusercontent.com/gh2o/digitalocean-debian-to-arch/debian9/install.sh -O install.sh

bash install.sh --archlinux_mirror https://ind.mirror.pkgbuild.com
# bash install.sh --archlinux_mirror http://mirror.cse.iitk.ac.in/archlinux
# bash install.sh --archlinux_mirror http://ftp.iitm.ac.in/archlinux