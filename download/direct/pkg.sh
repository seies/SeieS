#!/bin/bash

cd ${BASH_SOURCE%/*} 2>/dev/null
BKROOT="${PWD%/index*}"

[[ ! -f agent_linux.tar.gz ]] || rm -f agent_linux.tar.gz
[[ ! -f agent_win.tar.gz ]] || rm -f agent_win.tar.gz

cp -r $BKROOT/gse/{gseagent,gseagentw} ./
tar -zcf agent_linux.tar.gz install.sh gseagent cron_gse.sh
tar -zcf agent_win.tar.gz install.sh gseagentw cron_gse.sh
