#!/bin/bash
# Runs a worklaod

../local.sh

sleep 5

cockroach workload init ycsb
cockroach workload run ycsb --duration=5m --concurrency=2 --display-every=60s --tolerate-errors "postgresql://root@localhost:26000/ycsb?sslmode=disable" &

read -p "Press [Return] To End The Demo" nothing

roachprod destroy local
pkill -9 cockroach
pkill -9 haproxy
