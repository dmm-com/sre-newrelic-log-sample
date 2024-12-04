### ECS用 IAM Role ###
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsDMMTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test-attach1" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "test-attach2" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "test-attach3" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.example.arn
}

resource "aws_iam_policy" "example" {
  name   = "example_policy2"
  path   = "/"
  policy = data.aws_iam_policy_document.example.json
}

data "aws_iam_policy_document" "example" {
  statement {
    sid = "1"

    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
    ]

    resources = [
      aws_kinesis_firehose_delivery_stream.newrelic.arn
    ]
  }
}

### Amazon Data Firehose IAM Role ###

resource "aws_iam_role" "firehose" {
  name = "dmm-example-kinesis-firehose-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

}

/*
resource "aws_iam_role_policy_attachment" "firehose" {
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose.arn
}*/

resource "aws_iam_policy" "firehose" {
  name        = "dmm-example-kinesis-firehose-log-policy"
  path        = "/"
  description = "firehose-log"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "S3:*",
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.firehose.arn}",
          "${aws_s3_bucket.firehose.arn}/*"
        ]
      }
    ]
  })
}
