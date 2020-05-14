#!/bin/#!/usr/bin/env bash
# This demo performs a rolling upgrade for CockroachDB
# Dependencies
# 1) You need Cockroach binaries for 19.2.x and 20.1.x
# 2) roachprod needs to be installed
# 3) haproxy needs to be installed

export old_bin=/Users/chriscasano/Applications/crdb/binaries/cockroach-v19.2.5/cockroach
export new_bin=/Users/chriscasano/Applications/crdb/binaries/cockroach-v20.1.0-rc2/cockroach
export proxy_path=/Users/chriscasano/Workspace/roachprod/haproxy.cfg

roachprod destroy local
roachprod create local -n 5
roachprod start local --binary=${old_bin}
roachprod admin local:1 --ips --open

cockroach gen haproxy --insecure --host=localhost --port=26257 --out=${proxy_path}
sed -i.saved 's/^    bind :26257/    bind :26000/' ${proxy_path}
haproxy -f ${proxy_path} &

sleep 5

cockroach workload init ycsb
cockroach workload run ycsb --duration=5m --max-rate=50 --concurrency=2 --display-every=60s --tolerate-errors "postgresql://root@localhost:26000/ycsb?sslmode=disable" &

sleep 10

read -p "Press [Return] To Upgrade" nothing

echo "Upgrading Node 5..."
roachprod stop local:5
roachprod start local:5 --binary=${new_bin}

sleep 10

echo "Upgraded Node 4..."
roachprod stop local:4
roachprod start local:4 --binary=${new_bin}

sleep 10

echo "Upgraded Node 3..."
roachprod stop local:3
roachprod start local:3 --binary=${new_bin}

sleep 10

echo "Upgraded Node 2..."
roachprod stop local:2
roachprod start local:2 --binary=${new_bin}

sleep 10

echo "Upgraded Node 1..."
roachprod stop local:1
roachprod start local:1 --binary=${new_bin}

echo "Done"
read -p "Press [Return] To End The Demo" nothing

roachprod destroy local
pkill -9 haproxy
pkill -9 cockroach
