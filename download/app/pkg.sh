#!/bin/bash

cd ${BASH_SOURCE%/*} 2>/dev/null
BKROOT="${PWD%/index*}"
[[ -f gse_pkg.tar.gz ]] && rm -f gse_pkg.tar.gz

cp -r $BKROOT/gse/{gseagent,gseagentw,gsebtfilesserver,gsetransitserver} ./
cp -f cron_proxy.sh gsebtfilesserver/
cp -f cron_agent.sh gseagent/

tar -zcf gseagent.tar.gz gseagent
tar -zcf gseagentw.tar.gz gseagentw
tar -zcf gse_pkg.tar.gz fast_abs.sh gseagent.tar.gz gseagentw.tar.gz gsebtfilesserver gsetransitserver abs.tar.gz conf.tar.gz 
