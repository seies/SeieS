#!/bin/bash

WORKDIR="/usr/local/gse/gseagent"
BTDIR="/data/gse/gsebtfilesserver"
TRDIR="/data/gse/gsetransitserver"

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

[[ -d $BTDIR ]] &&
{
    if ! ps aux|grep './bk_gse_btfile' | grep -v grep;then
       echo 'starting bk_gse_btfile...'
       cd $BTDIR/
       ./start.sh
       echo 
       echo 'start bk_gse_btfile success.'
    else
       echo
       echo 'bk_gse_btfile started already.'
    fi
}

[[ -d $TRDIR ]] &&
{
    if ! ps aux|grep './bk_gse_transit' | grep -v grep;then
       echo 'starting bk_gse_transit...'
       cd $TRDIR/
       ./start.sh
       echo 
       echo 'start bk_gse_transit success.'
    else
       echo
       echo 'bk_gse_transit started already.'
    fi
}
