#!/bin/bash

set -eu

spruce merge ${MANIFEST} ${TEMPLATE} | spruce merge --cherry-pick cloudfoundry_outputs > cloudfoundry-state/state.yml
