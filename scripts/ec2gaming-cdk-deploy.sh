#!/bin/bash
source "$(dirname "$0")/ec2gaming.header"

cd ../cdk

export ALLOW_CIDR="$(curl --silent http://checkip.amazonaws.com)/32"

npm run build
cdk synth -q
cdk deploy --require-approval never