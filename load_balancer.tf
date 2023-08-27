resource "aws_lb" "lb" {
  name               = "lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public_subnet[*].id
  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "logs"
    enabled = true
  }

  tags = {
    Name        = "${local.project}-load-balancer"
    Environment = local.environment
  }
}

resource "aws_lb_target_group" "lb_tg" {
  name     = "lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  tags = {
    Name        = "${local.project}-target-group"
    Environment = local.environment
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }

  tags = {
    Name        = "${local.project}-alb-listener"
    Environment = local.environment
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "${local.project}-alb-logs"

  tags = {
    Name        = "${local.project}-alb-logs"
    Environment = local.environment
  }
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "s3:PutObject",
        Effect = "Allow",
        Resource = "${aws_s3_bucket.alb_logs.arn}/*",
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
      }
    ]
  })
}

output "alb_dns_name" {
  value = aws_lb.lb.dns_name
}