#!/bin/bash
_ckIPaddr () {
        ckStep1=`echo $1 | awk -F"." '{print NF}'`
        if [ $ckStep1 -eq 4 ] || [ $ckStep1 -eq 6 ]
        then
                ckStep2=`echo $1 | awk -F"." '{if ($1!=0 && $NF!=0) split ($0,IPNUM,".")} END \
        { for (k in IPNUM) if (IPNUM[k]==0) print IPNUM[k]; else if (IPNUM[k]!=0 && IPNUM[k]!~/[a-z|A-Z]/ && length(IPNUM[k])<=3 &&
IPNUM[k]<255 && IPNUM[k]!~/^0/) print IPNUM[k]}'| wc -l`
                if [ $ckStep2 -eq $ckStep1 ]
                then
                        echo 0
                else
                        echo 1
                fi
        else
                echo 1
        fi
}
>log
for IP in $(cat ip.txt)
do
CK_IPADDR=`_ckIPaddr $IP`
if [ $CK_IPADDR -eq 1 ]
then
     echo "$IP" >>log
     continue
fi

echo "=============== $IP ===============" >>log
ssh -Tq $IP >> log << RED
echo "open file:$(ulimit -n)"
echo "home size:$(df -hT | awk '/home$/{print $5}')"
echo "neic size:$(free -m | awk '/Mem/{print $4}')"
RED
done
