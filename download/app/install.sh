#!/bin/bash

usage () {

    cat <<_E

Usage: ./`basename $0` -i|-u [[parmas]]

    parmas :
	###非直连，并且是proxy
	#action runmode=0 cloudid mode=pa  tasksvr_num proxy_num tasksvrip_1 tasksvrip_2 proxy_innerip_1 \
	proxy_outerip_1 proxy_innerip_2 proxy_outerip_2
	###非直连，并且是agent
	#action runmode=0 cloudid mode=agent tasksvr_num proxy_num tasksvrip_1 tasksvrip_2 proxy_innerip_1 \
	proxy_outerip_1 proxy_innerip_2 proxy_outerip_2
	###直连
	#action runmode=1 zkhost
	
OPTIONS:
    -h      print this help info.
    -i      install agent
    -u      uninstall agent
	
_E
    return 0
}

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

msg_ok(){
	FTIME=$(date '+%Y%m%d%H%M%S')
	oparate=$1
	echo "$oparate ${innerip}_success_${FTIME}"
	exit 0
}

msg_fail(){
	FTIME=$(date '+%Y%m%d%H%M%S')
	oparate=$1
	msg=$2
	echo "$oparate ${innerip}_failed_${FTIME}:$msg"
	exit 1
}

install_expect(){
	which expect
	[[ $? -eq 0 ]] || { 
	os_type=`uname -a`
	if [[ "`echo ${os_type} | grep -i 'ubuntu'`" ]];then
		apt-get -y install expect 2>&1
	else
		yum -y install expect 2>&1
	fi
	}
	if ! which expect;then
		{ echo 'expect命令无法使用'; }
	fi
}

install_telnet(){
	which telnet
	[[ $? -eq 0 ]] || { 
	    os_type=`uname -a`
	    if [[ "`echo ${os_type} | grep -i 'ubuntu'`" ]];then
	    	apt-get -y install telnet 2>&1
	    else
	    	yum -y install telnet 2>&1
	    fi
	}
	if ! which telnet;then
		{ echo 'telnet命令无法使用'; }
	fi
}


telnet_server_port(){

ip="$1"
port=$2
resFile=/tmp/temptelnnfdswgproxyplat

export PATH=/usr/sbin:/sbin:/usr/local/sbin/:/usr/local/bin:$PATH

#echo "telnet $ip $port..."
/usr/bin/expect >${resFile} 2>&1 <<EOF
set timeout 5
spawn telnet  $ip $port
expect {
"Connected*" {
     send "q\r"
     exit 0
    }
"Connection refused" {
     puts "refused\r"
     exit 1
    }
timeout {
     puts "timeout\r"
     exit 2
    }
}
exit
expect eof
EOF

if grep Connected $resFile;then
	return 0
else
	return 1
fi
}

TPORT=48533
OS_TYPE=`uname -s`
if [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then
	AGENTCONFPATH='/cygdrive/c/gse/gseagentw/conf'
elif [[ "`echo ${OS_TYPE} | grep -i 'Linux'`" ]];then
	AGENTCONFPATH='/usr/local/gse/gseagent/conf'
	BTFILECONFPATH='/data/gse/gsebtfilesserver/conf'
	TRANSITCONFPATH='/data/gse/gsetransitserver/conf'
fi

WORKDIR=$(dirname $0)

#config配置文件
TMP_CONFIG=/tmp/.config

modify_conf(){

	#把配置文件内容加载进来
	. $TMP_CONFIG

	install_telnet
	install_expect

	tmpfile='/tmp/jgoiuieenkdshg'
   	>${tmpfile}
	#拷贝配置模板到对应程序目录
	(
		cd $WORKDIR
        #解压conf包
        tar -xf conf.tar.gz -C ./
		#拷贝非直连方式的agent的配置文件
		if [[ $runmode -eq 0 ]] && [[ $mode == 'agent' ]]; then
		
			[[ -f pa_agent_gse.conf ]] || msg_fail 'copy_template_failed' 'pa_agent_gse.conf 配置模板失败不存在'
			cp -f pa_agent_gse.conf ${AGENTCONFPATH}/gse.conf
			#拷贝非直连方式的pa的配置文件
			elif [[ $runmode -eq 0 ]] && [[ $mode == 'pa' ]]; then
			    [[ -f pa_gse.conf ]] || msg_fail 'copy_template_failed' 'pa_gse.conf 配置模板失败不存在'
			    cp -f pa_gse.conf ${AGENTCONFPATH}/gse.conf
			    [[ -f bt_gse.conf ]] || msg_fail 'copy_template_failed' 'bt_gse.conf配置模板失败不存在'
			    cp -f bt_gse.conf ${BTFILECONFPATH}/gse.conf
			    [[ -f trans_gse.conf ]] || msg_fail 'copy_template_failed' 'trans_gse.conf配置模板失败不存在'
			    cp -f trans_gse.conf ${TRANSITCONFPATH}/gse.conf
			    #拷贝直连方式的agent的配置文件
			else
			    [[ -f agent_gse.conf ]] || msg_fail 'copy_template_failed' 'agent_gse.conf 配置模板失败不存在'
    			cp -f agent_gse.conf ${AGENTCONFPATH}/gse.conf
		fi
	)
	
	(
		#修改配置文件###
		cd ${AGENTCONFPATH}
		if [[ $runmode -eq 0 ]] && [[ $mode == 'agent' ]]; then
			sed -i "s#\${btfileserver}#$btfileserver#g" gse.conf
			sed -i "s#\${taskserver}#$taskserver#g" gse.conf
			sed -i "s#\${dataserver_pa_agent}#$dataserver_pa_agent#g" gse.conf
			sed -i "s#\${cloudid}#$cloudid#g" gse.conf
		elif [[ $runmode -eq 0 ]] && [[ $mode == 'pa' ]]; then
			sed -i "s#\${proxylistenip}#$proxylistenip#g" gse.conf
			sed -i "s#\${proxytaskserver}#$proxytaskserver#g" gse.conf
			sed -i "s#\${btfileserver}#$btfileserver#g" gse.conf
			sed -i "s#\${dataserver_pa_agent}#$dataserver_pa_agent#g" gse.conf
			sed -i "s#\${taskserver}#$taskserver#g" gse.conf
			sed -i "s#\${cloudid}#$cloudid#g" gse.conf
		else
			sed -i "s#\${zkhost}#$zkhost#g" gse.conf
		fi
		
		### ###修改proxy配置文件end###
		if grep -q \\$  gse.conf;then
			msg_fail 'modify_conf_failed' '修改proxy agent配置文件失败.'
		fi
	)
	
	### agent不需要配置以下项
	[[ $runmode -eq 0 ]] && [[ $mode == 'pa' ]] &&
	{
	
		cd ${BTFILECONFPATH}
		### ###修改btfileserver配置文件###
		#添加平台id
		sed -i "s#\${cloudid}#$cloudid#g" gse.conf
		#添加其他
		sed -i "s#\${btServerOuterIP}#$btServerOuterIP#g" gse.conf
		sed -i "s#\${btfilesvrscfg}#$btfilesvrscfg#g" gse.conf
		### ###修改btfileserver配置文件end###
		if grep -q \\$  gse.conf;then
			msg_fail 'modify_conf_failed' '修改btfileserver配置文件失败'
		fi

        cd ${TRANSITCONFPATH}                       
        ###修改transitserver配置文件###
        #添加dataserver
        sed -i "s#\${dataserver}#$dataserver#g" gse.conf
        #添加transitserver的列表
        sed -i "s#\${transitserver}#$transitserver#g" gse.conf
        #添加平台id
        sed -i "s#\${cloudid}#$cloudid#g" gse.conf
        ### ###修改transitserver配置文件end###
        
        if grep -q \\$  gse.conf;then
            msg_failed 'modify_conf_failed' '修改transitserver配置文件失败'
        fi

		
        for ip in ${tasksvr_list};do
			echo 'wait...'
			###探测列表来
			telnet_server_port $ip $TPORT
			[[ $? -eq 0 ]]&&
			{
				echo "telnet $ip $TPORT OK" >>${tmpfile}
			}||
			{
				echo "telnet $ip $TPORT failed" >> ${tmpfile}
			}
        done

        if ! grep 'OK' ${tmpfile}
        then
            echo  'telnet_failed' $(grep -v 'OK' ${tmpfile})
        fi
	}
	
        return 0
}

stop_agent(){

	if [[ "`echo ${OS_TYPE} | grep -i 'Linux'`" ]];then 
		agentwk='/usr/local/gse'
		btserverwk='/data/gse/'
		trackwk='/data/gse/'
		transitwk='/data/gse/'
		opertranswk='/data/gse/'
		###停止agent服务###
		[[ -f $agentwk/gseagent/quit.sh ]] &&
		{
			cd $agentwk/gseagent/
			./quit.sh
			sleep 1
			###防止有孤儿进程没有被删除###
			if ps aux | grep -i gseAgent | grep -v grep;then
				pkill -9 gseMaster
				sleep 1
				pkill -9 AgentWorker
			fi
            report_pids=$(ps aux|grep 'gse/gseagent/plugins/bk_gse_basereport' | grep -v grep | awk '{print $2}')
            [[ -z "${report_pids}" ]] || kill -9 ${report_pids}
		}

		###停止transit###
		[[ -f $transitwk/gsetransitserver/quit.sh ]] &&
		{
			cd $transitwk/gsetransitserver/
			./quit.sh
			sleep 1
		}

		###停止btserver###
		[[ -f $btserverwk/gsebtfilesserver/quit.sh ]] &&
		{
			cd $btserverwk/gsebtfilesserver/
			./quit.sh
			sleep 1
		}
		
		###停止opertans###
		[[ -f $opertranswk/gseopertransserver/quit.sh ]] &&
		{
			cd $opertranswk/gseopertransserver/
			./quit.sh
			sleep 1
		}
		
		#确保进程被杀干净
        
        agent_pid=$(pidof ./bk_gse_agent)
        [[ -n "$agent_pid" ]] && kill -9 $agent_pid
		
        bt_pid=$(pidof ./bk_gse_btfile)
        [[ -n "$bt_pid" ]] && kill -9 $bt_pid
		
        tr_pid=$(pidof ./bk_gse_transit)
        [[ -n "$tr_pid" ]] && kill -9 $tr_pid
	
	elif [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then
		gsedir='/cygdrive/c/gse'
		workdir='/cygdrive/c/gse/gseagentw/'
		if [[ -f "$workdir/bk_gse_daemon.exe" ]]; then
			cd "$workdir/"
			chmod + quit.sh
			./quit.sh
			sleep 5
		fi
	
	fi	
	
}

restart_agent(){

	#先停止进程
	stop_agent
	
	#启动进程
	if [[ "`echo ${OS_TYPE} | grep -i 'Linux'`" ]];then
		agentwk='/usr/local/gse'
		btserverwk='/data/gse/'
		trackwk='/data/gse/'
		transitwk='/data/gse/'
		opertranswk='/data/gse/'
		cd $agentwk/gseagent/
		./start.sh &
		[[ $runmode -eq 0 ]] &&
		{
			cd $btserverwk/gsebtfilesserver/
			echo 'start bk_gse_btfile'
			./start.sh &
			
			cd $transitwk/gsetransitserver/
			echo 'start bk_gse_transit...'
			./start.sh &
		}
		
	elif [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then
		workdir='/cygdrive/c/gse/gseagentw/'
		./start.sh &
	fi
}

uninstall_winGseAgent(){

	gsedir='/cygdrive/c/gse'
	#停止服务
	stop_agent
	#删除部署目录
	rm -rf "$gsedir"
}

install_winGseAgent(){
	
	####验证是否是Administrator账户，非Administrator账户退出执行####
	if_admin=`whoami`
	[[ x"${if_admin}" != x'Administrator' ]] && msg_fail 'check_user_failed' "执行账户非Administrator，请切换到Administrator账户!!"
	
	wk=$(dirname $0)
	gsedir='/cygdrive/c/gse'
	workdir='/cygdrive/c/gse/gseagentw/'
	arch=''	##32/64
	[[ -d $gsedir ]] || mkdir -p $gsedir
	
	if uname.exe -a | grep -E 'WOW64|x86_64'; then
		arch=64
	else
		arch=32
	fi
	
	gsepkg="$wk/gseagentw.tar.gz"

	##
	if ! tar zxf "$gsepkg" -C "$gsedir" --no-same-owner; then
		msg_fail 'tar_xf_failed' "解压$gsepkg失败"
	fi

	if ! tar zxf "$wk/conf.tar.gz" -C $wk --no-same-owner; then
		msg_fail 'tar_xf_failed' "解压$wk/conf.tar.gz失败"
	fi
	
	###修改配置文件###
    modify_conf || msg_fail 'modify_conf_failed' "配置文件修改失败!"
	echo 'modify conf success.'

	cd "$workdir"
	if ! ls | grep -q "bk_gse_agentW${arch}";then
		msg_fail 'exe_file_not_exists' " windows $gsedir/bk_gse_agentW${arch} exe 不存在"
	fi
	agent_exe_file=$(ls | grep "bk_gse_agentW${arch}")
	
	if ! ls | grep -q "bk_gse_daemonW${arch}";then
		msg_fail 'exe_file_not_exists'  "windows $gsedir/bk_gse_daemonW${arch} exe 不存在"
	fi
	daemon_exe_file=$(ls | grep "bk_gse_daemonW${arch}")
	
	mv $agent_exe_file bk_gse_agent.exe
	mv $daemon_exe_file bk_gse_daemon.exe
	
	chmod 400 $workdir/conf/gse.conf
	chmod +x start.sh
	./start.sh

}

uninstall_linuxGseAgent() {

    ##清除crontab
    if [[ $runmode -eq 0 ]] && [[ $mode == 'pa' ]];then
        crontab -l | grep -v 'cron_proxy.sh' > /tmp/del_crontab_proxy
        crontab /tmp/del_crontab_proxy
    fi
    crontab -l | grep -v 'cron_agent.sh' > /tmp/del_crontab_agent
    crontab /tmp/del_crontab_agent

	agentwk='/usr/local/gse'
	btserverwk='/data/gse/'
	transitwk='/data/gse/'
	###停止agent服务###
	stop_agent
	
	###删除agent安装目录###
	[[ -d $agentwk/gseagent/ ]] &&
	{
        (
            cd $agentwk
		    rm -rf gseagent
        )
	}

	###删除transit安装目录###
	[[ -d $transitwk/gsetransitserver/ ]] &&
	{
	     rm -rf $transitwk/gsetransitserver
	}

	###删除btserver安装目录###
	[[ -d $btserverwk/gsebtfilesserver/ ]] &&
	{
        (
            cd $btserverwk
		    rm -rf gsebtfilesserver
        )
	}

	[[ ! -f $agentwk/gseagent.tar.gz ]] || rm -f $agentwk/gseagent.tar.gz
	[[ ! -f $transitwk/gsetransitserver.tar.gz ]] || rm -f $transitwk/gsetransitserver.tar.gz
	[[ ! -f $btserverwk/gsebtfilesserver.tar.gz ]] || rm -f $btserverwk/gsebtfilesserver.tar.gz
}

install_linuxGseAgent(){
	
	cd ${WORKDIR}
	os_bit=`getconf LONG_BIT`
	agentwk='/usr/local/gse'
	btserverwk='/data/gse/'
	transitwk='/data/gse/'
	####验证是否是root账户，非root账户退出执行####
	if_root=`whoami`
	[[ x"${if_root}" != x'root' ]] && msg_fail 'check_user_failed' "执行账户非root，请切换到root账户!!"

	###创建安装目录###
	[[ -d $agentwk ]]    || mkdir -p $agentwk
	[[ $runmode -eq 0 ]] && [[ $mode == 'pa' ]] &&
	{
		[[ -d $btserverwk ]] || mkdir -p $btserverwk
		[[ -d $transitwk ]] || mkdir -p $transitwk
	}
	
	#### 拷贝 安装文件####
	echo "cp gseagent.tar.gz to $agentwk..."
	[[ -f gseagent.tar.gz ]] || msg_fail 'copy_failed' '拷贝源文件gseagent.tar.gz失败!'
	tar -xf gseagent.tar.gz -C $agentwk

	[[ $runmode -eq 0 ]] && [[ $mode == 'pa' ]] &&
	{
		[[ -d gsebtfilesserver ]] || msg_fail 'copy_failed' '拷贝源目录gsebtfilesserver失败!'		
		cp -rf gsebtfilesserver $btserverwk
		cp -rf gsetransitserver $transitwk
	}

	###修改配置文件###
	modify_conf || msg_fail 'modify_conf_failed' "配置文件修改失败!!"
	echo 'modify conf success.'

	####启动agent_proxy服务####
	cd $agentwk/gseagent/
	###做软连接###
	[[ ! -s $agentwk/gseagent/bk_gse_agent ]] || rm -f $agentwk/gseagent/bk_gse_agent
	gse_name=`ls  |grep "gseAgent${os_bit}"`
	echo $gse_name
	chmod +x ${gse_name}
	chmod +x *.sh
	ln -fs ${gse_name} bk_gse_agent
	echo 'start bk_gse_agent...'
    ###实时数据上报初始化
    [[ -d $agentwk/gseagent/plugins/basereport/ ]] &&
    {
        (
            cd $agentwk/gseagent/plugins/basereport/
            ln -s bk_gse_basereport"${os_bit}" bk_gse_basereport
            chmod +x bk_gse_basereport"${os_bit}"
            python update.py
        )
    }
    ###部署采集器
    [[ -d $agentwk/gseagent/plugins/unifyTlogc/sbin ]] &&
    {
        (
            cd $agentwk/gseagent/plugins/unifyTlogc/sbin
            mv bk_gse_unifyTlogc${os_bit} bk_gse_unifyTlogc
        )
    }

	chmod 400 $agentwk/gseagent/conf/gse.conf
	./start.sh &
	
	[[ $runmode -eq 0 ]] &&  [[ $mode == 'pa' ]] &&
	{
		
		####启动btfilesserver服务####
		cd $btserverwk/gsebtfilesserver/
		[[ ! -s $btserverwk/gsebtfilesserver/bk_gse_btfile ]] || rm -f $btserverwk/gsebtfilesserver/bk_gse_btfile
		gsebt_name=`ls  |grep "gseBtFilesServer${os_bit}"`
		chmod +x ${gsebt_name}
		ln -fs ${gsebt_name} bk_gse_btfile
		chmod +x *.sh
		echo 'start bk_gse_btfile...'
		chmod 400 $btserverwk/gsebtfilesserver/conf/gse.conf
		./start.sh &
		
		####启动transitserver服务####
		cd $transitwk/gsetransitserver/
		[[ ! -s $transitwk/gsetransitserver/bk_gse_transit ]] || rm -f $transitwk/gsetransitserver/bk_gse_transit
		gsetr_name=`ls  |grep "gseTransitServer${os_bit}"`
		chmod +x ${gsetr_name}
		ln -fs ${gsetr_name} bk_gse_transit
		chmod +x *.sh
		echo 'start bk_gse_transit...'
		chmod 400 $transitwk/gsetransitserver/conf/gse.conf
		./start.sh &
	}
    if [[ $runmode -eq 0 ]] &&  [[ $mode == 'pa' ]]; then
        if ! crontab -l | grep 'cron_proxy.sh';then
            crontab -l >/tmp/new_crontab_proxy
            echo "*/1 * * * * cd /data/gse/gsebtfilesserver; ./cron_proxy.sh 1>/dev/null 2>&1" >> /tmp/new_crontab_proxy
            crontab /tmp/new_crontab_proxy
        fi
    fi

    if ! crontab -l | grep 'cron_agent.sh';then
        crontab -l >/tmp/new_crontab_agent
        echo "*/1 * * * * cd /usr/local/gse/gseagent; ./cron_agent.sh 1>/dev/null 2>&1" >> /tmp/new_crontab_agent
        crontab /tmp/new_crontab_agent
    fi
}

check_gseAgent_status(){

case "$1" in
	linux)
        psnum=`ps aux|grep './bk_gse_agent -f' | grep -v grep | wc -l`

        if [[ ${psnum} -ne 2 ]];then
            return 1
        fi

		os_type=`uname -a`
		if [[ "`echo ${os_type} | grep -i 'ubuntu'`" ]];then
			install_lsof
			if ! lsof -i:$TPORT | grep AgentWork; then
				return 2
			fi
		else
			if ! netstat -tnp | tr : ' ' | awk '{if($7 ~ /\<'$TPORT'\>/){print $0}}' | grep ESTABLISHED | grep -v grep; then

				return 2

			fi
		fi

        return 0
		;;
	win)
		if ! netstat -an | findstr ":$TPORT" | findstr ESTABLISHED
		then
			return 1
		fi
		return 0
		;;
esac

}

check_status(){
	os_type=$1
	try_times=40
	while true
	do
		check_gseAgent_status  ${os_type}
		if [[ $? -eq 0 ]];then
            return 0
		elif [[ ${try_times} -eq 0 ]];then
		    break
		fi
		sleep 1
		let try_times--
	done
	return 1
	
}

###参数
###非直连，并且是proxy
#action runmode=0 cloudid mode=pa  tasksvr_num proxy_num tasksvrip_1 tasksvrip_2 proxy_innerip_1 proxy_outerip_1 proxy_innerip_2 proxy_outerip_2
###非直连，并且是agent
#action runmode=0 cloudid mode=agent tasksvr_num proxy_num tasksvrip_1 tasksvrip_2 proxy_innerip_1 proxy_outerip_1 proxy_innerip_2 proxy_outerip_2
###直连
#action runmode=1 zkhost

OS_TYPE=`uname -s`
if [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then
    export innerip=`ipconfig | awk 'BEGIN{IGNORECASE=1}$1 ~ /IPv4/{print $NF}'`
else
    export innerip=$(get_ip)
fi

[[ $# -ge 3 ]] || { usage; exit 1; }

action=$1
if [[ $action != '-u' ]] && [[ $action != '-i' ]] ;then
	usage
	exit 1
fi

#运行模式，proxy为0，agent为1
runmode=$2

if [[ $runmode -eq 0 ]] ;then
	cloudid=$3
	compId=$((`echo $cloudid | awk '{print lshift($0,22)}'`))
	mode=$4
	tasksvr_num=$5
	proxy_num=$6
	tasksvrip=$7
	tasksvr_list=''
	#获取tasksvr列表
	shift 6
	for (( i=1;i<=${tasksvr_num};i++ ))
	do
	    eval tasksvrip_${i}=$1
	    tasksvr_list+="$1 "
	    shift 1
	done
	
	#获取proxy的ip列表
	shift $((6+$tasksvr_num))
	for (( i=1;i<=${proxy_num};i++ ))
	do
	    eval proxy_innerip_${i}=$1
	    eval proxy_outerip_${i}=$2
	    shift 2
	done
else
	zkhost=$3
fi

###public
btfileserver='['
taskserver='['

###bt_config
btServerOuterIP=''
btfilesvrscfg='['

###trans_config
dataserver='['
dataserver_pa_agent='['
transitserver='['

###proxy_agent_config
proxylistenip=${innerip}
proxytaskserver='['

if [[ $runmode -eq 0 ]] && [[ $tasksvr_num -eq 1 ]]; then
	proxytaskserver="[{\"ip\":\"${tasksvrip_1}\",\"port\":48533}]"
	dataserver="[{\"ip\":\"${tasksvrip_1}\",\"port\":58625}]"
	btfilesvrscfg+="{\"ip\":\"$tasksvrip_1\",\"compId\":\"0\",\"isTransmit\":0,\"tcpPort\":58925,\"thriftPort\":58930,\"btPort\":10020,\"trackerPort\":10030},"
elif [[ $runmode -eq 0 ]] && [[ $tasksvr_num -eq 2 ]]; then
	dataserver="[{\"ip\":\"${tasksvrip_1}\",\"port\":58625}]"
	proxytaskserver="[{\"ip\":\"${tasksvrip_1}\",\"port\":48533},{\"ip\":\"${tasksvrip_2}\",\"port\":48533}]"
	btfilesvrscfg+="{\"ip\":\"$tasksvrip_1\",\"compId\":\"0\",\"isTransmit\":0,\"tcpPort\":58925,\"thriftPort\":58930,\"btPort\":10020,\"trackerPort\":10030},{\"ip\":\"$tasksvrip_2\",\"compId\":\"0\",\"isTransmit\":0,\"tcpPort\":58925,\"thriftPort\":58930,\"btPort\":10020,\"trackerPort\":10030},"
fi

if [[ $runmode -eq 0 ]] && [[ ${proxy_num} -eq 1 ]]; then
	btServerOuterIP="[{\"ip\":\"${proxy_outerip_1}\",\"port\":58930}]"
	taskserver="[{\"ip\":\"${proxy_innerip_1}\",\"port\":48533}]"
	dataserver_pa_agent="[{\"ip\":\"${proxy_innerip_1}\",\"port\":58625}]"
	btfileserver="[{\"ip\":\"${proxy_innerip_1}\",\"port\":59173}]"
	transitserver="[{\"ip\":\"${proxy_innerip_1}\",\"port\":58625}]"
elif [[ $runmode -eq 0 ]] && [[ ${proxy_num} -eq 2 ]]; then	
	btServerOuterIP="[{\"ip\":\"${proxy_outerip_1}\",\"port\":58930}]"
	taskserver="[{\"ip\":\"${proxy_innerip_1}\",\"port\":48533},{\"ip\":\"${proxy_innerip_2}\",\"port\":48533}]"
	dataserver_pa_agent="[{\"ip\":\"${proxy_innerip_1}\",\"port\":58625},{\"ip\":\"${proxy_innerip_2}\",\"port\":58625}]"
	btfileserver="[{\"ip\":\"${proxy_innerip_1}\",\"port\":59173},{\"ip\":\"${proxy_innerip_2}\",\"port\":59173}]"
	transitserver="[{\"ip\":\"${proxy_innerip_1}\",\"port\":58625},{\"ip\":\"${proxy_innerip_2}\",\"port\":58625}]"
fi

[[ $runmode -eq 0 ]] && [[ ${proxy_num} -eq 2 ]] && btfilesvrscfg+="{\"ip\":\"$proxy_outerip_2\",\"compId\":\"$compId\",\"isTransmit\":0,\"tcpPort\":58925,\"thriftPort\":58930,\"btPort\":10020,\"trackerPort\":10030},"
btfilesvrscfg=`echo ${btfilesvrscfg%,*}`]

#生成参数配置文件config
echo "
cloudid=$cloudid
runmode=$runmode
mode=$mode
tasksvr_list='$tasksvr_list'
innerip=$innerip
proxylistenip=$proxylistenip
btfilesvrscfg='$btfilesvrscfg'
proxytaskserver='$proxytaskserver'
btServerOuterIP='$btServerOuterIP'
taskserver='$taskserver'
btfileserver='$btfileserver'
dataserver='$dataserver'
dataserver_pa_agent='$dataserver_pa_agent'
transitserver='$transitserver'
" > $TMP_CONFIG

. $TMP_CONFIG

#执行方式
if [[ $action = '-i' ]];then
	OS_TYPE=`uname -s`
	if [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then
		uninstall_winGseAgent
		install_winGseAgent
		check_status 'win' ||  msg_fail 'install_failed' "安装失败"
		msg_ok "install_success"
	elif [[ "`echo ${OS_TYPE} | grep -i 'Linux'`" ]];then
		uninstall_linuxGseAgent
		install_linuxGseAgent
		check_status 'linux' ||  msg_fail 'install_failed' "安装失败"
		msg_ok "install_success"
	fi

elif [[ $action = '-u' ]];then
	OS_TYPE=`uname -s`
	if [[ "`echo ${OS_TYPE} | grep -i 'CYGWIN'`" ]];then
		uninstall_winGseAgent
	elif [[ "`echo ${OS_TYPE} | grep -i 'Linux'`" ]];then
		uninstall_linuxGseAgent
	fi 
else
	usage
	exit 1
fi
