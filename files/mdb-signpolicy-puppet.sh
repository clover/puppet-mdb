#!/bin/bash
# This script gets an argument, which is the cert name, and stdin, which is
# the actual CSR. For basic node cert verification, for the moment, we're
# going to just verify that the name actually exists in mdb -- no mdb, no
# sign.

export PATH=/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/puppetlabs/bin

function log() {
    echo $(date "+%Y-%m-%d %H:%M:%S") "$@" >> /var/log/puppetlabs/puppetserver/mdb-puppet.log
    echo "$@"
}

# consume stdin, else java/puppetserver complains
cat >/dev/null

if [ -z "$1" ]; then
    log "ERROR" "Certificate signing request did not include certificate name"
    exit 1
fi

fqdn="${1}"

mdb endpoint dump "${fqdn}" >/dev/null 2>&1
rc=$?

if [ $rc -gt 0 ]; then
    log "WARN" "Rejected signing request for certificate '${fqdn}' (mdb return code ${rc})"

    # remove the CSR so that when we try again (if we screwed up and forgot
    # the host in mdb or such) that retry will actually work, rather than
    # blocking on a CSR already existing. The puppetca already filters out
    # relative paths, so we don't have worry about checking that here.
    rm -f "/var/lib/puppetca/ca/requests/${fqdn}.pem"
    exit 1
fi

# else
log "INFO" "Accepted signing request for certificate '${fqdn}'"
exit 0

