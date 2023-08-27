resource "aws_cloudwatch_log_group" "main" {
  name              = "${local.project}-log-group"
  retention_in_days = 14

  tags = {
    Name        = "${local.project}-log-group"
    Environment = local.environment
  }
}

# Custom CloudWatch Metric (e.g., for tracking specific application metrics)
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  count               = length(local.private_subnet_cidrs)
  alarm_name          = "${local.project}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm when server CPU exceeds 80%"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[count.index].name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up[count.index].arn]

  tags = {
    Name        = "${local.project}-high-cpu-utilization"
    Environment = local.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_utilization" {
  count               = length(local.private_subnet_cidrs)
  alarm_name          = "${local.project}-low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300" # 5 minutes to avoid premature scaling down
  statistic           = "Average"
  threshold           = "40"
  alarm_description   = "Alarm when server CPU is below 40%"
  alarm_actions       = [aws_autoscaling_policy.scale_down[count.index].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main[count.index].name
  }

  tags = {
    Name        = "${local.project}-low-cpu-utilization"
    Environment = local.environment
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  count                  = length(local.private_subnet_cidrs)
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main[count.index].name
}

resource "aws_autoscaling_policy" "scale_down" {
  count                  = length(local.private_subnet_cidrs)
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main[count.index].name
}