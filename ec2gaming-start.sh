#!/bin/bash

set -e

describe_gaming_image() {
  aws ec2 describe-images --owner "$1" --filters Name=name,Values=ec2gaming
}

num_images() {
  echo "$1" | jq '.Images | length'
}

describe_security_group() {
  aws ec2 describe-security-groups | jq -r '.SecurityGroups[] | select (.GroupName == "'"$1"'") | .GroupId'
}

# Get the current lowest price for the GPU machine we want (we'll be bidding a cent above)
echo -n "Getting lowest g2.2xlarge bid... "
PRICE="$(aws ec2 describe-spot-price-history --instance-types g2.2xlarge --product-descriptions "Windows" --start-time "$(date +%s)" | jq --raw-output '.SpotPriceHistory[].SpotPrice' | sort | head -1)"
echo "$PRICE"

echo -n "Looking for the ec2gaming AMI... "
AMI_SEARCH=$(describe_gaming_image self)
if [ "$(num_images "$AMI_SEARCH")" -eq "0" ]; then
	echo -n "not found. Going into bootstrap mode... "
  BOOTSTRAP=1
  AMI_SEARCH=$(describe_gaming_image 255191696678)
  if [ "$(num_images "$AMI_SEARCH")" -eq "0" ]; then
    echo "not found. Exiting."
    exit 1
  fi
fi
AMI_ID="$(echo "$AMI_SEARCH" | jq --raw-output '.Images[0].ImageId')"
echo "$AMI_ID"

echo -n "Looking for security groups... "
EC2_SECURITY_GROUP_ID=$(describe_security_group ec2gaming)
if [ -z "$EC2_SECURITY_GROUP_ID" ]; then
  echo -n "not found. Creating security groups... "
  aws ec2 create-security-group --group-name ec2gaming-rdp --description "EC2 Gaming RDP" > /dev/null
  aws ec2 authorize-security-group-ingress --group-name ec2gaming-rdp --protocol tcp --port 3389 --cidr "0.0.0.0/0"
  aws ec2 authorize-security-group-ingress --group-name ec2gaming-rdp --protocol tcp --port 1194 --cidr "0.0.0.0/0"
  aws ec2 authorize-security-group-ingress --group-name ec2gaming-rdp --protocol udp --port 1194 --cidr "0.0.0.0/0"

  aws ec2 create-security-group --group-name ec2gaming --description "EC2 Gaming" > /dev/null
  aws ec2 authorize-security-group-ingress --group-name ec2gaming --protocol tcp --port 1194 --cidr "0.0.0.0/0"
  aws ec2 authorize-security-group-ingress --group-name ec2gaming --protocol udp --port 1194 --cidr "0.0.0.0/0"
fi

if [ "$BOOTSTRAP" -eq "1" ]; then
  EC2_SECURITY_GROUP_ID=$(describe_security_group ec2gaming-rdp)
fi

echo "$EC2_SECURITY_GROUP_ID"

echo -n "Creating spot instance request... "
SPOT_INSTANCE_ID=$(aws ec2 request-spot-instances --spot-price "$(bc <<< "$PRICE + 0.01")" --launch-specification "
  {
    \"SecurityGroupIds\": [\"$EC2_SECURITY_GROUP_ID\"],
    \"ImageId\": \"$AMI_ID\",
    \"InstanceType\": \"g2.2xlarge\"
  }" | jq --raw-output '.SpotInstanceRequests[0].SpotInstanceRequestId')
echo "$SPOT_INSTANCE_ID"

echo -n "Waiting for instance to be launched... "
aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids "$SPOT_INSTANCE_ID"

INSTANCE_ID=$(aws ec2 describe-spot-instance-requests --spot-instance-request-ids "$SPOT_INSTANCE_ID" | jq --raw-output '.SpotInstanceRequests[0].InstanceId')
echo "$INSTANCE_ID"

echo "Removing the spot instance request..."
aws ec2 cancel-spot-instance-requests --spot-instance-request-ids "$SPOT_INSTANCE_ID" > /dev/null

echo -n "Getting ip address... "
IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" | jq --raw-output '.Reservations[0].Instances[0].PublicIpAddress')
echo "$IP"

echo "Waiting for server to become available..."
while ! nc -z "$IP" 1194; do sleep 5; done;

if [ "$BOOTSTRAP" -eq "1" ]; then
  echo -n "Generating RDP configuration... "
  sed "s/IP/$IP/g" ec2gaming.rdp.template > ec2gaming.rdp
  echo "remote host is $IP"

  echo "Starting Remote Desktop..."
  open ec2gaming.rdp
else
  VPN_IP="10.8.0.1"
  echo -n "Generating RDP configuration... "
  sed "s/IP/$VPN_IP/g" ec2gaming.rdp.template > ec2gaming.rdp
  echo "remote host is $VPN_IP"

  echo -n "Connecting VPN... "
  BACKING_CONFIG=~/Library/Application\ Support/Tunnelblick/Configurations/ec2gaming.tblk/Contents/Resources/config.ovpn
  if [ ! -f "$BACKING_CONFIG" ]; then
      sed "s/IP/$IP/g" ec2gaming.ovpn.template > ec2gaming.ovpn
      open ec2gaming.ovpn
      echo "Waiting 10 seconds for import..."
      sleep 10
  else
    # the authentication prompt on copy will block, avoids the messy sleep
    sed "s/IP/$IP/g" ec2gaming.ovpn.template > "$BACKING_CONFIG"
  fi
  osascript ec2gaming-vpnup.scpt

  echo "Starting Steam..."
  open steam://
fi
