#!/bin/sh

while [ true ]
do
  auto=$(uci get shadowsocks.@ssmgr[0].auto_refresh)
  echo $auto
  if [ $auto -eq 1 ]; then
    /usr/bin/ssmgr
  fi
  sleep 120
done