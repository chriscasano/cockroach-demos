#!/bin/bash
# This demonstrates CockroachDB's resilency
# It creates a 6 node cluster, kills a node, then brings the node back online
# Next, it will update the replication factor to 5 and show 2 simultaneous node failures

../local.sh 20.1.0 6 N

cockroach workload init ycsb
cockroach workload run ycsb --duration 5m --max-rate=50 --concurrency=2 --display-every=60s --tolerate-errors "postgresql://root@localhost:26000/ycsb?sslmode=disable" &

#### Stop a node
read -p '*Press [Return] to stop a node*' nothing
roachprod stop local:6

#### Start node back up
read -p '*Press [Return] to bring the node back*' nothing
roachprod start local:6

read -p '*Press [Return] to up the replication factor to 5*' nothing

#### Change replication factor to 5
cockroach sql --echo-sql --insecure --execute="ALTER RANGE default CONFIGURE ZONE USING num_replicas=5;"
## Add logic to check if underreplicated

read -p '*Press [Return] to stop 2 nodes' nothing

#### Stop 2 nodes
roachprod stop local:6
roachprod stop local:5

read -p '*Press [Return] to end the demo' nothing

pkill -9 haproxy
roachprod destroy local
pkill -9 cockroach
