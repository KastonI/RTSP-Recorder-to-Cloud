#---------------Provider---------------
provider "aws" {
  region = var.aws_region
}

#---------------VPC---------------
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name   = "Final Project"
  }
}

#---------------Subnets---------------
resource "aws_subnet" "public" {
  cidr_block              = var.public_subnet_cidr
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags                    = { Name = "Public subnet" }
}

resource "aws_subnet" "private" {
  cidr_block              = var.private_subnet_cidr
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false
  tags                    = { Name = "Private subnet" }
}

#---------------GateWays---------------

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "NAT Elastic IP" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "Internet Gateway" }
}

resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = aws_subnet.public.id
  allocation_id = aws_eip.nat_eip.allocation_id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "NAT Gateway" }
}

#---------------Security_Groups---------------

resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  tags = { Name = "Bastion Security Group" }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  } 

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Private Security Group" }
}

resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Public Security Group" }
}

#---------------Route_tables---------------

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "Public Route Table" }
}

resource "aws_route_table_association" "public_rt_assosiation" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id = aws_subnet.public.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = { Name = "Private Route Table" }
}

resource "aws_route_table_association" "private_rt_assosiation" {
  route_table_id = aws_route_table.private_rt.id
  subnet_id = aws_subnet.private.id
}

#---------------SSH-key---------------

resource "aws_key_pair" "ssh_public_key" {
  key_name   = "ssh_public_key"
  public_key = var.ssh_public_key
}

#---------------IAM_role---------------

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
  description = "Policy for upload to S3"

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

#---------------Instances---------------

resource "aws_instance" "nginx_instance" {
  subnet_id              = aws_subnet.public.id
  ami                    = var.aws_instance
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh_public_key.key_name
  vpc_security_group_ids = [aws_security_group.public_sg.id] 

  associate_public_ip_address = true
  tags = {
    Name   = "Nginx Reverse Proxy"
    role   = "nginx"
    subnet = "public"
  }
}

resource "aws_instance" "bastion_host_instance" {
  subnet_id              = aws_subnet.public.id
  ami                    = var.aws_instance
  instance_type          = var.instance_type
  key_name               = aws_key_pair.ssh_public_key.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id] 

  associate_public_ip_address = true
  tags = {
    Name   = "Bastion Host"
    role   = "bastion"
    subnet = "public"
  }
}

resource "aws_instance" "rtsp_to_web_instance" {
  subnet_id              = aws_subnet.private.id
  ami                    = var.aws_instance
  instance_type          = var.instance_type_rtsp
  key_name               = aws_key_pair.ssh_public_key.key_name
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  iam_instance_profile = aws_iam_instance_profile.s3_instance_profile.name

  tags = {
    Name   = "Rtsp to web"
    role   = "rtsp"
    subnet = "private"
  }
}
