#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

#Variables
input=$(echo $1 | grep -oP "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}$")
ip=$(echo $input | grep -oP "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")
cidr=$(echo $input | grep -oP "/\K\d{1,2}")
error="\n${redColour}[!]${endColour} ${grayColour}Something went wrong!${endColour}\n"
checkInput(){
  if [ -z $ip ];then
    echo -e $error
    helpPannel
    exit 1
  else
    for i in $(seq 1 4);do 
      local section=$(echo $ip | awk -v var="$i" $'{print $var}' FS='.')
      if [ $section -lt 0 ] || [ $section -gt 255 ];then
      echo -e $error
      helpPannel
        exit 1
      fi
    done
  fi
  if [ -z $cidr ] || [ $cidr -le 0 ] || [ $cidr -ge 32 ];then
    echo -e $error
    helpPannel
    exit 1
  fi
}
helpPannel(){
  echo -e "\nExample of usage:\n\n${redColour}$0${endColour} 192.168.10.12/24\n"
}
calcType(){
  if [ "${binNetwork:0:1}" == "0" ];then
    ipType="A"
  elif [ "${binNetwork:0:2}" == "10" ]; then
    ipType="B"
  elif [ "${binNetwork:0:3}" == "110" ]; then
    ipType="C"
  elif [ "${binNetwork:0:4}" == "1110" ]; then
    ipType="D"
  elif [ "${binNetwork:0:4}" == "1111" ]; then
    ipType="E"
  fi
  # ipType=""
}
cidrToMask(){
  binMask=""
  for i in $(seq 1 $cidr);do 
    binMask+="1"
  done
  while [ $(echo -n $binMask | wc -c) -lt 32 ]; do
    binMask+="0"
  done
  offset=0
  mask=""
  for i in $(seq 1 4);do 
    mask+=$(echo "ibase=2; ${binMask:offset:8}" | bc)
    mask+="."
    offset=$((offset + 8))
  done
  mask=$(echo $mask | sed -e "s/.$//g")
}
calcHosts(){
  ncidr=$((32-$cidr))
  hosts=$((2**$ncidr))
  uhosts=$(($hosts-2))
}
decToBin(){
  local dec=$1
  local tmp
  local bin=""
  for i in $(seq 1 4);do 
    tmp=$(echo "obase=2; $(echo $dec | awk -v var="$i" $'{print $var}' FS='.')" | bc)
    while [ $(echo -n $tmp | wc -c) -lt 8 ];do 
      tmp="0$tmp"
    done
    bin+=$tmp
  done
  echo -n $bin
}
calcNetwork(){
  binNetwork=""
  for i in $(seq 0 31);do 
    binNetwork+=$((${binIP:i:1}&${binMask:i:1}))
  done
  offset=0
  network=""
  for i in $(seq 1 4);do 
    network+=$(echo "ibase=2; ${binNetwork:offset:8}" | bc)
    network+="."
    offset=$((offset + 8))
  done
  network=$(echo $network | sed -e "s/.$//g")
}
calcBroadcast(){
  binBroadcast=""
  for i in $(seq 0 31);do 
    if [ ${binMask:i:1} -eq 1 ];then
      binBroadcast+=${binIP:i:1}
    else
      binBroadcast+="1"
    fi
  done
  offset=0
  broadcast=""
  for i in $(seq 1 4);do 
    broadcast+=$(echo "ibase=2; ${binBroadcast:offset:8}" | bc)
    broadcast+="."
    offset=$((offset + 8))
  done
  broadcast=$(echo $broadcast | sed -e "s/.$//g")
}
calcFirstAndLast(){
  binFirstIP="${binNetwork:0:31}1"
  binLastIP="${binBroadcast:0:31}0"
  offset=0
  firstIP=""
  lastIP=""
  for i in $(seq 1 4);do 
    firstIP+=$(echo "ibase=2; ${binFirstIP:offset:8}" | bc)
    firstIP+="."
    lastIP+=$(echo "ibase=2; ${binLastIP:offset:8}" | bc)
    lastIP+="."
    offset=$((offset + 8))
  done
  firstIP=$(echo $firstIP | sed -e "s/.$//g")
  lastIP=$(echo $lastIP | sed -e "s/.$//g")
}
binSpaces (){
  local in=$1
  offset=0
  result=""
  for i in $(seq 1 4);do 
    result+="${in:offset:8} "
    offset=$((offset + 8))
  done
  result=$(echo $result | sed -e "s/ $//g")
  echo -n $result
}

checkInput
cidrToMask
calcHosts

binIP=$(decToBin $ip)
calcNetwork
calcBroadcast
calcFirstAndLast
calcType

#Output
echo -e "${grayColour}\nResults for${endColour} ${redColour}$1${endColour}\n"
echo -e "\n${purpleColour}######### Decimal data #########${endColour}\n"
echo -e "IP ->\t\t\t${yellowColour}$ip${endColour}\n"
echo -e "Mask ->\t\t\t${yellowColour}$mask${endColour}\n"
echo -e "Class ->\t\t${yellowColour}$ipType${endColour}\n"
echo -e "CIDR ->\t\t\t${yellowColour}$cidr${endColour}\n"
echo -e "Hosts ->\t\t${yellowColour}$hosts${endColour}\n"
echo -e "Usable Hosts ->\t\t${yellowColour}$uhosts${endColour}\n"
echo -e "Network -> \t\t${yellowColour}$network${endColour}\n"
echo -e "Broadcast ->\t\t${yellowColour}$broadcast${endColour}\n"
echo -e "First IP ->\t\t${yellowColour}$firstIP${endColour}\n"
echo -e "Last IP ->\t\t${yellowColour}$lastIP${endColour}\n"
echo -e "\n${purpleColour}######### Binary data #########${endColour}\n"
echo -e "IP ->\t\t\t${yellowColour}$(binSpaces $binIP)${endColour}\n"
echo -e "Mask ->\t\t\t${yellowColour}$(binSpaces $binMask)${endColour}\n"
echo -e "Network ->\t\t${yellowColour}$(binSpaces $binNetwork)${endColour}\n"
echo -e "Broadcast ->\t\t${yellowColour}$(binSpaces $binBroadcast)${endColour}\n"
echo -e "First IP ->\t\t${yellowColour}$(binSpaces $binFirstIP)${endColour}\n"
echo -e "Last IP ->\t\t${yellowColour}$(binSpaces $binLastIP)${endColour}\n"
