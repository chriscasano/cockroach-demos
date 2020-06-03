#!/bin/bash
# This script creates a single node Cockroach cluster,
# runs the Movr workload and outputs all transactions
# on the rides table to S3.

export HTTP=8080
export RPC=26257
export BUCKET=chrisc-test

echo "*** Clean Up Prior Run ***"
echo "**************************"
cockroach quit --insecure --port=${RPC}
rm -Rf cockroach/
rm -Rf data/
rm -Rf logs/
rm -Rf rides/
aws s3 rm s3://${BUCKET}/changefeed/rides/ --recursive

echo "*** Create Single Node ***"
echo "**************************"
cockroach start-single-node --insecure --background --http-addr=:${HTTP} --listen-addr=:${RPC} --store=cockroach
open http://localhost:${HTTP}
sleep 5

read -p '*** Press [Return] to start the Movr workload ***' nothing
cockroach workload init movr --num-rides=20 "postgresql://root@localhost:${RPC}/movr?sslmode=disable"
cockroach sql --insecure -e="SET CLUSTER SETTING kv.rangefeed.enabled = true; SET CLUSTER SETTING enterprise.license = \"${COCKROACH_DEV_LICENSE}\"; SET CLUSTER SETTING cluster.organization = 'Cockroach Labs - Production Testing';"
cockroach sql --insecure -e="CREATE CHANGEFEED FOR TABLE movr.rides INTO \"experimental-s3://${BUCKET}/changefeed/rides?AUTH=implicit\" WITH updated,resolved='10s';"
cockroach workload run movr --duration=1m --display-every=30s --max-rate=10 --concurrency=1 "postgresql://root@localhost:26257/movr?sslmode=disable" > workload.log 2>&1 &

read -p '*** Press [Return] to view the CDC output in S3 ***' nothing
echo "Listing all S3 changefeed files..."
echo "**********************************"
aws s3 ls s3://${BUCKET}/changefeed/rides/
aws s3 sync s3://${BUCKET}/changefeed/ .

echo "Showing changefeed records..."
echo "*****************************"
cat rides/*/*.ndjson

read -p '*** Press [Return] to end the demo ***' nothing
cockroach quit --insecure --port=${RPC}
rm -Rf cockroach/
rm -Rf data/
rm -Rf logs/
rm -Rf rides/
aws s3 rm s3://${BUCKET}/changefeed/rides/ --recursive
