# Simple Backup Demo

This demonstration uses `cockroach demo` to show how you can backup data to S3.  Please be sure you have CockroachDB installed as well as the aws cli.

## Hi-Level Demo Steps
- Spin up a MOVR sample app using cockroach demo
- Remove prior backups
- Run a database backup
- Show the backup
- Run an incremental backup
- Rename the movr database
- Restore the database

## Demo Commands

Once you have a sql command prompt, you can run each of these lines one at a time.

`cockroach demo --geo-partitioned-replicas --with-load`

`\! aws s3 rm 's3://chrisc-test/backup/demo/' --recursive`

`backup database movr to 's3://chrisc-test/backup/demo?AUTH=implicit' as of system time '-10s' with revision_history;`

`show backup 's3://chrisc-test/backup/demo?AUTH=implicit';`

`backup database movr to 's3://chrisc-test/backup/demo?AUTH=implicit' as of system time '-10s' with revision_history;`

`show backup 's3://chrisc-test/backup/demo?AUTH=implicit';`

`use defaultdb;`

`alter database movr rename to movr_old;`

`restore database movr from 's3://chrisc-test/backup/demo?AUTH=implicit' as of system time '2020-09-29 02:54:00.26744+00:00'`
