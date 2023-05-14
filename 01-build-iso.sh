#!/bin/bash

set -u # Throw errors when unset variables are used
set -e # Exit on error
set -o pipefail # Bash specific

usage() {
  echo "Tool to build iso files for creating k3s nodes on fedora coreos"
  echo
  echo "Usage:"
  echo "$0 [-abh] [-u serverurl] -t <token>"
  echo
  echo "-a		Create ISO for agent, default is server"
  echo "-b		Create both server and agent ISOs"
  echo "-h		This help message"
  echo "-s		Single node (can't be used with -a/-b)"
  echo "-t <token>	Use this token for cluster"
  echo "-u <serverurl>	Server URL (needed with -a/-b)"
  exit
}

askyn() {
  while true; do
    echo -n "$1 "
    read -r yn
    case $yn in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) echo "Please answer [y]es or [n]o.";;
    esac
  done
}

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
CREATE_BOTH=""
INSTALL_TYPE="server"
TOKEN=""
SERVERURL=""

# getopts only allows single letter options (but is apparently the most
# portable). If you want multi letter options (eg --help) use getopt.
while getopts "habst:u:" opt; do
  case "$opt" in
  a)  INSTALL_TYPE="agent" ;;
  b)  CREATE_BOTH="yes" ;;
  h)
      usage
      exit 0
      ;;
  s)  INSTALL_TYPE="single" ;;
  t)  TOKEN="$OPTARG" ;;
  u)  SERVERURL="$OPTARG" ;;
  ?)  exit 1 ;; # message provided by getopts
  esac
done

shift $((OPTIND-1))

[ $# -ge 1 ] && [ "$1" = "--" ] && shift

MYDIR=$(dirname "$(realpath "$0")")
MYNAME=$(basename "$(realpath "$0")")

if [ ! "${INSTALL_TYPE}" == "single" -a -z "${TOKEN}" ]; then
  echo "Error: Token (-t) needed"
  usage
fi

if [ -n "${CREATE_BOTH}" -a -z "${SERVERURL}" ]; then
  echo "Error: Server URL (-u) needed"
  usage
fi

if [ -n "${CREATE_BOTH}" ]; then
  echo "Creating server ISO using:"
  echo "$MYDIR/$MYNAME -t ${TOKEN}"
  $MYDIR/$MYNAME -t "${TOKEN}"

  echo
  echo "Creating agent ISO using:"
  echo "$MYDIR/$MYNAME -a -t ${TOKEN} -s ${SERVERURL}"
  $MYDIR/$MYNAME -a -t "${TOKEN}" -s "${SERVERURL}"

  exit
fi

if [ "${INSTALL_TYPE}" == "agent" -a -z "${SERVERURL}" ]; then
  echo "Error: Server URL (-u) needed"
  usage
fi

OLDDIR=$(pwd)
cd $MYDIR

# Building the ISO image
# From https://www.murillodigital.com/tech_talk/k3s_in_coreos/
# FCCT is now butane

echo "Step 1: Download the vanilla CoreOS ISO image"
podman run --privileged --pull=always --rm -v .:/data -w /data quay.io/coreos/coreos-installer:release download -f iso

## The name will be something like fedora-coreos-...iso
ISOFILE=$(ls fedora-coreos-*.iso | tail -n 1)

echo
if [ $INSTALL_TYPE == "server" ]; then
  echo "Setting up for server"
  sed -e "s/%%% INSTALL OPTS %%%/server --token ${TOKEN} --with-node-id/" \
    < ignition/k3s-template/k3s-installer.sh \
    > ignition/build/k3s-installer.sh
else
  if [ $INSTALL_TYPE == "agent" ]; then
    echo "Setting up for agent"
    sed -e "s#%%% INSTALL OPTS %%%#agent --server ${SERVERURL} --token ${TOKEN} --with-node-id#" \
      < ignition/k3s-template/k3s-installer.sh \
      > ignition/build/k3s-installer.sh
  else
    echo "Setting up for single node"
    sed -e "s/%%% INSTALL OPTS %%%//" \
      < ignition/k3s-template/k3s-installer.sh \
      > ignition/build/k3s-installer.sh
  fi
fi

echo
echo "Step 2: Create an ign file from k3s-autoinstall.bu"
podman run --rm -v ./ignition:/ignition:z quay.io/coreos/butane:release --pretty -d /ignition --strict /ignition/k3s-autoinstall.bu > ignition/build/k3s-autoinstall.ign

# Insert the contents of k3s-autoinstall.ign inside coreos-autoinstall.fcc
# No longer needed! Yay! Just include the file using contents:local

echo
echo "Step 3: Create the coreos-autoinstall.ign file from coreos-autoinstall.bu"
podman run --rm -v ./ignition:/ignition:z quay.io/coreos/butane:release --pretty -d /ignition --strict /ignition/coreos-autoinstall.bu > ignition/build/coreos-autoinstall.ign

echo
echo "Step 4: Embed the coreos-autoinstall.ign ignition file inside the ISO image"
podman run --privileged --rm -v .:/data -w /data quay.io/coreos/coreos-installer:release iso ignition embed -i ignition/build/coreos-autoinstall.ign ./${ISOFILE}

echo
echo "Step 5: Storing ${INSTALL_TYPE} iso"
cp "${ISOFILE}" "${INSTALL_TYPE}.iso"

echo
echo "Step 6: Resetting Fedora CoreOS ISO image"
podman run --privileged --rm -v .:/data -w /data quay.io/coreos/coreos-installer:release iso reset ./${ISOFILE}

cd $OLDDIR
