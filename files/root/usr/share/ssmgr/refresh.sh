#!/bin/sh

ssmgrAddress=$(uci get shadowsocks.@ssmgr[0].site)
macAddress=`ifconfig | grep 'eth0' | awk '{print $5}' | sed 's/\://g'`
read -r oldAccount < ./account.txt
account=$(curl -s ${ssmgrAddress}api/user/account/mac/${macAddress})

if [ ${#account} -lt 10 ]; then
  return
fi
j=0
while [ $j -lt 20 ]
do
  uci delete shadowsocks.@servers[0]
  let j+=1
done
default_server_name=$(echo ${account} | /usr/share/ssmgr/JSON.sh -l | egrep '\["default","name"\]' | awk '{print $2}' | sed 's/\"//g')
stop=0
i=0
while [ $stop -eq 0 ]
do
  name=$(echo ${account} | /usr/share/ssmgr/JSON.sh -l | egrep '\["servers",'+$i+',"name"\]' | awk '{print $2}' | sed 's/\"//g')
  server=$(echo ${account} | /usr/share/ssmgr/JSON.sh -l | egrep '\["servers",'+$i+',"address"\]' | awk '{print $2}' | sed 's/\"//g')
  if [ -z "$server" ]; then
    stop=1
  else
    uci add shadowsocks servers

    port=$(echo ${account} | /usr/share/ssmgr/JSON.sh -l | egrep '\["default","port"\]' | awk '{print $2}' | sed 's/\"//g')
    password=$(echo ${account} | /usr/share/ssmgr/JSON.sh -l | egrep '\["default","password"\]' | awk '{print $2}' | sed 's/\"//g')
    method=$(echo ${account} | /usr/share/ssmgr/JSON.sh -l | egrep '\["default","method"\]' | awk '{print $2}' | sed 's/\"//g')

    uci set shadowsocks.@servers[${i}].alias=${name}
    uci set shadowsocks.@servers[${i}].fast_open=0
    uci set shadowsocks.@servers[${i}].server=${server}
    uci set shadowsocks.@servers[${i}].server_port=${port}
    uci set shadowsocks.@servers[${i}].timeout=60
    uci set shadowsocks.@servers[${i}].password=${password}
    uci set shadowsocks.@servers[${i}].encrypt_method=${method}
    let i+=1
  fi
done
uci commit shadowsocks

i=1
use_default_server=$(uci get shadowsocks.@ssmgr[0].use_default_server)
while [ true ]
do
  col='{print $'$i'}'
  name=$(uci get shadowsocks.@transparent_proxy[0].main_server | awk -F " " "${col}")
  if [ ${#name} -lt 3  ]; then
    break
  fi
  exists=$(uci show shadowsocks.${name}.server)
  if [ ${use_default_server} -eq 1 ]; then
    uci del_list shadowsocks.@transparent_proxy[0].main_server=${name}
  elif [ ${#exists} -lt 10 ]; then
    uci del_list shadowsocks.@transparent_proxy[0].main_server=${name}
  fi
  let i+=1
done
exists=$(uci get shadowsocks.@transparent_proxy[0].main_server)
if [ ${#exists} -lt 3  ]; then
  grep_word="alias=\'${default_server_name}\'"
  section=$(uci show shadowsocks | grep $grep_word | awk -F "." '{print $2}')
  section_name=$(uci show shadowsocks.${section} | grep $grep_word | awk -F "." '{print $2}')
  uci add_list shadowsocks.@transparent_proxy[0].main_server=${section_name}
fi
uci commit shadowsocks

if [ "$oldAccount" != "$account" ]; then
  /etc/init.d/shadowsocks restart
  echo $account > ./account.txt
fi 