terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 3.72"
        }
    }
  
    required_version = ">= 1.1"
}

variable "key_name" {
    type = string
}

variable "profile" {
    type = string
    default = "default"
}

variable "region" {
    type = string
    default = "us-east-1"
}

variable "instance_type" {
    type = string
    default = "g4dn.xlarge"
}

variable "allow_inbound_cidr" {
    type = string
    default = "0.0.0.0/0"
}

provider "aws" {
    profile = var.profile
    region = var.region

    default_tags {
      tags = {
          project = "ec2gaming"
      }
    }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_default_vpc" "default" { }

resource "aws_s3_bucket" "ec2gaming" {
    bucket = "ec2gaming-${local.account_id}"
}

resource "aws_security_group" "ec2gaming" {
    name = "ec2gaming"
    description = "Allow remote access"
    vpc_id = aws_default_vpc.default.id

    ingress {
        description = "RDP"
        from_port = 3389
        to_port = 3389
        protocol = "tcp"
        cidr_blocks = [ aws_default_vpc.default.cidr_block ]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
}

resource "aws_iam_role" "ec2gaming" {
    name = "ec2gaming"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [ {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }, ]
    })

    inline_policy {
        name = "ec2gaming"
        policy = jsonencode({
            Version = "2012-10-17"
            Statement = [ {
                Action = [ "s3:ListBucket" ]
                Effect = "Allow"
                Resource = [ aws_s3_bucket.ec2gaming.arn ]
            }, {
                Action = [ "s3:PutObject", "s3:GetObject", "s3:DeleteObject" ]
                Effect = "Allow"
                Resource = [ "${aws_s3_bucket.ec2gaming.arn}/*" ]
            } ]
        })
    }

    inline_policy {
        name = "GraphicsDriverS3Access"
        policy = jsonencode({
            Version = "2012-10-17"
            Statement = [ {
                Action = [  "s3:ListBucket" ]
                Effect = "Allow"
                Resource = [ "arn:aws:s3:::nvidia-gaming" ]
            }, {
                Action = [ "s3:GetObject" ],
                Effect = "Allow"
                Resource = [ "arn:aws:s3:::nvidia-gaming/*" ]
            }]
        })
    }
}

resource "aws_iam_instance_profile" "ec2gaming" {
    name = "ec2gaming"
    role = aws_iam_role.ec2gaming.id
}

resource "aws_launch_template" "ec2gaming" {
    name = "ec2gaming"
    security_group_names = [ aws_security_group.ec2gaming.name ]
    instance_type = var.instance_type
    key_name = var.key_name

    update_default_version = true

    iam_instance_profile {
        name = aws_iam_instance_profile.ec2gaming.name
    }

    dynamic "tag_specifications" {
        for_each = toset([ "instance", "volume" ])
        content {
            resource_type = tag_specifications.key
            tags = {
                project = "ec2gaming"
            }
        }
    }
}

resource "aws_iam_group" "ec2gaming" {
    name = "ec2gaming"
}

resource "aws_iam_group_policy" "ec2gaming" {
    name = "ec2gaming"
    group = aws_iam_group.ec2gaming.name

    // copied from IAM
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [ {
            Sid = "VisualEditor0"
            Effect = "Allow"
            Action = [
                "iam:CreateInstanceProfile",
                "s3:GetObject",
                "iam:PassRole",
                "iam:GetInstanceProfile",
                "iam:PutRolePolicy",
                "iam:GetUser",
                "iam:AddRoleToInstanceProfile",
            ]
            "Resource": [
                "arn:aws:iam::${local.account_id}:role/ec2gaming",
                "arn:aws:iam::${local.account_id}:instance-profile/ec2gaming",
                "arn:aws:iam::${local.account_id}:user/*",
                "arn:aws:s3:::*/*",
            ]
        }, {
            Sid = "VisualEditor1"
            Effect = "Allow"
            Action = [
                "s3:CreateBucket",
                "s3:ListBucket"
            ]
            Resource = "arn:aws:s3:::*"
        }, {
            Sid = "VisualEditor2"
            Effect = "Allow"
            Action = [
                "ec2:RebootInstances",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeregisterImage",
                "ec2:DeleteSnapshot",
                "ec2:DescribeInstances",
                "ec2:TerminateInstances",
                "ec2:RequestSpotInstances",
                "ec2:CreateKeyPair",
                "ec2:CreateTags",
                "ec2:CreateImage",
                "ec2:RunInstances",
                "ec2:DescribeSpotInstanceRequests",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSpotPriceHistory",
                "ec2:DescribeImages",
                "ec2:CancelSpotInstanceRequests",
                "ec2:CreateSecurityGroup",
                "sts:DecodeAuthorizationMessage"
            ]
            Resource = "*"
        } ]
    })
}
