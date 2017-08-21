#!/usr/bin/env bash

bbl --state-dir director-state print-env > bosh-env/set-env.sh
source bosh-env/set-env.sh
bosh cloud-config > temp.yml
bosh interpolate temp.yml -o persi-ci/operations/add-vip-network-to-bosh.yml > temp2.yml
bosh update-cloud-config temp2.yml