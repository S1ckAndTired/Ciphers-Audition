#!/bin/bash


Orange='\033[0;33m'
Yellow='\033[1;33m'
Red='\033[0;31m'
Green='\033[0;32m'
NC='\033[0m'


data=$(nmap -Pn --script ssl-enum-ciphers -p 443 $1 | awk '{print $2}' | grep "TLS" | sed 's/://g')
for ciphers in $data
do
  echo $ciphers >> .out
done
cat .out | sed -n '/^TLSv/{h;n}; /^TLS_/{G;s/\n/-/p}' >> .ready-to-go
echo "[*] Requesting ciphersuite"
for ciphers in $(cat .ready-to-go)
do
  cipher=$(echo $ciphers | awk -F "-" '{print $1}')
  version=$(echo $ciphers | awk -F "-" '{print $2}')
  response=$(curl -s https://ciphersuite.info/cs/$cipher/)
  result1=$(echo $response | sed 's/>/\n/g' | sed 's/</\n/g' | grep "^$cipher" | sed 's/ *$//')
  result2=$(echo $response | sed 's/> /\n/g' | grep "span class=\"text-" | awk -F "[><]" '{print $3}')  
  #version=$(echo $response | tr ' ' '\n' | grep "^TLS" | sed 's/,$//' | grep "[0-9]$ | paste -sd ' '")
  if [[ -z "$result1" ]];then
    not="!Not Found!"
    info="MANUAL SEARCH REQUIRED"
    echo -e "[$Red$not$NC] - [$Red$cipher$NC] - [$Red$info$NC]"
  elif [[ "Weak" == *"$result2"*  ]];then
    echo -e "[$Yellow$result2$NC] - [$Yellow$result1$NC] - [$version]"
  elif [[ "Insecure" == *"$result2"* ]];then
    echo -e "[$Red$result2$NC] - [$Red$result1$NC] - [$version]"
  else
    echo -e "[$Green$result2$NC] - [$Green$result1$NC] - [$version]"
  fi
  sleep 2
done
rm .out .ready-to-go
