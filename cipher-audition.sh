#!/bin/bash


Orange='\033[0;33m'
Yellow='\033[1;33m'
Red='\033[0;31m'
Green='\033[0;32m'
NC='\033[0m'

terminal_sets=$(stty -g)
data=$(nmap -Pn --script ssl-enum-ciphers -p 443 $1 | awk '{print $2}' | grep "TLS" | sed 's/://g')
for ciphers in $data
do
  echo $ciphers >> .out
done
cat .out | sed -n '/^TLSv/{h;n}; /^TLS_/{G;s/\n/-/p}' >> .ready-to-go
for ciphers in $(cat .ready-to-go)
do
  cipher=$(echo $ciphers | awk -F "-" '{print $1}')
  if [[ $cipher == *"AKE"* ]];then
    cipher=$(echo $cipher | sed 's/_AKE_WITH//g')
  else
    :
  fi
  version=$(echo $ciphers | awk -F "-" '{print $2}' | sed 's/ //g')
  ciphersuite="[*] Requesting CipherSuite"
  #printf "\r$ciphersuite"
  response=$(curl -s https://ciphersuite.info/cs/$cipher/)
  result1=$(echo $response | sed 's/>/\n/g' | sed 's/</\n/g' | grep "a href" | sed 's/"//g' | grep $cipher | awk -F "/" '{print $4}')
  result2=$(echo $response | sed 's/> /\n/g' | grep "span class=\"text-" | awk -F "[><]" '{print $3}' | sed 's/ //g') 
  #echo -e $colorful_result2" - "$colorful_result1" - "$version_of_version
  #version=$(echo $response | tr ' ' '\n' | grep "^TLS" | sed 's/,$//' | grep "[0-9]$ | paste -sd ' '")
  if [[ -z "$result1" ]];then
  not="!Not Found!"
  info="MANUAL SEARCH REQUIRED"
  echo -e $Red$not$NC"-"$Red$cipher$NC"-"$Red$info$NC >> .not-found
  elif [[ "Weak" == *"$result2"*  ]];then
  colorful_weak2="[$Yellow$result2$NC]"
  colorful_weak1="[$Yellow$result1$NC]"
  version_of_version="[$version]"
  echo -e $colorful_weak2"-"$colorful_weak1"-"$version_of_version >> .weak-ones
  elif [[ "Insecure" == *"$result2"* ]];then
  colorful_insecure2="[$Red$result2$NC]"
  colorful_insecure1="[$Red$result1$NC]"
  version_of_version="[$version]"
  echo -e $colorful_insecure2"-"$colorful_insecure1"-"$version_of_version >> .insecure-ones
  else
  colorful_strong2="[$Green$result2$NC]"
  colorful_strong1="[$Green$result1$NC]"
  version_of_version="[$version]"
  echo -e $colorful_strong2"-"$colorful_strong1"-"$version_of_version >> .secure-ones
  fi
done
tput cnorm
stty "$terminal_sets"
echo
secure_results=$(file .secure-ones | awk -F ": " '{print $2}')
weak_results=$(file .weak-ones | awk -F ": " '{print $2}')
insecure_results=$(file .insecure-ones | awk -F ": " '{print $2}')
not_results=$(file .not-found | awk -F ": " '{print $2}')

hold="[*] Sorting output. Please Wait!"
echo $hold
if [[ "$secure_results" == *"empty"* ]];then
 :
elif [[ "$secure_results" == *"cannot open"* ]];then
 :
else
 cat .secure-ones | sort -rn
 rm .secure-ones
fi

if [[ "$weak_results" == *"empty"* ]];then
 :
elif [[ "$weak_results" == *"cannot open"* ]];then
 :
else
 cat .weak-ones | awk '{print length "?"$N0}' | sort -rn | awk -F "?" '{print $2}'
 #rm .weak-ones
fi

if [[ "$insecure_results" == *"empty"* ]];then
 :
elif [[ "$insecure_results" == *"cannot open"* ]];then
 :
else
 cat .insecure-ones | sort -rn
 rm .insecure-ones
fi

if [[ "$not_results" == *"empty"* ]];then
 :
elif [[ "$not_results" == *"cannot open"* ]];then
 :
else
 cat .not-found | sort -rn
 rm .not-found
fi
rm .out .ready-to-go
