#!/bin/bash

# Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Variables
input=$(echo $1 | grep -oP "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}$")
input_regex="([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\/([0-9]{1,2})"

# Help Pannel
helpPannel() {
  echo -e "\nExample of usage:\n\n${redColour}$0${endColour} 192.168.10.12/24\n"
  exit 1
}

# Converts value to decimal
OctetToDec() {
  local bin_num=$1
  local dec_num=$(echo "ibase=2; $bin_num" | bc)

  echo $dec_num
}

# Converts value to binary
OctetToBin() {
  local dec_num=$1
  local bin_num=$(echo "obase=2; $dec_num" | bc)

  while [[ $(echo -n $bin_num | wc -c) < 8 ]]; do
    bin_num="0$bin_num"
  done
  
  echo $bin_num
}

if [[ $input =~ $input_regex ]]; then

  octets=(${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} ${BASH_REMATCH[4]})
  cidr=${BASH_REMATCH[5]}
  ip=$(echo ${octets[@]} | tr ' ' '.')

else
  helpPannel
fi

# Converts the ip from decimal to binary
for i in ${octets[@]}; do
  binary=$(OctetToBin $i)
  bin_ip+=($binary)
done

# Converts the cidr to mask
for i in $(seq 1 32); do
  if [[ $i -le $cidr ]]; then
    value=1
  else
    value=0
  fi

  if [[ $(($i % 8)) -eq 0 ]]; then
    section+=$value
    bin_mask+=($section)
    section=""
  else
    section+=$value
  fi
done

# Converts mask to decimal
for i in ${bin_mask[@]}; do
  dec_mask+=($(OctetToDec $i))
done
mask=$(echo ${dec_mask[@]} | tr ' ' '.')

# Gets network
for i in $(seq 1 32); do
  if [[ $(echo ${bin_ip[@]} | tr -d ' ' | cut -c $i) -eq 1 && $(echo ${bin_mask[@]} | tr -d ' ' | cut -c $i) -eq 1 ]]; then
    value=1
  else
    value=0
  fi

  if [[ $(($i % 8)) -eq 0 ]]; then
    section+=$value
    bin_network+=($section)
    section=""
  else
    section+=$value
  fi
done
for i in ${bin_network[@]}; do
  dec_network+=($(OctetToDec $i))
done
network=$(echo ${dec_network[@]} | tr ' ' '.')

# Gets broadcast
for i in $(seq 1 32); do
  if [[ $i -gt $cidr ]]; then
    value=1
  else
    value=$(echo ${bin_ip[@]} | tr -d ' ' | cut -c $i)
  fi

  if [[ $(($i % 8)) -eq 0 ]]; then
    section+=$value
    bin_broadcast+=($section)
    section=""
  else
    section+=$value
  fi
done
for i in ${bin_broadcast[@]}; do
  dec_broadcast+=($(OctetToDec $i))
done
broadcast=$(echo ${dec_broadcast[@]} | tr ' ' '.')

# Calculates hosts
hosts=$((2 ** (32 - $cidr)))
uhosts=$(($hosts - 2))

# Calculates ip type
if [ "${bin_network[0]:0:1}" == "0" ];then
  ipType="A"
elif [ "${bin_network[0]:0:2}" == "10" ]; then
  ipType="B"
elif [ "${bin_network[0]:0:3}" == "110" ]; then
  ipType="C"
elif [ "${bin_network[0]:0:4}" == "1110" ]; then
  ipType="D"
elif [ "${bin_network[0]:0:5}" == "1111" ]; then
  ipType="E"
fi

# Calculates first ip
bnet=$(echo ${bin_network[@]} | tr -d ' ')
for ((i = 0; i < 32; i++)); do
  if [[ i -eq 31 ]]; then
    value=1
  else
    value=${bnet:i:1}
  fi

  if [[ $((($i + 1) % 8)) -eq 0 ]]; then
    section+=$value
    bin_first+=($section)
    section=""
  else
    section+=$value
  fi
done
for i in ${bin_first[@]}; do
  dec_first+=($(OctetToDec $i))
done
first=$(echo ${dec_first[@]} | tr ' ' '.')

# Calculates last ip
bbroad=$(echo ${bin_broadcast[@]} | tr -d ' ')
for ((i = 0; i < 32; i++)); do
  if [[ i -eq 31 ]]; then
    value=0
  else
    value=${bbroad:i:1}
  fi

  if [[ $((($i + 1) % 8)) -eq 0 ]]; then
    section+=$value
    bin_last+=($section)
    section=""
  else
    section+=$value
  fi
done
for i in ${bin_last[@]}; do
  dec_last+=($(OctetToDec $i))
done
last=$(echo ${dec_last[@]} | tr ' ' '.')


# Output
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
echo -e "First IP ->\t\t${yellowColour}$first${endColour}\n"
echo -e "Last IP ->\t\t${yellowColour}$last${endColour}\n"
echo -e "\n${purpleColour}######### Binary data #########${endColour}\n"
echo -e "IP ->\t\t\t${yellowColour}${bin_ip[@]}${endColour}\n"
echo -e "Mask ->\t\t\t${yellowColour}${bin_mask[@]}${endColour}\n"
echo -e "Network ->\t\t${yellowColour}${bin_network[@]}${endColour}\n"
echo -e "Broadcast ->\t\t${yellowColour}${bin_broadcast[@]}${endColour}\n"
echo -e "First IP ->\t\t${yellowColour}${bin_first[@]}${endColour}\n"
echo -e "Last IP ->\t\t${yellowColour}${bin_last[@]}${endColour}\n"
