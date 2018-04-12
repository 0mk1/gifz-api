variable "name" {}
variable "environment" {}
variable "app_domain" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = "list"
}
variable "availability_zone" {}
variable "master_username" {}
variable "master_password" {}
variable "ingress_allow_security_groups" {
  type = "list"
}


resource "aws_security_group" "default" {
  name        = "${var.name}-sg"
  description = "Allows traffic to RDS from other security groups"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = "5432"
    to_port         = "5432"
    protocol        = "TCP"
    security_groups = ["${var.ingress_allow_security_groups}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-sg"
    Domain = "${var.app_domain}"
    Environment = "${var.environment}"
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.15.0"

  identifier = "${replace(var.name, "-", "")}"
  name = "${replace(var.name, "-", "")}"

  license_model = "postgresql-license"
  engine = "postgres"
  engine_version = "9.6.6"
  family = "postgres9.6"
  parameters = []

  instance_class = "db.t2.micro"
  storage_type = "gp2"
  allocated_storage = 20
  storage_encrypted = false

  username = "${var.master_username}"
  password = "${var.master_password}"
  port = "5432"

  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  availability_zone = "${var.availability_zone}"
  subnet_ids = ["${var.subnet_ids}"]
  multi_az = false
  publicly_accessible = false

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window = "03:00-06:00"
  backup_retention_period = 0  # No backups

  skip_final_snapshot = true
  final_snapshot_identifier = "${var.name}"

  auto_minor_version_upgrade = true
  apply_immediately = true

  tags = {
    Name = "${var.name}-rds"
    Domain = "${var.app_domain}"
    Environment = "${var.environment}"
  }
}


output "db_security_group_id" {
  value = "${aws_security_group.default.id}"
}
output "url" {
  value = "postgres://${module.rds.this_db_instance_username}:${module.rds.this_db_instance_password}@${module.rds.this_db_instance_endpoint}/${module.rds.this_db_instance_name}"
}
