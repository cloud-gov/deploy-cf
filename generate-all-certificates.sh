#!/bin/bash

set -ex

# Install certstrap
go get -v github.com/square/certstrap

depot_path="all-cf-certs"
mkdir -p "${depot_path}"

# Don't do this if a CA cert is passed in.
# certstrap --depot-path ${depot_path} init --passphrase '' --common-name master-bosh
# root master-bosh.crt and master-bosh.key

# Cloud Controller
cc_server_cn=cloud-controller-ng.service.cf.internal
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name $cc_server_cn
certstrap --depot-path ${depot_path} sign $cc_server_cn --CA master-bosh
mv -f ${depot_path}/$cc_server_cn.key ${depot_path}/cloud-controller.key
mv -f ${depot_path}/$cc_server_cn.csr ${depot_path}/cloud-controller.csr
mv -f ${depot_path}/$cc_server_cn.crt ${depot_path}/cloud-controller.crt

# Consul
consul_server_cn=server.dc1.cf.internal
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name $consul_server_cn
certstrap --depot-path ${depot_path} sign $consul_server_cn --CA master-bosh
mv -f ${depot_path}/$consul_server_cn.key ${depot_path}/consul_server.key
mv -f ${depot_path}/$consul_server_cn.csr ${depot_path}/consul_server.csr
mv -f ${depot_path}/$consul_server_cn.crt ${depot_path}/consul_server.crt
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name 'consul agent'
certstrap --depot-path ${depot_path} sign consul_agent --CA master-bosh

# HM9000
hm9000_server_cn=listener-hm9000.service.cf.internal
hm9000_server_domain='*.listener-hm9000.service.cf.internal'
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name $hm9000_server_cn --domain "${hm9000_server_domain},${hm9000_server_cn}"
certstrap --depot-path ${depot_path} sign $hm9000_server_cn --CA master-bosh
mv -f ${depot_path}/$hm9000_server_cn.key ${depot_path}/hm9000_server.key
mv -f ${depot_path}/$hm9000_server_cn.csr ${depot_path}/hm9000_server.csr
mv -f ${depot_path}/$hm9000_server_cn.crt ${depot_path}/hm9000_server.crt
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name 'hm9000_client'
certstrap --depot-path ${depot_path} sign hm9000_client --CA master-bosh

# UAA
uaa_server_cn="uaa.service.cf.internal"
certstrap --depot-path "${depot_path}" request-cert --passphrase '' --common-name "${uaa_server_cn}"
certstrap --depot-path "${depot_path}" sign "${uaa_server_cn}" --CA master-bosh
mv -f "${depot_path}/${uaa_server_cn}.key" "${depot_path}/uaa_server.key"
mv -f "${depot_path}/${uaa_server_cn}.csr" "${depot_path}/uaa_server.csr"
mv -f "${depot_path}/${uaa_server_cn}.crt" "${depot_path}/uaa_server.crt"

# etcd
# Server certificate to share across the etcd cluster
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name etcd.service.consul --domain '*.etcd.service.consul,etcd.service.consul'
certstrap --depot-path ${depot_path} sign etcd.service.consul --CA master-bosh
mv -f ${depot_path}/etcd.service.consul.key ${depot_path}/etcd_server.key
mv -f ${depot_path}/etcd.service.consul.csr ${depot_path}/etcd_server.csr
mv -f ${depot_path}/etcd.service.consul.crt ${depot_path}/etcd_server.crt

# Client certificate to distribute to jobs that access etcd
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name 'clientName'
certstrap --depot-path ${depot_path} sign clientName --CA master-bosh
mv -f ${depot_path}/clientName.key ${depot_path}/etcd_client.key
mv -f ${depot_path}/clientName.csr ${depot_path}/etcd_client.csr
mv -f ${depot_path}/clientName.crt ${depot_path}/etcd_client.crt

# Client certificate to distribute across etcd peers
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name etcd.service.consul --domain '*.etcd.service.consul,etcd.service.consul'
certstrap --depot-path ${depot_path} sign etcd.service.consul --CA master-bosh
mv -f ${depot_path}/etcd.service.consul.key ${depot_path}/etcd_peer.key
mv -f ${depot_path}/etcd.service.consul.csr ${depot_path}/etcd_peer.csr
mv -f ${depot_path}/etcd.service.consul.crt ${depot_path}/etcd_peer.crt

# Doppler certificate
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name doppler
certstrap --depot-path ${depot_path} sign doppler --CA master-bosh

# Traffic Controller certificate
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name trafficcontroller
certstrap --depot-path ${depot_path} sign trafficcontroller --CA master-bosh

# Metron certificate
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name metron
certstrap --depot-path ${depot_path} sign metron --CA master-bosh

# Reverse Log Proxy certificate
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name reverselogproxy
certstrap --depot-path ${depot_path} sign reverselogproxy --CA master-bosh

# Syslog drain binder certificate
certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name syslogdrainbinder
certstrap --depot-path ${depot_path} sign syslogdrainbinder --CA master-bosh
