#!/usr/bin/env node
import 'source-map-support/register';
import { App } from 'aws-cdk-lib';
import { InstanceType } from 'aws-cdk-lib/aws-ec2';
import { Ec2GamingStack } from '../lib/ec2gaming-stack';

const ACCOUNT_ID = process.env.ACCOUNT_ID || process.env.CDK_DEFAULT_ACCOUNT;
const REGION = process.env.REGION || process.env.CDK_DEFAULT_REGION;
const KEY_NAME = process.env.KEY_NAME || "";
const INSTANCE_TYPE = process.env.INSTANCE_TYPE || "g4dn.xlarge";
const ALLOW_INBOUND_CIDR = process.env.ALLOW_CIDR || "0.0.0.0/0";

const app = new App();

new Ec2GamingStack(app, "ec2gaming", {
    allowInboundCidr: ALLOW_INBOUND_CIDR,
	sshKeyName: KEY_NAME,
	instanceType: new InstanceType(INSTANCE_TYPE),
	env: {
		account: ACCOUNT_ID,
		region: REGION
	},
});