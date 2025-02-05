provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket  = "final-project-tfstate"
    key     = "terraform/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

#--------------------------VPC--------------------------
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "Final Project"
    create = "terraform"
  }
}

#--------------------------Subnets--------------------------
resource "aws_subnet" "public" {
  cidr_block = var.public_subnet_cidr
  vpc_id = aws_vpc.vpc.id
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true
  tags = { Name = "Public subnet"}
}

resource "aws_subnet" "private" {
  cidr_block = var.private_subnet_cidr
  vpc_id = aws_vpc.vpc.id
  availability_zone = var.availability_zone
  map_public_ip_on_launch = false
  tags = { Name = "Private subnet"}
}

#--------------------------IGW+NAT_GW--------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "Nat elastic IP"
  }
}

resource "aws_eip" "bastion_host_eip" {
  domain = "vpc"
  tags = {
    Name = "Nat elastic IP"
  }
}

resource "aws_eip_association" "eip_association" {
  instance_id   = aws_instance.bastion_host_instance.id
  allocation_id = aws_eip.bastion_host_eip.id
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id = aws_subnet.public.id
  allocation_id = aws_eip.nat_eip.allocation_id
  depends_on = [ aws_eip.nat_eip ]
  tags = {
    Name = "Nat Gatewway"
  }
}

#--------------------------SG--------------------------

resource "aws_security_group" "my_sg" {
  vpc_id      = aws_vpc.vpc.id
  description = "Allow SSH, HTTP, HTTPS"

  # ingress {
  #   description = "SSH"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "TCP"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # ingress {
  #   description = "HTTP"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "TCP"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

    ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Security Group"
  }
}

#--------------------------RT--------------------------

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "Private Route Table"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_association" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

#--------------------------IAM_role--------------------------
resource "aws_iam_role" "s3_uploader_role" {
  name = "S3UploaderRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com",
          "ecs-tasks.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = "Iam role for Recorder"
  }
}

resource "aws_iam_policy" "s3_upload_policy" {
  name        = "S3UploadPolicy"
  description = "Политика для загрузки в S3"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject"],
      "Resource": "arn:aws:s3:::${var.s3_records}/*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.s3_uploader_role.name
  policy_arn = aws_iam_policy.s3_upload_policy.arn
}


resource "aws_iam_instance_profile" "s3_instance_profile" {
  name = "S3UploaderInstanceProfile"
  role = aws_iam_role.s3_uploader_role.name
}


#--------------------------Public_instance--------------------------

resource "aws_instance" "nginx_instance" {
  subnet_id = aws_subnet.public.id
  ami = var.aws_instance
  instance_type = var.instance_type
  key_name = var.key_name
  security_groups = [aws_security_group.my_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "Nginx Reverse Proxy"
    role = "nginx"
    subnet = "public"
  }
}

resource "aws_instance" "bastion_host_instance" {
  subnet_id = aws_subnet.public.id
  ami = var.aws_instance
  instance_type = var.instance_type
  key_name = var.key_name
  security_groups = [aws_security_group.my_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "Bastion Host"
    role = "bastion"
    subnet = "public"
  }
}



resource "aws_instance" "rtsp_to_web_instance" {
  subnet_id = aws_subnet.public.id
  ami = var.aws_instance
  instance_type = "t2.medium"
  key_name = var.key_name
  security_groups = [aws_security_group.my_sg.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.s3_instance_profile.name

  tags = {
    Name = "Rtsp to web"
    role = "rtsp"
    subnet = "public"
  }
}

