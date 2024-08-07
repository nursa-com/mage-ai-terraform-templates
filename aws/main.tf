terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.23.0"
    }
  }
  backend "s3" {
    bucket  = "nursa-github-oidc-terraform-aws-tfstates"
    key     = "dataeng-mage/prod/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.app_name}-${var.app_environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-ecs"
    }
  )
}

resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.app_name}-${var.app_environment}-logs"

  tags = var.common_tags
}

resource "aws_ssm_parameter" "image_uri" {
  name  = "/prod/dataeng-mage/image-uri"
  type  = "String"
  value = "mage-ai/mage-ai:latest"
  tags = var.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}

data "template_file" "env_vars" {
  template = file("env_vars.json")

  vars = {
    aws_region_name = var.aws_region
    database_connection_url     = "postgresql+psycopg2://${jsondecode(data.aws_secretsmanager_secret_version.latest.secret_string)["user"]}:${jsondecode(data.aws_secretsmanager_secret_version.latest.secret_string)["password"]}@${aws_db_instance.rds.address}:5432/mage"
    ec2_subnet_id               = data.aws_subnet.subnet_1.id,
    redis_url                   = "redis://${aws_elasticache_cluster.redis_cluster.cache_nodes[0].address}/0"
    redshift_host               = var.redshift_host
    redshift_dbname             = var.redshift_dbname
    redshift_user               = var.redshift_user
    redshift_cluster_id         = var.redshift_cluster_id
  }
}

resource "aws_ecs_task_definition" "aws-ecs-task" {
  family = "${var.app_name}-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.app_name}-${var.app_environment}-container",
      "image": "${aws_ssm_parameter.image_uri.value}",
      "environment": ${data.template_file.env_vars.rendered},
      "essential": true,
      "mountPoints": [
        {
          "readOnly": false,
          "containerPath": "/home/src",
          "sourceVolume": "${var.app_name}-fs"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.app_name}-${var.app_environment}"
        }
      },
      "portMappings": [
        {
          "containerPort": 6789,
          "hostPort": 6789
        }
      ],
      "cpu": ${var.ecs_task_cpu},
      "memory": ${var.ecs_task_memory},
      "networkMode": "awsvpc",
      "ulimits": [
        {
          "name": "nofile",
          "softLimit": 16384,
          "hardLimit": 32768
        }
      ],
       "healthCheck": {
          "command": ["CMD-SHELL", "curl -f http://localhost:6789/api/status || exit 1"],
          "interval": 30,
          "timeout": 5,
          "retries": 3,
          "startPeriod": 10
        }
    }
  ]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = var.ecs_task_memory
  cpu                      = var.ecs_task_cpu
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn

  volume {
    name = "${var.app_name}-fs"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.file_system.id
      transit_encryption      = "ENABLED"
      transit_encryption_port = null
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-ecs-td"
    }
  )

  # depends_on = [aws_lambda_function.terraform_lambda_func]
}

data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.app_name}-${var.app_environment}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true
  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-ecs-service"
    }
  )

  network_configuration {
    subnets          = [data.aws_subnet.subnet_1.id, data.aws_subnet.subnet_2.id]
    assign_public_ip = true
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-${var.app_environment}-container"
    container_port   = 6789
  }

  depends_on = [aws_lb_listener.https_listener]
}

resource "aws_security_group" "service_security_group" {
  vpc_id = data.aws_vpc.aws-vpc.id

  ingress {
    from_port       = 6789
    to_port         = 6789
    protocol        = "tcp"
    cidr_blocks     = values(local.cidr_blocks)
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-service-sg"
    }
  )
}

resource "aws_s3_bucket" "bucket" {
  bucket = "mage-dataeng-prod"
  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-s3-bucket"
    }
  )
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
