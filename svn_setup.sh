#!/bin/bash
SVN_APTH_1="/mnt/f/svnfile"
SVN_APTH_2="/mnt/f/wcy_svn"
SVN_BIN=`which svnserve`
read -p "Input (sall|s3690|s3691|kall|k3690|k3691): " NMB
case $NMB in
sall)
    $SVN_BIN -d -r $SVN_APTH_1 --listen-port 3690
    $SVN_BIN -d -r $SVN_APTH_2 --listen-port 3691
    ;;
s3690)
    $SVN_BIN -d -r $SVN_APTH_1 --listen-port 3690
    ;;
s3691)
    $SVN_BIN -d -r $SVN_APTH_2 --listen-port 3691
    ;;
kall)
    kill $(ps -ef | grep -v grep | grep -E '3690|3691' | awk '{print $2}')
    ;;
k3690)
    kill $(ps -ef | grep -v grep | grep -E '3690' | awk '{print $2}')
    ;;
k3691)
    kill $(ps -ef | grep -v grep | grep -E '3691' | awk '{print $2}')
    ;;
*)
    echo "Input Error, Please Input (sall|s3690|s3691|kall|k3690|k3691)"
    ;;
esac


