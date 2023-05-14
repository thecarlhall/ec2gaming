#!/usr/bin/env bash
source "$(dirname "$0")/ec2gaming.header"

if [[ ! -z "$INSTANCE_ID" ]]; then
    echo "$INSTANCE_ID"
    exit 0
fi

# Verify that the gaming stane actually exists (and that there's only one)
INSTANCES=$(aws ec2 describe-instances --filters Name=instance-state-code,Values=[16,80] Name=instance-type,Values="$INSTANCE_TYPE")
INSTANCE_COUNT=$(echo "$INSTANCES" | jq '.Reservations | length')
if [ $INSTANCE_COUNT -eq "0" ]; then
    >&2 echo "didn't find an instance of $INSTANCE_TYPE"
    exit 1
fi

declare -i INSTANCE_PICK
INSTANCE_PICK=0

if [ $INSTANCE_COUNT -gt "1" ]; then
    >&2 echo "::Multiple Instances Found::"
    # >&2 echo "$INSTANCES" | jq --raw-output '.Reservations[].Instances[0].InstanceId'
    echo "$INSTANCES" \
        | jq -r '.Reservations[].Instances[0] | "\(.LaunchTime) -- \(.InstanceId)"' \
        | awk '{ print NR, $0 }' >&2
    read -p "Choose an instance [1-$INSTANCE_COUNT]: " INSTANCE_PICK
    INSTANCE_PICK=$((INSTANCE_PICK-1))
fi

echo "$INSTANCES" | jq --raw-output ".Reservations[$INSTANCE_PICK].Instances[0].InstanceId"