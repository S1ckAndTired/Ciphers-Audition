#!/bin/bash


OnRed='\033[41m'
Yellow='\033[1;33m'
Red='\033[0;31m'
Green='\033[0;32m'
NC='\033[0m'

#for cipher in $(nmap -Pn --script ssl-enum-ciphers -p 443 $1 | awk '{print $2}' | grep "TLS_")
for cipher in $(cat b)
do
  response=$(curl -s https://ciphersuite.info/cs/$cipher/)
  result1=$(echo $response | sed 's/>/\n/g' | sed 's/</\n/g' | grep "^$cipher" | sed 's/ *$//')
  result2=$(echo $response | sed 's/> /\n/g' | grep "span class=\"text-" | awk -F "[><]" '{print $3}')  
  #version=$(echo $response | tr ' ' '\n' | grep "^TLS" | sed 's/,$//' | grep "[0-9]$ | paste -sd ' '")
  if [[ -z "$result1" ]];then
    not="!Not Found!"
    echo -e "[$OnRed$not$NC] - [$OnRed$cipher$NC]"
  elif [[ "Weak" == *"$result2"*  ]];then
    echo -e "[$Yellow$result2$NC] - [$Yellow$result1$NC] - [$version]"
  elif [[ "Insecure" == *"$result2"* ]];then
    echo -e "[$Red$result2$NC] - [$Red$result1$NC] - [$version]"
  else
    echo -e "[$Green$result2$NC] - [$Green$result1$NC] - [$version]"
  fi
  #sleep 2
  done
