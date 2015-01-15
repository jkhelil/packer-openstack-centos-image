#!/bin/bash
export PATH="/bin/:/usr/sbin:/usr/bin:/sbin:${PATH}"
apt="apt-get -qq -y"
yum="yum -q -y"

set -x

OSRELEASE="$(lsb_release -s -r | sed -e 's/\..*//')"
