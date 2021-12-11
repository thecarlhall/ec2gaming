import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ec2 from "aws-cdk-lib/aws-ec2";
import { CfnInstanceProfile, PolicyDocument, PolicyStatement, Role, ServicePrincipal } from "aws-cdk-lib/aws-iam";
import { Stack, StackProps } from 'aws-cdk-lib';
import { Construct } from 'constructs';

export interface Ec2GamingProps extends StackProps {
    allowInboundCidr: string;
	sshKeyName: string;
	instanceType: ec2.InstanceType;
};

export class Ec2GamingStack extends Stack {
	constructor(scope: Construct, id: string, props: Ec2GamingProps) {
		super(scope, id, props);

		const vpc = ec2.Vpc.fromLookup(this, 'ec2gamingVpc', {
			isDefault: true,
		});

		const securityGroup = new ec2.SecurityGroup(this, 'ec2gamingSecurityGroup', {
			description: 'Allow remote access',
			securityGroupName: 'ec2gaming',
			vpc,
		});

		// RDP
		securityGroup.connections.allowFrom(ec2.Peer.ipv4(props.allowInboundCidr), ec2.Port.tcp(3389));

		const bucket = new s3.Bucket(this, 'ec2gamingBucket', {
			bucketName: `ec2gaming-${props?.env?.account}`
		});

		const ec2gamingRole = new Role(this, 'ec2gamingRole', {
			roleName: 'ec2gaming',
			assumedBy: new ServicePrincipal('ec2.amazonaws.com'),
			inlinePolicies: {
				'ec2gaming': new PolicyDocument({
					statements: [ new PolicyStatement({
						actions: [  's3:ListBucket' ],
						resources: [  bucket.bucketArn ],
					}),
					new PolicyStatement({
						actions: [ 's3:PutObject', 's3:GetObject', 's3:DeleteObject' ],
						resources: [ `${bucket.bucketArn}/*` ]
					}) ]
				}),
				[ `${id}.GraphicsDriverS3Access` ]: new PolicyDocument({
					statements: [ new PolicyStatement({
						actions: [ 's3:ListBucket' ],
						resources: [ 'arn:aws:s3:::nvidia-gaming' ],
					}),
					new PolicyStatement({
						actions: [ 's3:GetObject' ],
						resources: [ 'arn:aws:s3:::nvidia-gaming/*' ]
					}) ]
				})
			}
		});

		const instanceProfile = new CfnInstanceProfile(this, 'ec2gamingProfile', {
			instanceProfileName: 'ec2gaming',
			roles: [  ec2gamingRole.roleName ]
		});

		const launchTemplate = new ec2.LaunchTemplate(this, 'ec2gamingTemplate', {
            securityGroup,
            launchTemplateName: 'ec2gaming',
            instanceType: props.instanceType,
            keyName: props.sshKeyName,
			role: ec2gamingRole,
		});
	}
}
