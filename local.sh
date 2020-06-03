#!/bin/bash
# Wrapper script for roachprod
# Takes 2 optional parameters
#  1) version (i.e. 20.1.0)
#  2) nodes
#  3) start cli (Y/N)

echo -e 'Enterprise License: '$COCKROACH_DEV_LICENSE

## Parameter check

if [ -z "$1" ]
then
  VERSION=20.1.0
else
  VERSION=$1
fi

if [ -z "$2" ]
then
  NODES=5
else
  NODES=$2
fi

export CLUSTER=local
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export BIN_VER="${DIR}/crdb_bin/cockroach-v$VERSION/cockroach"

## Use the specified Cockroach binary version

if ( [ -f "$BIN_VER" ] )
then
  echo "Loading Bin Archive: ${BIN_VER}"
else
  echo "Exiting, couldn't find binary: ${BIN_VER}"
  exit 1;
fi

ln -sfn ${BIN_VER} /usr/local/bin/cockroach

## Create the cluster

roachprod destroy ${CLUSTER}
roachprod create ${CLUSTER} -n ${NODES}
roachprod start ${CLUSTER}
roachprod status ${CLUSTER}

## Setup haproxy

cockroach gen haproxy --insecure --host=localhost --port=26257 --out=${DIR}/haproxy/haproxy.cfg
sed -i.saved 's/^    bind :26257/    bind :26000/' ${DIR}/haproxy/haproxy.cfg
haproxy -f ${DIR}/haproxy/haproxy.cfg &

## Set License and open Admin UI

echo "Set Enterprise License"
cockroach sql --insecure --echo-sql -e "SET CLUSTER SETTING cluster.organization = 'Cockroach Labs - Production Testing';" -e "SET CLUSTER SETTING enterprise.license ='${COCKROACH_DEV_LICENSE}';" -e "SET CLUSTER SETTING kv.rangefeed.enabled=true;"
roachprod adminurl ${CLUSTER}:1 --open --ips

## Load data into extern directories for importing

mkdir ${HOME}/local/1/data/extern
mkdir ${HOME}/local/2/data/extern
mkdir ${HOME}/local/3/data/extern
mkdir ${HOME}/local/4/data/extern
mkdir ${HOME}/local/5/data/extern

cp ${DIR}/data/* /Users/chriscasano/local/1/data/extern
cp ${DIR}/data/* /Users/chriscasano/local/2/data/extern
cp ${DIR}/data/* /Users/chriscasano/local/3/data/extern
cp ${DIR}/data/* /Users/chriscasano/local/4/data/extern
cp ${DIR}/data/* /Users/chriscasano/local/5/data/extern

if [ "$3" == 'N' ]
then
  echo "no cli"
else
  roachprod sql local:1
fi
