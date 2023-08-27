data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_launch_template" "main" {
  count         = length(local.private_subnet_cidrs)
  name_prefix   = "main"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  user_data     = filebase64("data.sh")

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = aws_subnet.private_subnet[count.index].id
    security_groups             = [aws_security_group.main_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${local.project}-launch-template"
      Environment = local.environment
    }
  }
}

resource "aws_autoscaling_group" "main" {
  count = length(local.private_subnet_cidrs)
  
  desired_capacity       = 1
  max_size               = 2
  min_size               = 1
  target_group_arns      = [aws_lb_target_group.lb_tg.arn]
  vpc_zone_identifier    = [aws_subnet.private_subnet[count.index].id]
  placement_group        = aws_placement_group.deployment_strategy.id

  launch_template {
    id      = aws_launch_template.main[count.index].id
    version = "$Latest"
  }
}

resource "aws_placement_group" "deployment_strategy" {
  name     = "deployment_strategy"
  strategy = "spread"
}