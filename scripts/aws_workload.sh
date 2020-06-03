############################
# Standard Roachprod Demos
############################

export CLUSTER="${USER:0:6}-test"
export NODES=6
export CNODES=$(($NODES-1))

### Create
roachprod create ${CLUSTER} -n ${NODES} -c aws --local-ssd #--aws-machine-type-ssd=m5d.2xlarge
roachprod stage ${CLUSTER} workload
roachprod stage ${CLUSTER} release v19.2.6  #v20.1.0-beta.4
roachprod start ${CLUSTER}:1-${CNODES}

### HA Proxy
echo "installing haproxy..."
roachprod run ${CLUSTER}:${NODES} 'sudo apt-get -qq update'
roachprod run ${CLUSTER}:${NODES} 'sudo apt-get -qq install -y haproxy'
roachprod run ${CLUSTER}:${NODES} "./cockroach gen haproxy --insecure --host `roachprod ip $CLUSTER:1 --external`"
roachprod run ${CLUSTER}:${NODES} 'cat haproxy.cfg'
roachprod run ${CLUSTER}:${NODES} 'haproxy -f haproxy.cfg &' &

### Set dead nodes sooner
roachprod run ${CLUSTER}:1 <<EOF
./cockroach sql --insecure -e "set cluster setting server.time_until_store_dead='1m20s';"
EOF

### Check the admin UI.
roachprod admin ${CLUSTER}:1 --open

### Run a changefeed in CLI
#roachprod run $CLUSTER:1 <<EOF
#./cockroach sql --url="postgresql://root@127.0.0.1:26257?sslmode=disable" --format=csv
#SET CLUSTER SETTING kv.rangefeed.enabled = true;
#EXPERIMENTAL CHANGEFEED FOR bank.bank;
#EOF

### Run a changefeed to S3
#roachprod run $CLUSTER:1 <<EOF
#./cockroach sql --insecure -e "CREATE CHANGEFEED FOR TABLE bank.bank INTO 'experimental-s3://chrisc-test/changefeed/?AUTH=implicit' WITH updated, resolved='10s';"
#EOF
#aws s3 ls s3://chrisc-test/changefeed/

# Run Bank
#roachprod run ${CLUSTER}:1 -- ./workload init bank
#roachprod run ${CLUSTER}:6 -- ./workload run bank --duration 5m {pgurl:6}
#roachprod run ${CLUSTER}:4 -- ./workload run bank --duration 5m "postgresql://root@`roachprod ip ${CLUSTER}:1`:26257/bank?sslmode=disable"

#Run MOVR
#roachprod run ${CLUSTER}:1 -- ./workload init movr
#roachprod run ${CLUSTER}:6 -- ./workload run movr --db "postgresql://root@127.0.0.1:26257/movr?sslmode=disable"

echo "Run KV"
roachprod run ${CLUSTER}:1 -- "./workload init kv --drop --read-percent 25 --batch 1"
roachprod run ${CLUSTER}:${CNODES} -- "./workload run kv --duration 5m"

# Run YCSB
#roachprod run ${CLUSTER}:1 -- "./workload init ycsb --drop --insert-count 1000000 --data-loader IMPORT"
#roachprod run ${CLUSTER}:4 -- "./workload run ycsb --duration 5m --concurrency=64 --workload=A {pgurl:1-3}"
#roachprod run ${CLUSTER}:7 -- "./workload run ycsb --duration 10m --concurrency=64 --tolerate-errors postgresql://root@`roachprod ip ${CLUSTER}:7`:26257/ycsb?sslmode=disable"
#roachprod run ${CLUSTER}:6 -- "./workload run ycsb --duration 5m --concurrency=64 --tolerate-errors postgresql://root@`roachprod ip ${CLUSTER}:7`:26257/ycsb?sslmode=disable"

#echo "Run TPCC"
#roachprod run ${CLUSTER}:1 -- "./workload fixtures import tpcc --warehouses 1000 {pgurl:1}"
#roachprod run ${CLUSTER}:6 -- "./workload run tpcc --warehouses 1000 --ramp 1m --duration 10m {pgurl:1-5}"


## Kill 2 Nodes
### make sure replication factor is 5
#roachprod run $CLUSTER:1 <<EOF
# ./cockroach sql --execute="ALTER RANGE default CONFIGURE ZONE USING num_replicas=5;" --insecure --host=localhost:26257
#EOF
#

# Open a SQL connection to the first node.
roachprod sql ${CLUSTER}:${NODES}
