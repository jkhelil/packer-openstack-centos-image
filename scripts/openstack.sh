#!/bin/bash
. /tmp/common.sh
set -x

#cloud-init repo
cat << EOF >> /etc/yum.repos.d/cloud-init.repo
[cloud-init]
Name=Cloud Init Repo
baseurl=http://repos.fedorapeople.org/repos/openstack/cloud-init/epel-6/
gpgcheck=0
enabled=1
EOF

# install cloud packages
$yum update
$yum install -F cloud-init cloud-utils heat-cfntools dracut-modules-growroot dracut

if [ "$OS" == "centos" ] ; then
    # Change default user to centos and add to wheel
    # Also make it so that we use proper cloud-init
    # configuration.
    sed -ni '/system_info.*/q;p' /etc/cloud/cloud.cfg
    cat << EOF >> /etc/cloud/cloud.cfg
system_info:
  distro: rhel
  default_user:
    name: centos
    groups: [wheel]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  paths:
    cloud_dir: /var/lib/cloud
    templates_dir: /etc/cloud/templates
  ssh_svcname: sshd

# vim:syntax=yaml
EOF

    rm -f anaconda* install.log* shutdown.sh
fi


# Configure /etc/hosts automaticaly
sed -i 's/ssh_pwauth:   0/ssh_pwauth:   0\nmanage_etc_hosts: true/' /etc/cloud/cloud.

# Start cloud-init
services --enabled=cloud-init

# Update grub to allow images write logs to console
if [ -e /boot/grub/grub.conf ] ; then
        sed -i -e 's/rhgb.*/console=ttyS0,115200n8 console=tty0 quiet/' /boot/grub/grub.conf
        cd /boot
        ln -s boot .
elif [ -e /etc/default/grub ] ; then
        sed -i -e \
            's/GRUB_CMDLINE_LINUX=\"\(.*\)/GRUB_CMDLINE_LINUX=\"console=ttyS0,115200n8 console=tty0 quiet \1/g' \
            /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
fi

# Make sure sudo works properly with openstack
sed -i "s/^.*requiretty$/Defaults !requiretty/" /etc/sudoers

# Cleanup after yum
$yum clean all

# Tweak udev to not auto-gen virtual network devices
rm -rf /etc/udev/rules.d/70-persistent-net.rules
cat <<EOF >/tmp/udev.patch.1
# ignore OpenStack default virtual interfaces
ENV{MATCHADDR}=="fa:16:3e:*", GOTO="persistent_net_generator_end"
EOF

# sed-ism: we need to N below to make this an insert rather than an append
sed -e '/\# do not use empty address/ {
  h
  r /tmp/udev.patch.1
  g
  N
}' \
  /lib/udev/rules.d/75-persistent-net-generator.rules >/etc/udev/rules.d/75-persistent-net-generator.rules


# Set up to grow root in initramfs
cat << EOF > 05-grow-root.sh
#!/bin/sh

/bin/echo
/bin/echo Resizing root filesystem

growpart --fudge 20480 -v /dev/vda 1
e2fsck -f /dev/vda1
resize2fs /dev/vda1
EOF

chmod +x 05-grow-root.sh

dracut --force --include 05-grow-root.sh /mount --install 'echo awk grep fdisk sfdisk growpart partx e2fsck resize2fs' "$(ls /boot/initramfs-*)" $(ls /boot/|grep vmlinuz|sed s/vmlinuz-//g)
rm -f 05-grow-root.sh
