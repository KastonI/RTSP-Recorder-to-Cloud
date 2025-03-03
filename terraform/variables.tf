variable "aws_region" {
  default     = "" #"eu-central-1"
  description = "Aws region"
}

variable "vpc_cidr" {
  default     = "" #"10.0.0.0/16"
  description = "CIDR block for VPC"
}

variable "public_subnet_cidr" {
  default     = "" #"10.0.1.0/24"
  description = "Public CIDR for VPC"
}

variable "private_subnet_cidr" {
  default     = "" #"10.0.2.0/24"
  description = "Private CIDR for VPC"
}

variable "availability_zone" {
  default     = "" #"eu-central-1a"
  description = "Availability zone"
}

variable "aws_instance" {
  default     = "" #"ami-07eef52105e8a2059"
  description = "AMI for EC2 instances"
}

variable "instance_type" {
  default     = ""  #"t2.micro"
  description = "Instance type for common EC2"
}

variable "instance_type_rtsp" {
  default     = ""  #"t2.medium"
  description = "Instance type for RTSP EC2"
}

variable "ssh_public_key" {
  default     = ""
  description = "Public key for instances"
}

variable "s3_records" {
  default     = "" #"s3-for-records1"
  description = "S3 backet for records"
}