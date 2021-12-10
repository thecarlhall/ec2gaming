#!/usr/bin/env bash
source "$(dirname "$0")/ec2gaming.header"

cd ../cdk

npm install
cdk bootstrap