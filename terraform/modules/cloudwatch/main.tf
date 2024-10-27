resource "aws_cloudwatch_log_group" "log_roup" {
  name = var.log_roup_name
  retention_in_days = var.retention_days
}

resource "aws_cloudwatch_event_rule" "node_creation" {
  name = "EC2InstanceLaunchRule"
  description = "Log the records at the time of Cassandra node creation"
  event_pattern = jsonencode({
    "source": ["aws.autoscaling"],
    "detail-type": ["EC2 Instance Launch Successful"],
    "detail": {
      "AutoScalingGroupName": ["${var.aws_autoscaling_group}"]
    }
  })
}

# New Target for CloudWatch Log Group
resource "aws_cloudwatch_event_target" "log_target" {
  rule = aws_cloudwatch_event_rule.node_creation.name
  arn  = aws_cloudwatch_log_group.log_roup.arn
}