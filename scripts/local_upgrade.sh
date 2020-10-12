#!/bin/bash
# This demo performs a rolling upgrade for CockroachDB
# Dependencies:
#  - Make sure you have two CockroachDB binaries in crdb_bin/


export old_bin=19.2.5
export new_bin=20.1.6

../local.sh 19.2.5 5 N

sleep 5

cockroach workload init ycsb
cockroach workload run ycsb --duration=15m --max-rate=50 --concurrency=2 --display-every=60s --tolerate-errors "postgresql://root@localhost:26000/ycsb?sslmode=disable" &

sleep 10

read -p "Press [Return] To Upgrade" nothing

echo "Upgrading Node 5..."
roachprod stop local:5
roachprod start local:5 --binary=../crdb_bin/cockroach-v${new_bin}/cockroach

sleep 10

echo "Upgraded Node 4..."
roachprod stop local:4
roachprod start local:4 --binary=../crdb_bin/cockroach-v${new_bin}/cockroach

sleep 10

echo "Upgraded Node 3..."
roachprod stop local:3
roachprod start local:3 --binary=../crdb_bin/cockroach-v${new_bin}/cockroach

sleep 10

echo "Upgraded Node 2..."
roachprod stop local:2
roachprod start local:2 --binary=../crdb_bin/cockroach-v${new_bin}/cockroach

sleep 10

echo "Upgraded Node 1..."
roachprod stop local:1
roachprod start local:1 --binary=../crdb_bin/cockroach-v${new_bin}/cockroach

echo "Done"
read -p "Press [Return] To End The Demo" nothing

roachprod destroy local
pkill -9 haproxy
pkill -9 cockroach
