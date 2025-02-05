variable "aws_region" {
  default     = "eu-central-1"
  description = "Aws region"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block for VPC"
}

variable "public_subnet_cidr" {
  default     = "10.0.1.0/24"
  description = "Public CIDR for VPC"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}


variable "availability_zone" {
  default = "eu-central-1a"
}

variable "s3_bucket_name" {
  default = "terraform-kast"
}

variable "aws_instance" {
  default = "ami-07eef52105e8a2059"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "instance_test_key"
}

variable "s3_records" {
  default = "s3-for-records1"
}