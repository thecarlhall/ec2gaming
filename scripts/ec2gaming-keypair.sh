#!/bin/bash
source "$(dirname "$0")/ec2gaming.header"

KEY_NAME=${KEY_NAME:-ec2gaming}
PEM_FILE="$KEY_NAME.pem"
echo -n "Looking for pem... "
if [[ ! -f "$PEM_FILE" ]]; then
	echo -n "not found. Creating... "
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query KeyMaterial --output text > "../$PEM_FILE"
fi
echo $PEM_FILE