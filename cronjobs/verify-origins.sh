#!/bin/bash

set -eux

UAAC_CLI=/var/vcap/TBD

$UAAC_CLI target "$UAA_TARGET"

$UAAC_CLI token client get "$UAA_USER" -s "$UAA_USER_TOKEN"

GET_USERS_ORIGIN_UAA=$($UAAC_CLI users -a origin,username --count $UAA_USER_COUNT | grep -E 'uaa' -A2 | grep -oE '\s.+@.+' | cut -d ':' -f 2)


