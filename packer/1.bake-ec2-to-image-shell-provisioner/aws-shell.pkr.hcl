packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "aws" {
  ami_name      = "jiangren-packer-demo-1-${local.timestamp}" //ami + timestamp https://learn.hashicorp.com/tutorials/packer/aws-get-started-build-image?in=packer/aws-get-started
  instance_type = "t2.micro"
  region        = "ap-southeast-2"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  tags = {
    Base_AMI_Name  = "jiangren-packer-demo-1" //Here make a tage 
  }
}

build {
  name = "jiangren-packer-demo-1"
  sources = [
    "source.amazon-ebs.aws"
  ]
  provisioner "shell" { //EC2 command 
    script = "bake.sh"
  }

}
