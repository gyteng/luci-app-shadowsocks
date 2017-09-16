#!/bin/sh

ssmgrAddress=$(uci get shadowsocks.@ssmgr[0].site)
macAddress=`ifconfig | grep 'eth0' | awk '{print $5}' | sed 's/\://g'`
account=$(curl -s ${ssmgrAddress}api/user/account/mac/${macAddress})
echo $account
if [ ${#account} -lt 10 ]; then
  return
fi
j=0
while [ $j -lt 20 ]
do
  uci delete shadowsocks.@servers[0]
  let j+=1
done
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

# i=1
# while [ true ]
# do
#   col='{print $'$i'}'
#   name=$(uci get shadowsocks.@transparent_proxy[0].main_server | awk -F " " "${col}")
#   if [ ${#name} -lt 3  ]; then
#     break
#   fi
#   exists=$(uci show shadowsocks.${name}.server)
#   if [ ${#exists} -lt 10  ]; then
#     uci del_list shadowsocks.@transparent_proxy[0].main_server=${name}
#   fi
#   let i+=1
# done
# uci commit shadowsocks