#!/bin/bash
# vim:ft=sh

OS_TYPE=`uname -s`

if [ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ];then
    WORKDIR="/cygdrive/c/gse/gseagentw"
else
    WORKDIR="/usr/local/gse/gseagent"
fi
action="$1"

usage () {

    cat <<_E

Usage: ./`basename $0` -i|-u 

   DESCRIPTION : run as gse agent, work for server

OPTIONS:
    -h      print this help info.
    -i      install agent
    -u      uninstall agent

_E
    return 0
}

lanip () {
    ip addr | awk '/inet/{
            sub("/.*", "", $2);
            split($2, P, ".")

            if (P[1] == 10) {
                print $2
            }

            if ((P[1] == "192") && (P[2] == "168")) {
                print $2
            }

            if ((P[1] == 172) && (P[2] >= 16 && P[2] <= 31)) {
                print $2
            }
        }'
}

uninstall_WinAgent(){
        
    echo 'unnstall bk_gse_agent...'
    if [[ -f "$WORKDIR/bk_gse_daemon.exe" ]]; then
        (
            cd "$WORKDIR"
            chmod + quit.sh
            ./quit.sh
            sleep 2
        )
    fi
    rm -rf "$WORKDIR"

    return $?
}

uninstall_LinuxAgent(){

    echo 'unnstall bk_gse_agent...'
	
	crontab -l | grep -v 'cron_gse.sh' > /tmp/del_crontab_gse
    crontab /tmp/del_crontab_gse
	
    [[ -d $WORKDIR ]] || return 0
    (
        cd $WORKDIR
        chmod +x quit.sh
        ./quit.sh
        sleep 1 
        ./quit.sh
    )

    if ps aux | grep -i bk_gse_agent | grep -v grep;then
        pkill -9 gseMaster
        sleep 1
        pkill -9 AgentWorker
    fi

    report_pids=$(ps aux|grep 'gse/gseagent/plugins/bk_gse_basereport' | grep -v grep | awk '{print $2}')
    [[ -z "${report_pids}" ]] || kill -9 ${report_pids}

    rm -rf $WORKDIR

    return $?
}

install_LinuxAgent(){
	(
        echo "install gseagent..."
		cd $WORKDIR
		os_bit=`getconf LONG_BIT`
		gse_name=`ls  |grep "gseAgent${os_bit}"`
		chmod +x ${gse_name}
		ln -fs ${gse_name} bk_gse_agent
        ###实时数据上报初始化
        [[ -d $WORKDIR/plugins/basereport/ ]] &&
        {
            (
                cd $WORKDIR/plugins/basereport/
                ln -s bk_gse_basereport"${os_bit}" bk_gse_basereport
                chmod +x bk_gse_basereport"${os_bit}"
                
                # update agentip configrations in gse.conf
                ipaddr=$(lanip | head -1)
                sed -i "s/agentip\":.*/agentip\":\"$ipaddr\",/" $WORKDIR/conf/gse.conf

                python update.py
            )
        }
        ###部署采集器
        [[ -d $WORKDIR/plugins/unifyTlogc/sbin ]] &&
        {
            (
                cd $WORKDIR/plugins/unifyTlogc/sbin
                mv bk_gse_unifyTlogc${os_bit} bk_gse_unifyTlogc
            )
        }
		chmod +x start.sh
		./start.sh
        if ! crontab -l | grep 'cron_gse.sh';then
            crontab -l >/tmp/new_crontab_gse
            echo "*/1 * * * * cd /usr/local/gse/; ./cron_gse.sh 1>/dev/null 2>&1" >> /tmp/new_crontab_gse
            crontab /tmp/new_crontab_gse
        fi
	)
	
	return $?
}

install_WinAgent(){
	(
        echo "install bk_gse_agent..."
		cd $WORKDIR
		arch=''
		if uname.exe -a | grep -E 'WOW64|x86_64'; then
			arch=64
		else
			arch=32
		fi
		agent_exe_file=$(ls | grep "bk_gse_agentW${arch}")
		daemon_exe_file=$(ls | grep "bk_gse_daemonW${arch}")
		mv $agent_exe_file bk_gse_agent.exe
		mv $daemon_exe_file bk_gse_daemon.exe
		chmod +x start.sh
		./start.sh
	)
	
	return $?
}
	
if [[ $action = '-i' ]];then
    if [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then
            install_WinAgent
    elif [[ "`echo ${OS_TYPE} | grep -i 'Linux'`" ]];then
            install_LinuxAgent
    fi

elif [[ $action = '-u' ]];then

    if [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then
            uninstall_WinAgent
    elif [[ "`echo ${OS_TYPE} | grep -i 'Linux'`" ]];then
            uninstall_LinuxAgent
    fi
   
else
    usage
    exit 1
fi
