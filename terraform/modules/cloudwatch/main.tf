resource "aws_cloudwatch_log_group" "log_roup" {
  name = var.log_roup_name
  retention_in_days = var.retention_days
}

# Step 1a: Create a Log Stream within the CloudWatch Log Group
resource "aws_cloudwatch_log_stream" "ec2_creation_log_stream" {
  name           = "ec2-creation-log-stream"
  log_group_name = aws_cloudwatch_log_group.log_roup.name
}

resource "aws_cloudwatch_event_rule" "node_creation" {
  name = "EC2InstanceLaunchRule"
  description = "Log the records at the time of Cassandra node creation"
  event_pattern = jsonencode({
  "source": ["aws.ec2"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["ec2.amazonaws.com"],
    "eventName": ["RunInstances"],
    "userIdentity": {
      "invokedBy": ["autoscaling.amazonaws.com"]
    }
  }
})
}

# Step 2: Create an IAM Role for EventBridge to publish to CloudWatch Logs
# resource "aws_iam_role" "eventbridge_logging_role" {
#   name = "EventBridgeLoggingRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "events.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "eventbridge_logging_policy" {
#   name = "EventBridgeLoggingPolicy"
#   role = aws_iam_role.eventbridge_logging_role.name

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Resource = aws_cloudwatch_log_group.log_roup.arn
#       }
#     ]
#   })
# }

resource "aws_cloudwatch_event_target" "log_target" {
  rule = aws_cloudwatch_event_rule.node_creation.name
  arn  = aws_cloudwatch_log_group.log_roup.arn
  target_id = "CloudWatchLogTarget"
}

output "event_rule_arn" {
  value = aws_cloudwatch_event_rule.node_creation.arn
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.log_roup.arn
}