#!/usr/bin/env bash
source "$(dirname "$0")/ec2gaming.header"

describe_gaming_image self | jq --raw-output '.Images[0].ImageId'
