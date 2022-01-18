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

provider "aws" {
    profile = var.profile
    region = var.region

    default_tags {
      tags = {
          project = "ec2gaming"
      }
    }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = [ "amazon" ]
  filter {
    name   = "name"
    values = [ "Windows_Server-2019-English-Full-Base*" ]
  }
}

locals {
    account_id = data.aws_caller_identity.current.account_id
    region = data.aws_region.current.name
    grid_sw_cert_url = "https://nvidia-gaming.s3.amazonaws.com/GridSwCert-Archive/GridSwCertWindows_2021_10_2.cert"
    steam_url = "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe"
    parsec_url = "https://builds.parsecgaming.com/package/parsec-windows.exe"
    nvfbc_url = "https://lg.io/assets/NvFBCEnable.zip"
    vb_audio_url = "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip"
    aws_cli_url = "https://awscli.amazonaws.com/AWSCLIV2.msi"
    installation_files = <<-ID
        C:\Users\Administrator\Desktop\InstallationFiles
    ID
    startup_folder = <<-SUF
        C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
    SUF
    local_temp = <<-LT
        C:\Users\Administrator\Desktop\temp
    LT
}

resource "aws_default_vpc" "default" {}

data aws_subnet_ids current {
  vpc_id = aws_default_vpc.default.id
}

resource "aws_security_group" "remote" {
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

resource "aws_iam_role" "s3read" {
    name = "GraphicsDriverS3Access"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [ {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        } ]
    })
    managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    ]
}

resource "aws_iam_instance_profile" "GamingInstanceProfile" {
    name = "GamingInstanceProfile"
    role = aws_iam_role.s3read.name
}

resource "aws_instance" "GamingInstance" {
    instance_type = "g4dn.xlarge"
    vpc_security_group_ids = [ aws_security_group.remote.id ]
    # vpc
    # vpcSubnets
    #subnet_id = aws_default_vpc.default
    key_name = var.key_name
    ami = data.aws_ami.windows-2019.id
    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = 35
        volume_type = "gp3"
    }
    iam_instance_profile = aws_iam_instance_profile.GamingInstanceProfile.id
    user_data = base64encode(<<UD
$Bucket = "nvidia-gaming"

msiexec.exe /i ${local.aws_cli_url}

$Objects = Get-S3Object -BucketName $Bucket -KeyPrefix "windows/latest" -Region us-east-1
foreach ($Object in $Objects) {
    $LocalFileName = $Object.Key
    if ($LocalFileName -ne '' -and $Object.Size -ne 0) {
        $LocalFilePath = Join-Path ${local.local_temp} $LocalFileName
        Copy-S3Object -BucketName $Bucket -Key $Object.Key -LocalFile $LocalFilePath -Region us-east-1
    }
}
Expand-Archive $LocalFilePath -DestinationPath ${local.installation_files}\1_NVIDIA_drivers
Invoke-WebRequest -Uri "${local.vb_audio_url}" -OutFile ${local.local_temp}\VbAudio.zip
Expand-Archive "${local.local_temp}\VbAudio.zip" -DestinationPath ${local.installation_files}\2_VbAudio
Invoke-WebRequest -Uri "${local.nvfbc_url}" -OutFile ${local.local_temp}\NvFBCEnable.zip
Expand-Archive "${local.local_temp}\NvFBCEnable.zip" -DestinationPath ${local.installation_files}\3_NvFBCEnable
Invoke-WebRequest -Uri "${local.parsec_url}" -OutFile ${local.installation_files}\4_parsec-windows.exe
'reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global" /v vGamingMarketplace /t REG_DWORD /d 2' >> ${local.installation_files}\5_update_registry.ps1
Invoke-WebRequest -Uri "${local.grid_sw_cert_url}" -OutFile "$Env:PUBLIC\Documents\GridSwCert.txt"
Invoke-WebRequest -Uri "${local.steam_url}" -OutFile ${local.installation_files}\6_SteamSetup.exe
Remove-Item ${local.local_temp} -Recurse
'' >> ${local.installation_files}\OK
UD
)

    provisioner "file" {
        source = "scripts"
        destination = "${local.installation_files}"
    }

    provisioner "file" {
        content = "reg add \"HKLM\\SOFTWARE\\NVIDIA Corporation\\Global\" /v vGamingMarketplace /t REG_DWORD /d 2"
        destination = "${local.installation_files}\\5_update_registry.ps1"
    }

    provisioner "file" {
        content = <<-PS
            PowerShell -Command "Set-ExecutionPolicy Unrestricted" >> ${local.installation_files}\StartupLog.txt" 2>&1
            PowerShell -windowstyle hidden ${local.installation_files}\init-local-storage.ps1 >> ${local.installation_files}\StartupLog.txt" 2>&1
        PS
        destination = "${local.startup_folder}\\InitLocalStorage.cmd"
    }
}

output "Credentials" {
    value = "https://${local.region}.console.aws.amazon.com/ec2/v2/home?region=${local.region}#ConnectToInstance:instanceId=${aws_instance.GamingInstance.id}"
}

output "InstanceId" {
    value = aws_instance.GamingInstance.id
}