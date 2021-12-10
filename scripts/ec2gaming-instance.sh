#!/usr/bin/env bash
source "$(dirname "$0")/ec2gaming.header"

# Verify that the gaming stane actually exists (and that there's only one)
INSTANCES=$(aws ec2 describe-instances --filters Name=instance-state-code,Values=[16,80] Name=instance-type,Values="$INSTANCE_TYPE")
if [ "$(echo "$INSTANCES" | jq '.Reservations | length')" -ne "1" ]; then
    >&2 echo "didn't find an instance or there wasn't exactly one $INSTANCE_TYPE instance"
    exit 1
fi
echo "$INSTANCES" | jq --raw-output '.Reservations[0].Instances[0].InstanceId'
