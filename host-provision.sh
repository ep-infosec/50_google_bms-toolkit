#!/bin/bash
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo Command used:
echo "$0 $@"
echo

shopt -s nocasematch

# Check if we're using the Mac stock getopt and fail if true
out=`getopt -T`
if [ $? != 4 ]; then
  echo -e "Your getopt does not support long parameters, possibly you're on a Mac, if so please install gnu-getopt with brew"
  echo -e "\thttps://brewformulas.org/Gnu-getopt"
  exit
fi

GETOPT_MANDATORY="instance-ip-addr:"
GETOPT_OPTIONAL="instance-ssh-user:,proxy-setup:,u01-lun:,help"
GETOPT_LONG="${GETOPT_MANDATORY},${GETOPT_OPTIONAL}"
GETOPT_SHORT="h"

INSTANCE_SSH_USER="${INSTANCE_SSH_USER:-'ansible'}"

options=$(getopt --longoptions "$GETOPT_LONG" --options "$GETOPT_SHORT" -- "$@")

[ $? -eq 0 ] || {
       echo "Invalid options provided: $*"
       exit 1
}

# echo "PARSED COMMAND LINE FLAGS: $options"

eval set -- "$options"

while true; do
    case "$1" in
    --u01-lun)
        ORA_U01_LUN="$2"
        shift;
        ;;
    --proxy-setup)
        ORA_PROXY_SETUP="$2"
        shift;
        ;;
    --instance-ssh-user)
        INSTANCE_SSH_USER="$2"
        shift;
        ;;
    --instance-ip-addr)
        ORA_CS_HOSTS="$2"
        shift;
        ;;
    --help|-h)
        echo -e "\tUsage: `basename $0` "
        echo $GETOPT_MANDATORY|sed 's/,/\n/g'|sed 's/:/ <value>/'|sed 's/\(.\+\)/\t  --\1/'
        echo $GETOPT_OPTIONAL |sed 's/,/\n/g'|sed 's/:/ <value>/'|sed 's/\(.\+\)/\t  [ --\1 ]/'
        exit 2
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done


export INSTANCE_SSH_USER
export ORA_CS_HOSTS
export ORA_PROXY_SETUP
export ORA_U01_LUN
export INVENTORY_FILE="$ORA_CS_HOSTS,"

echo -e "Running with parameters from command line or environment variables:\n"
set | egrep '^(ORA_|INVENTORY_|INSTANCE_)' | grep -v '_PARAM='
echo

ANSIBLE_PARAMS="-i ${INVENTORY_FILE} ${ANSIBLE_PARAMS}"
ANSIBLE_EXTRA_PARAMS="${*}"

export ANSIBLE_DISPLAY_SKIPPED_HOSTS=false

ANSIBLE_PLAYBOOK="ansible-playbook"
if ! type ansible-playbook > /dev/null 2>&1; then
  echo "Ansible executable not found in path"
  exit 3
else
  echo "Found Ansible: `type ansible-playbook`"
fi

# exit on any error from the following scripts
set -e

PLAYBOOK="host-provision.yml"
ANSIBLE_COMMAND="${ANSIBLE_PLAYBOOK} ${ANSIBLE_PARAMS} ${ANSIBLE_EXTRA_PARAMS} ${PLAYBOOK}"
echo
echo "Running Ansible playbook: ${ANSIBLE_COMMAND}"
eval ${ANSIBLE_COMMAND}
