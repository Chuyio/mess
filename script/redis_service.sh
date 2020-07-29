#!/bin/bash
#owner:WCY
if [ $# -ne 2 ]; then
        echo "usage: $0 port"
        exit -1;
fi
PORT=$1
REDIS_SERVER="/usr/bin/redis-server"
REDIS_CLI="/usr/bin/redis-cli"
REDIS_CONF="/usr/local/redis-6.0.6/redis_${PORT}.conf"
#REDIS_CONF="/usr/local/redis-6.0.6/redis.conf"
###################################################################
cmd="ps -ef | grep ${REDIS_SERVER} | grep -Ev 'grep|vim|defunct' | grep '$PORT' | awk '{ print \$2 }'"
PID=$(eval ${cmd})

START(){
if [ ! -e $REDIS_SERVER ]; then
        echo "$REDIS_SERVER does not exist!"
        exit -1
fi
if [ ! -e $REDIS_CONF ]; then
        echo "$REDIS_CONF does not exist!"
        exit -1
fi
if [[ ${PID} != "" ]]; then
        echo "redis-server(port:$PORT) is running, can't start"
        exit -1
else
        $REDIS_SERVER $REDIS_CONF &
fi
startfail=1
for i in `seq 0 180`
do
        PID=$(eval ${cmd})
        #echo $PID
        if [[ $PID"e" != "e" ]]; then
                ${REDIS_SERVER} --version
                echo "Redis server(port:$PORT) is stared..."
                startfail=0
                break
        fi
        sleep 1
done
exit $startfail
}
STOP(){
if [ ${PID}"e" = "e" ]; then
        echo "redis-server(port:$PORT) is not started"
        #exit -1
else
        kill $PID
fi
stopfail=1
for i in `seq 0 30`
do
        PID=$(eval ${cmd})
        #echo $PID
        if [ ${PID}"e" != "e" ]; then
                echo "redis-server(port:$PORT) is still running, waiting to stop[${i}]..."
        else
                echo "redis-server(port:$PORT) is stoped"
                stopfail=0
           break
        fi
        sleep 1
done
#exit $stopfail
}
case $2 in
start)
    START
;;
stop)
    STOP
;;
restart)
    STOP
    START
;;
*)
    echo "bash redis_service.sh PORT (start|stop|restart)"
;;
esac
