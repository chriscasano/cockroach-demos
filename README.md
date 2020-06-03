# Simple Cockroach Demos

Alot of the demos here that utilize roachprod, which should be switched out to something more customer friendly.

## local.sh

This is the main script for running CockroachDB demonstrations on your local machine.  It takes 3 parameters or none.
- CockroachDB Version  (i.e. 20.1.0)
- Number of Nodes (i.e. 5)
- Run cli (if parameter equals 'N', the cockroach cli will not start at the end of the script)

All CockroachDB you would like to utilize should be placed in the crdb_bin/ directory.  The binaries placed in this directory should contain the following format:  /crdb_bin/cockroach-v${VERSION}/cockroach.  An example would be /crdb_bin/cockroach-v19.2.5/cockroach.  The local.sh script will create symlink from /usr/local/bin/cockroach to the binaries in the /crdb_bin directory.

The script will spin up haproxy, the # of nodes you specify for a particular CockroachDB version, preload data from the data/ directory to the local Cockroach extern directory and lastly add your enterprise license to the cluster.

## data/

Contains sample data that can be used to import into a database

## haproxy/

Haproxy configuration resides here.  It can be adjusted as need.  

## scripts/

#### Local Demos

1) *Change Data Capture* (`local_cdc.sh`) - This shows how CDC can output data into a S3 cloud sink

2) *Backup & Restore* (`local_backup.md`) - This shows how to backup data to S3 and do a restore

3) *Resilience & Failover* (`local_resilience.sh`) - This show how you can increase resilency by increasing the cluster's replication factor

4) *Rolling Upgrade* (`local_upgrade.sh`) - This shows how to do a live rolling upgrade to a cluster

5) *Run a workload* (`local_run_workload.sh`) - This runs a simple workload on your local machine

#### Cloud Demos

1) Standard AWS Workload (aws_workload.sh)
