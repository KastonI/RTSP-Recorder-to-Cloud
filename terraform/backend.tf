terraform {
  backend "s3" {
    bucket  = ""
    key     = "terraform/terraform.tfstate"
    region  = ""
    encrypt = true
  }
}