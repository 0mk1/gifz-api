variable app_name {}
variable domain {}
variable app_domain {}
variable environment {}
variable region {}
variable image_url {}
variable db_master_username {}
variable db_master_password {}


provider "aws" {
  region = "${var.region}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.29.0"
  name = "${var.app_name}-${var.environment}-vpc"
  cidr = "10.0.0.0/16"
  azs = ["${var.region}a", "${var.region}b"]
  public_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  private_subnets = []
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]
  elasticache_subnets = ["10.0.31.0/24", "10.0.32.0/24"]
  create_database_subnet_group = false
  enable_nat_gateway = false
  enable_vpn_gateway = false
  enable_s3_endpoint = false

  tags = {
    Name = "${var.app_name} VPC"
    Domain = "${var.domain}"
    Environment = "${var.environment}"
  }
}

module "db" {
  source = "../../modules/db"
  name = "${var.app_name}-${var.environment}-db"
  environment = "${var.environment}"
  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.database_subnets}"
  app_domain = "${var.domain}"
  master_username = "${var.db_master_username}"
  master_password = "${var.db_master_password}"
  availability_zone = "${var.region}a"
  ingress_allow_security_groups = [
    "${module.django_ecs_cluster.django_security_group_id}",
    "${module.django_ecs_cluster.celery_security_group_id}"
  ]
}

module "redis" {
  source = "../../modules/redis"
  name = "${var.app_name}-${var.environment}"
  environment = "${var.environment}"
  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.elasticache_subnets}"
  app_domain = "${var.domain}"
  ingress_allow_security_groups = [
    "${module.django_ecs_cluster.django_security_group_id}",
    "${module.django_ecs_cluster.celery_security_group_id}"
  ]
}

module "mail" {
  source = "../../modules/mail"
  domain = "${var.app_domain}"
  region = "${var.region}"
}

module "cdn" {
  source = "../../modules/cdn"
  domain = "static.${var.app_domain}"
  environment = "${var.environment}"
}

module "django_ecs_cluster" {
  source = "../../modules/django_ecs_fargate_cluster"
  name = "${var.app_name}-${var.environment}-ecs"
  environment = "${var.environment}"
  domain = "${var.domain}"
  app_domain = ""
  image_url = "${var.image_url}"
  vpc_id = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.public_subnets}"
  app_port = 8000
  db_endpoint = "${module.db.url}"
  redis_endpoint = "${module.redis.url}"
  mail_servername = "${module.mail.smtp_server_name}"
  mail_username = "${module.mail.smtp_username}"
  mail_password = "${module.mail.smtp_password}"
  cdn_endpoint = "${module.cdn.endpoint}"
  s3_bucket_name = "${module.cdn.bucket_name}"
}


output "ses_verification_token" {
  value = "${module.mail.verification_token}"
}
