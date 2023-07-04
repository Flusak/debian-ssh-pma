#!/bin/bash
if [ $EUID -ne 0 ]
then
echo Error: script not running by sudo
exit
fi

read -p "New port: " port
sed -i -e "/^.\?Port\s[0-9]\+/s/\s[0-9]\+/ $port/;\
 /^.\?Port\s[0-9]\+/s/^#//;\
 /^.\?PermitRootLogin/s/\s[a-z]\+-\?[a-z]\+/ no/;\
 /^.\?PermitRootLogin/s/^#//;\
 /^.\?PubkeyAuthentication/s/\s[a-z]\+/ yes/;\
 /^.\?PubkeyAuthentication/s/^#//;\
 /^.\?PasswordAuthentication/s/\s[a-z]\+/ no/;\
 /^.\?PasswordAuthentication/s/^#//;" /etc/ssh/sshd_config

systemctl restart sshd
