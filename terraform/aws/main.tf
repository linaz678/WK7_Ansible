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

resource "aws_security_group_rule" "allow_80" { //create security group and alllow 80, 
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "sg-0212b4a25537026c9"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_8080" {// 之后我们要通过ansible 的playbook装一下Jenkins 所以需要开放8080 端口
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = "sg-0212b4a25537026c9"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_key_pair" "deployer" { // create aws_key pair
  key_name   = "ansible-deployer-key"
  public_key = file("/var/lib/jenkins/.ssh/id_rsa.pub") // invoke jinkins 用户已有的密钥，没有新生成密钥
}

data "aws_ami" "image_packer-shell" { //search aws_ami with the filter ami aws_ami.iamge_packer-shell
  most_recent = true
  owners = ["self"]
  filter {
    name = "tag:Base_AMI_Name"
    values = ["jiangren-packer-demo-1"] // choose ami with tag jiangren-packer-demo-1, defined in packer file line 29 
  }
}

data "aws_ami" "image_packer-ansible" {// search aws_ami ami aws_ami.iamge_packer-ansible
  most_recent = true
  owners = ["self"]
  filter {
    name = "tag:Base_AMI_Name"
    values = ["jiangren-packer-demo-2"]
  }
}

resource "aws_instance" "packer-shell" {
  ami           = "${data.aws_ami.image_packer-shell.id}" //create instance using ami iamge from the data 
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.deployer.key_name}"

  tags = {
    Name = "shell"//EC2 tage shell 
    Project = "JRAnsible"
  }
}

resource "aws_instance" "packer-ansible" {
  ami           = "${data.aws_ami.image_packer-ansible.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.deployer.key_name}"
//<<EOF EOD 表面一整段字符串， 把一整段文字写进index.html
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
    Name = "ansible" //EC2 tag ansible 
    Project = "JRAnsible"
  }
}

