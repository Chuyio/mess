#!/bin/bash
# Filename:    centos7-init.sh
# owner:       chuyi
if [ `whoami` != "root" ];then
echo " only root can run it"
exit 1
fi
echo -e "\033[31m 这是centos7系统初始化脚本,将更新系统内核至最新版本,请慎重运行! \033[0m" 
read -s -n1 -p "Press any key to continue or ctrl+C to cancel"
echo "Your inputs: $REPLY"

yum_config(){
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all && yum makecache
}

ntp_config(){
yum –y install chrony
systemctl start chronyd && systemctl enable chronyd
timedatectl set-timezone Asia/Shanghai && timedatectl set-ntp yes
}

close_firewalld(){
systemctl stop firewalld.service &> /dev/null 
systemctl disable firewalld.service &> /dev/null
}

close_selinux(){
setenforce 0
sed -i 's/enforcing/disabled/g' /etc/selinux/config
}

yum_tools(){
yum install –y vim wget curl curl-devel bash-completion lsof iotop iostat unzip bzip2 bzip2-devel
yum install –y gcc gcc-c++ make cmake autoconf openssl-devel openssl-perl net-tools
source /usr/share/bash-completion/bash_completion
}

update_kernel (){
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install -y kernel-ml
grub2-set-default 0
grub2-mkconfig -o /boot/grub2/grub.cfg
}

main(){
    yum_config;
    ntp_config;
    close_firewalld;
    close_selinux;
    yum_tools;
    update_kernel;
}
main
