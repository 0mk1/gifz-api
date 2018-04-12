variable "name" {}
variable "region" {
  default = "us-east-1"
}
variable "environment" {}
variable "domain" {}
variable "app_domain" {}
variable "image_url" {}
variable "image_version" {
  default = "latest"
}
variable "vpc_id" {}
variable "subnet_ids" {
  type = "list"
}
variable "app_port" {}
variable "db_endpoint" {}
variable "redis_endpoint" {}
variable "mail_servername" {}
variable "mail_username" {}
variable "mail_password" {}
variable "cdn_endpoint" {}
variable "s3_bucket_name" {}


resource "aws_iam_role" "ecs_task_assume" {
  name = "ecs_task_assume"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecs_task_assume" {
  name = "ecs_task_assume"
  role = "${aws_iam_role.ecs_task_assume.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
              "arn:aws:s3:::${var.s3_bucket_name}",
              "arn:aws:s3:::${var.s3_bucket_name}/*"
            ]
        }
    ]
}
EOF
}

resource "aws_cloudwatch_log_group" "django" {
  name              = "/ecs/${var.name}-django"
  retention_in_days = 1
  tags {
    Name = "${var.name} Django"
    Domain = "${var.domain}"
    Environment = "${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "celery" {
  name              = "/ecs/${var.name}-celery"
  retention_in_days = 1
  tags {
    Name = "${var.name} Celery"
    Domain = "${var.domain}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "lb" {
  name = "${var.name}-lb-sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-lb-sg"
    Domain = "${var.domain}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "django" {
  name = "${var.name}-sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    protocol = "TCP"
    from_port = "${var.app_port}"
    to_port = "${var.app_port}"
    security_groups = ["${aws_security_group.lb.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-sg"
    Domain = "${var.domain}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "celery" {
  name = "${var.name}-celery-sg"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-celery-sg"
    Domain = "${var.domain}"
    Environment = "${var.environment}"
  }
}

resource "aws_alb" "django" {
  name            = "${var.name}-alb"
  subnets         = ["${var.subnet_ids}"]
  security_groups = ["${aws_security_group.lb.id}"]

  tags {
    Name = "${var.name}-alb"
    Domain = "${var.domain}"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_target_group" "django" {
  name        = "${var.name}-alb-tg"
  vpc_id      = "${var.vpc_id}"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path = "/v1/"
    matcher = "200,400,401"
  }

  tags {
    Name = "${var.name}-alb-tg"
    Domain = "${var.domain}"
    Environment = "${var.environment}"
  }
}

resource "aws_alb_listener" "django-http" {
  load_balancer_arn = "${aws_alb.django.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.django.id}"
    type             = "forward"
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"
}

data "template_file" "django" {
  template = "${file("${path.module}/django_task_definition.json")}"

  vars {
    name = "${var.name}-django"
    command = "[\"uwsgi\", \"--ini=./uwsgi.ini\"]"
    region = "${var.region}"
    app_domain = "${var.app_domain}"
    db_endpoint = "${var.db_endpoint}"
    redis_endpoint = "${var.redis_endpoint}"
    image_url = "${var.image_url}"
    image_version = "${var.image_version}"
    app_port = "${var.app_port}"
    allowed_hosts = "${aws_alb.django.dns_name}"
    mail_servername = "${var.mail_servername}"
    mail_username = "${var.mail_username}"
    mail_password = "${var.mail_password}"
    s3_bucket_name = "${var.s3_bucket_name}"
    cdn_endpoint = "${var.cdn_endpoint}"
  }
}

resource "aws_ecs_task_definition" "django" {
  family = "${var.name}-django"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "512"
  memory = "1024"
  execution_role_arn = "${aws_iam_role.ecs_task_assume.arn}"
  task_role_arn = "${aws_iam_role.ecs_task_assume.arn}"
  container_definitions = "${data.template_file.django.rendered}"
}

resource "aws_ecs_service" "django" {
  name = "${var.name}-django"
  cluster = "${aws_ecs_cluster.this.id}"
  launch_type = "FARGATE"
  task_definition = "${aws_ecs_task_definition.django.arn}"
  desired_count = 1

  network_configuration {
    security_groups = ["${aws_security_group.django.id}"]
    subnets = ["${var.subnet_ids}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.django.id}"
    container_name = "${var.name}-django"
    container_port = "${var.app_port}"
  }

  depends_on = [
    "aws_alb_listener.django-http",
  ]
}

data "template_file" "celery" {
  template = "${file("${path.module}/django_task_definition.json")}"

  vars {
    name = "${var.name}-celery"
    command = "[\"celery\"]"
    region = "${var.region}"
    db_endpoint = "${var.db_endpoint}"
    app_domain = "${var.app_domain}"
    redis_endpoint = "${var.redis_endpoint}"
    image_url = "${var.image_url}"
    image_version = "${var.image_version}"
    app_port = "${var.app_port}"
    allowed_hosts = "${aws_alb.django.dns_name}"
    mail_servername = "${var.mail_servername}"
    mail_username = "${var.mail_username}"
    mail_password = "${var.mail_password}"
    s3_bucket_name = "${var.s3_bucket_name}"
    cdn_endpoint = "${var.cdn_endpoint}"
  }
}

resource "aws_ecs_task_definition" "celery" {
  family = "${var.name}-celery"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "512"
  memory = "1024"
  task_role_arn = "${aws_iam_role.ecs_task_assume.arn}"
  execution_role_arn = "${aws_iam_role.ecs_task_assume.arn}"
  container_definitions = "${data.template_file.celery.rendered}"
}

resource "aws_ecs_service" "celery" {
  name = "${var.name}-celery"
  cluster = "${aws_ecs_cluster.this.id}"
  launch_type = "FARGATE"
  task_definition = "${aws_ecs_task_definition.celery.arn}"
  desired_count = 1

  network_configuration {
    security_groups = ["${aws_security_group.celery.id}"]
    subnets = ["${var.subnet_ids}"]
    assign_public_ip = true
  }
}


output "django_security_group_id" {
  value = "${aws_security_group.django.id}"
}
output "celery_security_group_id" {
  value = "${aws_security_group.celery.id}"
}
