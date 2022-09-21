terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "ap-southeast-2"
}

resource "aws_security_group_rule" "allow_80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "sg-0212b4a25537026c9"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_8080" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = "sg-0212b4a25537026c9"
  cidr_blocks       = ["0.0.0.0/0"]
}
resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = "sg-0212b4a25537026c9"
  cidr_blocks       = ["0.0.0.0/0"]
}





resource "aws_key_pair" "deployer" {
  key_name   = "ansible-deployer-key"
  public_key = file("/var/lib/jenkins/.ssh/id_rsa.pub")
}

data "aws_ami" "image_packer-shell" {
  most_recent = true
  owners = ["self"]
  filter {
    name = "tag:Base_AMI_Name"
    values = ["jiangren-packer-demo-1"]
  }
}

data "aws_ami" "image_packer-ansible" {
  most_recent = true
  owners = ["self"]
  filter {
    name = "tag:Base_AMI_Name"
    values = ["jiangren-packer-demo-2"]
  }
}

resource "aws_instance" "packer-shell" {
  ami           = "${data.aws_ami.image_packer-shell.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.deployer.key_name}"

  tags = {
    Name = "shell"
    Project = "JRAnsible"
  }
}

resource "aws_instance" "packer-ansible" {
  ami           = "${data.aws_ami.image_packer-ansible.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.deployer.key_name}"

  user_data = <<EOD
#!/bin/bash
sudo cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to Jiangren Devops!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to Jiangren Devops!</h1>
<p>Hello from $(hostname -f)</p>
</body>
</html>
EOF
EOD

  tags = {
    Name = "ansible"
    Project = "JRAnsible"
  }
}