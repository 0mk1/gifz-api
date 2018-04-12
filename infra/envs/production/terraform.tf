terraform {
  required_version = "~> 0.10"

  backend "s3" {
    region = "us-east-1"
    bucket = "terraform-gifz-api"
    key = "production/terraform.tfstate"
    encrypt = true
  }
}

variable app_name {}
variable domain {}
variable app_domain {}
variable environment {}
variable region {}
variable db_master_username {}
variable db_master_password {}


provider "aws" {
  region = "${var.region}"
}

module "registry" {
  source = "../../modules/registry"
  name = "${var.app_name}"
}

module "stack" {
  source = "../../modules/stack"
  app_name = "${var.app_name}"
  domain = "${var.domain}"
  app_domain = "${var.app_domain}"
  environment = "${var.environment}"
  image_url = "${module.registry.url}"
  region = "${var.region}"
  db_master_username = "${var.db_master_username}"
  db_master_password = "${var.db_master_password}"
}


output "registry_url" {
  value = "${module.registry.url}"
}
output "ses_verification_token" {
  value = "${module.stack.ses_verification_token}"
}
