provider "aws" {
  version    = "~> 2.2"
  region     = "eu-west-1"
}

terraform {
  backend "s3" {
    bucket = "personal-test-cluster-tfstate"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
