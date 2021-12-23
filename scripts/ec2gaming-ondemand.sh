#!/bin/bash
source "$(dirname "$0")/ec2gaming.header"

BOOTSTRAP=0

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
  echo -n "not found. Exiting."
  exit 1
fi
echo "$EC2_SECURITY_GROUP_ID"

echo -n "Looking for S3 bucket... "
ACCOUNT_ID=$(aws iam get-user | jq '.User.Arn' | cut -d ':' -f 5)
BUCKET="ec2gaming-$ACCOUNT_ID"
if ! aws s3api head-bucket --bucket "$BUCKET" &> /dev/null; then
  echo -n "not found. Exiting."
  exit 1
fi
sed "s/BUCKET/$BUCKET/g;s/USERNAME/$USERNAME/g;s/PASSWORD/$PASSWORD/g" ec2gaming.bat.template > ../ec2gaming.bat
echo "$BUCKET"

echo -n "Creating instance... "
INSTANCE_ID=$(aws ec2 run-instances --launch-template LaunchTemplateName=ec2gaming,Version=\$Latest --key-name $KEY_NAME --image-id $AMI_ID | jq --raw-output '.Instances[0].InstanceId')
echo "$INSTANCE_ID"

echo -n "Waiting for instance IP... "
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
IP=$(./ec2gaming-ip.sh)
echo "$IP"

echo -n "Waiting for server to become available... "
while ! nc -z "$IP" 3389 &> /dev/null; do sleep 5; done;
echo "up!"

if [ "$BOOTSTRAP" -eq "1" ]; then
  ./ec2gaming-rdp.sh
else
  ./ec2gaming-vpnup.sh

  echo "Starting Steam..."
  open steam://
fi
