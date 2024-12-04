
data "aws_vpc_endpoint_service" "kinesis_firehose" {
  service      = "kinesis-firehose"
  service_type = "Interface"
}

resource "aws_vpc_endpoint" "firehose" {
  vpc_id             = data.aws_vpc.vpc.id
  service_name       = data.aws_vpc_endpoint_service.kinesis_firehose.service_name
  subnet_ids = data.aws_subnets.public.ids
  vpc_endpoint_type   = data.aws_vpc_endpoint_service.kinesis_firehose.service_type
  private_dns_enabled = true

  security_group_ids = [aws_security_group.vpc_endpoint.id]
}

resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "dmm-example-vpce-sg"
  description = "Security Group for VPC Endpoint"
  vpc_id      = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}