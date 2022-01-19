resource "aws_security_group" "app1_sg" {
  name        = "app1_sg"
  description = "Allow inbound traffic to app1 poc"
  vpc_id      = "vpc-00000000000000000"

  ingress {
    description = "All traffic from VPC"
    port        = "all"
    protocol    = "all"
    cidr_blocks = ["10.0.0.0/8"]

  }

  egress {
    description = "All traffic to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "app1_sg"
  }
}