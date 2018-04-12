variable "name" {}
variable "app_domain" {}
variable "environment" {}
variable "vpc_id" {}
variable "subnet_ids" {
  type = "list"
}
variable "ingress_allow_security_groups" {
  type = "list"
}

resource "aws_security_group" "this" {
  name        = "${var.name}-sg"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = "6379"
    to_port         = "6379"
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

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-subng"
  subnet_ids = ["${var.subnet_ids}"]
}

resource "aws_elasticache_cluster" "this" {
  cluster_id = "${var.name}"
  engine = "redis"
  node_type = "cache.t2.micro"
  num_cache_nodes = 1
  parameter_group_name = "default.redis3.2"
  port = 6379
  subnet_group_name = "${aws_elasticache_subnet_group.this.name}"
  security_group_ids = ["${aws_security_group.this.id}"]
  apply_immediately = true

  tags = {
    Name = "${var.name}"
    Domain = "${var.app_domain}"
    Environment = "${var.environment}"
  }
}

output "url" {
  value = "${aws_elasticache_cluster.this.cache_nodes.0.address}"
}
