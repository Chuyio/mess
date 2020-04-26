#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear

echo "#========================================================="
echo "# System Required: CentOS 6/7+ Debian 6/7+ Ubuntu 14.04+"
echo "# Description: Linux系统初始化脚本"
echo "# Version: 3.6.0"
echo "# Author:Chuyio"
echo "# Date:18/06/2017"
echo "# Blog:https://www.cnblogs.com/chuyiwang"
echo "# Github:https://github.com/Chuyio"
echo "#========================================================="

CENTOS_VERSION=`cat /etc/redhat-release | awk -F'release' '{print $2}' | awk -F'[ .]+' '{print $2}'`
STDOUT=`>/dev/null 2>&1`
GREEN_FONT_PREFIX="\033[46;34m" && PURPLE_FONT_PREFIX="\033[35m" && RED_FONT_PREFIX="\033[41;33;5m" && GREEN_BACKGROUND_PREFIX="\033[42;37m" && FONT_COLOR_SUFFIX="\033[0m"
INFO="${GREEN_FONT_PREFIX}[信息]${FONT_COLOR_SUFFIX}"
ERROR="${RED_FONT_PREFIX}[错误]${FONT_COLOR_SUFFIX}"
TIP="${PURPLE_FONT_PREFIX}[注意]${FONT_COLOR_SUFFIX}"

VERSION_ERROR() {
echo -e "
${RED_FONT_PREFIX}
本脚本仅支持 CentOS6+/7+ 版本系统 暂时不支持本系统版本
System Version Error,Scripts only apply to Centos 6 and 7 versions
${FONT_COLOR_SUFFIX}"
exit 110
}

JDT(){
echo "准备中..."
i=0
str=""
arr=("|" "/" "-" "\\")
while [ $i -le 20 ]
do
  let index=i%4
  let indexcolor=i%8
  let color=30+indexcolor
  let NUmbER=$i*5
  printf "\e[0;$color;1m[%-20s][%d%%]%c\r" "$str" "$NUmbER" "${arr[$index]}"
  sleep 0.1
  let i++
  str+='+'
done
printf "\n"
echo "正在执行...稍候！"
}

#CHECK_RESULT() {
#if [ ! $? -eq 0 ]; then
#    echo -e "${ERROR} ERROR,Please To Check "
#    exit 110
#fi
#}

# 检查系统是否符合&是否已经初始化过该机器

CHECK_ROOT() {
        [[ $EUID != 0 ]] && echo -e "${ERROR} 当前账号非ROOT(或没有ROOT权限)，无法继续操作，请使用${GREEN_BACKGROUND_PREFIX} sudo su ${FONT_COLOR_SUFFIX}来获取临时ROOT权限（执行后会提示输入当前账号的密码）。" && exit 1
}

CHECK_SYS() {
        if [[ -f /etc/redhat-release ]]; then
                release="centos"
        elif cat /etc/issue | grep -q -E -i "debian"; then
                release="debian"
        elif cat /etc/issue | grep -q -E -i "ubuntu"; then
                release="ubuntu"
        elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
                release="centos"
        elif cat /proc/version | grep -q -E -i "debian"; then
                release="debian"
        elif cat /proc/version | grep -q -E -i "ubuntu"; then
                release="ubuntu"
        elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
                release="centos"
        fi
        bit=$(uname -m)
}
CHECK_SYS
#[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${ERROR} 本脚本不支持当前系统 ${release} !" && exit 1
[[ ${release} != "centos" ]] && echo -e "${ERROR} 本脚本暂时不支持当前系统 ${release} ! 当前仅支持CentOS6/7+ 感谢理解" && exit 110

CHECK_RESULT() {
	if [ ! $? -eq 0 ]; then
 	    echo -e "${ERROR} ERROR,Please To Check !!!"
	    exit 110
	fi
}

NETWORK() {
	CHECK_ROOT
        NETPATH="/etc/sysconfig/network-scripts/"
        NETCNF=`ls ${NETPATH} | grep if | head -1`
        NETNAME=`ip a | grep -E '^2:' | awk -F'[: ]+' '{print $2}'`
        CHECK_CNF=`echo ${NETCNF} | awk -F'-' '{print $2}'`
        if [[ ! ${CHECK_CNF} == ${NETNAME} ]]; then
                NET_CHECK=`echo ${NETCNF} | awk -F'-' '{print $1}'`
                NETCNF=`echo ${NET_CHECK}-${NETNAME}`
        fi
        cp $NETPATH$NETCNF /tmp/$NETCNF-$(date +%m%d%H%M)
        echo "###########################################"
        echo && stty erase '^H' && read -p "Please Input IPAddress :" IPA
        echo && stty erase '^H' && read -p "Please Input Netmask :" NTM
        echo && stty erase '^H' && read -p "Please Input Gateway :" GTW
        echo && stty erase '^H' && read -p "Please Input DNS (Default[223.5.5.5]):" DNS
        if [[ $DNS == "" ]]; then
            DNS="223.5.5.5"
        fi
        echo -e "${PURPLE_FONT_PREFIX} 配置中请稍候... 完成后请使用新地址 $IPA 进行SSH登陆 ${FONT_COLOR_SUFFIX}"
	NET_RULES="/etc/udev/rules.d/70-persistent-net.rules"
	if [ -f $NET_RULES ]
	then
	    mv -bf $NET_RULES /tmp $STDOUT
	fi
        case $CENTOS_VERSION in
        6)
            C6NETWORK
        ;;
        7)
            C7NETWORK
        ;;
        *)
            VERSION_ERROR
        ;;
        esac
}

HINT() {
echo -e "
${PURPLE_FONT_PREFIX}
[     ## Network configuration succeeded ##    ]
[     ##### Please restart the server #####    ]
[      CentOS 6+: server restart network       ]
[ CentOS 7+: systemctl restart network.service ]${FONT_COLOR_SUFFIX}"
}

C6NETWORK() {
cat > $NETPATH$NETCNF << END
DEVICE=$NETNAME
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=static
IPADDR=$IPA
NETMASK=$NTM
GATEWAY=$GTW
DNS=$DNS
END
if [ -e NetworkManager ]; then
service NetworkManager stop $STDOUT
chkconfig NetworkManager off $STDOUT
fi
chkconfig network on $STDOUT
JDT
HINT
}

C7NETWORK() {
cat > $NETPATH$NETCNF << EOF
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=$NETNAME
DEVICE=$NETNAME
ONBOOT=yes
IPADDR=$IPA
NETMASK=$NTM
GATEWAY=$GTW
DNS=$DNS
EOF
if [ -e "/usr/lib/systemd/system/NetworkManager.service" ]; then
systemctl stop NetworkManager $STDOUT
systemctl disable NetworkManager $STDOUT
fi
systemctl enable network.service $STDOUT
JDT
HINT
}

HISTORY() {
#history modify
FILE_PATH="/var/log/Command"
FILE_NAME="Command.log"
PROFILE_PATH="/etc/profile"
PROFILE=`cat ${PROFILE_PATH} | grep HISTORY_FILE | wc -l`
COMMAND=`cat /var/spool/cron/root | grep history.sh | wc -l`
CROND='/var/spool/cron/root'

CLUSTER1() {
touch $FILE_PATH/$FILE_NAME
chown -R nobody:nobody $FILE_PATH
chmod 001 $FILE_PATH
chmod 002 $FILE_PATH/$FILE_NAME
chattr +a $FILE_PATH/$FILE_NAME
}
CLUSTER2() {
cat >> ${PROFILE_PATH} << EPP
export HISTORY_FILE=$FILE_PATH/$FILE_NAME
export PROMPT_COMMAND='{ date "+%y-%m-%d %T ## \$(who am i |awk "{print \\\$1,\\\$2,\\\$5}") ## \$(whoami) ## \$(history 1 | { read x cmd; echo "\$cmd"; })"; } >>\$HISTORY_FILE'
EPP
}

if [ ! -d $FILE_PATH ]
then
    mkdir -p $FILE_PATH
    CLUSTER1
else
    if [ ! -f $FILE_PATH/$FILE_NAME ]
    then
        CLUSTER1
    fi
fi
if [ $PROFILE -lt 1 ]
then
    CLUSTER2
else
    sed -i '/.*HISTORY_FILE.*/d' ${PROFILE_PATH}
    CLUSTER2
fi
if [ ! -f $FILE_PATH/history.sh ]
then
cat >> $FILE_PATH/history.sh << EOF
#!/bin/bash

#Time=\`date +%Y%m%d%H -d '-1 hours'\`
Time=\`date +%Y%m%d%H\`
logs_path="$FILE_PATH/"
logs_name="$FILE_NAME"
new_file="\$logs_path\$logs_name-\$Time"
old_file=\`find \$logs_path -mtime +30 -type f -name "Command.*"\`
chattr -a \$logs_path\$logs_name
mv \$logs_path\$logs_name \$new_file
chattr +a \$new_file
touch \$logs_path\$logs_name
chown -R nobody:nobody \$logs_path\$logs_name
chmod -R 002 \$logs_path\$logs_name
chattr +a \$logs_path\$logs_name
if [[ ! -z \$old_file ]]
then
    echo "delet \$old_file \$Time" >> /var/log/messages
    chattr -a \$old_file
    rm -rf \$old_file
fi
EOF
chmod 100 $FILE_PATH/history.sh
fi
if [ $COMMAND -lt 1 ]
then
    echo "30 10 * * 6 /bin/bash $FILE_PATH/history.sh $STDOUT" >> $CROND
else
    sed -i '/.*history\.sh.*/d' $CROND
    echo "30 10 * * 6 /bin/bash $FILE_PATH/history.sh $STDOUT" >> $CROND
fi
case $CENTOS_VERSION in
6)
    service crond restart $STDOUT
;;
7)
    systemctl restart crond $STDOUT
;;
*)
    VERSION_ERROR
;;
esac
source ${PROFILE_PATH}
if [ $? -eq 0 ]
then
    JDT
    echo "###########################################"
    echo -e "${TIP} 配置完成 命令审计文件位于：/var/log/Command/Command.log "
else
    echo -e "${ERROR},Please To Check "
    exit 110
fi
}

YUMREPO() {
YUM='/etc/yum.repos.d'
if [ ! -d $YUM/oldbackup ]
then
    mkdir -p $YUM/oldbackup
fi
REPO=`ls $YUM | grep -E "*.repo$"`
if [[ ! $REPO == "" ]]; then
    for repo in REPO; do
    mv -bf $YUM/$repo $YUM/oldbackup $STDOUT
    done
fi
/bin/ping -c 3 -i 0.1 -w 1 baidu.com $STDOUT
CHECK_RESULT

echo -e "${INFO} 网络正常"

echo "正在执行中ing...请确保网络连接正常..."
wget -P $YUM http://mirrors.aliyun.com/repo/Centos-$CENTOS_VERSION.repo $STDOUT
if [ ! $? -eq 0 ]
then
    echo "wget 命令执行失败 正在尝试使用curl命令..."
    curl -Os http://mirrors.aliyun.com/repo/Centos-$CENTOS_VERSION.repo
    CHECK_RESULT
    mv Centos-$CENTOS_VERSION.repo $YUM
fi
rpm -e $(rpm -qa | grep epel-release) $STDOUT
rpm -ivh http://mirrors.aliyun.com/epel/epel-release-latest-$CENTOS_VERSION.noarch.rpm $STDOUT
CHECK_RESULT
echo "重新构建YUM仓库中稍候...如果网络不佳会造成失败"
yum clean all && yum makecache
CHECK_RESULT
}

MYSQL_REPO() {
REPO_PATH="/etc/yum.repos.d/mysql-community.repo"
MYSQL_INSTALL() {
yum -y install mysql-community-server
CHECK_RESULT
}
/bin/ping -c 3 -i 0.1 -w 1 baidu.com $STDOUT
CHECK_RESULT
echo -e "${INFO} 网络正常"
echo "正在执行中ing...请确保网络连接正常..."
rpm -e $(rpm -qa | grep -E "mysql.*release") $STDOUT
echo -e "
${PURPLE_FONT_PREFIX}
####################  本脚本不支持一个系统安装多个数据库  ########################
                      也不建议使用其他方法安装多个数据库
                  如果有多个数据库的需求,可以使用多实例来实现
             正在检查是否已安装过MySQL,如已安装MySQL将尝试自动卸载...
#########  注意 如果不想卸载当前数据库 请在进度条处按Ctrl+C结束脚本运行  #########${FONT_COLOR_SUFFIX}"
sleep 10
JDT
for PACKAGE in $(rpm -qa | grep -i mysql)
do
	rpm -e $PACKAGE
	if [ $? -eq 0 ]; then
		echo -e "${TIP} $PACKAGE 已成功卸载..."
	else
		yum remove $PACKAGE
			if [ ! $? -eq 0 ]; then
		#yum remove $(rpm -qa | grep -i mysql)
				echo -e "${ERROR} $PACKAGE 自动卸载失败,请手动卸载!!!"
			fi
	fi
done
rpm -Uvh https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql-connectors-community-el$CENTOS_VERSION/mysql-community-release-el$CENTOS_VERSION-5.noarch.rpm
CHECK_RESULT
yum repolist enabled | grep "mysql.*-community.*"
sed -i '/^#/d' $REPO_PATH
echo -e "${TIP}以下为目前仅支持安装的MySQL版本"
MYSQL_VER=`cat ${REPO_PATH}  | grep -E "^\[mysql5.*" | awk -F'[[-]' '{print $2}'`
sed -i '/.*mysql56.*/,/.*mysql57.*/s/enabled=1/enabled=0/' ${REPO_PATH}
echo -e "${PURPLE_FONT_PREFIX}
${MYSQL_VER}${FONT_COLOR_SUFFIX}"
echo && stty erase '^H' && read -p "请输入你要安装的MySQL版本 (55/56/57) :" NMB
case $NMB in
55)
	sed -i '/.*mysql55.*/,/.*mysql56.*/s/enabled=0/enabled=1/' ${REPO_PATH}
	MYSQL_INSTALL
	;;
56)
	sed -i '/.*mysql56.*/,/.*mysql57.*/s/enabled=0/enabled=1/' ${REPO_PATH}
	MYSQL_INSTALL
	;;
57)
	echo "# INSTALL_SCRIPT #" >> ${REPO_PATH}
	sed -i '/.*mysql57.*/,/.*INSTALL_SCRIPT.*/s/enabled=0/enabled=1/' ${REPO_PATH}
	MYSQL_INSTALL
	;;
*)
	echo -e "${ERROR} 输入信息有误,请输入正确的数字!!!"
	;;
esac
}

##########################################################################
# 以下为系统优化项
##########################################################################

######################## 配置SSH服务优化 ########################

MUTUAL() {
echo && stty erase '^H' && read -p "Whether or not to perform? (y/n):" NMB
if [[ $NMB == y ]] || [[ $NMB == "" ]]; then
    echo -e "${PURPLE_FONT_PREFIX}正在执行此项优化...${FONT_COLOR_SUFFIX}"
    JDT
else
    echo -e "${PURPLE_FONT_PREFIX}即将跳过此项优化...${FONT_COLOR_SUFFIX}"
    JDT
    return 100
fi
}

OPTSSH() {
clear
echo -e "
${GREEN_FONT_PREFIX}
#########################################################
[              配置SSH端口 关闭DNS反向解析              ]
${FONT_COLOR_SUFFIX}"
MUTUAL
if [ ! $? -eq 0 ]; then
    return 100
fi
SSHD_CONF_PATH="/etc/ssh/sshd_config"
echo && stty erase '^H' && read -p "Please enter the SSH port :" PT
if [[ $PT =~ ^[1-65534]$ ]]; then
    echo -e "${ERROR} 输入端口有误,请输入[1-65534]之间的数字"
    exit 110
fi
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' ${SSHD_CONF_PATH}
sed -i 's/#UseDNS yes/UseDNS no/' ${SSHD_CONF_PATH}
sed -i "s/#Port 22/Port $PT/" ${SSHD_CONF_PATH}
sed -i "s/^Port.*/Port $PT/g" ${SSHD_CONF_PATH}
sed -i 's/#PrintMotd yes/PrintMotd yes/' ${SSHD_CONF_PATH}
case $CENTOS_VERSION in
6)
    service sshd restart $STDOUT
;;
7)
    systemctl restart sshd $STDOUT
;;
*)
    VERSION_ERROR
;;
esac
}

######################## 关闭IPv6服务 ########################

OFFIPV6() {
clear
echo -e "
${GREEN_FONT_PREFIX}
##########################################
[              关闭IPv6服务              ]
${FONT_COLOR_SUFFIX}"
MUTUAL
if [ ! $? -eq 0 ]; then
    return 100
fi
MODPROBE_CONF_PATH="/etc/modprobe.conf"
sed -i '/.*net-pf-10.*/d' ${MODPROBE_CONF_PATH}
sed -i '/.*ipv6.*/d' ${MODPROBE_CONF_PATH}
echo "alias net-pf-10 off" >> ${MODPROBE_CONF_PATH}
echo "alias ipv6 off" >> ${MODPROBE_CONF_PATH}
}

######################## 关闭selinux ########################

OFFSELINUX() {
clear
echo -e "
${GREEN_FONT_PREFIX}
#########################################
[              关闭selinux              ]
${FONT_COLOR_SUFFIX}"
MUTUAL
if [ ! $? -eq 0 ]; then
    return 100
fi
SELINUX_CONF_PATH="/etc/selinux/config"
sed -i '/SELINUX/s/enforcing/disabled/' ${SELINUX_CONF_PATH} 
setenforce 0 $STDOUT
}

######################## 关闭防火墙 ######################## 

OFFFIREWALL() {
clear
echo -e "
${GREEN_FONT_PREFIX}
########################################
[              关闭防火墙              ]
${FONT_COLOR_SUFFIX}"
MUTUAL
if [ ! $? -eq 0 ]; then
    return 100
fi
case $CENTOS_VERSION in
6)
    service iptables stop $STDOUT
    chkconfig iptables off $STDOUT
;;
7)
    systemctl stop firewalld $STDOUT
    systemctl disable firewalld $STDOUT
;;
*)
    VERSION_ERROR
;;
esac
}

######################## 设置时间同步 ########################

TIMELOCK() {
clear
echo -e "
${GREEN_FONT_PREFIX}
##########################################
[              设置时间同步              ]
${FONT_COLOR_SUFFIX}"
MUTUAL
if [ ! $? -eq 0 ]; then
    return 100
fi
CROND_PATH="/var/spool/cron/root"
sed -i '/.*ntpdate.*/d' ${CROND_PATH}
echo "*/5    *    *    *    *    /usr/sbin/ntpdate 203.107.6.88 $STDOUT" >> ${CROND_PATH}
ntpdate 203.107.6.88
CHECK_RESULT
case $CENTOS_VERSION in
6)
    service crond restart $STDOUT
;;
7)
    systemctl restart crond $STDOUT
;;
*)
    VERSION_ERROR
;;
esac
}

######################## 配置用户最大文件打开数 ########################

LIMITSCONF() {
clear
echo -e "
${GREEN_FONT_PREFIX}
####################################################
[              配置用户最大文件打开数              ]
${FONT_COLOR_SUFFIX}"
MUTUAL
if [ ! $? -eq 0 ]; then
    return 100
fi
CONF_PATH="/etc/security/limits.conf"
CHECK_OLD=`tail -4 ${CONF_PATH} | grep -E 'nofile|nproc' | wc -l`
if [[ ! $CHECK_OLD -eq 4 ]]; then
cat >> ${CONF_PATH} << COMMENTBLOCK
*           soft   nofile       102400
*           hard   nofile       102400
*           soft   nproc        102400
*           hard   nproc        102400
COMMENTBLOCK
CHECK_RESULT
fi
}

######################## 配置用户最大进程数 ########################

NPROCCONF() {
clear
echo -e "
${GREEN_FONT_PREFIX}
################################################
[              配置用户最大进程数              ]
${FONT_COLOR_SUFFIX}"
MUTUAL
if [ ! $? -eq 0 ]; then
    return 100
fi
NPROC_CONF_PATH="/etc/security/limits.d"
SYSTEM_CONF_PATH="/etc/systemd/system.conf"
case $CENTOS_VERSION in
6)
    sed -i 's/1024$/102400/' ${NPROC_CONF_PATH}/90-nproc.conf
;;
7)
    sed -i 's/4096$/20480/' ${NPROC_CONF_PATH}/20-nproc.conf
    sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=100000/g' ${SYSTEM_CONF_PATH}
    sed -i 's/^#DefaultLimitNPROC=.*/DefaultLimitNPROC=100000/g' ${SYSTEM_CONF_PATH} 
;;
*)
    VERSION_ERROR
;;
esac
}

######################## 优化系统内核参数项 ########################

SYSCTLCONF() {
clear
echo -e "
${GREEN_FONT_PREFIX}
################################################
[              优化系统内核参数项              ]
${FONT_COLOR_SUFFIX}"
MUTUAL
if [ ! $? -eq 0 ]; then
    return 100
fi
SYSCTL_CONF_PATH="/etc/sysctl.conf"
true > ${SYSCTL_CONF_PATH}
cat >> ${SYSCTL_CONF_PATH} << EIZ
net.ipv4.ip_forward = 0
#该文件内容为0 表示禁止数据包转发 1表示允许
net.ipv4.conf.default.rp_filter = 0
#是否忽略arp请求
net.ipv4.conf.default.accept_source_route = 0
#是否接受源路由(source route)
kernel.sysrq = 0
#是否开启sysrq,0为disable sysrq, 1为enable sysrq completely
kernel.core_uses_pid = 1
#如果这个文件的内容被配置成1,那么即使core_pattern中没有设置%p,最后生成的core dump文件名仍会加上进程ID
kernel.unknown_nmi_panic = 0
#该参数的值影响的行为(非屏蔽中断处理).当这个值为非0,未知的NMI受阻,PANIC出现.这时,内核调试信息显示控制台,则可以减轻系统中的程序挂起.
kernel.msgmnb = 65536
#指定内核中每个消息队列的最大字节限制
kernel.msgmax = 65536
#指定内核中单个消息的最大长度(bytes).进程间的消息传递是在内核的内存中进行的,不会交换到磁盘上,所以如果增大该值,则将增大操作系统所使用的内存数量
kernel.shmmax = 68719476736
#指定共享内存片段的最大尺寸(bytes)
kernel.shmall = 4294967296
#指定可分配的共享内存数量
vm.swappiness = 10
#内存不足时=0,进行少量交换 而不禁用交换=1,系统内存足够时=10 提高性能,默认值=60,值=100将积极使用交换空间

net.ipv4.tcp_tw_reuse = 1
#开启重用,允许Time-WAIT sockets重新用于新的TCP连接
net.ipv4.tcp_syncookies = 1
#开启SYN Cookies,当出现SYN等待队列溢出时,启用cookies来处理
net.ipv4.tcp_fin_timeout = 30
#如果套接字有本端要求关闭,这个参数决定了保持在FIN-WAIT-2状态的时间,对端可以出错并永远关闭连接,甚至以外宕机,缺省值是60秒,2.2内核的通常值是180秒,你可以按这个设置,但要记住的是,即时你的机器是一个轻载的WEB服务器,也有因为大量的死套接字而内存溢出的风险,FIN-WAIT-2的危险性比FIN-WAIT-1要小,因为它最多只能吃掉1.5K内存,但是他们生存期长些
net.ipv4.tcp_syn_retries = 3
#在内核放弃建立连接之前发送SYN包的数量可以设置为1
net.ipv4.tcp_synack_retries = 3
#为了打开对端的连接,内核需要发送一个SYN并附带一个回应前面一个SYN的ACK,也就是所谓的三次握手中的第二次握手,这个设置决定了内核放弃连接之前发送SYN+ACK包的数量可以设置为1
net.ipv4.tcp_max_orphans = 262144
#系统中最多有多少个TCP套接字不被关联到任何一个用户文件句柄上,如果超过这个数字,孤儿连接将即刻被复位并打印出警告信息,这个限制仅仅是为了防止简单的Dos攻击,不能过分依靠它或者人为地减小这个值,更应该增加这个值(如果增加了内存之后)
net.ipv4.tcp_keepalive_time = 60
#当keepzlived起作用的时候,TCP发送keepzlived消息的频度,缺省是两小时,可以设置为30
net.ipv4.tcp_max_tw_buckets = 180000
#time_wait的数量,默认是180000
net.ipv4.conf.all.send_redirects = 0
#禁止转发重定向报文
net.ipv4.conf.default.send_redirects = 0
#不充当路由器
net.ipv4.conf.all.secure_redirects = 0
#如果服务器不作为网关/路由器,该值建议设置为0
net.ipv4.conf.default.secure_redirects = 0
#禁止转发安全ICMP重定向报文
net.ipv4.conf.all.accept_redirects = 0
#禁止包含源路由的ip包
net.ipv4.conf.default.accept_redirects = 0
#禁止包含源路由的ip包

##### iptables ##############
net.ipv4.neigh.default.gc_thresh1 = 2048
#存在于ARP高速缓存中的最少层数,如果少于这个数,垃圾收集器将不会运行.缺省值是128。
net.ipv4.neigh.default.gc_thresh2 = 4096
#保存在 ARP 高速缓存中的最多的记录软限制.垃圾收集器在开始收集前,允许记录数超过这个数字 5 秒.缺省值是 512
net.ipv4.neigh.default.gc_thresh3 = 8192
#保存在 ARP 高速缓存中的最多记录的硬限制,一旦高速缓存中的数目高于此,垃圾收集器将马上运行.缺省值是1024
net.ipv4.ip_local_port_range = 1024 65535
#用于定义网络连接可用作其源(本地)端口的最小和最大端口的限制,同时适用于TCP和UDP连接.
net.ipv6.conf.all.disable_ipv6 = 1
#禁用整个系统所有接口的IPv6
fs.file-max = 1000000
#系统最大打开文件描述符数
fs.inotify.max_user_watches = 10000000
#表示同一用户同时可以添加的watch数目(watch一般是针对目录,决定了同时同一用户可以监控的目录数量)
net.core.rmem_max = 16777216
#接收套接字缓冲区大小的最大值(以字节为单位)
net.core.wmem_max = 16777216
#发送套接字缓冲区大小的最大值(以字节为单位)
net.core.wmem_default = 262144
#发送套接字缓冲区大小的默认值(以字节为单位)
net.core.rmem_default = 262144
#接收套接字缓冲区大小的默认值(以字节为单位)
net.core.somaxconn = 65535
#用来限制监听(LISTEN)队列最大数据包的数量,超过这个数量就会导致链接超时或者触发重传机制
net.core.netdev_max_backlog = 262144
#当网卡接收数据包的速度大于内核处理的速度时,会有一个队列保存这些数据包.这个参数表示该队列的最大值
net.ipv4.tcp_max_syn_backlog = 8120
#表示系统同时保持TIME_WAIT套接字的最大数量.如果超过此数,TIME_WAIT套接字会被立刻清除并且打印警告信息.之所以要设定这个限制,纯粹为了抵御那些简单的DoS攻击,不过,过多的TIME_WAIT套接字也会消耗服务器资源,甚至死机
net.netfilter.nf_conntrack_max = 1000000
#CONNTRACK_MAX 允许的最大跟踪连接条目,是在内核内存中netfilter可以同时处理的"任务"(连接跟踪条目)

EIZ
/sbin/sysctl -p
echo -e "
${PURPLE_FONT_PREFIX}
内核参数已优化完毕,请按需自行修改/etc/sysctl.conf配置文件${FONT_COLOR_SUFFIX}"
}

###################################################################################
###################################################################################

echo -e "  CentOS 初始化一键配置脚本 ${PURPLE_FONT_PREFIX}Powered By Chuyio${FONT_COLOR_SUFFIX}

  ${GREEN_FONT_PREFIX}1.${FONT_COLOR_SUFFIX} 配置网络
  ${GREEN_FONT_PREFIX}2.${FONT_COLOR_SUFFIX} 配置审计
  ${GREEN_FONT_PREFIX}3.${FONT_COLOR_SUFFIX} 优化系统
  ${GREEN_FONT_PREFIX}4.${FONT_COLOR_SUFFIX} 配置YUM仓库
  ${GREEN_FONT_PREFIX}5.${FONT_COLOR_SUFFIX} 安装MySQL数据库
  "
echo && stty erase '^H' && read -p "Please Input Number (1/2/3/4/5) :" NMB
case "$NMB" in
1)
	NETWORK
	;;
2)
	HISTORY
	;;
3)
	OPTSSH
	OFFIPV6
	OFFSELINUX
	OFFFIREWALL
	TIMELOCK
	LIMITSCONF
	NPROCCONF
	SYSCTLCONF
	;;	
4)
	YUMREPO
	;;
5)
	MYSQL_REPO
	;;
*)
	echo -e "${ERROR} 请输入正确的数字 [1-4]"
	;;
esac

