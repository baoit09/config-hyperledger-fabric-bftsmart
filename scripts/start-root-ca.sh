#!/bin/bash
#
# Copyright Deevo Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
usage() { echo "Usage: $0 [-g <orgname>]" 1>&2; exit 1; }
while getopts ":g::" o; do
    case "${o}" in
        g)
            g=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))
if [ -z "${g}" ] ; then
    usage
fi

set -e
export FABRIC_CA_SERVER_HOME=$HOME/fabric-ca
export FABRIC_CA_SERVER_TLS_ENABLED=true
export FABRIC_CA_SERVER_CSR_CN=rca-${g}
export FABRIC_CA_SERVER_CSR_HOSTS=rca-${g}
export FABRIC_CA_SERVER_DEBUG=true
export BOOTSTRAP_USER_PASS=rca-${g}-admin:rca-${g}-adminpw
export TARGET_CERTFILE=$DATA/${g}-ca-cert.pem
# Initialize the root CA
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-server/fabric-ca-server init -b $BOOTSTRAP_USER_PASS

# Copy the root CA's signing certificate to the data directory to be used by others
mkdir -p ${DATA}
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem $TARGET_CERTFILE

# Add the custom orgs
for o in $FABRIC_ORGS; do
   aff=$aff"\n   $o: []"
done
aff="${aff#\\n   }"
sed -i "/affiliations:/a \\   $aff" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml
sed -i "s/OU: Fabric/OU: COP/g" \
   $FABRIC_CA_SERVER_HOME/fabric-ca-server-config.yaml

# Start the root CA
$GOPATH/src/github.com/hyperledger/fabric-ca/cmd/fabric-ca-server/fabric-ca-server start
