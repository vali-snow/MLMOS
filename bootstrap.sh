#!/bin/bash
echo "if it works, it aint stupid"
cd "$(dirname "$0")"
yum -y -q update

if [[ $(nmcli con show | cut -d" " -f1 | grep -e enp0s3 | wc -l) -ge 1 ]]
then
	nmcli con delete enp0s3
fi
if [[ $(nmcli con show | cut -d" " -f1 | grep -e staticIP | wc -l) -ge 1 ]]
then
	nmcli con delete staticIP
	IP=$(crudini --get vmcentos1.ini enp0s3 IP)
	GATEWAY=$(crudini --get vmcentos1.ini enp0s3 GATEWAY)
	DNS=$(crudini --get vmcentos1.ini enp0s3 DNS)
	nmcli con add type ethernet con-name staticIP ifname enp0s3 ip4 $IP/24 gw4 $GATEWAY ipv4.dns "$DNS"
fi
if [[ $(nmcli con show | cut -d" " -f1 | grep -e enp0s8 | wc -l) -ge 1 ]]
then
	nmcli con delete enp0s8
fi
if [[ $(nmcli con show | cut -d" " -f1 | grep -e sshIP | wc -l) -ge 1 ]]
then
	nmcli con delete sshIP
	IP=$(crudini --get vmcentos1.ini enp0s8 IP)
	nmcli con add type ethernet con-name sshIP ifname enp0s8 ip4 $IP/24
fi
systemctl restart network.service

PUBLICKEY=$(crudini --get vmcentos1.ini ssh PUBLICKEY)
mkdir -p /root/.ssh
echo $PUBLICKEY > /root/.ssh/authorized_keys
chmod -R go= /root/.ssh

mkdir -p /home/va/.ssh
echo $PUBLICKEY > /home/va/.ssh/authorized_keys
chmod -R go= /home/va/.ssh
chown -R va:va /home/va/.ssh

grep -q "ChallengeResponseAuthentication" /etc/ssh/sshd_config && sed -i "/^[^#]*ChallengeResponseAuthentication[[:space:]]yes.*/c\ChallengeResponseAuthentication no" /etc/ssh/sshd_config || echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
grep -q "^[^#]*PasswordAuthentication" /etc/ssh/sshd_config && sed -i "/^[^#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
systemctl restart sshd.service

sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
setenforce 0