#!/bin/bash
# vim:ft=sh

OS_TYPE=`uname -s`

if [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then
    PREFIX="/cygdrive/c"
else
    PREFIX="/usr/local"
fi

SERVER_IP="__PAAS_IP__:__NGINX_PORT__"
CMDB_IP="__PAAS_IP__:8888"
INSTALL_DIR="$PREFIX/gse"
TMPDIR="/tmp/tmpgse"

## get associated LAN ip address
getlanip () {

    ip addr | \
       awk -F '[ /]+' 'BEGIN{
            PRIVATE_PREFIX["10"]="";
            PRIVATE_PREFIX["172"]="";
    }
    /inet /{
            split($3, A, ".");
            if (A[1] in PRIVATE_PREFIX) {
                    print $3
            }

            if ((A[1] == 192) && (A[2] >= 168)) {
                    print $3
            }
    }'

return 0
}

[[ -d "$TMPDIR" ]] || mkdir $TMPDIR

echo "install bk_gse_agent..."

[[ `which curl` ]] || { echo "curl comman not support, install it first."; exit 1; }

if [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then

    curl -o $TMPDIR/agent_win.tar.gz  http://${SERVER_IP}/download/direct/agent_win.tar.gz
    (
        cd $TMPDIR
        tar -xf agent_win.tar.gz
        bash install.sh -u
        [[ -d $INSTALL_DIR ]] || mkdir -p $INSTALL_DIR
        cp -rf $TMPDIR/* $INSTALL_DIR
        cd $INSTALL_DIR
        [[ -d $TMPDIR ]] && rm -rf $TMPDIR
        bash install.sh -i
    )
    ip=`ipconfig | awk 'BEGIN{IGNORECASE=1}$1 ~ /IPv4/{print $NF}'`

elif [[ "`echo ${OS_TYPE} | grep -i 'Linux'`" ]];then

    curl -o $TMPDIR/agent_linux.tar.gz  http://${SERVER_IP}/download/direct/agent_linux.tar.gz
    (
        cd $TMPDIR
        tar -xf agent_linux.tar.gz
        bash install.sh -u
        [[ -d $INSTALL_DIR ]] || mkdir -p $INSTALL_DIR
        cp -rf $TMPDIR/* $INSTALL_DIR
        cd $INSTALL_DIR
        [[ -d $TMPDIR ]] && rm -rf $TMPDIR
        bash install.sh -i
    )
    ip=$(echo $(getlanip) | cut -d ' ' -f 1)
fi

if [ ! -z "$ip" ]; then
    curl -d "ip=${ip}&hostname=$(hostname)" http://${CMDB_IP}/api/host/enterIP
fi
exit $?
