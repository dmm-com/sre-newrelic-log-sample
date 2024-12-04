
provider "aws" {
  region = "ap-northeast-1"
}

############################################################
# ECS
############################################################
resource "aws_ecs_cluster" "example" {
  name = "dmm-example-cluster"
}

resource "aws_ecs_task_definition" "example" {
  family                   = "dmm-example-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "nginx:latest"
      cpu       = 128
      memory    = 256
      essential = true
      portMappings : [
        {
          "containerPort" : 80,
          "hostPort" : 80
        }
      ]
      logConfiguration = {
        logDriver : "awsfirelens",
        options : {
          Name : "firehose",
          region : "ap-northeast-1",
          delivery_stream : "dmm-example-cluster-log"
        }
      },
    },
    {
      name      = "log-router"
      image     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:latest"
      essential = false
      firelensConfiguration = {
        type : "fluentbit"
      },
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.example.name
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "fluentbit"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/ecs/fluentbit"
  retention_in_days = 7
}


resource "aws_ecs_service" "example" {
  name                 = "example-service"
  cluster              = aws_ecs_cluster.example.id
  task_definition      = aws_ecs_task_definition.example.arn
  desired_count        = 1
  force_new_deployment = true
  launch_type          = "FARGATE"


  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.example.id]
    assign_public_ip = true
  }
}

resource "aws_security_group" "example" {

  name        = "ecs-sg"
  description = "Security group for ECS"

  vpc_id = data.aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["111.108.92.1/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ssm_parameter" "newrelic" {
  name = "/newrelic-license-key"
}

resource "aws_kinesis_firehose_delivery_stream" "newrelic" {

  name = "dmm-example-cluster-log"

  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "https://aws-api.newrelic.com/firehose/v1"
    name               = "New Relic"
    access_key         = data.aws_ssm_parameter.newrelic.value
    buffering_size     = 5
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose.arn
    s3_backup_mode     = "AllData"

    request_configuration {
      content_encoding = "GZIP"
    }

    s3_configuration {
      role_arn           = aws_iam_role.firehose.arn
      bucket_arn         = aws_s3_bucket.firehose.arn
      buffering_size     = 5
      buffering_interval = 60
      compression_format = "GZIP"
    }
  }
}

resource "aws_s3_bucket" "firehose" {
  bucket = "dmm-example-kinesis-firehose-log-s3"
}
