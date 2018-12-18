#!/bin/bash
for CA_CERT in `credhub curl -X GET --path "/api/v1/certificates" | jq '.certificates[] | select(.name | endswith( "_ca"))' | .name`; do
    #check cert expiry_date, if expire in 30 days, rotate
    echo $CA_CERT
done
export id=$(curl -k -H "Content-Type: application/json" -H "Authorization: $(credhub --token)" $(echo $CREDHUB_SERVER)v1/certificates?name=$NAME
| jq)