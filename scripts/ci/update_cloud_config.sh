#!/usr/bin/env bash

set -e -x -u

bbl --state-dir director-state/bbl-state print-env > set-env.sh
source set-env.sh
sleep 2

bosh cloud-config > temp.yml
bosh interpolate temp.yml -o persi-ci/operations/add-vip-network-to-bosh.yml > temp2.yml
bosh -n update-cloud-config temp2.yml
