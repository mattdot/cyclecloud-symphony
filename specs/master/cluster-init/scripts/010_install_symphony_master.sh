#!/bin/bash
# see: https://www.ibm.com/support/knowledgecenter/SSZUMP_7.2.0/install/install_linux_management.html
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

set -x

. /etc/profile.d/symphony.sh

SYM_ENTITLEMENT_FILE="${CYCLECLOUD_SPEC_PATH}/files/sym_adv_ev_entitlement.dat"

set -e

sed -i '/EGO_GET_CONF/d' ${EGO_CONFDIR}/ego.conf


su - -c 'source /etc/profile.d/symphony.sh && yes | egoconfig join $( hostname )' egoadmin
su - -c "source /etc/profile.d/symphony.sh && yes | egoconfig setentitlement ${SYM_ENTITLEMENT_FILE}" egoadmin

# Enable automatic startup after reboot (TODO: might want to move restart to chef so volumes are mounted)
egosetrc.sh

# Grant sudoer access to egosudoers in file /etc/ego.sudoers (by default: egoadmin and root)
egosetsudoers.sh -f
su - -c 'source /etc/profile.d/symphony.sh && yes | egosh ego start' egoadmin

# Give the services 10 tries to start
counter=0
until su - -c 'source /etc/profile.d/symphony.sh && egosh user logon -u Admin -x Admin' egoadmin; do
    if [[ "$counter" -gt 10 ]]; then
	echo "Failed to connect to cluster after $counter retries.  Aborting..."
	exit -1
    else
	counter=$((counter+1))
	sleep 5
	echo "Retry $counter..."
    fi
done

# Verify setup
su - -c 'source /etc/profile.d/symphony.sh && egosh ego info' egoadmin
su - -c 'source /etc/profile.d/symphony.sh && egosh client view' egoadmin

