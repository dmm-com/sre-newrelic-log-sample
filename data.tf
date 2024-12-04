
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["sre-stg-vpc"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["sre-stg-subnet-public*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["sre-stg-subnet-private*"]
  }
}