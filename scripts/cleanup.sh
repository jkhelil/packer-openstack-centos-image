#!/bin/bash
. /tmp/common.sh
set -x

# Remove log files from the VM
find /var/log -type f -exec rm -f {} \;

# rm  hosts keys
rm -f /etc/ssh/*key*

# Remove hardware specific settings from eth0
sed -i -e 's/^\(HWADDR\|UUID\|IPV6INIT\|NM_CONTROLLED\|MTU\).*//;/^$/d' \
        /etc/sysconfig/network-scripts/ifcfg-eth0
# Remove all kernels except the current version
rpm -qa | grep ^kernel-[0-9].* | sort | grep -v $(uname -r) | \
        xargs -r yum -y remove
yum -y clean all
# Have a sane vimrc
echo "set background=dark" >> /etc/vimrc
rm /tmp/common.sh
