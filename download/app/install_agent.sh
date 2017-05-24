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
[[ $runmode -eq 0 ]] &&
{
    mode=$5
}

shift 1
install_parmas="$@"
server=${server_ip%:*}
base_path=/tmp/iagent
OS_TYPE=`uname -s`

[[ -d $base_path ]] || mkdir -p $base_path

which curl
[[ $? -eq 0 ]] || msg_fail "chk_curl" "curl not supported."

(
	cd $base_path
    curl -O http://${server_ip}/download/app/gse_pkg.tar.gz
    [[ ! -d gseagent ]] || rm -rf gseagent
    [[ ! -d gseagentw ]] || rm -rf gseagentw
    [[ ! -d gsebtfilesserver ]] || rm -rf gsebtfilesserver
    [[ ! -d gsetransitserver ]] || rm -rf gsetransitserver

	if ! tar -xf gse_pkg.tar.gz  --no-same-owner; then
	    msg_fail  'tar_xf_failed' "解压gse_pkg.tar.gz 安装包失败!!"
    fi
	curl -O http://${server_ip}/download/app/install_agent.sh
	curl -O http://${server_ip}/download/app/install.sh
)

if [[ $runmode -eq 0 ]] && [[ $mode == 'agent' ]]; then
    exit 0
fi

bash ${base_path}/install.sh $install_parmas
