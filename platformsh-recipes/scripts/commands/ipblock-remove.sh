#!/bin/bash
#ddev-generated
set -e -o pipefail

USAGE=$(cat << EOM
Usage: ahoy ... ipblock:rm [options] [ip-to-unblock]

  -h                This help text.
  -r                Run the command instead of printing it
EOM
)

function print_help() {
  gum style --border "rounded" --margin "1 2" --padding "1 2" "$@" "$USAGE"
}

run=
while getopts ":hr" option; do
  case ${option} in
    h)
      print_help
      exit 0
      ;;
    r)
      run=true

      ;;
  esac
done
shift $(($OPTIND - 1))

# The command sets all of the IP addresses path, this is a helper command so
# that one can add a new ip to the list, it will not do anything, only build the
# command for you to run it unless you pass --run

if [[ -z "$1" ]]; then
  echo -e "You need to provide an ip to remove!"
  exit 1
fi

httpaccess=$(platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} 2>&1)
# { grep deny || test $? = 1; } from https://stackoverflow.com/a/49627999
blocked_already=$(echo "$httpaccess" 2>&1 | { grep deny || test $? = 1; } | perl -pe "s/.*?address: '?([^\s']*).*/\$1/")

OLDIFS=$IFS
IFS=$'\n'
ips_array=($blocked_already)
IFS=$OLDIFS
block=
found=

for i in ${!ips_array[*]}; do
  if [[ ! "${ips_array[$i]}" =~ ^"$1" ]]; then
    block="$block --access deny:${ips_array[$i]}"
  else
    found="${found}IP '$1' matched ${ips_array[$i]}, will be removed!\n"
  fi
done

if [ -z "$found" ]; then
  >&2 echo -e "\033[0;32m\nNo IP matching $1 was found!\n\033[0m"
else
  if [ "$run" == "true" ]; then
    platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master} $block
  else
    >&2 echo -e "\033[0;36m\nIf you want to remove the IPs matching $1 from the currently blocked IPs, run the following...\n\033[0m"
    >&2 echo -e "platform httpaccess -e ${PLATFORMSH_RECIPES_MAIN_BRANCH-master}\\\\\n\t\t$block"
  fi

  >&2 echo -e "\033[0;32m\n$found\033[0m"

fi
