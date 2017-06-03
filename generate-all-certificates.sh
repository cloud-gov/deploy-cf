#!/bin/bash

set -e

go get -v github.com/square/certstrap
RED='\033[0;31m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

if [[ -n $1 && $1 =~ (-h|--help)$ ]]
then
  echo "
  ./generate-all-certificates [--help, -h] [--grab-cert, -g] [<ca-cert> <ca-private-key>]

  For generating all the Cloud Foundry certificates and private keys based on a
  'single' root CA certificate. All of these certstrap commands have been taken
  from various \`cf-release/scripts/generate-*\` files.
  "
  exit
fi

local_ca_cert_name='cloud-foundry'
depot_path="all-cf-certs"
mkdir -p "${depot_path}"

if [[ -n $1 && $1 =~ (-g|--grab-cert)$ ]]
then
  if [[ -z $CG_PIPELINE ]]
  then
    echo -e "${RED}ERROR${NC} Please set a ${YELLOW}\$CG_PIPELINE${NC} variable pointing to a clone of ${YELLOW}https://github.com/18F/cg-pipeline-tasks${NC}"
    echo -e "eg, ${PURPLE}CG_PIPELINE=~/dev/cg-pipeline-tasks ./generate-all-certificates.sh --grab-cert${NC}"
    exit 98
  fi

  if [[ -z "${ci_env}" ]]
  then
    echo -e "${RED}ERROR${NC} Please set a ${YELLOW}\$ci_env${NC} variable to continue from ${YELLOW}fly targets${NC}"
    echo -e "eg, ${PURPLE}ci_env=fr ./generate-all-certificates.sh --grab-cert${NC}"
    exit 99
  fi

  # Download deploy-bosh pipeline
  deploy_bosh_json=$(
  fly --target "${ci_env}" \
      get-pipeline \
      --pipeline deploy-bosh | \
  spruce json
  )

  echo -e "${GREEN}Downloading${NC} master-bosh-root-cert"
  eval "$(
  echo "${deploy_bosh_json}" | \
  jq -r '
    .resources[] |
    select( .name == "master-bosh-root-cert" ) |
    @sh "export AWS_DEFAULT_REGION=\(.source.region_name)
    export CA_CERT=\(.source.versioned_file)
    export CA_BUCKET=\(.source.bucket)"
  '
  )"
  aws s3 cp "s3://${CA_BUCKET}/${CA_CERT}" "${depot_path}/${CA_CERT}"

  echo -e "${GREEN}Downloading${NC} master-bosh-root-key"
  eval "$(
  echo "${deploy_bosh_json}" | \
  jq -r '
    .resources[] |
    select( .name == "common-masterbosh" ) |
    @sh "export AWS_DEFAULT_REGION=\(.source.region)
    export PASSPHRASE=\(.source.secrets_passphrase)
    export CA_KEY_ENCRYPTED=\(.source.bosh_cert)
    export CA_BUCKET=\(.source.bucket_name)"
  '
  )"
  aws s3 cp "s3://${CA_BUCKET}/${CA_KEY_ENCRYPTED}" "${depot_path}/${CA_KEY_ENCRYPTED}"

  echo -e "${GREEN}Decrypting${NC} master-bosh-root-key"
  export INPUT_FILE="${depot_path}/${CA_KEY_ENCRYPTED}"
  export OUTPUT_FILE=$(
    echo "${depot_path}/${CA_KEY_ENCRYPTED}" | \
    sed 's/\.pem/.key/'
  )
  eval "$(
  echo "${deploy_bosh_json}" | \
  jq -r '
    .jobs[] |
    select( .name == "deploy-master-bosh" ) |
    .plan[] |
    select( .task == "decrypt-private-key") |
    @sh "export PASSPHRASE=\(.params.PASSPHRASE)"
  '
  )"
  "${CG_PIPELINE}"/decrypt.sh
  local_ca_cert_name="${CA_KEY_ENCRYPTED//\.pem/}"
  echo -e "${GREEN}Signing${NC} certificates with certificate authority ${YELLOW}${local_ca_cert_name}${NC} and key"
elif [[ -n $1 && -n $2 ]]
then
  echo -e "${YELLOW}Copying ${1},${2} to ${depot_path}${NC}"
  cp -p {"$1","$2"} "${depot_path}"/.
  local_ca_cert_name=$(basename "$1" | sed 's/\.crt//')
  echo -e "${GREEN}Signing${NC} certificates with supplied certificate authority ${YELLOW}${local_ca_cert_name}${NC} and key"
else
  echo -e "${GREEN}Creating${NC} ${YELLOW}new${NC} certificate authority ${YELLOW}${local_ca_cert_name}${NC} and key"
  certstrap --depot-path "${depot_path}" init --passphrase '' --common-name "${local_ca_cert_name}"
fi

echo -e "${CYAN}Generating${NC} all Cloud Foundry key and certificate pairs"

echo -e "${GREEN}Creating${NC} JWT key pairs"
openssl genrsa -out ${depot_path}/jwt_privkey.pem 2048
openssl genrsa -out ${depot_path}/jwt_privkey.pem 2048
openssl rsa -pubout -in ${depot_path}/jwt_privkey.pem -out ${depot_path}/jwt_pubkey.pem

echo -e "${GREEN}Creating${NC} Cloud Controller key and certificate pairs"
cc_server_cn=cloud-controller-ng.service.cf.internal
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name $cc_server_cn
certstrap --depot-path "${depot_path}" sign $cc_server_cn --CA "${local_ca_cert_name}"
mv -f ${depot_path}/$cc_server_cn.key ${depot_path}/cloud-controller.key
mv -f ${depot_path}/$cc_server_cn.csr ${depot_path}/cloud-controller.csr
mv -f ${depot_path}/$cc_server_cn.crt ${depot_path}/cloud-controller.crt

echo -e "${GREEN}Creating${NC} Consul key and certificate pairs"
consul_server_cn=server.dc1.cf.internal
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name $consul_server_cn
certstrap --depot-path "${depot_path}" sign $consul_server_cn --CA "${local_ca_cert_name}"
mv -f ${depot_path}/$consul_server_cn.key ${depot_path}/consul_server.key
mv -f ${depot_path}/$consul_server_cn.csr ${depot_path}/consul_server.csr
mv -f ${depot_path}/$consul_server_cn.crt ${depot_path}/consul_server.crt
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name 'consul agent'
certstrap --depot-path "${depot_path}" sign consul_agent --CA "${local_ca_cert_name}"

echo -e "${GREEN}Creating${NC} UAA key and certificate pairs"
uaa_server_cn="uaa.service.cf.internal"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name "${uaa_server_cn}"
certstrap --depot-path "${depot_path}" sign "${uaa_server_cn}" --CA "${local_ca_cert_name}"
mv -f "${depot_path}/${uaa_server_cn}.key" "${depot_path}/uaa_server.key"
mv -f "${depot_path}/${uaa_server_cn}.csr" "${depot_path}/uaa_server.csr"
mv -f "${depot_path}/${uaa_server_cn}.crt" "${depot_path}/uaa_server.crt"

echo -e "${GREEN}Creating${NC} etcd server key and certificate pairs"
# Server certificate to share across the etcd cluster
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name etcd.service.consul --domain '*.etcd.service.consul,etcd.service.consul'
certstrap --depot-path "${depot_path}" sign etcd.service.consul --CA "${local_ca_cert_name}"
mv -f ${depot_path}/etcd.service.consul.key ${depot_path}/etcd_server.key
mv -f ${depot_path}/etcd.service.consul.csr ${depot_path}/etcd_server.csr
mv -f ${depot_path}/etcd.service.consul.crt ${depot_path}/etcd_server.crt

echo -e "${GREEN}Creating${NC} etcd client key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name 'clientName'
certstrap --depot-path "${depot_path}" sign clientName --CA "${local_ca_cert_name}"
mv -f ${depot_path}/clientName.key ${depot_path}/etcd_client.key
mv -f ${depot_path}/clientName.csr ${depot_path}/etcd_client.csr
mv -f ${depot_path}/clientName.crt ${depot_path}/etcd_client.crt

echo -e "${GREEN}Creating${NC} etcd peers key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name etcd.service.consul --domain '*.etcd.service.consul,etcd.service.consul'
certstrap --depot-path "${depot_path}" sign etcd.service.consul --CA "${local_ca_cert_name}"
mv -f ${depot_path}/etcd.service.consul.key ${depot_path}/etcd_peer.key
mv -f ${depot_path}/etcd.service.consul.csr ${depot_path}/etcd_peer.csr
mv -f ${depot_path}/etcd.service.consul.crt ${depot_path}/etcd_peer.crt

echo -e "${GREEN}Creating${NC} statsd key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name statsdinjector
certstrap --depot-path "${depot_path}" sign statsdinjector --CA "${local_ca_cert_name}"

echo -e "${GREEN}Creating${NC} Doppler key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name doppler
certstrap --depot-path "${depot_path}" sign doppler --CA "${local_ca_cert_name}"

echo -e "${GREEN}Creating${NC} Traffic Controller key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name trafficcontroller
certstrap --depot-path "${depot_path}" sign trafficcontroller --CA "${local_ca_cert_name}"

echo -e "${GREEN}Creating${NC} Metron key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name metron
certstrap --depot-path "${depot_path}" sign metron --CA "${local_ca_cert_name}"

echo -e "${GREEN}Creating${NC} Reverse Log Proxy key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name reverselogproxy
certstrap --depot-path "${depot_path}" sign reverselogproxy --CA "${local_ca_cert_name}"

echo -e "${GREEN}Creating${NC} Syslog drain binder key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name syslogdrainbinder
certstrap --depot-path "${depot_path}" sign syslogdrainbinder --CA "${local_ca_cert_name}"

echo -e "${CYAN}Generating${NC} all Diego key and certificate pairs"

echo -e "${GREEN}Generating${NC} BBS server key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name bbs.service.cf.internal --domain '*.bbs.service.cf.internal,bbs.service.cf.internal'
certstrap --depot-path "${depot_path}" sign bbs.service.cf.internal --CA "${local_ca_cert_name}"
mv -f ${depot_path}/bbs.service.cf.internal.key ${depot_path}/bbs_server.key
mv -f ${depot_path}/bbs.service.cf.internal.csr ${depot_path}/bbs_server.csr
mv -f ${depot_path}/bbs.service.cf.internal.crt ${depot_path}/bbs_server.crt

echo -e "${GREEN}Generating${NC} BBS client key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name 'bbs client'
certstrap --depot-path "${depot_path}" sign bbs_client --CA "${local_ca_cert_name}"

echo -e "${GREEN}Generating${NC} REP server key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name cell.service.cf.internal --domain '*.cell.service.cf.internal,cell.service.cf.internal'
certstrap --depot-path "${depot_path}" sign cell.service.cf.internal --CA "${local_ca_cert_name}"
mv -f ${depot_path}/cell.service.cf.internal.key ${depot_path}/rep_server.key
mv -f ${depot_path}/cell.service.cf.internal.csr ${depot_path}/rep_server.csr
mv -f ${depot_path}/cell.service.cf.internal.crt ${depot_path}/rep_server.crt

echo -e "${GREEN}Generating${NC} REP client key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name 'rep client'
certstrap --depot-path "${depot_path}" sign rep_client --CA "${local_ca_cert_name}"

echo -e "${GREEN}Generating${NC} Auctioneer server key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name auctioneer.service.cf.internal --domain 'auctioneer.service.cf.internal'
certstrap --depot-path "${depot_path}" sign auctioneer.service.cf.internal --CA "${local_ca_cert_name}"
mv -f ${depot_path}/auctioneer.service.cf.internal.key ${depot_path}/autioneer_server.key
mv -f ${depot_path}/auctioneer.service.cf.internal.csr ${depot_path}/autioneer_server.csr
mv -f ${depot_path}/auctioneer.service.cf.internal.crt ${depot_path}/autioneer_server.crt

echo -e "${GREEN}Generating${NC} Auctioneer client key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name 'auctioneer client'
certstrap --depot-path "${depot_path}" sign auctioneer_client --CA "${local_ca_cert_name}"

echo -e "${GREEN}Generating${NC} TPS client key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name tps_watcher
certstrap --depot-path "${depot_path}" sign tps_watcher --CA "${local_ca_cert_name}"
mv -f "${depot_path}/tps_watcher.key" "${depot_path}/tps_client.key"
mv -f "${depot_path}/tps_watcher.csr" "${depot_path}/tps_client.csr"
mv -f "${depot_path}/tps_watcher.crt" "${depot_path}/tps_client.crt"

echo -e "${GREEN}Generating${NC} CC Uploader server key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name cc-uploader.service.cf.internal
certstrap --depot-path "${depot_path}" sign cc-uploader.service.cf.internal --CA "${local_ca_cert_name}"
mv -f "${depot_path}/cc-uploader.service.cf.internal.key" "${depot_path}/cc_uploader_server.key"
mv -f "${depot_path}/cc-uploader.service.cf.internal.csr" "${depot_path}/cc_uploader_server.csr"
mv -f "${depot_path}/cc-uploader.service.cf.internal.crt" "${depot_path}/cc_uploader_server.crt"

echo -e "${GREEN}Generating${NC} CC Uploader client key and certificate pairs"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name cc_uploader
certstrap --depot-path "${depot_path}" sign cc_uploader --CA "${local_ca_cert_name}"
mv -f "${depot_path}/cc_uploader.key" "${depot_path}/cc_uploader_client.key"
mv -f "${depot_path}/cc_uploader.csr" "${depot_path}/cc_uploader_client.csr"
mv -f "${depot_path}/cc_uploader.crt" "${depot_path}/cc_uploader_client.crt"
