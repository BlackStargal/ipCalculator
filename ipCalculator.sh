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
if [ -z "$1" ]
then
echo -e "\nComo se usa:\n\n${purpleColour}$0${endColour} ${yellowColour}192.168.10.12/24${endColour}\n"
exit 1
fi
ip=$(echo $1 | awk $'{print $1}' FS="/")
cidr=$(echo $1 | awk $'{print $2}' FS="/")
ncidr=$(echo "32 - $cidr" | bc)
null="11111111111111111111111111111111"
bmask1=""
bmask2=""
temp1=""
temp2=""
temp3=""
temp4=""
network=""
nhosts=$(echo "2 ^ $ncidr -2" | bc)
for i in {1..32}
do
	if [ $i -gt $cidr ]
    	then
        	break
    	fi
	bmask1="1$bmask1"
done
mcidr=$(echo "32-$cidr" | bc)
for i in {1..32}
do
	if [ $i -gt $mcidr ]
        then
                break
        fi
	bmask2="0$bmask2"
done
bnetmask=$bmask1$bmask2
temp1=$(echo "ibase=2; ${bnetmask:0:8}" | bc)
temp2=$(echo "ibase=2; ${bnetmask:8:8}" | bc)
temp3=$(echo "ibase=2; ${bnetmask:16:8}" | bc)
temp4=$(echo "ibase=2; ${bnetmask:24:8}" | bc)
netmask="$temp1.$temp2.$temp3.$temp4"
temp1=$(echo "obase=2; $(echo $ip | awk $'{print $1}' FS=".")" | bc)
temp2=$(echo "obase=2; $(echo $ip | awk $'{print $2}' FS=".")" | bc)
temp3=$(echo "obase=2; $(echo $ip | awk $'{print $3}' FS=".")" | bc)
temp4=$(echo "obase=2; $(echo $ip | awk $'{print $4}' FS=".")" | bc)
for i in {1..4}
do
	tempi="temp${i}"
	if [ $(echo "$(echo $(echo "${!tempi}" | wc -c) - 1)" | bc) -lt 8 ]
	then
		while [ $(echo "$(echo $(echo "${!tempi}" | wc -c) - 1)" | bc) -lt 8 ]
		do
			declare ${tempi}="0${!tempi}"
		done
	fi
done
bnetwork=""
bip="$temp1$temp2$temp3$temp4"
for i in {0..31}
do
	if [ ${bip:i:1} -eq 1 ] && [ ${bnetmask:i:1} -eq 1 ]
	then
		bnetwork=${bnetwork}1
	else
		bnetwork=${bnetwork}0
	fi
done
temp1=$(echo "ibase=2; ${bnetwork:0:8}" | bc)
temp2=$(echo "ibase=2; ${bnetwork:8:8}" | bc)
temp3=$(echo "ibase=2; ${bnetwork:16:8}" | bc)
temp4=$(echo "ibase=2; ${bnetwork:24:8}" | bc)
network="$temp1.$temp2.$temp3.$temp4"
temp1=$(echo "ibase=2; ${bnetwork:0:8}" | bc)
temp2=$(echo "ibase=2; ${bnetwork:8:8}" | bc)
temp3=$(echo "ibase=2; ${bnetwork:16:8}" | bc)
temp4=$(echo "ibase=2; ${bnetwork:24:7}1" | bc)
firstIP="$temp1.$temp2.$temp3.$temp4"
bbroadcast="${bnetwork:0:cidr}${null:0:ncidr}"
temp1=$(echo "ibase=2; ${bbroadcast:0:8}" | bc)
temp2=$(echo "ibase=2; ${bbroadcast:8:8}" | bc)
temp3=$(echo "ibase=2; ${bbroadcast:16:8}" | bc)
temp4=$(echo "ibase=2; ${bbroadcast:24:7}0" | bc)
lastIP="$temp1.$temp2.$temp3.$temp4"
temp1=$(echo "ibase=2; ${bbroadcast:0:8}" | bc)
temp2=$(echo "ibase=2; ${bbroadcast:8:8}" | bc)
temp3=$(echo "ibase=2; ${bbroadcast:16:8}" | bc)
temp4=$(echo "ibase=2; ${bbroadcast:24:8}" | bc)
broadcast="$temp1.$temp2.$temp3.$temp4"
echo -e "\n\n${purpleColour}####### Estos son los datos en decimal #######${endColour}"
echo -e "\n${greyColour}Esta es la ip ->                    ${endColour}${yellowColour}$ip${endColour}"
echo -e "\n${greyColour}Este es el cidr ->                  ${endColour}${yellowColour}$cidr${endColour}"
echo -e "\n${greyColour}Este es el número de hosts ->       ${endColour}${yellowColour}$nhosts${endColour}"
echo -e "\n${greyColour}Esta es la mascara de red ->        ${endColour}${yellowColour}$netmask${endColour}"
echo -e "\n${greyColour}Esta es la dirección de red -> 	    ${endColour}${yellowColour}$network${endColour}"
echo -e "\n${greyColour}Esta es la primera ip ->            ${endColour}${yellowColour}$firstIP${endColour}"
echo -e "\n${greyColour}Esta es la última ip ->             ${endColour}${yellowColour}$lastIP${endColour}"
echo -e "\n${greyColour}Esta es la dirección broadcast ->   ${endColour}${yellowColour}$broadcast${endColour}"
echo -e "\n\n${purpleColour}####### Estos son los datos en binario #######${endColour}"
echo -e "\n${greyColour}Dirección IP ->        ${endColour}${yellowColour}$bip${endColour}"
echo -e "\n${greyColour}Mascara de capa ->     ${endColour}${yellowColour}$bnetmask${endColour}"
echo -e "\n${greyColour}Dirección de red ->    ${endColour}${yellowColour}$bnetwork${endColour}"
echo -e "\n${greyColour}Dirección broadcast -> ${endColour}${yellowColour}$bbroadcast${endColour}\n"
