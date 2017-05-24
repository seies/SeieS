#!/bin/bash

get_ip () 
{
    ## get associated LAN ip address

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

function msg_ok(){
	FTIME=$(date '+%Y%m%d%H%M%S')
	oparate=$1
	echo "$oparate ${innerip}_success_${FTIME}"
	exit 0
}

function msg_fail(){
	FTIME=$(date '+%Y%m%d%H%M%S')
	oparate=$1
	msg=$2
	echo "$oparate ${innerip}_failed_${FTIME}:$msg"
	exit 1
}

server_ip=$1
runmode=$3
[ $runmode -eq 0 ] &&
{
    mode=$5
}

shift 1
parmas="$@"
server=${server_ip%:*}
base_path=/tmp/iagent
OS_TYPE=`uname -s`

[ -d $base_path ] || mkdir -p $base_path

(
        cd $base_path
        tar -ztf gse_pgk.tar.gz 2>&1|grep error -i && curl -O  http://${server_ip}/iagent/gse_pgk.tar.gz
        if ! tar -xf gse_pgk.tar.gz  --no-same-owner; then
            msg_fail  'tar_xf_failed' "解压gse_pgk.tar.gz 安装包失败!!"
        fi
        curl -O http://${server_ip}/iagent/install_agent.sh
        curl -O http://${server_ip}/iagent/install.sh
)

modify_ipconf () {
cat > /tmp/iagent/abs/abs-iplist <<"_ACEOF"
10.104.55.126 root yy123456 22 passwd
_ACEOF
return 0
}

# 参数检查
[ $# -ne 0 ] || msg_fail 'params check failed.'

# 修改abs配置
if ! tar zxf /tmp/iagent/abs.tar.gz -C /tmp/iagent --no-same-owner; then
	msg_fail 'abs not exists.'
fi

modify_ipconf

# 替换安装脚本参数
(
	cd /tmp/iagent/abs/
	echo $params
	
	if [ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ];then
		cp abs-config_win abs-config
	else
		cp abs-config_linux  abs-config
	fi
	
	sed -i "s#\$parms#$parmas#g" abs-config

        ./mabs.sh

)

