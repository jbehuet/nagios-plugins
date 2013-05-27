#! /bin/bash
#################################################################################
# Ident		: check_fs.sh - 1.0
# Auteur	: J.Behuet
#
# Description 	: Vérifie que les points de montage du système de fichier
#		  ne sont pas en RO par un test d'ecriture
# 
# Usage		: ./check_fs.sh
# Remarque(s)	:
#
#
# Versions	:
#  V   | Date     | Auteur           | Description des modifications
# -----|----------|------------------|------------------------------------------	
# 0.1  |10-05-2013| J.Behuet	     | Initial
# 0.2  |11-05-2013| J.Behuet	     | Boucle sur les FS et touch
# 1.0  |13-05-2013| J.Behuet	     | Message de sortie et mode verbeux
#
#
#################################################################################

SCRIPTNAME=`basename $0`
VERSION="1.0"

# COLOR
GREEN="\\033[1;32m"
RED="\\033[1;31m"
NORMAL="\\033[0;39m"

# STATE
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4
DESCRIPTION="Vérifie que les points de montage du système de fichier ne sont pas en Read-Only par un test d'écriture"

STATE=$STATE_UNKNOWN
VERBOSE=false

function print_usage() {
  echo -e "Usage\t: ./check_fs.sh"
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
ARR=(`df -h | grep -vE "^Filesystem|shm|boot|none" |  awk '{ print $1";"$6; }'`)

CPT=0
ERROR=0

FS_OK=""
FS_ERROR=""

for v in "${ARR[@]}"; do

  if [ $CPT -ne 0 ]; then
  
    FS_INFO=(`echo $v | tr ';' ' '`)
    FILENAME=$(</dev/urandom tr -dc '[:alnum:]' | head -c ${1:-8} 2>&1)

    if [ `touch ${FS_INFO[1]}/$FILENAME 2> /dev/null; echo "$?"` -eq 0 ]; then
       FS_OK+=${FS_INFO[0]}", "
       if $VERBOSE; then
         echo -e "${FS_INFO[0]}\t [$GREEN SUCCESS $NORMAL]"
       fi
       rm ${FS_INFO[1]}/$FILENAME
    else
       FS_CRITICAL+=${FS_INFO[0]}", "
       if $VERBOSE; then
        echo -e "${FS_INFO[0]}\t [$RED ERROR $NORMAL]" 
       fi
       ((ERROR++))
    fi
  fi

  ((CPT++))
done

if [ $ERROR -ne 0 ]; then
  echo "CRITICAL - $FS_CRITICAL" |sed 's/.\{2\}$//'
  STATE=$STATE_CRITICAL
else
  echo "OK - $FS_OK" |sed 's/.\{2\}$//'
  STATE=$STATE_OK
fi

exit $STATE
