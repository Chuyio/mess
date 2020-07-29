#!/bin/bash  
# description:  MySQL buckup shell script  
# owner:        chuyiwang
# 192.168.245.100 为专门的备份服务器,需要做一下服务器之间免密码登录

#Mysql全量备份+异地备份,MYSQL从库上执行全量备份+增量备份方式,在从库备份避免Mysql主库备份的时候锁表造成业务影响.

#备份的数据库名
DATABASES=(
            "magedu01"
            "magedu02"                    
)
USER="root"
PASSWORD="123123"

MAIL="chuyi@gmail.com" 
BACKUP_DIR="/data/backup"
LOGFILE="/data/backup/data_backup.log"
DATE=`date +%Y%m%d_%H%M`

cd $BACKUP_DIR
#开始备份之前,将备份信息头写入日记文件   
echo "--------------------" >> $LOGFILE   
echo "BACKUP DATE:" $(date +"%y-%m-%d %H:%M:%S") >> $LOGFILE   
echo "-------------------" >> $LOGFILE

for DATABASE in ${DATABASES};do
  /usr/local/mysql/bin/mysqldump -u$USER -p$PASSWORD --events  -R --opt  $DATABASE |gzip >${BACKUP_DIR}\/${DATABASE}_${DATE}.sql.gz
  if [ $? == 0 ];then
    echo "$DATE--$DATABASE is backup succeed" >> $LOGFILE
  else
    echo "Database Backup Fail!" >> $LOGFILE   
done
#判断数据库备份是否全部成功,全部成功就同步到异地备份服务器
if [ $? == 0 ];then
  /usr/bin/rsync -zrtopg   --delete  /data/backup/* root@192.168.245.100:/data/backup/  >/dev/null 2>&1
else
  echo "Database Backup Fail!" >> $LOGFILE   
  #备份失败后向管理者发送邮件提醒
  mail -s "database Daily Backup Fail!" $MAIL   
fi

#删除30天以上的备份文件  
find $BACKUP_DIR  -type f -mtime +30 -name "*.gz" -exec rm -f {} \;
