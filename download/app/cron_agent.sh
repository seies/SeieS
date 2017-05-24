#!/bin/bash

WORKDIR="/usr/local/gse/gseagent"

[[ -d $WORKDIR ]] &&
{
    if ! ps aux|grep './bk_gse_agent' | grep -v grep;then
       echo 'starting bk_gse_agent...'
       cd $WORKDIR/plugins/basereport/
       python update.py
       sleep 1
       cd $WORKDIR/
       ./start.sh
       echo 
       echo 'start bk_gse_agent success.'
    else
       echo
       echo 'bk_gse_agent started already.'
    fi
}
