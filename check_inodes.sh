#! /bin/bash
#################################################################################
# Ident		: check_inodes.sh - 1.2
# Auteur	: J.Behuet
#
# Description 	: Vérification des inodes du système de fichier
# 
# Usage		: ./check_inodes.sh
# Remarque(s)	:
#
#
# Versions	:
#  V   | Date     | Auteur           | Description des modifications
# -----|----------|------------------|------------------------------------------	
# 1.0  |23-05-2013| J.Behuet	     |
# 1.1  |23-05-2013| J.Behuet	     | Inversement FS_CRITICAL et FS_OK
# 1.2  |25-05_2013| J.Behuet	     | Correction substr()
#
#################################################################################

SCRIPTNAME=`basename $0`
VERSION="1.2"

# COLOR
GREEN="\\033[1;32m"
RED="\\033[1;31m"
YELLOW="\\033[1;33m"
NORMAL="\\033[0;39m"

# STATE
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4
DESCRIPTION="Vérification des inodes du système de fichier"

STATE=$STATE_UNKNOWN

#PARAM
WARNING_VALUE=40
CRITICAL_VALUE=70
VERBOSE=false

function print_usage() {
  echo -e "Usage\t: ./$SCRIPTNAME"
  echo -e "ARGS"
  echo -e "\t-h : Print help"
  echo -e "\t-v : Verbose"
}

function print_version() {
  echo -e "Ident\t: $SCRIPTNAME version $VERSION"
  echo -e "Auteur\t: J.Behuet"
}

function print_help() {
  print_version
  echo ""
  print_usage
  echo $DESCRIPTION
}

while getopts :hv OPT
do
  case $OPT in
    h)
      print_help
      exit $STATE_UNKNOWN
      ;;
    v)
      VERBOSE=true
      ;;
    \?)
      echo -e "$SCRIPTNAME : Option incorrecte : $OPTARG"
      print_usage
      exit $STATE_UNKNOWN
      ;;
   esac
done

# FS ARRAY
ARR=(`df -i | grep -E "^/dev/" |  awk '{ print $1";"$5; }'`)

CPT=0
WARNING=0
CRITICAL=0

FS_OK=""
FS_WARNING=""
FS_CRITICAL=""

for v in "${ARR[@]}"; do

  if [ $CPT -ne 0 ]; then
  
    FS_INFO=(`echo $v | tr ';' ' '`)
    INODE=(`echo ${FS_INFO[1]} | sed 's/%//'`)

    if [ "$INODE" -ge "$CRITICAL_VALUE" ]; then
       FS_CRITICAL+=${FS_INFO[0]}", "
       if $VERBOSE; then
         echo -e "${FS_INFO[0]}\t$INODE%\t [$RED CRITICAL $NORMAL]"
       fi
       ((CRITICAL++))
    elif [ "$INODE" -ge "$WARNING_VALUE" ] && [ "$INODE" -lt "$CRITICAL_VALUE" ]; then
	FS_WARNING+=${FS_INFO[0]}", "
	if $VERBOSE; then
	 echo -e "${FS_INFO[0]}\t$INODE%\t [$YELLOW WARNING $NORMAL]"
	fi
	((WARNING++))
    else
       FS_OK+=${FS_INFO[0]}", "
       if $VERBOSE; then
        echo -e "${FS_INFO[0]}\t$INODE%\t [$GREEN OK $NORMAL]" 
       fi
    fi
  fi

  ((CPT++))
done

if [ $CRITICAL -gt $WARNING ]; then
  echo "CRITICAL - $FS_CRITICAL" |sed 's/.\{2\}$//'
  STATE=$STATE_CRITICAL
elif [ $WARNING -ne 0 ]; then
  echo "WARNING - $FS_CRITICAL" |sed 's/.\{2\}$//'
  STATE=$STATE_WARNING
else
  echo "OK - $FS_OK" |sed 's/.\{2\}$//'
  STATE=$STATE_OK
fi

exit $STATE
